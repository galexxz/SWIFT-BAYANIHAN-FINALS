import Foundation

// MARK: - Phase 2: Local Auth Service
//
// AuthService implementation backed by the local SwiftData store:
//   • profiles   → PersistedUser (BayanihanDataStore)
//   • passwords  → PersistedCredential (salted PBKDF2 hash only)
//   • session    → SessionStore (remembered account id only)
//
// Replace with a Firebase-backed AuthService later; the Controller and
// Views only depend on the AuthService protocol.

@MainActor
final class LocalAuthService: AuthService {

    private let dataStore: BayanihanDataStore
    private let sessionStore: SessionStore

    /// `sessionStore` defaults to the standard one. The default is created
    /// inside this main-actor init (not as a default argument, which Swift
    /// evaluates outside the actor and warns about).
    init(
        dataStore: BayanihanDataStore,
        sessionStore: SessionStore? = nil
    ) {
        self.dataStore = dataStore
        self.sessionStore = sessionStore ?? SessionStore()
    }


    // MARK: - Accounts

    func allAccounts() -> [BayanihanUser] {
        dataStore.loadUsers().map(BayanihanUser.init(persisted:))
    }

    private func account(
        matching identifier: String
    ) -> BayanihanUser? {

        let value = AccountValidator.trimmed(identifier)
        let accounts = allAccounts()

        // "@name" or plain "name" → username; anything else with "@" → email.
        let looksLikeEmail = value.contains("@") && !value.hasPrefix("@")

        if looksLikeEmail {
            let email = AccountValidator.normalizedEmail(value)
            return accounts.first {
                AccountValidator.normalizedEmail($0.email) == email
            }
        }

        let username = AccountValidator.normalizedUsername(value)
        return accounts.first {
            AccountValidator.normalizedUsername($0.username) == username
        }
    }


    // MARK: - AuthService

    func restoreSession() -> BayanihanUser? {

        guard let userID = sessionStore.rememberedUserID else {
            return nil
        }

        guard let user = allAccounts().first(where: { $0.id == userID }) else {
            // The remembered account no longer exists — forget it.
            sessionStore.clear()
            return nil
        }

        return user
    }

    func signIn(
        identifier: String,
        password: String,
        rememberMe: Bool
    ) async throws -> BayanihanUser {

        guard
            !AccountValidator.trimmed(identifier).isEmpty,
            !password.isEmpty
        else {
            throw AuthError.missingCredentials
        }

        // The same generic error is used for "no such account" and "wrong
        // password" so the screen never reveals which accounts exist.
        guard
            let user = account(matching: identifier),
            let credential = dataStore.loadCredential(for: user.id),
            PasswordHasher.verify(
                password,
                hash: credential.passwordHash,
                salt: credential.passwordSalt,
                iterations: credential.iterations
            )
        else {
            throw AuthError.invalidCredentials
        }

        if rememberMe {
            sessionStore.remember(user.id)
        } else {
            sessionStore.clear()
        }

        return user
    }

    func register(
        _ registration: AccountRegistration,
        rememberMe: Bool
    ) async throws -> BayanihanUser {

        try AccountValidator.validateRegistration(registration)

        let accounts = allAccounts()
        let email = AccountValidator.normalizedEmail(registration.email)

        guard !accounts.contains(where: {
            AccountValidator.normalizedEmail($0.email) == email
        }) else {
            throw AuthError.emailAlreadyInUse
        }

        let username = AccountValidator.makeUsername(
            fromFullName: registration.fullName,
            existingUsernames: Set(accounts.map {
                AccountValidator.normalizedUsername($0.username)
            })
        )

        let user = BayanihanUser(
            id: UUID(),
            name: AccountValidator.trimmed(registration.fullName),
            username: username,
            email: email,
            location: AccountValidator.trimmed(registration.location),
            requestsPosted: 0,
            requestsHelped: 0,
            communityPoints: 0
        )

        try createAccount(user, password: registration.password)

        if rememberMe {
            sessionStore.remember(user.id)
        } else {
            sessionStore.clear()
        }

        return user
    }

    func updateAccount(
        _ user: BayanihanUser
    ) async throws -> BayanihanUser {

        try AccountValidator.validateProfile(
            name: user.name,
            username: user.username,
            email: user.email,
            location: user.location
        )

        var updated = user
        updated.name = AccountValidator.trimmed(user.name)
        updated.username = AccountValidator.normalizedUsername(user.username)
        updated.email = AccountValidator.normalizedEmail(user.email)
        updated.location = AccountValidator.trimmed(user.location)

        let otherAccounts = allAccounts().filter { $0.id != user.id }

        guard !otherAccounts.contains(where: {
            AccountValidator.normalizedEmail($0.email) == updated.email
        }) else {
            throw AuthError.emailAlreadyInUse
        }

        guard !otherAccounts.contains(where: {
            AccountValidator.normalizedUsername($0.username) == updated.username
        }) else {
            throw AuthError.usernameAlreadyInUse
        }

        // Same id → updates the existing PersistedUser row in place.
        dataStore.saveUser(updated.toPersisted())

        return updated
    }

    func signOut() {
        sessionStore.clear()
    }


    // MARK: - Local Account Setup (local implementation only)

    /// Saves a new profile together with its password hash.
    private func createAccount(
        _ user: BayanihanUser,
        password: String
    ) throws {

        guard let passwordHash = PasswordHasher.makeHash(for: password) else {
            throw AuthError.storageFailure
        }

        // Credential first: if it fails, no password-less profile is left
        // behind. (An orphan credential without a profile is harmless.)
        let saved = dataStore.saveCredential(
            PersistedCredential(
                userID: user.id,
                passwordHash: passwordHash.hash,
                passwordSalt: passwordHash.salt,
                iterations: passwordHash.iterations,
                algorithm: PasswordHash.algorithm
            )
        )

        guard saved else {
            throw AuthError.storageFailure
        }

        dataStore.saveUser(user.toPersisted())
    }

    /// Migration helper: gives an existing account (created before Phase 2,
    /// when there were no passwords) a password. Never replaces a password
    /// that already exists. Returns true if a credential was added.
    @discardableResult
    func addCredentialIfMissing(
        for userID: UUID,
        password: String
    ) -> Bool {

        guard dataStore.loadCredential(for: userID) == nil,
              let passwordHash = PasswordHasher.makeHash(for: password)
        else {
            return false
        }

        return dataStore.saveCredential(
            PersistedCredential(
                userID: userID,
                passwordHash: passwordHash.hash,
                passwordSalt: passwordHash.salt,
                iterations: passwordHash.iterations,
                algorithm: PasswordHash.algorithm
            )
        )
    }

    /// Migration helper: creates a demo account unless an account with the
    /// same email or username already exists (then nothing is changed).
    @discardableResult
    func addDemoAccountIfMissing(
        _ user: BayanihanUser,
        password: String
    ) -> Bool {

        let email = AccountValidator.normalizedEmail(user.email)
        let username = AccountValidator.normalizedUsername(user.username)

        let alreadyExists = allAccounts().contains {
            AccountValidator.normalizedEmail($0.email) == email ||
            AccountValidator.normalizedUsername($0.username) == username
        }

        guard !alreadyExists else {
            return false
        }

        do {
            try createAccount(user, password: password)
            return true
        } catch {
            print("LocalAuthService: Failed to create demo account: \(error)")
            return false
        }
    }
}
