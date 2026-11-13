import Foundation

// MARK: - Phase 2: Identity Migration (v1)
//
// Before Phase 2 there were no account ids: ownership was stored as text
// (requesterUsername, helperName, senderUsername, actorName "You"). This
// one-time migration links existing records to accounts by filling in the
// new *empty* id fields only.
//
// Safety rules:
//  • Additive only — never deletes records and never overwrites an id that
//    is already set.
//  • Matches only when exactly ONE account matches (ambiguous → left nil).
//  • Records of seeded community members without an account stay nil.
//  • Pure logic (no SwiftData) so it can be unit-tested.

enum IdentityMigrationV1 {

    /// Stored in PersistedMigrationRecord once completed.
    static let name = "identity-v1"

    struct Result: Equatable {

        var changedRequestIDs: Set<UUID> = []
        var changedMessageIDs: Set<UUID> = []
        var changedActivityIDs: Set<UUID> = []
        var changedAgreementIDs: Set<UUID> = []

        var totalChanges: Int {
            changedRequestIDs.count +
            changedMessageIDs.count +
            changedActivityIDs.count +
            changedAgreementIDs.count
        }
    }

    /// - Parameters:
    ///   - accounts: every account that exists after demo accounts are set
    ///     up.
    ///   - legacyLocalUserID: the single pre-Phase-2 local user. Activities
    ///     stored with actorName "You" belonged to that user.
    static func backfill(
        requests: inout [CommunityRequest],
        messages: inout [ChatMessage],
        activities: inout [CommunityActivity],
        agreements: inout [HelpAgreement],
        accounts: [BayanihanUser],
        legacyLocalUserID: UUID?
    ) -> Result {

        var result = Result()

        // Requests: requester by username, helper by display name.
        for index in requests.indices {

            var changed = false

            if requests[index].requesterID == nil,
               let id = uniqueAccountID(username: requests[index].requesterUsername, in: accounts) {
                requests[index].requesterID = id
                changed = true
            }

            if requests[index].helperID == nil,
               let helperName = requests[index].helperName,
               let id = uniqueAccountID(name: helperName, in: accounts) {
                requests[index].helperID = id
                changed = true
            }

            if changed {
                result.changedRequestIDs.insert(requests[index].id)
            }
        }

        // Chat messages: sender by username.
        for index in messages.indices where messages[index].senderID == nil {

            if let id = uniqueAccountID(username: messages[index].senderUsername, in: accounts) {
                messages[index].senderID = id
                result.changedMessageIDs.insert(messages[index].id)
            }
        }

        // Activities: "You" = the legacy local user; others by name.
        for index in activities.indices where activities[index].actorID == nil {

            let actorName = activities[index].actorName

            let id: UUID? = actorName == "You"
                ? legacyLocalUserID
                : uniqueAccountID(name: actorName, in: accounts)

            if let id {
                activities[index].actorID = id
                result.changedActivityIDs.insert(activities[index].id)
            }
        }

        // Agreements: prefer the linked request's ids, else match by name.
        for index in agreements.indices {

            let request = requests.first { $0.id == agreements[index].requestID }
            var changed = false

            if agreements[index].requesterID == nil,
               let id = request?.requesterID ??
                    uniqueAccountID(name: agreements[index].requesterName, in: accounts) {
                agreements[index].requesterID = id
                changed = true
            }

            if agreements[index].helperID == nil,
               let id = request?.helperID ??
                    uniqueAccountID(name: agreements[index].helperName, in: accounts) {
                agreements[index].helperID = id
                changed = true
            }

            if changed {
                result.changedAgreementIDs.insert(agreements[index].id)
            }
        }

        return result
    }


    // MARK: - Matching

    static func uniqueAccountID(
        username: String,
        in accounts: [BayanihanUser]
    ) -> UUID? {

        let target = AccountValidator.normalizedUsername(username)

        guard target.count > 1 else {
            return nil
        }

        let matches = accounts.filter {
            AccountValidator.normalizedUsername($0.username) == target
        }

        return matches.count == 1 ? matches[0].id : nil
    }

    static func uniqueAccountID(
        name: String,
        in accounts: [BayanihanUser]
    ) -> UUID? {

        let target = AccountValidator.trimmed(name).lowercased()

        guard !target.isEmpty else {
            return nil
        }

        let matches = accounts.filter {
            AccountValidator.trimmed($0.name).lowercased() == target
        }

        return matches.count == 1 ? matches[0].id : nil
    }
}
