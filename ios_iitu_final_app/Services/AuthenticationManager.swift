import Foundation
import LocalAuthentication
import Combine

class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var authError: String?

    private let keychain = KeychainManager()
    private let defaults = UserDefaults.standard

    override init() {
        super.init()
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        // Check if PIN is set
        if keychain.retrievePIN() != nil {
            isAuthenticated = checkBiometrics() ?? false
        } else {
            isAuthenticated = true // First launch - no auth required
        }
    }

    func setupPIN(_ pin: String) {
        keychain.savePIN(pin)
        isAuthenticated = true
    }

    func authenticate() {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Fallback to PIN
            authenticateWithPIN()
            return
        }

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Разблокируйте FinanceFlow") { [weak self] success, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    self.authError = nil
                } else {
                    self.authError = error?.localizedDescription ?? "Ошибка аутентификации"
                }
            }
        }
    }

    private func checkBiometrics() -> Bool? {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return true
        }

        return false
    }

    private func authenticateWithPIN() {
        // This will be handled in UI
        isAuthenticated = false
    }

    func logout() {
        isAuthenticated = false
    }

    func resetAuthentication() {
        keychain.deletePIN()
        isAuthenticated = false
    }
}

// MARK: - Keychain Manager
class KeychainManager {
    private let service = "com.financeflow.app"
    private let account = "authentication"

    func savePIN(_ pin: String) {
        guard let data = pin.data(using: .utf8) else {
            print("Failed to encode PIN")
            return
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
        ]

        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func retrievePIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
        ]

        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)

        if let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }

    func deletePIN() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        SecItemDelete(query as CFDictionary)
    }
}
