import Foundation

// MARK: - Phase 5: Personal Activity Feed Rules
//
// Pure Foundation logic (unit-testable). The Activity tab is PERSONAL:
//   • the signed-in user's own activities, plus
//   • activities on requests the user posted (e.g. someone offering help).
// Unrelated people's activities are never shown. Ownership uses account
// ids only; names are only for display.

enum ActivityFeedRules {

    /// Label shown when the signed-in user performed the activity.
    static let currentUserLabel = "You"

    static func isVisible(
        _ activity: CommunityActivity,
        to userID: UUID?,
        requests: [CommunityRequest]
    ) -> Bool {

        guard let userID else {
            return false
        }

        if activity.actorID == userID {
            return true
        }

        guard let requestID = activity.requestID,
              let request = requests.first(where: { $0.id == requestID })
        else {
            return false
        }

        return request.requesterID == userID
    }

    /// The signed-in user's personal feed, newest first.
    static func personalFeed(
        _ activities: [CommunityActivity],
        for userID: UUID?,
        requests: [CommunityRequest]
    ) -> [CommunityActivity] {

        activities
            .filter { isVisible($0, to: userID, requests: requests) }
            .sorted { $0.date > $1.date }
    }

    /// "You" for the signed-in actor; otherwise the actor's current account
    /// name, falling back to the stored name. Older records stored the
    /// placeholder "You" — for anyone else they show the real account name
    /// (looked up by id), never "You".
    static func displayName(
        for activity: CommunityActivity,
        currentUserID: UUID?,
        accountNames: [UUID: String]
    ) -> String {

        if let actorID = activity.actorID {

            if actorID == currentUserID {
                return currentUserLabel
            }

            if let name = accountNames[actorID], !name.isEmpty {
                return name
            }
        }

        if activity.actorName == currentUserLabel {
            // A legacy "You" whose account cannot be found: never claim it
            // was the current user.
            return "Community Member"
        }

        return activity.actorName
    }
}
