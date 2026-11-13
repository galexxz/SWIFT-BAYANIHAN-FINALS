import Foundation

// MARK: - Phase 4: Messaging Rules
//
// Pure Foundation logic for messaging (no SwiftUI/SwiftData) so it can be
// unit-tested anywhere and reused unchanged with Firebase:
//   • message text validation (1,000-character limit)
//   • per-user, per-conversation unread counts
//   • "last read" timestamps
//   • sorting conversations by most recent activity
//
// A conversation is identified by its request id. Only the request's
// requester and helper take part (enforced by RequestLifecycle).


// MARK: - Errors

enum MessageError: LocalizedError, Equatable {

    case emptyMessage
    case messageTooLong(maximum: Int)

    var errorDescription: String? {

        switch self {

        case .emptyMessage:
            return "Please type a message."

        case .messageTooLong(let maximum):
            return "Messages can be at most \(maximum) characters."
        }
    }
}


// MARK: - Rules

enum MessagingRules {

    /// Maximum characters in one message.
    static let maximumMessageLength = 1_000

    /// Name of the one-time migration whose completion time is the
    /// "already read" cutoff: every message created before Phase 4 was
    /// installed counts as read for everyone, so upgrading never produces
    /// sudden unread badges for old messages.
    static let readStateMigrationName = "messaging-read-state-v1"


    // MARK: Text

    /// Returns the trimmed text, or throws if it is empty or too long.
    static func validatedText(
        _ text: String
    ) throws -> String {

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            throw MessageError.emptyMessage
        }

        guard trimmed.count <= maximumMessageLength else {
            throw MessageError.messageTooLong(maximum: maximumMessageLength)
        }

        return trimmed
    }

    /// Cuts typed/pasted text down to the limit (used by the text field so
    /// the user can never enter more than the limit).
    static func limitedInput(
        _ text: String
    ) -> String {

        guard text.count > maximumMessageLength else {
            return text
        }

        return String(text.prefix(maximumMessageLength))
    }


    // MARK: Unread

    /// Messages in `requestID`'s conversation that `userID` has not read:
    /// sent by someone else, after both the user's last-read time and the
    /// Phase 4 upgrade cutoff.
    static func unreadCount(
        in requestID: UUID,
        messages: [ChatMessage],
        for userID: UUID,
        lastReadAt: Date?,
        readCutoff: Date?
    ) -> Int {

        let threshold = max(
            lastReadAt ?? .distantPast,
            readCutoff ?? .distantPast
        )

        return messages.filter {
            $0.requestID == requestID &&
            $0.senderID != userID &&
            $0.createdAt > threshold
        }.count
    }

    /// The time to store when a user opens a conversation: now, or the
    /// newest message's time if that is later (e.g. clock differences), so
    /// every message currently shown counts as read.
    static func readTimestamp(
        now: Date,
        conversationMessages: [ChatMessage]
    ) -> Date {

        let newest = conversationMessages.map(\.createdAt).max() ?? .distantPast

        return max(now, newest)
    }


    // MARK: Sorting

    /// Most recent activity in a conversation: its newest message, or the
    /// request's creation time when there are no messages yet.
    static func lastActivity(
        of request: CommunityRequest,
        messages: [ChatMessage]
    ) -> Date {

        messages
            .filter { $0.requestID == request.id }
            .map(\.createdAt)
            .max() ?? request.createdAt
    }

    /// Conversations ordered newest activity first (ties: newer request
    /// first, then id, so the order is always stable).
    static func sortedByRecentActivity(
        _ requests: [CommunityRequest],
        messages: [ChatMessage]
    ) -> [CommunityRequest] {

        let activity = Dictionary(
            uniqueKeysWithValues: requests.map {
                ($0.id, lastActivity(of: $0, messages: messages))
            }
        )

        return requests.sorted { lhs, rhs in

            let lhsActivity = activity[lhs.id] ?? lhs.createdAt
            let rhsActivity = activity[rhs.id] ?? rhs.createdAt

            if lhsActivity != rhsActivity {
                return lhsActivity > rhsActivity
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
