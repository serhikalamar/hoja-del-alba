import Foundation
import Security

/// Guarda datos sensibles (la sesión de la cuenta) en el llavero del sistema.
/// La contraseña del jugador no se guarda nunca: solo los tokens que devuelve Supabase.
enum KeychainStore {
    static let service = "com.sergimartinez.gametest1.cuenta"

    private static func query(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    @discardableResult
    static func save(_ data: Data, account: String) -> Bool {
        let base = query(account)
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(base as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }
        var add = base
        add[kSecValueData as String] = data
        // Solo en este dispositivo y sin copia a iCloud: la sesión no viaja a otros aparatos.
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func load(account: String) -> Data? {
        var request = query(account)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    static func delete(account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }
}
