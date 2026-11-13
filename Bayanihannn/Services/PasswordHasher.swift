import Foundation
import CommonCrypto

// MARK: - Phase 2: Password Hashing
//
// Passwords are NEVER stored. Each account stores only:
//   • a random 16-byte salt, and
//   • PBKDF2-HMAC-SHA256(password, salt, 120,000 iterations), 32 bytes,
// both Base64-encoded. Verification re-derives the key and compares it in
// constant time. Firebase Authentication replaces this later.

struct PasswordHash {

    static let algorithm = "PBKDF2-HMAC-SHA256"

    let hash: String
    let salt: String
    let iterations: Int
}

enum PasswordHasher {

    static let defaultIterations = 120_000

    private static let saltLength = 16
    private static let keyLength = 32


    // MARK: Create

    /// Returns a new salted hash for `password`, or nil if key derivation
    /// fails (not expected in practice).
    static func makeHash(
        for password: String
    ) -> PasswordHash? {

        var generator = SystemRandomNumberGenerator()

        let salt = (0..<saltLength).map { _ in
            UInt8.random(in: UInt8.min...UInt8.max, using: &generator)
        }

        guard let derived = deriveKey(
            password: password,
            salt: salt,
            iterations: defaultIterations
        ) else {
            return nil
        }

        return PasswordHash(
            hash: Data(derived).base64EncodedString(),
            salt: Data(salt).base64EncodedString(),
            iterations: defaultIterations
        )
    }


    // MARK: Verify

    static func verify(
        _ password: String,
        hash: String,
        salt: String,
        iterations: Int
    ) -> Bool {

        guard
            iterations > 0,
            let saltData = Data(base64Encoded: salt),
            let expected = Data(base64Encoded: hash),
            let derived = deriveKey(
                password: password,
                salt: [UInt8](saltData),
                iterations: iterations
            )
        else {
            return false
        }

        return constantTimeEquals([UInt8](expected), derived)
    }


    // MARK: PBKDF2

    private static func deriveKey(
        password: String,
        salt: [UInt8],
        iterations: Int
    ) -> [UInt8]? {

        let passwordBytes = Array(password.utf8)
        var derived = [UInt8](repeating: 0, count: keyLength)

        let status = passwordBytes.withUnsafeBufferPointer { passwordBuffer in
            salt.withUnsafeBufferPointer { saltBuffer in
                derived.withUnsafeMutableBufferPointer { derivedBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer.baseAddress.map {
                            UnsafeRawPointer($0).assumingMemoryBound(to: CChar.self)
                        },
                        passwordBuffer.count,
                        saltBuffer.baseAddress,
                        saltBuffer.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        derivedBuffer.baseAddress,
                        derivedBuffer.count
                    )
                }
            }
        }

        guard status == Int32(kCCSuccess) else {
            return nil
        }

        return derived
    }

    /// Compares every byte so timing does not reveal where a mismatch is.
    private static func constantTimeEquals(
        _ lhs: [UInt8],
        _ rhs: [UInt8]
    ) -> Bool {

        guard lhs.count == rhs.count else {
            return false
        }

        var difference: UInt8 = 0

        for index in lhs.indices {
            difference |= lhs[index] ^ rhs[index]
        }

        return difference == 0
    }
}
