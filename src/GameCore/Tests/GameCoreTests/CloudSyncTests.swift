import Foundation
import Testing
@testable import GameCore

@Suite("Cuenta: reglas y configuración")
struct AccountRulesTests {
    @Test func usernames() {
        #expect(AccountRules.normalizedUsername("  Pepe_01 ") == "pepe_01")
        #expect(AccountRules.usernameProblem("Pepe_01") == nil)
        #expect(AccountRules.usernameProblem("ab") != nil)
        #expect(AccountRules.usernameProblem(String(repeating: "a", count: 21)) != nil)
        #expect(AccountRules.usernameProblem("toño") != nil)
        #expect(AccountRules.usernameProblem("pe pe") != nil)
        #expect(AccountRules.usernameProblem("pepe@x") != nil)
        #expect(AccountRules.usernameProblem("") != nil)
    }

    @Test func passwords() {
        #expect(AccountRules.passwordProblem("1234567") != nil)
        #expect(AccountRules.passwordProblem("12345678") == nil)
        #expect(AccountRules.passwordProblem("        ") != nil)
        #expect(AccountRules.passwordProblem(String(repeating: "x", count: 73)) != nil)
        #expect(AccountRules.passwordProblem(String(repeating: "x", count: 72)) == nil)
    }

    @Test func syntheticEmail() {
        #expect(AccountRules.email(forUsername: " Pepe ", template: "{usuario}@jugadores.valdehierro.app") == "pepe@jugadores.valdehierro.app")
        #expect(AccountRules.email(forUsername: "pepe", template: "yo+{usuario}@gmail.com") == "yo+pepe@gmail.com")
    }

    @Test func settingsFromTemplateAreMissing() {
        let result = AccountSettings.validated(url: "https://TU-PROYECTO.supabase.co", key: "PEGA-AQUI-LA-CLAVE", emailTemplate: nil)
        #expect(result == .failure(.missingURL))
        #expect(AccountSettings.validated(url: nil, key: nil, emailTemplate: nil) == .failure(.missingURL))
        #expect(AccountSettings.validated(url: "https://abc.supabase.co", key: "PEGA-AQUI", emailTemplate: nil) == .failure(.missingKey))
    }

    @Test func validSettings() throws {
        let settings = try AccountSettings.validated(url: "https://abc.supabase.co/", key: "sb_publishable_123", emailTemplate: "").get()
        #expect(settings.projectURL.absoluteString == "https://abc.supabase.co")
        #expect(settings.emailTemplate == AccountSettings.defaultEmailTemplate)
        // Supabase local (`supabase start`) va por http.
        #expect((try? AccountSettings.validated(url: "http://127.0.0.1:54321", key: "k", emailTemplate: nil).get()) != nil)
        #expect(AccountSettings.validated(url: "http://abc.supabase.co", key: "k", emailTemplate: nil) == .failure(.invalidURL))
        #expect(AccountSettings.validated(url: "https://abc.supabase.co", key: "k", emailTemplate: "sin-arroba") == .failure(.invalidEmailTemplate))
    }

    @Test func secretKeysAreRejected() {
        #expect(AccountSettings.validated(url: "https://abc.supabase.co", key: "sb_secret_abc", emailTemplate: nil) == .failure(.secretKey))
        #expect(AccountSettings.isSecretKey(fakeJWT(role: "service_role")))
        #expect(!AccountSettings.isSecretKey(fakeJWT(role: "anon")))
        #expect(!AccountSettings.isSecretKey("sb_publishable_abc"))
    }

    /// JWT sin firma válida, solo para probar la lectura del rol.
    private func fakeJWT(role: String) -> String {
        func b64(_ s: String) -> String {
            Data(s.utf8).base64EncodedString().replacingOccurrences(of: "=", with: "")
                .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
        }
        return b64(#"{"alg":"HS256","typ":"JWT"}"#) + "." + b64(#"{"iss":"supabase","role":"\#(role)"}"#) + ".firma"
    }

    @Test func serverDates() throws {
        let micro = try #require(CloudDate.parse("2026-10-07T10:20:30.123456+00:00"))
        let plain = try #require(CloudDate.parse("2026-10-07T10:20:30Z"))
        #expect(abs(micro.timeIntervalSince(plain) - 0.123) < 0.001)
        #expect(CloudDate.parse("2026-10-07 10:20:30.5+02:00") != nil)
        #expect(CloudDate.parse("ayer") == nil)
    }
}

@Suite("Cuenta: sincronización de personajes")
struct RosterSyncTests {
    let a = UUID()
    let b = UUID()
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func info(_ id: UUID, _ version: Int, minutes: Double = 0) -> CloudCharacterInfo {
        CloudCharacterInfo(id: id, version: version, updatedAt: t0.addingTimeInterval(minutes * 60))
    }

    func ledger(_ id: UUID, synced: Int?, dirty: Bool, changedMinutes: Double? = nil) -> SyncLedger {
        let date = changedMinutes.map { t0.addingTimeInterval($0 * 60) }
        return SyncLedger(accountID: "u1", entries: [id.uuidString: .init(syncedVersion: synced, dirty: dirty, localChangedAt: date)])
    }

    @Test func noteSaveOnlyCountsRealChanges() {
        var profile = PlayerProfile.newCharacter(name: "Aldric", race: .human, appearance: Appearance())
        let id = profile.characterID!
        var ledger = SyncLedger()
        ledger.markDownloaded(id, version: 3)
        ledger.noteSave(profile, previous: profile, at: t0)
        #expect(!ledger.isDirty(id))
        let before = profile
        profile.gold += 5
        ledger.noteSave(profile, previous: before, at: t0)
        #expect(ledger.isDirty(id))
        #expect(ledger.entry(id)?.localChangedAt == t0)
        #expect(ledger.entry(id)?.syncedVersion == 3)
        // Nuevo personaje (sin versión anterior): cambio.
        let fresh = PlayerProfile.newCharacter(name: "Helga", race: .dwarf, appearance: Appearance())
        ledger.noteSave(fresh, previous: nil, at: t0)
        #expect(ledger.isDirty(fresh.characterID!))
    }

    @Test func deletesAndUploads() {
        var ledger = SyncLedger()
        ledger.markDownloaded(a, version: 2)
        ledger.noteDelete(a)
        #expect(ledger.pendingDeletes == [a])
        // Nunca subido: se olvida sin más.
        ledger.markUploaded(b, version: 1, stillCurrent: true)
        ledger.forget(b)
        let c = UUID()
        ledger.entries[c.uuidString] = .init()
        ledger.noteDelete(c)
        #expect(ledger.entry(c) == nil)
        #expect(!ledger.pendingDeletes.contains(c))
        // Cambió durante la subida: sigue pendiente.
        ledger.markUploaded(b, version: 4, stillCurrent: false)
        #expect(ledger.isDirty(b))
        #expect(ledger.entry(b)?.syncedVersion == 4)
    }

    @Test func ownership() {
        #expect(RosterSync.ownership(of: SyncLedger(), userID: "u1") == .adopt)
        #expect(RosterSync.ownership(of: SyncLedger(accountID: "u1"), userID: "u1") == .same)
        #expect(RosterSync.ownership(of: SyncLedger(accountID: "u2"), userID: "u1") == .otherAccount)
    }

    @Test func newLocalCharacterIsCreated() {
        let plan = RosterSync.plan(localIDs: [a], ledger: SyncLedger(), remote: [], maxCharacters: 8)
        #expect(plan.uploads == [.init(id: a, expectedVersion: nil)])
        #expect(plan.conflicts.isEmpty)
    }

    @Test func nothingChanged() {
        let plan = RosterSync.plan(localIDs: [a], ledger: ledger(a, synced: 3, dirty: false), remote: [info(a, 3)], maxCharacters: 8)
        #expect(plan.isEmpty)
    }

    @Test func localChangeIsUploadedWithExpectedVersion() {
        let plan = RosterSync.plan(localIDs: [a], ledger: ledger(a, synced: 3, dirty: true), remote: [info(a, 3)], maxCharacters: 8)
        #expect(plan.uploads == [.init(id: a, expectedVersion: 3)])
        #expect(plan.downloads.isEmpty)
    }

    @Test func remoteChangeIsDownloaded() {
        let plan = RosterSync.plan(localIDs: [a], ledger: ledger(a, synced: 3, dirty: false), remote: [info(a, 5)], maxCharacters: 8)
        #expect(plan.downloads == [a])
        #expect(plan.uploads.isEmpty)
    }

    @Test func conflictNewestWins() {
        // Local cambiado a los 10 min; la nube a los 5 → gana local y sobrescribe la versión 5.
        let localWins = RosterSync.plan(localIDs: [a], ledger: ledger(a, synced: 3, dirty: true, changedMinutes: 10),
                                        remote: [info(a, 5, minutes: 5)], maxCharacters: 8)
        #expect(localWins.uploads == [.init(id: a, expectedVersion: 5)])
        #expect(localWins.conflicts == [a])
        // Al revés: gana la nube.
        let remoteWins = RosterSync.plan(localIDs: [a], ledger: ledger(a, synced: 3, dirty: true, changedMinutes: 5),
                                         remote: [info(a, 5, minutes: 10)], maxCharacters: 8)
        #expect(remoteWins.downloads == [a])
        #expect(remoteWins.conflicts == [a])
    }

    @Test func unknownLocalCopyLosesToCloud() {
        // Mismo personaje en local y en la nube, sin registro (p. ej. registro perdido): manda la nube.
        let plan = RosterSync.plan(localIDs: [a], ledger: SyncLedger(accountID: "u1"), remote: [info(a, 2)], maxCharacters: 8)
        #expect(plan.downloads == [a])
    }

    @Test func remoteDeletion() {
        let clean = RosterSync.plan(localIDs: [a], ledger: ledger(a, synced: 3, dirty: false), remote: [], maxCharacters: 8)
        #expect(clean.deleteLocal == [a])
        // Borrado en otro dispositivo pero jugado aquí: se conserva y se vuelve a subir.
        let played = RosterSync.plan(localIDs: [a], ledger: ledger(a, synced: 3, dirty: true), remote: [], maxCharacters: 8)
        #expect(played.deleteLocal.isEmpty)
        #expect(played.uploads == [.init(id: a, expectedVersion: nil)])
        #expect(played.conflicts == [a])
    }

    @Test func localDeletion() {
        var deleted = ledger(a, synced: 3, dirty: false)
        deleted.noteDelete(a)
        let plan = RosterSync.plan(localIDs: [], ledger: deleted, remote: [info(a, 3)], maxCharacters: 8)
        #expect(plan.deleteRemote == [a])
        // Si en la nube cambió después, no se borra: vuelve.
        let changed = RosterSync.plan(localIDs: [], ledger: deleted, remote: [info(a, 4)], maxCharacters: 8)
        #expect(changed.deleteRemote.isEmpty)
        #expect(changed.downloads == [a])
        // Ya no está en la nube: solo hay que olvidarlo.
        let gone = RosterSync.plan(localIDs: [], ledger: deleted, remote: [], maxCharacters: 8)
        #expect(gone.staleDeletes == [a])
    }

    @Test func cloudOnlyCharacterIsDownloaded() {
        let plan = RosterSync.plan(localIDs: [], ledger: SyncLedger(accountID: "u1"), remote: [info(b, 1)], maxCharacters: 8)
        #expect(plan.downloads == [b])
    }

    @Test func accountLimit() {
        let remote = (0..<7).map { _ in info(UUID(), 1) }
        let plan = RosterSync.plan(localIDs: [a, b], ledger: SyncLedger(), remote: remote, maxCharacters: 8)
        #expect(plan.uploads == [.init(id: a, expectedVersion: nil)])
        #expect(plan.overLimit == [b])
        #expect(plan.downloads.count == 7)
    }

    @Test func ledgerRoundTrip() throws {
        var ledger = ledger(a, synced: 2, dirty: true, changedMinutes: 1)
        ledger.pendingDeletes = [b]
        let data = try JSONEncoder().encode(ledger)
        #expect(try JSONDecoder().decode(SyncLedger.self, from: data) == ledger)
    }
}
