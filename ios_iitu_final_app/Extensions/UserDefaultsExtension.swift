import Foundation

extension UserDefaults {
    private static let defaultAccountIdKey = "com.financeflow.defaultAccountId"

    var defaultAccountId: UUID? {
        guard let uuidString = string(forKey: Self.defaultAccountIdKey) else { return nil }
        return UUID(uuidString: uuidString)
    }

    func setDefaultAccountId(_ id: UUID?) {
        if let id = id {
            set(id.uuidString, forKey: Self.defaultAccountIdKey)
        } else {
            removeObject(forKey: Self.defaultAccountIdKey)
        }
    }
}
