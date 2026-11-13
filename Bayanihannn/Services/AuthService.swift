import Foundation

// MARK: - Phase 2: Authentication Abstraction
//
// The Controller talks to accounts ONLY through this protocol. Today it is
// implemented by `LocalAuthService` (SwiftData + PBKDF2 password hashes).
// When Firebase is added, a `FirebaseAuthService` can implement the same
// protocol and be passed to the Controller instead — no View changes.


// MARK: - Registration Input

struct AccountRegistration {

    var fullName: String
    var email: String
    var password: String
    var confirmPassword: String
    var location: String
    var agreedToTerms: Bool
}


// MARK: - Auth Errors

/// User-facing account errors. `errorDescription` is shown as-is in the
/// existing alert style.
enum AuthError: LocalizedError, Equatable {

    case missingCredentials
    case missingName
    case invalidName
    case invalidEmail
    case invalidUsername
    case weakPassword(String)
    case passwordMismatch
    case missingLocation
    case termsNotAccepted
    case emailAlreadyInUse
    case usernameAlreadyInUse
    case invalidCredentials
    case notSignedIn
    case storageFailure

    var errorDescription: String? {

        switch self {

        case .missingCredentials:
            return "Please enter your email or username and your password."

        case .missingName:
            return "Please enter your full name."

        case .invalidName:
            return "Please enter a name with 2 to 60 characters."

        case .invalidEmail:
            return "Please enter a valid email address (for example, name@example.com)."

        case .invalidUsername:
            return "Usernames must be 3–20 characters using only letters, numbers, periods or underscores."

        case .weakPassword(let reason):
            return reason

        case .passwordMismatch:
            return "The passwords do not match."

        case .missingLocation:
            return "Please enter your barangay or area."

        case .termsNotAccepted:
            return "Please agree to the Bayanihan Terms and Privacy Policy."

        case .emailAlreadyInUse:
            return "An account with this email already exists."

        case .usernameAlreadyInUse:
            return "This username is already taken."

        case .invalidCredentials:
            return "Incorrect email/username or password."

        case .notSignedIn:
            return "Please log in again."

        case .storageFailure:
            return "Something went wrong while saving your account. Please try again."
        }
    }
}


// MARK: - Auth Service

@MainActor
protocol AuthService {

    /// Returns the remembered account when "Remember Me" was used, so the
    /// app can log in automatically on launch. Nil when there is none.
    func restoreSession() -> BayanihanUser?

    /// Signs in with an email or username and a password.
    func signIn(
        identifier: String,
        password: String,
        rememberMe: Bool
    ) async throws -> BayanihanUser

    /// Validates and creates a new account, returning it signed in.
    func register(
        _ registration: AccountRegistration,
        rememberMe: Bool
    ) async throws -> BayanihanUser

    /// Validates and saves profile changes (name, username, email,
    /// location) for an existing account. The account id never changes.
    func updateAccount(
        _ user: BayanihanUser
    ) async throws -> BayanihanUser

    /// Ends the session and forgets any remembered account.
    func signOut()
}
