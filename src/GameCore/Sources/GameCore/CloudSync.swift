import Foundation

// Cuentas y guardado en la nube (Supabase): reglas y sincronización, sin red.
// La app (src/GameTest1/Account/) hace las peticiones; aquí se decide qué subir, qué bajar y qué borrar.
// Detalles del servidor en backend/README.md.

// MARK: - Reglas de la cuenta

public enum AccountRules {
    public static let usernameLength = 3...20
    public static let passwordLength = 8...72
    /// En la plantilla de email, se sustituye por el nombre de usuario.
    public static let usernamePlaceholder = "{usuario}"

    private static let usernameCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789_")

    /// Los nombres de usuario no distinguen mayúsculas: `Pepe` y `pepe` son la misma cuenta.
    public static func normalizedUsername(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    /// `nil` si el nombre vale; si no, el motivo (para enseñárselo al jugador).
    /// Las mismas reglas que la restricción `profiles_username_formato` de la migración SQL.
    public static func usernameProblem(_ raw: String) -> String? {
        let name = normalizedUsername(raw)
        if name.isEmpty { return "Escribe un nombre de usuario." }
        guard usernameLength.contains(name.count) else {
            return "El usuario debe tener entre \(usernameLength.lowerBound) y \(usernameLength.upperBound) caracteres."
        }
        guard name.unicodeScalars.allSatisfy({ usernameCharacters.contains($0) }) else {
            return "Usa solo letras sin acentos (a-z), números y _."
        }
        return nil
    }

    /// `nil` si la contraseña vale. Máximo 72 bytes: es el límite de bcrypt, que usa Supabase.
    public static func passwordProblem(_ password: String) -> String? {
        if password.count < passwordLength.lowerBound {
            return "La contraseña debe tener al menos \(passwordLength.lowerBound) caracteres."
        }
        if password.utf8.count > passwordLength.upperBound {
            return "La contraseña es demasiado larga (máximo \(passwordLength.upperBound) caracteres)."
        }
        if password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "La contraseña no puede ser solo espacios."
        }
        return nil
    }

    /// Supabase Auth inicia sesión con email: cada usuario tiene un email "sintético" sacado de la plantilla.
    public static func email(forUsername raw: String, template: String) -> String {
        template.replacingOccurrences(of: usernamePlaceholder, with: normalizedUsername(raw))
    }
}

// MARK: - Configuración del proyecto de Supabase

/// URL del proyecto y clave pública, ya comprobadas. Vienen de `SupabaseConfig.plist` (no versionado).
public struct AccountSettings: Equatable, Sendable {
    public let projectURL: URL
    /// Clave pública: la `anon` (JWT) o la `sb_publishable_...`. Nunca la `service_role` ni la `sb_secret_...`.
    public let publicKey: String
    public let emailTemplate: String

    public static let defaultEmailTemplate = "{usuario}@jugadores.valdehierro.app"

    public enum Problem: Error, Equatable, Sendable {
        case missingURL, invalidURL, missingKey, secretKey, invalidEmailTemplate

        public var message: String {
            switch self {
            case .missingURL: "Falta la URL del proyecto de Supabase."
            case .invalidURL: "La URL de Supabase no es válida (debe ser https://<proyecto>.supabase.co)."
            case .missingKey: "Falta la clave pública (anon / publishable) de Supabase."
            case .secretKey: "Esa clave es secreta (service_role / sb_secret). En la app solo va la clave pública."
            case .invalidEmailTemplate: "La plantilla de email debe contener {usuario} y una @."
            }
        }
    }

    /// Comprueba los valores del fichero de configuración. Los textos de la plantilla de ejemplo cuentan como vacíos.
    public static func validated(url rawURL: String?, key rawKey: String?, emailTemplate rawTemplate: String?) -> Result<AccountSettings, Problem> {
        let urlText = (rawURL ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let key = (rawKey ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var template = (rawTemplate ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if template.isEmpty { template = defaultEmailTemplate }

        guard !urlText.isEmpty, !isPlaceholder(urlText) else { return .failure(.missingURL) }
        guard var components = URLComponents(string: urlText), let host = components.host, !host.isEmpty else {
            return .failure(.invalidURL)
        }
        let isLocal = ["localhost", "127.0.0.1"].contains(host)
        guard components.scheme == "https" || (components.scheme == "http" && isLocal) else { return .failure(.invalidURL) }
        // Solo el origen: las rutas /auth/v1 y /rest/v1 las pone la app.
        components.path = ""
        components.query = nil
        components.fragment = nil
        guard let url = components.url else { return .failure(.invalidURL) }

        guard !key.isEmpty, !isPlaceholder(key) else { return .failure(.missingKey) }
        guard !isSecretKey(key) else { return .failure(.secretKey) }

        guard template.contains(AccountRules.usernamePlaceholder), template.contains("@") else {
            return .failure(.invalidEmailTemplate)
        }
        return .success(AccountSettings(projectURL: url, publicKey: key, emailTemplate: template))
    }

    static func isPlaceholder(_ text: String) -> Bool {
        let upper = text.uppercased()
        return upper.contains("TU-PROYECTO") || upper.contains("PEGA-AQUI") || upper.contains("PEGA_AQUI")
    }

    /// Claves que dan acceso total a la base de datos: no pueden ir dentro de la app.
    public static func isSecretKey(_ key: String) -> Bool {
        if key.hasPrefix("sb_secret_") { return true }
        return jwtRole(key) == "service_role"
    }

    /// El campo `role` de un JWT (sin comprobar la firma: solo para avisar de claves equivocadas).
    static func jwtRole(_ token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var base64 = parts[1].replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let data = Data(base64Encoded: base64),
              let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return payload["role"] as? String
    }
}

// MARK: - Fechas del servidor

public enum CloudDate {
    /// Fechas de Postgres (`2026-10-07T10:20:30.123456+00:00`): fracciones de segundo de cualquier longitud.
    public static func parse(_ text: String) -> Date? {
        var value = text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "T")
        // Recorta la fracción a milisegundos, que es lo que entiende ISO8601DateFormatter.
        if let dot = value.firstIndex(of: ".") {
            let afterDot = value.index(after: dot)
            let digitsEnd = value[afterDot...].firstIndex { !$0.isNumber } ?? value.endIndex
            var digits = String(value[afterDot..<digitsEnd])
            digits = String((digits + "000").prefix(3))
            value = String(value[..<dot]) + "." + digits + String(value[digitsEnd...])
        }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: value) { return date }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: value)
    }
}

// MARK: - Sincronización

/// Lo que dice el servidor de un personaje (sin el JSON, que solo se baja si hace falta).
public struct CloudCharacterInfo: Equatable, Sendable {
    public let id: UUID
    /// Sube en 1 en cada escritura (lo hace un trigger en Postgres).
    public let version: Int
    /// Hora del servidor de la última escritura.
    public let updatedAt: Date

    public init(id: UUID, version: Int, updatedAt: Date) {
        self.id = id
        self.version = version
        self.updatedAt = updatedAt
    }
}

/// Registro local de la sincronización: qué versión de la nube tiene cada personaje y si ha cambiado desde entonces.
/// Se guarda junto a `roster.json` (fichero aparte para no tocar el formato de los personajes).
public struct SyncLedger: Codable, Equatable, Sendable {
    public struct Entry: Codable, Equatable, Sendable {
        /// Versión de la nube con la que coincidía la copia local la última vez (`nil`: nunca se ha subido).
        public var syncedVersion: Int?
        /// Cambiado en local desde la última sincronización.
        public var dirty: Bool
        /// Hora (del dispositivo) del último cambio local: decide los conflictos.
        public var localChangedAt: Date?

        public init(syncedVersion: Int? = nil, dirty: Bool = true, localChangedAt: Date? = nil) {
            self.syncedVersion = syncedVersion
            self.dirty = dirty
            self.localChangedAt = localChangedAt
        }
    }

    /// Cuenta (id de usuario de Supabase) a la que pertenecen los personajes de este dispositivo. `nil`: sin cuenta todavía.
    public var accountID: String?
    /// Por id de personaje (texto, para que el JSON sea legible).
    public var entries: [String: Entry]
    /// Personajes borrados en local que aún hay que borrar en la nube.
    public var pendingDeletes: Set<UUID>

    public init(accountID: String? = nil, entries: [String: Entry] = [:], pendingDeletes: Set<UUID> = []) {
        self.accountID = accountID
        self.entries = entries
        self.pendingDeletes = pendingDeletes
    }

    public func entry(_ id: UUID) -> Entry? { entries[id.uuidString] }

    /// Sin registro = nunca sincronizado = hay que subirlo.
    public func isDirty(_ id: UUID) -> Bool { entry(id)?.dirty ?? true }

    /// Se llama al guardar un personaje. Solo cuenta como cambio si es distinto de lo que había guardado.
    public mutating func noteSave(_ profile: PlayerProfile, previous: PlayerProfile?, at date: Date) {
        guard let id = profile.characterID, profile != previous else { return }
        var current = entry(id) ?? Entry()
        current.dirty = true
        current.localChangedAt = date
        entries[id.uuidString] = current
        pendingDeletes.remove(id)
    }

    /// Borrado en local: si ya estaba en la nube, queda pendiente de borrar allí.
    public mutating func noteDelete(_ id: UUID) {
        if entry(id)?.syncedVersion != nil {
            pendingDeletes.insert(id)
        } else {
            entries[id.uuidString] = nil
        }
    }

    /// Subida correcta. Si el personaje cambió mientras se subía (`stillCurrent == false`), sigue pendiente.
    public mutating func markUploaded(_ id: UUID, version: Int, stillCurrent: Bool) {
        var current = entry(id) ?? Entry()
        current.syncedVersion = version
        current.dirty = !stillCurrent
        entries[id.uuidString] = current
    }

    /// Bajado de la nube: la copia local es exactamente esa versión.
    public mutating func markDownloaded(_ id: UUID, version: Int) {
        entries[id.uuidString] = Entry(syncedVersion: version, dirty: false, localChangedAt: nil)
        pendingDeletes.remove(id)
    }

    /// Ya no existe ni en local ni en la nube.
    public mutating func forget(_ id: UUID) {
        entries[id.uuidString] = nil
        pendingDeletes.remove(id)
    }
}

/// A quién pertenecen los personajes de este dispositivo al iniciar sesión.
public enum RosterOwnership: Equatable, Sendable {
    /// Ya eran de esta cuenta.
    case same
    /// Personajes sin cuenta: pasan a esta cuenta (se suben).
    case adopt
    /// Eran de otra cuenta: se apartan (copia de seguridad) y se bajan los de esta.
    case otherAccount
}

/// Qué hacer con cada personaje.
public struct SyncPlan: Equatable, Sendable {
    public struct Upload: Equatable, Sendable {
        public let id: UUID
        /// Versión que debe tener la nube para sobrescribirla (`nil`: crear el personaje en la nube).
        public let expectedVersion: Int?

        public init(id: UUID, expectedVersion: Int?) {
            self.id = id
            self.expectedVersion = expectedVersion
        }
    }

    public var uploads: [Upload] = []
    public var downloads: [UUID] = []
    public var deleteRemote: [UUID] = []
    public var deleteLocal: [UUID] = []
    /// Cambiaron a la vez en local y en la nube (o se borraron en un lado y cambiaron en el otro).
    /// Ya están resueltos dentro de `uploads`/`downloads`; la app guarda una copia de la versión perdedora.
    public var conflicts: [UUID] = []
    /// No caben en la cuenta (máximo de personajes): se quedan solo en este dispositivo.
    public var overLimit: [UUID] = []
    /// Borrados pendientes que ya no están en la nube: basta con olvidarlos.
    public var staleDeletes: [UUID] = []

    public init() {}

    public var isEmpty: Bool {
        uploads.isEmpty && downloads.isEmpty && deleteRemote.isEmpty && deleteLocal.isEmpty && staleDeletes.isEmpty
    }
}

public enum RosterSync {
    public static func ownership(of ledger: SyncLedger, userID: String) -> RosterOwnership {
        guard let owner = ledger.accountID else { return .adopt }
        return owner == userID ? .same : .otherAccount
    }

    /// Decide la sincronización comparando la lista local, el registro y lo que hay en la nube.
    ///
    /// Reglas (en caso de duda, no perder progreso):
    /// - Solo cambió un lado → gana ese lado.
    /// - Cambiaron los dos → gana el cambio más reciente (`localChangedAt` frente a `updated_at` del servidor).
    /// - Borrado en un lado y cambiado en el otro → se conserva el personaje.
    /// - Las subidas llevan la versión esperada: si alguien escribió entretanto, el servidor no la aplica
    ///   y se vuelve a decidir en la siguiente sincronización.
    public static func plan(localIDs: [UUID], ledger: SyncLedger, remote: [CloudCharacterInfo], maxCharacters: Int) -> SyncPlan {
        var plan = SyncPlan()
        let remoteByID = Dictionary(remote.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let localSet = Set(localIDs)

        // Solo en la nube: bajarlo, o borrarlo si se borró aquí y nadie lo ha tocado después.
        for info in remote where !localSet.contains(info.id) {
            if ledger.pendingDeletes.contains(info.id) {
                if info.version == ledger.entry(info.id)?.syncedVersion {
                    plan.deleteRemote.append(info.id)
                } else {
                    plan.downloads.append(info.id)
                    plan.conflicts.append(info.id)
                }
            } else {
                plan.downloads.append(info.id)
            }
        }
        plan.staleDeletes = ledger.pendingDeletes.filter { remoteByID[$0] == nil && !localSet.contains($0) }
            .sorted { $0.uuidString < $1.uuidString }

        var remoteCount = remote.count - plan.deleteRemote.count
        for id in localIDs {
            let dirty = ledger.isDirty(id)
            let synced = ledger.entry(id)?.syncedVersion
            guard let info = remoteByID[id] else {
                if synced != nil && !dirty {
                    // Estaba en la nube, aquí no ha cambiado y allí ya no está: se borró en otro dispositivo.
                    plan.deleteLocal.append(id)
                    continue
                }
                if synced != nil { plan.conflicts.append(id) }  // borrado allí, cambiado aquí: se conserva
                if remoteCount < maxCharacters {
                    plan.uploads.append(.init(id: id, expectedVersion: nil))
                    remoteCount += 1
                } else {
                    plan.overLimit.append(id)
                }
                continue
            }
            if info.version == synced {
                if dirty { plan.uploads.append(.init(id: id, expectedVersion: info.version)) }
            } else if !dirty {
                plan.downloads.append(id)
            } else {
                plan.conflicts.append(id)
                let localDate = ledger.entry(id)?.localChangedAt ?? .distantPast
                if localDate > info.updatedAt {
                    plan.uploads.append(.init(id: id, expectedVersion: info.version))
                } else {
                    plan.downloads.append(id)
                }
            }
        }
        return plan
    }
}
