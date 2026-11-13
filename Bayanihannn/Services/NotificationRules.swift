import Foundation

// MARK: - Phase 5: Notification Rules
//
// Pure Foundation logic (no SwiftUI/SwiftData) — unit-testable and reusable
// with Firebase (e.g. in a Cloud Function):
//   • which event notifies whom (never the person who acted)
//   • the wording/icon of each notification
//   • the duplicate-prevention key (request + event + recipient)
//   • per-account visibility and unread counts
//
// Ownership uses stable account ids only — never display names.


// MARK: - Events

enum NotificationEvent: String, CaseIterable {

    case helpOffered
    case agreementCreated
    /// First of the two confirmations: tells the other participant.
    case agreementConfirmedByOther
    /// Second confirmation: tells the participant who confirmed first.
    case agreementFullyConfirmed
    case helpStarted
    case helpCompleted
    case paymentMarkedPaid
    /// Merged: one notification per conversation per recipient.
    case newMessage
}


// MARK: - Draft

/// A notification to create (or, for messages, to merge into an existing
/// one with the same `dedupeKey`).
struct NotificationDraft: Equatable {

    let event: NotificationEvent
    let recipientID: UUID
    let requestID: UUID
    let title: String
    let message: String
    let icon: String
    let dedupeKey: String
}


// MARK: - Rules

enum NotificationRules {

    // MARK: Recipients

    /// The participant who is not `actorID` (nil if the actor is not a
    /// participant or the other side has no account).
    static func otherParticipant(
        of actorID: UUID,
        in request: CommunityRequest
    ) -> UUID? {

        if request.requesterID == actorID {
            return request.helperID
        }

        if request.helperID == actorID {
            return request.requesterID
        }

        return nil
    }

    /// Who receives `event`. Nil when nobody should be notified.
    static func recipient(
        for event: NotificationEvent,
        request: CommunityRequest,
        actorID: UUID
    ) -> UUID? {

        let recipient: UUID?

        switch event {

        case .helpOffered, .helpStarted:
            recipient = request.requesterID

        case .helpCompleted, .paymentMarkedPaid:
            recipient = request.helperID

        case .agreementCreated,
             .agreementConfirmedByOther,
             .agreementFullyConfirmed,
             .newMessage:
            recipient = otherParticipant(of: actorID, in: request)
        }

        // The person who acted is never notified about their own action.
        guard let recipient, recipient != actorID else {
            return nil
        }

        return recipient
    }


    // MARK: Duplicate prevention

    static func dedupeKey(
        event: NotificationEvent,
        requestID: UUID,
        recipientID: UUID
    ) -> String {
        "\(event.rawValue)|\(requestID.uuidString)|\(recipientID.uuidString)"
    }


    // MARK: Drafts

    /// Builds the notification for `event`, or nil when nobody should be
    /// notified (e.g. the recipient would be the actor).
    static func draft(
        for event: NotificationEvent,
        request: CommunityRequest,
        actorID: UUID,
        actorName: String
    ) -> NotificationDraft? {

        guard let recipientID = recipient(
            for: event,
            request: request,
            actorID: actorID
        ) else {
            return nil
        }

        let title = request.title
        let (heading, message, icon) = content(
            for: event,
            actorName: actorName,
            requestTitle: title
        )

        return NotificationDraft(
            event: event,
            recipientID: recipientID,
            requestID: request.id,
            title: heading,
            message: message,
            icon: icon,
            dedupeKey: dedupeKey(
                event: event,
                requestID: request.id,
                recipientID: recipientID
            )
        )
    }

    static func content(
        for event: NotificationEvent,
        actorName: String,
        requestTitle: String
    ) -> (title: String, message: String, icon: String) {

        switch event {

        case .helpOffered:
            return ("Helper Found",
                    "\(actorName) offered to help with “\(requestTitle).”",
                    "hands.sparkles.fill")

        case .agreementCreated:
            return ("Agreement Created",
                    "\(actorName) created a help agreement for “\(requestTitle).” Please review and confirm.",
                    "doc.text.fill")

        case .agreementConfirmedByOther:
            return ("Agreement Confirmed",
                    "\(actorName) confirmed the agreement for “\(requestTitle).” Please confirm to continue.",
                    "checkmark.seal.fill")

        case .agreementFullyConfirmed:
            return ("Help Confirmed",
                    "\(actorName) also confirmed the agreement for “\(requestTitle).” You're all set.",
                    "handshake.fill")

        case .helpStarted:
            return ("Help Started",
                    "\(actorName) started helping with “\(requestTitle).”",
                    "figure.walk")

        case .helpCompleted:
            return ("Request Completed",
                    "\(actorName) marked “\(requestTitle)” as completed. You earned \(RequestLifecycle.pointsPerCompletedHelp) points!",
                    "checkmark.circle.fill")

        case .paymentMarkedPaid:
            return ("Payment Marked Paid",
                    "\(actorName) marked the payment for “\(requestTitle)” as paid.",
                    "creditcard.fill")

        case .newMessage:
            return ("New Message",
                    "\(actorName) sent you a message about “\(requestTitle).”",
                    "message.fill")
        }
    }


    // MARK: Visibility & unread

    /// Only the recipient ever sees a notification. Notifications without a
    /// recipient are shown to nobody.
    static func visible(
        _ notifications: [CommunityNotification],
        to userID: UUID?
    ) -> [CommunityNotification] {

        guard let userID else {
            return []
        }

        return notifications
            .filter { $0.recipientID == userID }
            .sorted { $0.date > $1.date }
    }

    static func unreadCount(
        _ notifications: [CommunityNotification],
        for userID: UUID?
    ) -> Int {
        visible(notifications, to: userID).filter { !$0.isRead }.count
    }


    // MARK: Insert / merge

    /// Applies `draft` to `notifications`:
    ///  • no notification with the same `dedupeKey` → inserts a new one;
    ///  • `.newMessage` with an existing key → updates that one (new text,
    ///    new date, unread again) instead of adding a duplicate;
    ///  • any other event with an existing key → does nothing (duplicate).
    /// - Returns: the inserted/updated notification to save, or nil when
    ///   nothing changed.
    @discardableResult
    static func apply(
        _ draft: NotificationDraft,
        to notifications: inout [CommunityNotification],
        now: Date
    ) -> CommunityNotification? {

        if let index = notifications.firstIndex(where: { $0.dedupeKey == draft.dedupeKey }) {

            guard draft.event == .newMessage else {
                return nil
            }

            notifications[index].title = draft.title
            notifications[index].message = draft.message
            notifications[index].icon = draft.icon
            notifications[index].date = now
            notifications[index].isRead = false

            return notifications[index]
        }

        let notification = CommunityNotification(
            title: draft.title,
            message: draft.message,
            icon: draft.icon,
            date: now,
            isRead: false,
            recipientID: draft.recipientID,
            requestID: draft.requestID,
            dedupeKey: draft.dedupeKey
        )

        notifications.insert(notification, at: 0)

        return notification
    }


    // MARK: Request linking (migration of old records)

    /// The id of the ONLY request whose title EXACTLY equals a title quoted
    /// in `text` (between “ and ”), or nil when there is no quoted title,
    /// no exact match, or more than one matching request. Unquoted words
    /// ("help", "community", a person's name) are never matched, so a
    /// short request title can never capture an unrelated record.
    static func uniqueRequestID(
        mentionedIn text: String,
        requests: [CommunityRequest]
    ) -> UUID? {

        let candidates = quotedTitleCandidates(in: text)

        guard !candidates.isEmpty else {
            return nil
        }

        let matches = requests.filter {
            !$0.title.isEmpty && candidates.contains($0.title)
        }

        return matches.count == 1 ? matches[0].id : nil
    }

    /// Every “quoted” segment in `text`, trimmed, plus the same segment
    /// without one trailing period (the app writes "Posted “Title.”"). A
    /// title that itself ends in "?" or "!" still matches exactly.
    static func quotedTitleCandidates(
        in text: String
    ) -> Set<String> {

        var candidates: Set<String> = []
        var remaining = text[...]

        while let open = remaining.firstIndex(of: "“") {

            let afterOpen = remaining.index(after: open)

            guard let close = remaining[afterOpen...].firstIndex(of: "”") else {
                break
            }

            let segment = remaining[afterOpen..<close]
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !segment.isEmpty {

                candidates.insert(segment)

                if segment.hasSuffix(".") {
                    let withoutPeriod = String(segment.dropLast())
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if !withoutPeriod.isEmpty {
                        candidates.insert(withoutPeriod)
                    }
                }
            }

            remaining = remaining[remaining.index(after: close)...]
        }

        return candidates
    }
}


// MARK: - Phase 5 Migration (v1)

/// One-time, additive upgrade of activities/notifications created before
/// Phase 5. Never deletes, never overwrites a value that is already set,
/// never invents an actor.
enum ActivityNotificationMigrationV1 {

    /// Step 1 — request linking. Runs ONCE (recorded on completion), so
    /// requests posted later can never capture older records.
    static let name = "activity-notification-v1"

    /// Step 2 — giving old notifications an owner. Recorded ONLY when no
    /// notification is left without an owner; otherwise it is retried on
    /// the next launch (it only fills empty recipients, so retrying never
    /// duplicates or overwrites anything).
    static let ownerAssignmentName = "legacy-notification-owner-v1"

    /// The original demo account's identity (the pre-Phase-2 single user).
    static let demoUsername = "@alexrivera"
    static let demoEmail = "alex@example.com"

    struct Result: Equatable {
        var changedActivityIDs: Set<UUID> = []
        var changedNotificationIDs: Set<UUID> = []
    }


    // MARK: Original account (H1)

    /// The original demo account (Alex):
    ///  1. the account matching BOTH the demo username and email, else
    ///  2. the account with the demo email (the login identity), else
    ///  3. the account with the demo username, else
    ///  4. the owner of the OLDEST legacy "You" activity (the seeded ones
    ///     are the oldest; any account may own newer "You" activities
    ///     created before Phase 5), else nil.
    static func originalAccountID(
        accounts: [BayanihanUser],
        activities: [CommunityActivity]
    ) -> UUID? {

        let email = AccountValidator.normalizedEmail(demoEmail)
        let username = AccountValidator.normalizedUsername(demoUsername)

        func hasEmail(_ user: BayanihanUser) -> Bool {
            AccountValidator.normalizedEmail(user.email) == email
        }

        func hasUsername(_ user: BayanihanUser) -> Bool {
            AccountValidator.normalizedUsername(user.username) == username
        }

        if let both = accounts.first(where: { hasEmail($0) && hasUsername($0) }) {
            return both.id
        }

        if let byEmail = accounts.first(where: hasEmail) {
            return byEmail.id
        }

        if let byUsername = accounts.first(where: hasUsername) {
            return byUsername.id
        }

        return activities
            .filter {
                $0.actorName == ActivityFeedRules.currentUserLabel &&
                $0.actorID != nil
            }
            .min { $0.date < $1.date }?
            .actorID
    }


    // MARK: Step 1 — request linking (M1)

    /// Links activities and notifications that have no request yet, using
    /// exact quoted-title matching to exactly one request. Never overwrites
    /// an existing link; never touches actors.
    static func linkRequests(
        activities: inout [CommunityActivity],
        notifications: inout [CommunityNotification],
        requests: [CommunityRequest]
    ) -> Result {

        var result = Result()

        for index in activities.indices where activities[index].requestID == nil {

            if let requestID = NotificationRules.uniqueRequestID(
                mentionedIn: activities[index].message,
                requests: requests
            ) {
                activities[index].requestID = requestID
                result.changedActivityIDs.insert(activities[index].id)
            }
        }

        for index in notifications.indices where notifications[index].requestID == nil {

            if let requestID = NotificationRules.uniqueRequestID(
                mentionedIn: notifications[index].message,
                requests: requests
            ) {
                notifications[index].requestID = requestID
                result.changedNotificationIDs.insert(notifications[index].id)
            }
        }

        return result
    }


    // MARK: Step 2 — owners (L1)

    /// Gives every notification WITHOUT a recipient to the original
    /// account. Title, message, date and read state are untouched; an
    /// existing recipient is never changed.
    /// - Returns: ids of the notifications that were changed.
    static func assignOwners(
        notifications: inout [CommunityNotification],
        originalAccountID: UUID?
    ) -> Set<UUID> {

        guard let originalAccountID else {
            return []
        }

        var changed: Set<UUID> = []

        for index in notifications.indices where notifications[index].recipientID == nil {
            notifications[index].recipientID = originalAccountID
            changed.insert(notifications[index].id)
        }

        return changed
    }

    /// True while some notification still has no owner (step 2 must be
    /// retried on a later launch).
    static func needsOwnerAssignment(
        _ notifications: [CommunityNotification]
    ) -> Bool {
        notifications.contains { $0.recipientID == nil }
    }


    // MARK: Both steps (used by tests)

    static func backfill(
        activities: inout [CommunityActivity],
        notifications: inout [CommunityNotification],
        requests: [CommunityRequest],
        originalAccountID: UUID?
    ) -> Result {

        var result = linkRequests(
            activities: &activities,
            notifications: &notifications,
            requests: requests
        )

        result.changedNotificationIDs.formUnion(
            assignOwners(
                notifications: &notifications,
                originalAccountID: originalAccountID
            )
        )

        return result
    }
}
