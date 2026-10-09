import Foundation
import GameCore
import Observation

/// Cuenta del jugador: sesión (en el llavero) y sincronización de los personajes con Supabase.
///
/// - Sin configuración o sin sesión, no hace nada: el juego guarda en local como siempre.
/// - Al guardar un personaje (`GameStore.save()`), lo apunta como cambiado y sube los cambios a los pocos segundos.
/// - Al iniciar sesión (y al abrir la app), sincroniza todo: sube, baja y borra según `RosterSync.plan` (GameCore).
/// - Durante una partida solo sube: lo que baje de la nube se aplica al volver a la selección de personaje.
///   (Lo que se sube es siempre `store.roster`, que guarda el personaje de verdad, nunca la copia de la arena.)
@Observable
final class AccountManager {
    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced(Date)
        case failed(String)
    }

    let configuration: SupabaseConfig.State
    private(set) var session: AuthSession?
    private(set) var syncStatus: SyncStatus = .idle
    /// Ocupado iniciando sesión, creando la cuenta o cerrándola.
    private(set) var isBusy = false
    /// Personajes que no caben en la cuenta (máximo 8) y se quedan solo en este dispositivo.
    private(set) var charactersOverLimit = 0
    /// Personajes de la nube que esta versión del juego no sabe leer.
    private(set) var unreadableCharacters = 0

    @ObservationIgnored private let client: SupabaseClient?
    @ObservationIgnored private weak var store: GameStore?
    @ObservationIgnored private var ledger: SyncLedger
    @ObservationIgnored private let ledgerURL: URL
    @ObservationIgnored private let backupFolder: URL
    @ObservationIgnored private var pendingSync: Task<Void, Never>?
    @ObservationIgnored private var isSyncing = false
    @ObservationIgnored private var syncAgain = false

    private static let keychainAccount = "sesion"

    init(configuration: SupabaseConfig.State = SupabaseConfig.load(),
         folder: URL = RosterStore.defaultURL().deletingLastPathComponent()) {
        self.configuration = configuration
        self.client = configuration.settings.map { SupabaseClient(settings: $0) }
        self.ledgerURL = folder.appendingPathComponent("sync-cuenta.json")
        self.backupFolder = folder.appendingPathComponent("copias-cuenta", isDirectory: true)
        self.ledger = (try? Data(contentsOf: ledgerURL)).flatMap { try? JSONDecoder().decode(SyncLedger.self, from: $0) } ?? SyncLedger()
        if let settings = configuration.settings,
           let data = KeychainStore.load(account: Self.keychainAccount),
           let saved = try? JSONDecoder().decode(AuthSession.self, from: data),
           saved.project == settings.projectURL.absoluteString {
            self.session = saved
        }
    }

    var isConfigured: Bool { client != nil }
    var username: String? { session?.username }

    /// Texto corto para el botón de la selección de personaje.
    var statusLine: String {
        guard let username else { return "Sin cuenta" }
        return "Conectado como \(username)"
    }

    // MARK: - Conexión con el juego

    /// Engancha la cuenta al estado del juego (una vez, al abrir la app).
    func attach(to store: GameStore) {
        guard self.store !== store else { return }
        self.store = store
        store.onCharacterSaved = { [weak self] saved, previous in
            self?.characterSaved(saved, previous: previous)
        }
        store.onCharacterDeleted = { [weak self] id in
            self?.characterDeleted(id)
        }
        scheduleSync(after: 0.5)
    }

    private func characterSaved(_ profile: PlayerProfile, previous: PlayerProfile?) {
        let before = ledger
        ledger.noteSave(profile, previous: previous, at: Date())
        guard ledger != before else { return }
        saveLedger()
        scheduleSync(after: 4)
    }

    private func characterDeleted(_ id: UUID) {
        ledger.noteDelete(id)
        saveLedger()
        scheduleSync(after: 1)
    }

    // MARK: - Iniciar y cerrar sesión

    /// Devuelve el mensaje de error para el jugador, o `nil` si ha ido bien.
    @MainActor
    func signIn(username: String, password: String) async -> String? {
        guard let client else { return AccountError.notConfigured.errorDescription }
        if let problem = AccountRules.usernameProblem(username) { return problem }
        guard !password.isEmpty else { return "Escribe la contraseña." }
        isBusy = true
        defer { isBusy = false }
        do {
            adopt(try await client.signIn(username: username, password: password))
        } catch {
            return Self.describe(error)
        }
        await syncNow()
        return nil
    }

    @MainActor
    func signUp(username: String, password: String) async -> String? {
        guard let client else { return AccountError.notConfigured.errorDescription }
        if let problem = AccountRules.usernameProblem(username) ?? AccountRules.passwordProblem(password) { return problem }
        isBusy = true
        defer { isBusy = false }
        do {
            adopt(try await client.signUp(username: username, password: password))
        } catch {
            return Self.describe(error)
        }
        await syncNow()
        return nil
    }

    /// Sube lo pendiente (si se puede) y cierra la sesión. Los personajes se quedan en el dispositivo.
    @MainActor
    func signOut() async {
        guard let client, let current = session else { return }
        isBusy = true
        defer { isBusy = false }
        pendingSync?.cancel()
        // Espera a la sincronización en curso (si la hay) y hace una última subida.
        while isSyncing { try? await Task.sleep(nanoseconds: 100_000_000) }
        await syncNow()
        await client.signOut(current)
        endSession()
    }

    private func adopt(_ newSession: AuthSession) {
        session = newSession
        if let data = try? JSONEncoder().encode(newSession) {
            KeychainStore.save(data, account: Self.keychainAccount)
        }
    }

    private func endSession(reason: String? = nil) {
        pendingSync?.cancel()
        session = nil
        KeychainStore.delete(account: Self.keychainAccount)
        syncStatus = reason.map { .failed($0) } ?? .idle
    }

    // MARK: - Sincronización

    /// Sincroniza dentro de unos segundos (agrupa varios guardados seguidos en una sola subida).
    func scheduleSync(after seconds: Double = 4) {
        guard client != nil, session != nil else { return }
        pendingSync?.cancel()
        pendingSync = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            // Tarea aparte: cancelar la espera no debe cortar una sincronización ya empezada.
            Task { @MainActor [weak self] in await self?.syncNow() }
        }
    }

    @MainActor
    func syncNow() async {
        guard let client, session != nil, let store else { return }
        if isSyncing {
            syncAgain = true
            return
        }
        isSyncing = true
        syncStatus = .syncing
        do {
            try await runSync(client: client, store: store)
            syncStatus = .synced(Date())
        } catch AccountError.sessionExpired {
            // El token pudo caducar entre medias: un intento más con uno nuevo.
            do {
                try await refreshSession(client: client, force: true)
                try await runSync(client: client, store: store)
                syncStatus = .synced(Date())
            } catch AccountError.sessionExpired {
                endSession(reason: AccountError.sessionExpired.errorDescription)
            } catch {
                syncStatus = .failed(Self.describe(error))
            }
        } catch {
            syncStatus = .failed(Self.describe(error))
        }
        isSyncing = false
        if syncAgain {
            syncAgain = false
            scheduleSync(after: 1)
        }
    }

    @MainActor
    private func refreshSession(client: SupabaseClient, force: Bool) async throws {
        guard let current = session else { throw AccountError.sessionExpired }
        guard force || current.expiresSoon() else { return }
        adopt(try await client.refresh(current))
    }

    @MainActor
    private func runSync(client: SupabaseClient, store: GameStore) async throws {
        try await refreshSession(client: client, force: false)
        guard let current = session else { return }

        switch RosterSync.ownership(of: ledger, userID: current.userID) {
        case .same:
            break
        case .adopt:
            // Personajes creados sin cuenta: pasan a esta cuenta.
            ledger.accountID = current.userID
            saveLedger()
        case .otherAccount:
            // Los personajes de este dispositivo son de otra cuenta: se apartan (copia) y se bajan los de esta.
            guard store.canApplyCloudChanges else { return }
            backup(store.roster, name: "otra-cuenta")
            let ids = store.roster.characters.compactMap(\.characterID)
            guard store.applyCloudChanges(upserts: [], removals: ids) else { return }
            ledger = SyncLedger(accountID: current.userID)
            saveLedger()
        }

        let remote = try await client.characterInfos(current)
        let plan = RosterSync.plan(localIDs: store.roster.characters.compactMap(\.characterID), ledger: ledger,
                                   remote: remote, maxCharacters: Roster.maxCharacters)
        charactersOverLimit = plan.overLimit.count

        // Subidas
        for upload in plan.uploads {
            guard let profile = store.roster.characters.first(where: { $0.characterID == upload.id }) else { continue }
            let info: CloudCharacterInfo?
            do {
                if let expected = upload.expectedVersion {
                    info = try await client.updateCharacter(profile, expectedVersion: expected, session: current)
                } else {
                    info = try await client.insertCharacter(profile, session: current)
                }
            } catch AccountError.alreadyExists, AccountError.characterLimit {
                info = nil  // se vuelve a decidir en la siguiente sincronización
            }
            guard let info else { continue }
            let now = store.roster.characters.first { $0.characterID == upload.id }
            ledger.markUploaded(upload.id, version: info.version, stillCurrent: now == profile)
            saveLedger()
        }

        // Borrados en la nube
        for id in plan.deleteRemote {
            try await client.deleteCharacter(id, session: current)
            ledger.forget(id)
        }
        for id in plan.staleDeletes { ledger.forget(id) }
        saveLedger()

        // Bajadas y borrados en local (solo fuera de una partida)
        guard !plan.downloads.isEmpty || !plan.deleteLocal.isEmpty, store.canApplyCloudChanges else { return }
        let rows = try await client.characters(ids: plan.downloads, session: current)
        var upserts: [PlayerProfile] = []
        var versions: [UUID: Int] = [:]
        var unreadable = 0
        for row in rows {
            guard var profile = row.profile else {
                unreadable += 1
                continue
            }
            profile.characterID = row.info.id
            upserts.append(profile)
            versions[row.info.id] = row.info.version
        }
        unreadableCharacters = unreadable
        // Copia de lo que se va a sustituir o borrar en local (conflictos y borrados desde otro dispositivo).
        let replaced = Set(plan.conflicts).intersection(versions.keys).union(plan.deleteLocal)
        let losers = store.roster.characters.filter { $0.characterID.map(replaced.contains) ?? false }
        if !losers.isEmpty { backup(Roster(characters: losers), name: "sustituidos") }

        guard store.applyCloudChanges(upserts: upserts, removals: plan.deleteLocal) else { return }
        for (id, version) in versions { ledger.markDownloaded(id, version: version) }
        for id in plan.deleteLocal { ledger.forget(id) }
        saveLedger()
    }

    // MARK: - Ficheros

    private func saveLedger() {
        guard let data = try? JSONEncoder().encode(ledger) else { return }
        try? FileManager.default.createDirectory(at: ledgerURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: ledgerURL, options: .atomic)
    }

    /// Copia de seguridad de personajes que la sincronización va a quitar o sustituir en este dispositivo.
    private func backup(_ roster: Roster, name: String) {
        guard !roster.characters.isEmpty, let data = try? JSONEncoder().encode(roster) else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let url = backupFolder.appendingPathComponent("\(formatter.string(from: Date()))-\(name).json")
        try? FileManager.default.createDirectory(at: backupFolder, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private static func describe(_ error: Error) -> String {
        if let error = error as? AccountError { return error.errorDescription ?? "Error desconocido." }
        if error is DecodingError { return "Respuesta inesperada de Supabase." }
        return error.localizedDescription
    }
}
