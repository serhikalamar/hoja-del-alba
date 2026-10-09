import Foundation
import GameCore

// Cliente mínimo de la API REST de Supabase, sin dependencias (URLSession):
//   /auth/v1/...  → registro, inicio de sesión, refresco del token, cierre de sesión (Supabase Auth / GoTrue)
//   /rest/v1/...  → tabla `characters` (PostgREST, protegida con RLS)
// Esquema de la base de datos: backend/supabase/migrations/001_cuentas.sql.

/// Sesión iniciada. Se guarda en el llavero (nunca la contraseña).
struct AuthSession: Codable, Equatable, Sendable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var userID: String
    var username: String
    /// URL del proyecto con la que se inició: si cambia la configuración, la sesión ya no vale.
    var project: String

    /// El token de acceso dura ~1 h: se renueva un poco antes de que caduque.
    func expiresSoon(now: Date = Date()) -> Bool {
        expiresAt.timeIntervalSince(now) < 120
    }
}

enum AccountError: LocalizedError, Equatable {
    case notConfigured
    case offline
    case invalidCredentials
    case usernameTaken
    case weakPassword(String?)
    case confirmationRequired
    case invalidEmail
    case rateLimited
    case sessionExpired
    case characterLimit
    /// El personaje ya existe en la nube (p. ej. se reintentó una subida que sí había llegado).
    case alreadyExists
    case missingTables
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "Las cuentas no están activadas en esta versión."
        case .offline: "Sin conexión. Tus personajes se guardan en este dispositivo."
        case .invalidCredentials: "Usuario o contraseña incorrectos."
        case .usernameTaken: "Ese nombre de usuario ya existe. Prueba con otro."
        case .weakPassword(let detail): "Contraseña demasiado débil." + (detail.map { " \($0)" } ?? "")
        case .confirmationRequired: "Supabase pide confirmar el email: desactiva \"Confirm email\" (ver backend/README.md)."
        case .invalidEmail: "Supabase no acepta el email sintético: cambia EMAIL_PLANTILLA (ver backend/README.md)."
        case .rateLimited: "Demasiados intentos. Espera un momento y vuelve a probar."
        case .sessionExpired: "La sesión ha caducado: vuelve a iniciar sesión."
        case .characterLimit: "La cuenta ya tiene el máximo de \(Roster.maxCharacters) personajes."
        case .alreadyExists: "Ese personaje ya está en la nube."
        case .missingTables: "Faltan las tablas en Supabase: ejecuta backend/supabase/migrations/001_cuentas.sql."
        case .server(let message): message
        }
    }
}

/// Un personaje de la nube con su JSON (si se ha podido leer: una versión más nueva del juego podría no entenderse).
struct CloudCharacterRow {
    let info: CloudCharacterInfo
    let profile: PlayerProfile?
}

struct SupabaseClient: Sendable {
    let settings: AccountSettings

    // MARK: - Cuenta

    func signUp(username: String, password: String) async throws -> AuthSession {
        let name = AccountRules.normalizedUsername(username)
        let body: [String: Any] = [
            "email": AccountRules.email(forUsername: name, template: settings.emailTemplate),
            "password": password,
            "data": ["username": name],
        ]
        let (data, _) = try await send("POST", "auth/v1/signup", json: body)
        return try session(from: data, username: name)
    }

    func signIn(username: String, password: String) async throws -> AuthSession {
        let name = AccountRules.normalizedUsername(username)
        let body: [String: Any] = [
            "email": AccountRules.email(forUsername: name, template: settings.emailTemplate),
            "password": password,
        ]
        let (data, _) = try await send("POST", "auth/v1/token", query: [URLQueryItem(name: "grant_type", value: "password")], json: body)
        return try session(from: data, username: name)
    }

    func refresh(_ current: AuthSession) async throws -> AuthSession {
        let body: [String: Any] = ["refresh_token": current.refreshToken]
        do {
            let (data, _) = try await send("POST", "auth/v1/token", query: [URLQueryItem(name: "grant_type", value: "refresh_token")], json: body)
            return try session(from: data, username: current.username)
        } catch AccountError.invalidCredentials {
            throw AccountError.sessionExpired
        }
    }

    /// Cierra la sesión en el servidor (invalida el refresh token). Si falla, da igual: se borra en local.
    func signOut(_ current: AuthSession) async {
        _ = try? await send("POST", "auth/v1/logout", token: current.accessToken)
    }

    // MARK: - Personajes

    private static let infoColumns = "id,version,updated_at"

    /// Lo que hay en la nube, sin el JSON (es lo que se mira en cada sincronización).
    func characterInfos(_ current: AuthSession) async throws -> [CloudCharacterInfo] {
        let (data, _) = try await send("GET", "rest/v1/characters", query: [URLQueryItem(name: "select", value: Self.infoColumns)],
                                       token: current.accessToken)
        return try decodeInfos(data)
    }

    func characters(ids: [UUID], session current: AuthSession) async throws -> [CloudCharacterRow] {
        guard !ids.isEmpty else { return [] }
        let list = ids.map { $0.uuidString.lowercased() }.joined(separator: ",")
        let (data, _) = try await send("GET", "rest/v1/characters", query: [
            URLQueryItem(name: "select", value: Self.infoColumns + ",data"),
            URLQueryItem(name: "id", value: "in.(\(list))"),
        ], token: current.accessToken)
        let rows = try JSONDecoder().decode([FullRow].self, from: data)
        return rows.compactMap { row in
            guard let date = CloudDate.parse(row.updated_at) else { return nil }
            return CloudCharacterRow(info: CloudCharacterInfo(id: row.id, version: row.version, updatedAt: date), profile: row.data.profile)
        }
    }

    /// Crea el personaje en la nube.
    func insertCharacter(_ profile: PlayerProfile, session current: AuthSession) async throws -> CloudCharacterInfo {
        guard let id = profile.characterID else { throw AccountError.server("Personaje sin identificador.") }
        let body = try JSONEncoder().encode(Upload(id: id, name: Self.cloudName(profile), data: profile))
        let (data, _) = try await send("POST", "rest/v1/characters", query: [URLQueryItem(name: "select", value: Self.infoColumns)],
                                       body: body, token: current.accessToken, prefer: "return=representation")
        guard let info = try decodeInfos(data).first else { throw AccountError.server("Respuesta vacía al guardar.") }
        return info
    }

    /// Sobrescribe el personaje solo si en la nube sigue la versión `expectedVersion`.
    /// Devuelve `nil` si alguien lo cambió entretanto (lo resuelve la siguiente sincronización).
    func updateCharacter(_ profile: PlayerProfile, expectedVersion: Int, session current: AuthSession) async throws -> CloudCharacterInfo? {
        guard let id = profile.characterID else { throw AccountError.server("Personaje sin identificador.") }
        let body = try JSONEncoder().encode(Patch(name: Self.cloudName(profile), data: profile))
        let (data, _) = try await send("PATCH", "rest/v1/characters", query: [
            URLQueryItem(name: "id", value: "eq.\(id.uuidString.lowercased())"),
            URLQueryItem(name: "version", value: "eq.\(expectedVersion)"),
            URLQueryItem(name: "select", value: Self.infoColumns),
        ], body: body, token: current.accessToken, prefer: "return=representation")
        return try decodeInfos(data).first
    }

    func deleteCharacter(_ id: UUID, session current: AuthSession) async throws {
        _ = try await send("DELETE", "rest/v1/characters", query: [URLQueryItem(name: "id", value: "eq.\(id.uuidString.lowercased())")],
                           token: current.accessToken)
    }

    private static func cloudName(_ profile: PlayerProfile) -> String {
        let name = (profile.name ?? "Héroe").trimmingCharacters(in: .whitespaces)
        return String((name.isEmpty ? "Héroe" : name).prefix(32))
    }

    // MARK: - Formatos

    private struct Upload: Encodable {
        let id: UUID
        let name: String
        let data: PlayerProfile
    }

    private struct Patch: Encodable {
        let name: String
        let data: PlayerProfile
    }

    private struct InfoRow: Decodable {
        let id: UUID
        let version: Int
        let updated_at: String
    }

    private struct FullRow: Decodable {
        let id: UUID
        let version: Int
        let updated_at: String
        let data: LenientProfile
    }

    /// Si un personaje no se puede leer, se ignora ese personaje (no toda la lista).
    private struct LenientProfile: Decodable {
        let profile: PlayerProfile?
        init(from decoder: Decoder) throws {
            profile = try? PlayerProfile(from: decoder)
        }
    }

    private func decodeInfos(_ data: Data) throws -> [CloudCharacterInfo] {
        try JSONDecoder().decode([InfoRow].self, from: data).compactMap { row in
            CloudDate.parse(row.updated_at).map { CloudCharacterInfo(id: row.id, version: row.version, updatedAt: $0) }
        }
    }

    private struct TokenResponse: Decodable {
        struct User: Decodable { let id: String }
        let access_token: String?
        let refresh_token: String?
        let expires_in: Double?
        let expires_at: Double?
        let user: User?
    }

    private func session(from data: Data, username: String) throws -> AuthSession {
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)
        // Con "Confirm email" activado, el registro devuelve el usuario sin sesión.
        guard let access = response.access_token, let refresh = response.refresh_token, let user = response.user else {
            throw AccountError.confirmationRequired
        }
        let expiresAt = response.expires_at.map { Date(timeIntervalSince1970: $0) }
            ?? Date().addingTimeInterval(response.expires_in ?? 3600)
        return AuthSession(accessToken: access, refreshToken: refresh, expiresAt: expiresAt, userID: user.id,
                           username: username, project: settings.projectURL.absoluteString)
    }

    // MARK: - Peticiones

    private func send(_ method: String, _ path: String, query: [URLQueryItem] = [], json: [String: Any]? = nil,
                      body: Data? = nil, token: String? = nil, prefer: String? = nil) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: settings.projectURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty { components?.queryItems = query }
        guard let url = components?.url else { throw AccountError.notConfigured }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = method
        request.setValue(settings.publicKey, forHTTPHeaderField: "apikey")
        // La clave pública va solo en `apikey`; en Authorization va el token del jugador (si hay sesión).
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let prefer { request.setValue(prefer, forHTTPHeaderField: "Prefer") }
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let json {
            request.httpBody = try JSONSerialization.data(withJSONObject: json)
        } else if let body {
            request.httpBody = body
        }
        if request.httpBody != nil { request.setValue("application/json", forHTTPHeaderField: "Content-Type") }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError {
            switch error.code {
            case .notConnectedToInternet, .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
                 .dnsLookupFailed, .internationalRoamingOff, .dataNotAllowed:
                throw AccountError.offline
            default:
                throw AccountError.server("Error de red (\(error.code.rawValue)).")
            }
        }
        guard let http = response as? HTTPURLResponse else { throw AccountError.server("Respuesta no válida del servidor.") }
        guard (200..<300).contains(http.statusCode) else {
            throw Self.error(status: http.statusCode, body: data)
        }
        return (data, http)
    }

    /// Traduce los errores de Supabase Auth (`error_code`, `msg`) y de PostgREST (`code`, `message`).
    static func error(status: Int, body: Data) -> AccountError {
        let json = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]
        let code = (json["error_code"] as? String) ?? (json["code"] as? String) ?? (json["error"] as? String) ?? ""
        let message = (json["msg"] as? String) ?? (json["message"] as? String) ?? (json["error_description"] as? String) ?? ""
        let hint = json["hint"] as? String

        if hint == "limite_personajes" || message.contains("Máximo 8 personajes") { return .characterLimit }
        switch code {
        case "invalid_credentials":
            return .invalidCredentials
        case "invalid_grant":
            return message.lowercased().contains("refresh token") ? .sessionExpired : .invalidCredentials
        case "user_already_exists", "email_exists":
            return .usernameTaken
        case "23505":  // id de personaje repetido
            return .alreadyExists
        case "weak_password":
            return .weakPassword(nil)
        case "email_address_invalid", "email_address_not_authorized":
            return .invalidEmail
        case "email_not_confirmed":
            return .confirmationRequired
        case "over_request_rate_limit", "over_email_send_rate_limit":
            return .rateLimited
        case "refresh_token_not_found", "refresh_token_already_used", "session_not_found", "session_expired",
             "bad_jwt", "user_not_found", "PGRST301", "PGRST303":
            return .sessionExpired
        case "signup_disabled":
            return .server("El registro de cuentas está desactivado en Supabase (Authentication → Sign In / Providers).")
        case "PGRST205", "42P01":
            return .missingTables
        default:
            break
        }
        if status == 409 { return .alreadyExists }
        if status == 429 { return .rateLimited }
        if status == 401 { return .sessionExpired }
        // El trigger que crea el perfil falla si el nombre ya existe: Supabase lo devuelve como error de base de datos.
        if status >= 500, message.contains("Database error saving new user") { return .usernameTaken }
        return .server(message.isEmpty ? "Error del servidor (\(status))." : "Error del servidor: \(message)")
    }
}
