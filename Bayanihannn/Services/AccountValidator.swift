import Foundation

// MARK: - Phase 2: Account Validation
//
// Pure, Foundation-only rules shared by registration and Edit Profile.
// Kept free of SwiftUI/SwiftData so they can be unit-tested anywhere and
// reused unchanged when Firebase is added.

enum AccountValidator {

    // MARK: Limits

    static let minimumPasswordLength = 8
    static let maximumPasswordLength = 64
    static let usernameLengthRange = 3...20


    // MARK: Normalization

    static func trimmed(
        _ value: String
    ) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Emails are compared and stored trimmed and lowercased.
    static func normalizedEmail(
        _ email: String
    ) -> String {
        trimmed(email).lowercased()
    }

    /// Usernames are stored as "@name" in lowercase. Accepts input with or
    /// without the leading "@".
    static func normalizedUsername(
        _ username: String
    ) -> String {

        var body = trimmed(username).lowercased()

        while body.hasPrefix("@") {
            body.removeFirst()
        }

        return "@" + body
    }


    // MARK: Single-field Rules

    static func isValidEmail(
        _ email: String
    ) -> Bool {

        let value = normalizedEmail(email)

        guard value.count <= 254, !value.contains("..") else {
            return false
        }

        let pattern = "^[a-z0-9._%+-]+@[a-z0-9-]+(\\.[a-z0-9-]+)*\\.[a-z]{2,}$"

        return value.range(
            of: pattern,
            options: .regularExpression
        ) != nil
    }

    static func isValidUsername(
        _ username: String
    ) -> Bool {

        let body = String(normalizedUsername(username).dropFirst())

        guard usernameLengthRange.contains(body.count) else {
            return false
        }

        return body.range(
            of: "^[a-z0-9._]+$",
            options: .regularExpression
        ) != nil
    }

    static func isValidName(
        _ name: String
    ) -> Bool {
        (2...60).contains(trimmed(name).count)
    }

    /// Returns nil when the password is acceptable, otherwise a message.
    static func passwordProblem(
        _ password: String
    ) -> String? {

        if password.count < minimumPasswordLength {
            return "Password must be at least \(minimumPasswordLength) characters."
        }

        if password.count > maximumPasswordLength {
            return "Password must be at most \(maximumPasswordLength) characters."
        }

        if !password.contains(where: { $0.isLetter }) ||
            !password.contains(where: { $0.isNumber }) {
            return "Password must contain at least one letter and one number."
        }

        return nil
    }


    // MARK: Form Rules

    /// Validates the Sign Up form (format only — duplicate checks need the
    /// account list and are done by the AuthService).
    static func validateRegistration(
        _ registration: AccountRegistration
    ) throws {

        let name = trimmed(registration.fullName)

        guard !name.isEmpty else {
            throw AuthError.missingName
        }

        guard isValidName(name) else {
            throw AuthError.invalidName
        }

        guard isValidEmail(registration.email) else {
            throw AuthError.invalidEmail
        }

        if let problem = passwordProblem(registration.password) {
            throw AuthError.weakPassword(problem)
        }

        guard registration.password == registration.confirmPassword else {
            throw AuthError.passwordMismatch
        }

        guard !trimmed(registration.location).isEmpty else {
            throw AuthError.missingLocation
        }

        guard registration.agreedToTerms else {
            throw AuthError.termsNotAccepted
        }
    }

    /// Validates Edit Profile values (format only).
    static func validateProfile(
        name: String,
        username: String,
        email: String,
        location: String
    ) throws {

        guard isValidName(name) else {
            throw AuthError.invalidName
        }

        guard isValidUsername(username) else {
            throw AuthError.invalidUsername
        }

        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }

        guard !trimmed(location).isEmpty else {
            throw AuthError.missingLocation
        }
    }


    // MARK: Username Generation

    /// Builds a unique "@username" from a full name, e.g. "Maria Santos" →
    /// "@mariasantos", then "@mariasantos2" if taken. `existingUsernames`
    /// must contain normalized usernames.
    static func makeUsername(
        fromFullName fullName: String,
        existingUsernames: Set<String>
    ) -> String {

        let folded = fullName
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()

        var base = String(
            folded.unicodeScalars
                .filter { ("a"..."z").contains($0) || ("0"..."9").contains($0) }
                .map(Character.init)
        )

        if base.count < usernameLengthRange.lowerBound {
            base = "user"
        }

        // Leave room for a numeric suffix within the maximum length.
        base = String(base.prefix(usernameLengthRange.upperBound - 4))

        var candidate = "@" + base
        var suffix = 2

        while existingUsernames.contains(candidate) {
            candidate = "@\(base)\(suffix)"
            suffix += 1
        }

        return candidate
    }
}
