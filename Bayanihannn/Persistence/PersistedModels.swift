import Foundation
import SwiftData

// MARK: - Step 1: Persisted Models


// MARK: - RequestCategory Persistence Keys

extension RequestCategory {

    /// Stable string key used for persistence. Independent from `rawValue`
    /// (which is used for display text), so display text can change later
    /// without breaking already-stored data.
    var persistenceKey: String {

        switch self {

        case .food:
            return "food"

        case .medical:
            return "medical"

        case .education:
            return "education"

        case .housing:
            return "housing"

        case .donation:
            return "donation"

        case .volunteer:
            return "volunteer"

        case .emergency:
            return "emergency"

        case .other:
            // NOTE: RequestCategory.other has display rawValue "Others",
            // but the persistence key stays "other" and must never change.
            return "other"
        }
    }

    /// Safely reconstructs a RequestCategory from a stored persistence key.
    /// Falls back to `.other` for any unknown/future value instead of
    /// crashing.
    init(persistenceKey: String) {

        switch persistenceKey {

        case "food":
            self = .food

        case "medical":
            self = .medical

        case "education":
            self = .education

        case "housing":
            self = .housing

        case "donation":
            self = .donation

        case "volunteer":
            self = .volunteer

        case "emergency":
            self = .emergency

        default:
            self = .other
        }
    }
}


// MARK: - RequestUrgency Persistence Keys

extension RequestUrgency {

    var persistenceKey: String {

        switch self {

        case .normal:
            return "normal"

        case .urgent:
            return "urgent"

        case .emergency:
            return "emergency"
        }
    }

    init(persistenceKey: String) {

        switch persistenceKey {

        case "urgent":
            self = .urgent

        case "emergency":
            self = .emergency

        default:
            self = .normal
        }
    }
}


// MARK: - CommunityRequestStatus Persistence Keys

extension CommunityRequestStatus {

    var persistenceKey: String {

        switch self {

        case .open:
            return "open"

        case .inDiscussion:
            return "inDiscussion"

        case .confirmed:
            return "confirmed"

        case .inProgress:
            return "inProgress"

        case .completed:
            return "completed"
        }
    }

    init(persistenceKey: String) {

        switch persistenceKey {

        case "inDiscussion":
            self = .inDiscussion

        case "confirmed":
            self = .confirmed

        case "inProgress":
            self = .inProgress

        case "completed":
            self = .completed

        default:
            self = .open
        }
    }
}


// MARK: - ExchangeType Persistence Keys

extension ExchangeType {

    var persistenceKey: String {

        switch self {

        case .noPayment:
            return "noPayment"

        case .cash:
            return "cash"

        case .goods:
            return "goods"
        }
    }

    init(persistenceKey: String) {

        switch persistenceKey {

        case "cash":
            self = .cash

        case "goods":
            self = .goods

        default:
            self = .noPayment
        }
    }
}


// MARK: - PaymentStatus Persistence Keys

extension PaymentStatus {

    var persistenceKey: String {

        switch self {

        case .pending:
            return "pending"

        case .paid:
            return "paid"

        case .notApplicable:
            return "notApplicable"
        }
    }

    init(persistenceKey: String) {

        switch persistenceKey {

        case "paid":
            self = .paid

        case "notApplicable":
            self = .notApplicable

        default:
            self = .pending
        }
    }
}


// MARK: - ActivityType Persistence Keys

extension ActivityType {

    var persistenceKey: String {

        switch self {

        case .all:
            return "all"

        case .volunteered:
            return "volunteered"

        case .posted:
            return "posted"
        }
    }

    init(persistenceKey: String) {

        switch persistenceKey {

        case "all":
            self = .all

        case "volunteered":
            self = .volunteered

        default:
            self = .posted
        }
    }
}


// MARK: - Persisted User

@Model
final class PersistedUser {

    @Attribute(.unique) var id: UUID

    var name: String
    var username: String
    var email: String
    var location: String

    var requestsPosted: Int
    var requestsHelped: Int
    var communityPoints: Int

    init(
        id: UUID = UUID(),
        name: String,
        username: String,
        email: String,
        location: String,
        requestsPosted: Int,
        requestsHelped: Int,
        communityPoints: Int
    ) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.location = location
        self.requestsPosted = requestsPosted
        self.requestsHelped = requestsHelped
        self.communityPoints = communityPoints
    }
}


// MARK: - Persisted Request

@Model
final class PersistedRequest {

    @Attribute(.unique) var id: UUID

    var title: String
    var requestDescription: String
    var categoryKey: String
    var location: String
    var date: Date
    var time: String
    var peopleNeeded: Int
    var urgencyKey: String

    var requesterName: String
    var requesterUsername: String

    var statusKey: String
    var helperName: String?

    var createdAt: Date

    // Phase 2: optional account IDs with a default of nil. Adding optional
    // properties is a lightweight (automatic) SwiftData migration, so the
    // existing store opens without any reset or data loss.
    var requesterID: UUID? = nil
    var helperID: UUID? = nil

    // Phase 3: default false → lightweight (automatic) migration. Existing
    // completed requests stay false, but they can never be completed again,
    // so no reward is granted retroactively.
    var completionRewardGranted: Bool = false

    init(
        id: UUID = UUID(),
        title: String,
        requestDescription: String,
        categoryKey: String,
        location: String,
        date: Date,
        time: String,
        peopleNeeded: Int,
        urgencyKey: String,
        requesterName: String,
        requesterUsername: String,
        statusKey: String,
        helperName: String? = nil,
        createdAt: Date,
        requesterID: UUID? = nil,
        helperID: UUID? = nil,
        completionRewardGranted: Bool = false
    ) {
        self.requesterID = requesterID
        self.helperID = helperID
        self.completionRewardGranted = completionRewardGranted
        self.id = id
        self.title = title
        self.requestDescription = requestDescription
        self.categoryKey = categoryKey
        self.location = location
        self.date = date
        self.time = time
        self.peopleNeeded = peopleNeeded
        self.urgencyKey = urgencyKey
        self.requesterName = requesterName
        self.requesterUsername = requesterUsername
        self.statusKey = statusKey
        self.helperName = helperName
        self.createdAt = createdAt
    }
}


// MARK: - Persisted Activity

@Model
final class PersistedActivity {

    @Attribute(.unique) var id: UUID

    var message: String
    var date: Date
    var typeKey: String
    var actorName: String

    // Phase 2: optional (lightweight migration).
    var actorID: UUID? = nil

    // Phase 5: optional, default nil (lightweight migration).
    var requestID: UUID? = nil

    init(
        id: UUID = UUID(),
        message: String,
        date: Date,
        typeKey: String,
        actorName: String,
        actorID: UUID? = nil,
        requestID: UUID? = nil
    ) {
        self.actorID = actorID
        self.requestID = requestID
        self.id = id
        self.message = message
        self.date = date
        self.typeKey = typeKey
        self.actorName = actorName
    }
}


// MARK: - Persisted Chat Message

@Model
final class PersistedChatMessage {

    @Attribute(.unique) var id: UUID

    var requestID: UUID
    var senderUsername: String
    var text: String

    /// Existing display-formatted string (e.g. "9:00 AM"), preserved exactly
    /// as produced by ChatMessage so the View can remain unchanged.
    var time: String

    /// Persistence-only value used to reliably reorder messages after
    /// loading from SwiftData. `ChatMessage` itself is not modified to add
    /// this property.
    var createdAt: Date

    // Phase 2: optional (lightweight migration).
    var senderID: UUID? = nil

    init(
        id: UUID = UUID(),
        requestID: UUID,
        senderUsername: String,
        text: String,
        time: String,
        createdAt: Date = Date(),
        senderID: UUID? = nil
    ) {
        self.senderID = senderID
        self.id = id
        self.requestID = requestID
        self.senderUsername = senderUsername
        self.text = text
        self.time = time
        self.createdAt = createdAt
    }
}


// MARK: - Persisted Help Agreement

@Model
final class PersistedHelpAgreement {

    @Attribute(.unique) var id: UUID

    var requestID: UUID
    var requesterName: String
    var helperName: String

    var agreementDescription: String
    var date: Date
    var time: String
    var location: String

    var exchangeTypeKey: String
    var amount: Double

    var paymentStatusKey: String

    var isConfirmedByRequester: Bool
    var isConfirmedByHelper: Bool

    // NOTE: `isConfirmed` on HelpAgreement is a computed property
    // (isConfirmedByRequester && isConfirmedByHelper) and is intentionally
    // not persisted.

    // Phase 2: optional (lightweight migration).
    var requesterID: UUID? = nil
    var helperID: UUID? = nil

    init(
        id: UUID = UUID(),
        requestID: UUID,
        requesterName: String,
        helperName: String,
        agreementDescription: String,
        date: Date,
        time: String,
        location: String,
        exchangeTypeKey: String,
        amount: Double,
        paymentStatusKey: String,
        isConfirmedByRequester: Bool,
        isConfirmedByHelper: Bool,
        requesterID: UUID? = nil,
        helperID: UUID? = nil
    ) {
        self.requesterID = requesterID
        self.helperID = helperID
        self.id = id
        self.requestID = requestID
        self.requesterName = requesterName
        self.helperName = helperName
        self.agreementDescription = agreementDescription
        self.date = date
        self.time = time
        self.location = location
        self.exchangeTypeKey = exchangeTypeKey
        self.amount = amount
        self.paymentStatusKey = paymentStatusKey
        self.isConfirmedByRequester = isConfirmedByRequester
        self.isConfirmedByHelper = isConfirmedByHelper
    }
}


// MARK: - Persisted Notification

@Model
final class PersistedNotification {

    @Attribute(.unique) var id: UUID

    var title: String
    var message: String
    var icon: String
    var date: Date
    var isRead: Bool

    // Phase 5: optional, default nil (lightweight migration). `dedupeKey`
    // deliberately has NO unique constraint: existing rows would all share
    // the same nil value during migration. Duplicates are prevented in the
    // Controller instead.
    var recipientID: UUID? = nil
    var requestID: UUID? = nil
    var dedupeKey: String? = nil

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        icon: String,
        date: Date,
        isRead: Bool,
        recipientID: UUID? = nil,
        requestID: UUID? = nil,
        dedupeKey: String? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.icon = icon
        self.date = date
        self.isRead = isRead
        self.recipientID = recipientID
        self.requestID = requestID
        self.dedupeKey = dedupeKey
    }
}


// MARK: - Persisted Credential

/// Phase 2: local sign-in credential for one account, kept separate from
/// the profile (PersistedUser) so password data never travels with profile
/// data. Only a salted PBKDF2 hash is stored — never the password itself.
/// This model is replaced by Firebase Authentication later.
@Model
final class PersistedCredential {

    @Attribute(.unique) var userID: UUID

    var passwordHash: String
    var passwordSalt: String
    var iterations: Int
    var algorithm: String
    var updatedAt: Date

    init(
        userID: UUID,
        passwordHash: String,
        passwordSalt: String,
        iterations: Int,
        algorithm: String,
        updatedAt: Date = Date()
    ) {
        self.userID = userID
        self.passwordHash = passwordHash
        self.passwordSalt = passwordSalt
        self.iterations = iterations
        self.algorithm = algorithm
        self.updatedAt = updatedAt
    }
}


// MARK: - Persisted Migration Record

/// Phase 2: records one-time data migrations inside the same store as the
/// data they migrate, so a migration can never be skipped or repeated by
/// accident.
@Model
final class PersistedMigrationRecord {

    @Attribute(.unique) var name: String

    var completedAt: Date

    init(
        name: String,
        completedAt: Date = Date()
    ) {
        self.name = name
        self.completedAt = completedAt
    }
}


// MARK: - Persisted Conversation Read State (Phase 4)

/// When one user last read one conversation. Adding this entity is a
/// lightweight (automatic) SwiftData migration — no existing data changes.
/// Maps to a per-user read-state document in Firestore later.
@Model
final class PersistedConversationReadState {

    /// "<userID>|<requestID>" — one row per user per conversation.
    @Attribute(.unique) var key: String

    var userID: UUID
    var requestID: UUID
    var lastReadAt: Date

    init(
        userID: UUID,
        requestID: UUID,
        lastReadAt: Date
    ) {
        self.key = Self.makeKey(userID: userID, requestID: requestID)
        self.userID = userID
        self.requestID = requestID
        self.lastReadAt = lastReadAt
    }

    static func makeKey(
        userID: UUID,
        requestID: UUID
    ) -> String {
        "\(userID.uuidString)|\(requestID.uuidString)"
    }
}


// MARK: - Persisted Bookmark (Phase 6)

/// One account's bookmarked request. New entity → lightweight (automatic)
/// SwiftData migration; no existing data changes.
@Model
final class PersistedBookmark {

    /// "<userID>|<requestID>" — one row per account per request.
    @Attribute(.unique) var key: String

    var userID: UUID
    var requestID: UUID
    var createdAt: Date

    init(
        userID: UUID,
        requestID: UUID,
        createdAt: Date
    ) {
        self.key = Self.makeKey(userID: userID, requestID: requestID)
        self.userID = userID
        self.requestID = requestID
        self.createdAt = createdAt
    }

    static func makeKey(
        userID: UUID,
        requestID: UUID
    ) -> String {
        "\(userID.uuidString)|\(requestID.uuidString)"
    }
}


// MARK: - Persisted Request Report (Phase 6)

/// A local report of a request. New entity → lightweight migration.
@Model
final class PersistedRequestReport {

    @Attribute(.unique) var id: UUID

    var requestID: UUID
    var reporterID: UUID
    var reasonKey: String
    var createdAt: Date

    init(
        id: UUID,
        requestID: UUID,
        reporterID: UUID,
        reasonKey: String,
        createdAt: Date
    ) {
        self.id = id
        self.requestID = requestID
        self.reporterID = reporterID
        self.reasonKey = reasonKey
        self.createdAt = createdAt
    }
}


// MARK: - Conversion: RequestBookmark / RequestReport (Phase 6)

extension RequestBookmark {

    func toPersisted() -> PersistedBookmark {
        PersistedBookmark(userID: userID, requestID: requestID, createdAt: createdAt)
    }

    init(persisted: PersistedBookmark) {
        self.init(userID: persisted.userID, requestID: persisted.requestID, createdAt: persisted.createdAt)
    }
}

extension RequestReport {

    func toPersisted() -> PersistedRequestReport {
        PersistedRequestReport(
            id: id,
            requestID: requestID,
            reporterID: reporterID,
            reasonKey: reason.rawValue,
            createdAt: createdAt
        )
    }

    /// Unknown stored reasons fall back to `.other` instead of failing.
    init(persisted: PersistedRequestReport) {
        self.init(
            id: persisted.id,
            requestID: persisted.requestID,
            reporterID: persisted.reporterID,
            reason: ReportReason(rawValue: persisted.reasonKey) ?? .other,
            createdAt: persisted.createdAt
        )
    }
}


// MARK: - Conversion: ConversationReadState <-> PersistedConversationReadState

extension ConversationReadState {

    func toPersisted() -> PersistedConversationReadState {

        PersistedConversationReadState(
            userID: userID,
            requestID: requestID,
            lastReadAt: lastReadAt
        )
    }

    init(persisted: PersistedConversationReadState) {

        self.init(
            userID: persisted.userID,
            requestID: persisted.requestID,
            lastReadAt: persisted.lastReadAt
        )
    }
}


// MARK: - Conversion: CommunityRequest <-> PersistedRequest

extension CommunityRequest {

    /// Builds a PersistedRequest snapshot, preserving the id exactly.
    func toPersisted() -> PersistedRequest {

        PersistedRequest(
            id: id,
            title: title,
            requestDescription: description,
            categoryKey: category.persistenceKey,
            location: location,
            date: date,
            time: time,
            peopleNeeded: peopleNeeded,
            urgencyKey: urgency.persistenceKey,
            requesterName: requesterName,
            requesterUsername: requesterUsername,
            statusKey: status.persistenceKey,
            helperName: helperName,
            createdAt: createdAt,
            requesterID: requesterID,
            helperID: helperID,
            completionRewardGranted: completionRewardGranted
        )
    }

    init(persisted: PersistedRequest) {

        self.init(
            id: persisted.id,
            title: persisted.title,
            description: persisted.requestDescription,
            category: RequestCategory(persistenceKey: persisted.categoryKey),
            location: persisted.location,
            date: persisted.date,
            time: persisted.time,
            peopleNeeded: persisted.peopleNeeded,
            urgency: RequestUrgency(persistenceKey: persisted.urgencyKey),
            requesterName: persisted.requesterName,
            requesterUsername: persisted.requesterUsername,
            status: CommunityRequestStatus(persistenceKey: persisted.statusKey),
            helperName: persisted.helperName,
            createdAt: persisted.createdAt,
            requesterID: persisted.requesterID,
            helperID: persisted.helperID,
            completionRewardGranted: persisted.completionRewardGranted
        )
    }
}


// MARK: - Conversion: BayanihanUser <-> PersistedUser

extension BayanihanUser {

    /// Builds a PersistedUser snapshot, preserving the account `id` exactly
    /// (Phase 2: BayanihanUser now carries its own stable id).
    func toPersisted() -> PersistedUser {

        PersistedUser(
            id: id,
            name: name,
            username: username,
            email: email,
            location: location,
            requestsPosted: requestsPosted,
            requestsHelped: requestsHelped,
            communityPoints: communityPoints
        )
    }

    init(persisted: PersistedUser) {

        self.init(
            id: persisted.id,
            name: persisted.name,
            username: persisted.username,
            email: persisted.email,
            location: persisted.location,
            requestsPosted: persisted.requestsPosted,
            requestsHelped: persisted.requestsHelped,
            communityPoints: persisted.communityPoints
        )
    }
}


// MARK: - Conversion: CommunityActivity <-> PersistedActivity

extension CommunityActivity {

    func toPersisted() -> PersistedActivity {

        PersistedActivity(
            id: id,
            message: message,
            date: date,
            typeKey: type.persistenceKey,
            actorName: actorName,
            actorID: actorID,
            requestID: requestID
        )
    }

    init(persisted: PersistedActivity) {

        self.init(
            id: persisted.id,
            message: persisted.message,
            date: persisted.date,
            type: ActivityType(persistenceKey: persisted.typeKey),
            actorName: persisted.actorName,
            actorID: persisted.actorID,
            requestID: persisted.requestID
        )
    }
}


// MARK: - Conversion: ChatMessage <-> PersistedChatMessage

extension ChatMessage {

    /// Builds a PersistedChatMessage snapshot. `time` (the existing
    /// display-formatted string) is carried over unchanged. Phase 4: the
    /// message's own `createdAt` is used, so re-saving a message can never
    /// change its original send time.
    func toPersisted() -> PersistedChatMessage {

        PersistedChatMessage(
            id: id,
            requestID: requestID,
            senderUsername: senderUsername,
            text: text,
            time: time,
            createdAt: createdAt,
            senderID: senderID
        )
    }

    init(persisted: PersistedChatMessage) {

        self.init(
            id: persisted.id,
            requestID: persisted.requestID,
            senderUsername: persisted.senderUsername,
            text: persisted.text,
            time: persisted.time,
            senderID: persisted.senderID,
            createdAt: persisted.createdAt
        )
    }
}


// MARK: - Conversion: HelpAgreement <-> PersistedHelpAgreement

extension HelpAgreement {

    func toPersisted() -> PersistedHelpAgreement {

        PersistedHelpAgreement(
            id: id,
            requestID: requestID,
            requesterName: requesterName,
            helperName: helperName,
            agreementDescription: description,
            date: date,
            time: time,
            location: location,
            exchangeTypeKey: exchangeType.persistenceKey,
            amount: amount,
            paymentStatusKey: paymentStatus.persistenceKey,
            isConfirmedByRequester: isConfirmedByRequester,
            isConfirmedByHelper: isConfirmedByHelper,
            requesterID: requesterID,
            helperID: helperID
        )
    }

    init(persisted: PersistedHelpAgreement) {

        self.init(
            id: persisted.id,
            requestID: persisted.requestID,
            requesterName: persisted.requesterName,
            helperName: persisted.helperName,
            description: persisted.agreementDescription,
            date: persisted.date,
            time: persisted.time,
            location: persisted.location,
            exchangeType: ExchangeType(persistenceKey: persisted.exchangeTypeKey),
            amount: persisted.amount,
            paymentStatus: PaymentStatus(persistenceKey: persisted.paymentStatusKey),
            isConfirmedByRequester: persisted.isConfirmedByRequester,
            isConfirmedByHelper: persisted.isConfirmedByHelper,
            requesterID: persisted.requesterID,
            helperID: persisted.helperID
        )
    }
}


// MARK: - Conversion: CommunityNotification <-> PersistedNotification

extension CommunityNotification {

    func toPersisted() -> PersistedNotification {

        PersistedNotification(
            id: id,
            title: title,
            message: message,
            icon: icon,
            date: date,
            isRead: isRead,
            recipientID: recipientID,
            requestID: requestID,
            dedupeKey: dedupeKey
        )
    }

    init(persisted: PersistedNotification) {

        self.init(
            id: persisted.id,
            title: persisted.title,
            message: persisted.message,
            icon: persisted.icon,
            date: persisted.date,
            isRead: persisted.isRead,
            recipientID: persisted.recipientID,
            requestID: persisted.requestID,
            dedupeKey: persisted.dedupeKey
        )
    }
}
