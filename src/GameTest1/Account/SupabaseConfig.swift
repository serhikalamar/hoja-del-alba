import Foundation
import GameCore

/// Configuración de las cuentas: `SupabaseConfig.plist` dentro de la app.
/// Ese fichero NO se versiona (está en .gitignore); la plantilla es `backend/SupabaseConfig.example.plist`.
/// Sin él, el juego funciona en local y la pantalla de cuenta lo explica.
enum SupabaseConfig {
    static let fileName = "SupabaseConfig"

    enum State: Equatable {
        /// No hay fichero, o tiene los valores de la plantilla.
        case missing
        /// Hay fichero pero algo está mal (p. ej. una clave secreta).
        case invalid(AccountSettings.Problem)
        case ready(AccountSettings)

        var settings: AccountSettings? {
            if case .ready(let settings) = self { return settings }
            return nil
        }
    }

    static func load(bundle: Bundle = .main) -> State {
        guard let url = bundle.url(forResource: fileName, withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return .missing }
        let result = AccountSettings.validated(
            url: values["SUPABASE_URL"] as? String,
            key: values["SUPABASE_CLAVE_PUBLICA"] as? String,
            emailTemplate: values["EMAIL_PLANTILLA"] as? String
        )
        switch result {
        case .success(let settings): return .ready(settings)
        case .failure(.missingURL), .failure(.missingKey): return .missing
        case .failure(let problem): return .invalid(problem)
        }
    }
}
