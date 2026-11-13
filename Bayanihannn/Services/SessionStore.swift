import Foundation

// MARK: - Phase 2: Remembered Session
//
// Stores ONLY the account id of a user who chose "Remember Me" — never a
// password or hash. Used for automatic login on launch. Firebase
// Authentication manages its own session later, replacing this.

struct SessionStore {

    private let defaults: UserDefaults
    private let rememberedUserIDKey = "bayanihan.session.rememberedUserID"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var rememberedUserID: UUID? {

        guard let value = defaults.string(forKey: rememberedUserIDKey) else {
            return nil
        }

        return UUID(uuidString: value)
    }

    func remember(
        _ userID: UUID
    ) {
        defaults.set(userID.uuidString, forKey: rememberedUserIDKey)
    }

    func clear() {
        defaults.removeObject(forKey: rememberedUserIDKey)
    }
}
