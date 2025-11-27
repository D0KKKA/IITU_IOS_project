import Foundation
import LocalAuthentication
import Combine

class AuthenticationManager: NSObject, ObservableObject {
    static let shared = AuthenticationManager()

    @Published var isAuthenticated = false
    @Published var authError: String?
    @Published var biometricType: BiometricType = .none
    @Published var isBiometricAvailable = false

    let keychain = KeychainManager()
    private let defaults = UserDefaults.standard

    override init() {
        super.init()
        checkAuthenticationStatus()
    }

    func checkAuthenticationStatus() {
        // Check if biometric or PIN is enabled
        if keychain.isBiometricEnabled() {
            // Check biometric availability
            updateBiometricStatus()
            isAuthenticated = false
        } else {
            isAuthenticated = true // First launch - no auth required
        }
    }

    func setupBiometric() {
        keychain.enableBiometric()
        updateBiometricStatus()
    }

    private func updateBiometricStatus() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricAvailable = true
            biometricType = context.biometryType == .faceID ? .faceID : .touchID
        } else {
            isBiometricAvailable = false
            biometricType = .none
        }
    }

    func authenticate() {
        let context = LAContext()
        context.localizedFallbackTitle = "Использовать PIN"
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authError = "Биометрия недоступна"
            return
        }

        let reason = biometricType == .faceID ? "Разблокируйте приложение через Face ID" : "Разблокируйте приложение через Touch ID"

        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    self.isAuthenticated = true
                    self.authError = nil
                } else {
                    if let error = error as? LAError {
                        switch error.code {
                        case .userCancel:
                            self.authError = "Аутентификация отменена"
                        case .userFallback:
                            self.authError = "Используйте PIN"
                        case .biometryNotEnrolled:
                            self.authError = "Биометрия не настроена"
                        case .biometryNotAvailable:
                            self.authError = "Биометрия недоступна"
                        default:
                            self.authError = error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    func disableBiometric() {
        keychain.disableBiometric()
        updateBiometricStatus()
        isAuthenticated = true
    }

    func logout() {
        isAuthenticated = false
    }
}

enum BiometricType {
    case faceID
    case touchID
    case none
}

// MARK: - Keychain Manager
class KeychainManager {
    private let service = "com.financeflow.app"
    private let biometricKey = "biometric_enabled"
    private let defaults = UserDefaults.standard

    func enableBiometric() {
        defaults.set(true, forKey: biometricKey)
    }

    func disableBiometric() {
        defaults.set(false, forKey: biometricKey)
    }

    func isBiometricEnabled() -> Bool {
        return defaults.bool(forKey: biometricKey)
    }
}
