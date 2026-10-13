import Foundation

// Ajustes en vivo: qué hace el juego con la configuración publicada desde el panel de administración. Sin red.
// La app (src/GameTest1/Account/RemoteConfig.swift) la descarga de `GET /rest/v1/rpc/published_config` con la clave
// pública, guarda la última respuesta en disco y usa esto para decidir qué aplicar y cuándo.
// Servidor: backend/supabase/migrations/002_panel.sql. Contrato del documento: `GameTuning` (assets/admin/contrato.md).
//
// Reglas:
// - Manda el servidor: si cambia la versión publicada (también al volver atrás, que publica una versión nueva), se aplica.
// - Si no hay nada publicado, se vuelve a los valores de serie del juego.
// - Un formato (`schema_version`) más nuevo que el que entiende esta versión del juego se ignora con un aviso:
//   se sigue con lo que hubiera (la caché o los valores de serie) hasta actualizar la app.
// - Si no se puede leer, se ignora (y la caché no se toca).
// - Solo se aplica fuera de una partida: lo que llega durante una se guarda como pendiente para la siguiente.

/// Configuración publicada, ya leída.
public struct PublishedTuning: Equatable, Sendable {
    /// Número de publicación (crece siempre: volver atrás publica una copia con un número nuevo).
    public let version: Int
    public let schemaVersion: Int
    public let publishedAt: Date?
    /// El documento, con `version` puesta a la versión publicada.
    public let tuning: GameTuning

    public init(version: Int, schemaVersion: Int, publishedAt: Date?, tuning: GameTuning) {
        self.version = version
        self.schemaVersion = schemaVersion
        self.publishedAt = publishedAt
        var tuning = tuning
        tuning.version = version
        self.tuning = tuning
    }
}

/// Lo que dice el servidor (o la caché) sobre la configuración publicada.
public enum RemoteTuningResponse: Equatable, Sendable {
    /// No hay nada publicado: valores de serie.
    case nothingPublished
    case published(PublishedTuning)
    /// Formato más nuevo que el que entiende esta versión del juego.
    case tooNew(version: Int, schemaVersion: Int)
    /// No se ha podido leer (el motivo, para el log).
    case unreadable(String)

    /// Lee la respuesta de `published_config()`: una lista JSON con 0 o 1 filas
    /// `{ "version", "schema_version", "data", "published_at" }`.
    public static func parse(_ body: Data, supportedSchemaVersion: Int = GameTuning.currentSchemaVersion) -> RemoteTuningResponse {
        guard let json = try? JSONSerialization.jsonObject(with: body) else { return .unreadable("La respuesta no es JSON.") }
        let rows: [[String: Any]]
        if let list = json as? [[String: Any]] {
            rows = list
        } else if let single = json as? [String: Any] {
            rows = [single]
        } else {
            return .unreadable("La respuesta no es una lista de filas.")
        }
        // Debería haber como mucho una; si hubiera más, la de versión más alta.
        guard let row = rows.max(by: { (intValue($0["version"]) ?? 0) < (intValue($1["version"]) ?? 0) }) else {
            return .nothingPublished
        }
        guard let version = intValue(row["version"]), version > 0 else { return .unreadable("Fila sin versión.") }
        guard let document = row["data"] as? [String: Any] else { return .unreadable("La versión \(version) no tiene un objeto en data.") }
        // El formato puede venir en la columna y dentro del documento: manda el más alto.
        let schema = max(intValue(row["schema_version"]) ?? 1, intValue(document["schemaVersion"]) ?? 1)
        guard schema <= supportedSchemaVersion else { return .tooNew(version: version, schemaVersion: schema) }
        let tuning: GameTuning
        do {
            let data = try JSONSerialization.data(withJSONObject: document)
            tuning = try JSONDecoder().decode(GameTuning.self, from: data)
        } catch {
            return .unreadable("La versión \(version) no se puede leer como GameTuning: \(Self.describe(error))")
        }
        let publishedAt = (row["published_at"] as? String).flatMap(CloudDate.parse)
        return .published(PublishedTuning(version: version, schemaVersion: schema, publishedAt: publishedAt, tuning: tuning))
    }

    private static func intValue(_ value: Any?) -> Int? {
        guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
        let double = number.doubleValue
        guard double.isFinite, double == double.rounded(), abs(double) < 1e9 else { return nil }
        return Int(double)
    }

    private static func describe(_ error: Error) -> String {
        guard let error = error as? DecodingError else { return error.localizedDescription }
        let context: DecodingError.Context
        switch error {
        case .typeMismatch(_, let c), .valueNotFound(_, let c), .keyNotFound(_, let c), .dataCorrupted(let c): context = c
        @unknown default: return "\(error)"
        }
        let path = context.codingPath.map { $0.intValue.map(String.init) ?? $0.stringValue }.joined(separator: "/")
        return path.isEmpty ? context.debugDescription : "\(path): \(context.debugDescription)"
    }
}

/// Estado de los ajustes en vivo en esta ejecución del juego: qué versión está aplicada y qué espera a aplicarse.
public struct RemoteTuningState: Equatable, Sendable {
    /// Un cambio de ajustes que hay que aplicar.
    public enum Change: Equatable, Sendable {
        case apply(PublishedTuning)
        /// Volver a los valores de serie (ya no hay nada publicado).
        case reset

        /// Versión que queda aplicada (nil = valores de serie).
        public var version: Int? {
            if case .apply(let published) = self { return published.version }
            return nil
        }

        /// El documento que hay que pasar a `GameTuning.apply`.
        public var tuning: GameTuning {
            if case .apply(let published) = self { return published.tuning }
            return GameTuning()
        }
    }

    /// Qué hacer con la caché en disco tras una respuesta del servidor.
    public enum CacheAction: Equatable, Sendable {
        case keep, save, delete
    }

    public struct Outcome: Equatable, Sendable {
        public let cache: CacheAction
        /// Para el log (nil = nada que contar).
        public let message: String?
    }

    /// Como mucho una descarga cada tanto al volver a primer plano (al abrir el juego siempre se pide).
    public static let minimumFetchInterval: TimeInterval = 15 * 60

    /// Versión aplicada en el juego (nil = valores de serie).
    public private(set) var appliedVersion: Int?
    /// Cambio que espera a un momento seguro (fuera de una partida).
    public private(set) var pending: Change?
    /// Última descarga que salió bien.
    public private(set) var lastFetch: Date?

    public init() {}

    /// ¿Toca preguntar al servidor? Tras un fallo (sin red) se vuelve a intentar en la siguiente ocasión.
    public func shouldFetch(now: Date, minimumInterval: TimeInterval = RemoteTuningState.minimumFetchInterval) -> Bool {
        guard let lastFetch else { return true }
        let elapsed = now.timeIntervalSince(lastFetch)
        return elapsed >= minimumInterval || elapsed < 0  // (< 0: han cambiado la hora del dispositivo)
    }

    public mutating func noteFetched(at date: Date) {
        lastFetch = date
    }

    /// Versión que tendrá el juego cuando se aplique lo pendiente.
    public var targetVersion: Int? {
        pending.map(\.version) ?? appliedVersion
    }

    /// Llega una respuesta (del servidor o de la caché). Deja pendiente lo que haya que aplicar.
    public mutating func receive(_ response: RemoteTuningResponse) -> Outcome {
        switch response {
        case .published(let published):
            if published.version == appliedVersion {
                pending = nil
                return Outcome(cache: .save, message: nil)
            }
            let isNew = pending?.version != published.version
            pending = .apply(published)
            return Outcome(cache: .save, message: isNew ? "Ajustes en vivo: versión \(published.version) recibida." : nil)
        case .nothingPublished:
            pending = appliedVersion == nil ? nil : .reset
            return Outcome(cache: .delete, message: appliedVersion == nil ? nil : "Ajustes en vivo: ya no hay nada publicado; se vuelve a los valores de serie.")
        case .tooNew(let version, let schemaVersion):
            return Outcome(cache: .keep, message: "Ajustes en vivo: se ignora la versión \(version): su formato (schema_version \(schemaVersion)) "
                           + "es más nuevo que el de este juego (\(GameTuning.currentSchemaVersion)). Hay que actualizar la app.")
        case .unreadable(let reason):
            return Outcome(cache: .keep, message: "Ajustes en vivo: no se pudo leer la configuración publicada (\(reason)).")
        }
    }

    /// En un momento seguro (fuera de una partida): el cambio que hay que aplicar ahora, que queda como aplicado.
    public mutating func takePending() -> Change? {
        guard let change = pending else { return nil }
        pending = nil
        appliedVersion = change.version
        return change
    }
}

/// Última respuesta del servidor guardada en disco (tal cual llegó), para aplicarla sin red al abrir el juego.
public struct RemoteTuningCache: Sendable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() -> Data? {
        try? Data(contentsOf: url)
    }

    public func save(_ body: Data) {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? body.write(to: url, options: .atomic)
    }

    public func delete() {
        try? FileManager.default.removeItem(at: url)
    }
}
