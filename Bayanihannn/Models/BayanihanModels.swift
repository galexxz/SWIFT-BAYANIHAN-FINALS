import Foundation

// MARK: - Community Request

struct CommunityRequest: Identifiable {
    
    let id: UUID
    var title: String
    var description: String
    var category: RequestCategory
    var location: String
    var date: Date
    var time: String
    var peopleNeeded: Int
    var urgency: RequestUrgency
    
    var requesterName: String
    var requesterUsername: String
    
    var status: CommunityRequestStatus
    var helperName: String?

    var createdAt: Date

    // Phase 2: stable account IDs. Ownership is decided by these IDs, never
    // by names/usernames (which can change in Edit Profile). Optional so
    // seeded community members without an account stay valid.
    var requesterID: UUID?
    var helperID: UUID?

    // Phase 3: set when the helper has received the completion reward, so
    // points/helped stats can never be awarded twice for one request.
    var completionRewardGranted: Bool

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: RequestCategory,
        location: String,
        date: Date = Date(),
        time: String,
        peopleNeeded: Int,
        urgency: RequestUrgency,
        requesterName: String,
        requesterUsername: String,
        status: CommunityRequestStatus = .open,
        helperName: String? = nil,
        createdAt: Date = Date(),
        requesterID: UUID? = nil,
        helperID: UUID? = nil,
        completionRewardGranted: Bool = false
    ) {
        self.id = id
        self.completionRewardGranted = completionRewardGranted
        self.title = title
        self.description = description
        self.category = category
        self.location = location
        self.date = date
        self.time = time
        self.peopleNeeded = peopleNeeded
        self.urgency = urgency
        self.requesterName = requesterName
        self.requesterUsername = requesterUsername
        self.status = status
        self.helperName = helperName
        self.requesterID = requesterID
        self.helperID = helperID
        self.createdAt = createdAt
    }
}


// MARK: - Request Category

enum RequestCategory: String, CaseIterable, Identifiable {
    
    case food = "Food"
    case medical = "Medical"
    case education = "Education"
    case housing = "Housing"
    case donation = "Donation"
    case volunteer = "Volunteer"
    case emergency = "Emergency"
    case other = "Others"
    
    var id: String {
        rawValue
    }
    
    var icon: String {
        
        switch self {
            
        case .food:
            return "fork.knife"
            
        case .medical:
            return "cross.case.fill"
            
        case .education:
            return "book.fill"
            
        case .housing:
            return "house.fill"
            
        case .donation:
            return "gift.fill"
            
        case .volunteer:
            return "person.2.fill"
            
        case .emergency:
            return "exclamationmark.triangle.fill"
            
        case .other:
            return "square.grid.2x2.fill"
        }
    }
}


// MARK: - Request Urgency

enum RequestUrgency: String, CaseIterable, Identifiable {
    
    case normal = "Normal"
    case urgent = "Urgent"
    case emergency = "Emergency"
    
    var id: String {
        rawValue
    }
    
    var icon: String {
        
        switch self {
            
        case .normal:
            return "circle.fill"
            
        case .urgent:
            return "exclamationmark.circle.fill"
            
        case .emergency:
            return "exclamationmark.triangle.fill"
        }
    }

    /// Phase 3: the "Urgent" filter chips include Emergency requests too
    /// (Emergency is more urgent than Urgent).
    var isUrgentOrHigher: Bool {
        self != .normal
    }
}


// MARK: - Community Request Status

enum CommunityRequestStatus: String, CaseIterable, Identifiable {
    
    case open = "OPEN"
    case inDiscussion = "IN DISCUSSION"
    case confirmed = "CONFIRMED"
    case inProgress = "IN PROGRESS"
    case completed = "COMPLETED"
    
    var id: String {
        rawValue
    }
    
    var icon: String {
        
        switch self {
            
        case .open:
            return "circle.fill"
            
        case .inDiscussion:
            return "message.fill"
            
        case .confirmed:
            return "handshake.fill"
            
        case .inProgress:
            return "figure.walk"
            
        case .completed:
            return "checkmark.circle.fill"
        }
    }
}


// MARK: - Help Agreement

struct HelpAgreement: Identifiable {

    let id: UUID

    var requestID: UUID
    var requesterName: String
    var helperName: String

    var description: String
    var date: Date
    var time: String
    var location: String

    var exchangeType: ExchangeType
    var amount: Double

    var paymentStatus: PaymentStatus

    var isConfirmedByRequester: Bool
    var isConfirmedByHelper: Bool

    // Phase 2: stable account IDs of both parties (optional for records
    // created before accounts existed).
    var requesterID: UUID?
    var helperID: UUID?

    var isConfirmed: Bool {
        isConfirmedByRequester && isConfirmedByHelper
    }

    init(
        id: UUID = UUID(),
        requestID: UUID,
        requesterName: String,
        helperName: String,
        description: String,
        date: Date,
        time: String,
        location: String,
        exchangeType: ExchangeType,
        amount: Double,
        paymentStatus: PaymentStatus = .pending,
        isConfirmedByRequester: Bool = false,
        isConfirmedByHelper: Bool = false,
        requesterID: UUID? = nil,
        helperID: UUID? = nil
    ) {
        self.requesterID = requesterID
        self.helperID = helperID
        self.id = id
        self.requestID = requestID
        self.requesterName = requesterName
        self.helperName = helperName
        self.description = description
        self.date = date
        self.time = time
        self.location = location
        self.exchangeType = exchangeType
        self.amount = amount
        self.paymentStatus = paymentStatus
        self.isConfirmedByRequester = isConfirmedByRequester
        self.isConfirmedByHelper = isConfirmedByHelper
    }
}


// MARK: - Exchange Type

enum ExchangeType: String, CaseIterable, Identifiable {

    case noPayment = "No Payment"
    case cash = "Cash"
    case goods = "Goods"

    var id: String {
        rawValue
    }
}


// MARK: - Payment Status

enum PaymentStatus: String, CaseIterable, Identifiable {

    case pending = "Pending"
    case paid = "Paid"
    case notApplicable = "Not Applicable"

    var id: String {
        rawValue
    }
}


// MARK: - Activity

struct CommunityActivity: Identifiable {

    let id: UUID

    var message: String
    var date: Date
    var type: ActivityType
    var actorName: String = "You"

    // Phase 2: account ID of whoever performed the activity (nil for
    // seeded community members without an account).
    var actorID: UUID? = nil

    // Phase 5: the request this activity is about (replaces matching the
    // request title inside the message text). Nil when unknown.
    var requestID: UUID? = nil
}


// MARK: - Activity Type

enum ActivityType: String, CaseIterable, Identifiable {
    
    case all = "All"
    case volunteered = "Volunteered"
    case posted = "Posted"
    
    var id: String {
        rawValue
    }
}


// MARK: - Current User

struct BayanihanUser: Identifiable, Equatable {

    /// Phase 2: unique, stable account ID. Never changes, even when the
    /// name, username or email is edited.
    let id: UUID

    var name: String
    var username: String
    var email: String
    var location: String
    
    var requestsPosted: Int
    var requestsHelped: Int
    var communityPoints: Int

    /// Placeholder used before anyone has logged in. No screen that shows
    /// profile data is visible while signed out.
    static let signedOut = BayanihanUser(
        id: UUID(),
        name: "",
        username: "",
        email: "",
        location: "",
        requestsPosted: 0,
        requestsHelped: 0,
        communityPoints: 0
    )
}


// MARK: - Chat Message

struct ChatMessage: Identifiable {

    let id: UUID

    var requestID: UUID
    var senderUsername: String
    var text: String
    var time: String

    // Phase 2: account ID of the sender (decides which side the bubble is
    // on). Optional for messages created before accounts existed.
    var senderID: UUID?

    // Phase 4: the real send time (loaded from the value SwiftData already
    // stored). Used for ordering, unread counts and "most recent" sorting.
    // The bubble still displays only `time` (e.g. "9:00 AM").
    var createdAt: Date

    init(
        id: UUID = UUID(),
        requestID: UUID,
        senderUsername: String,
        text: String,
        time: String,
        senderID: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.requestID = requestID
        self.senderUsername = senderUsername
        self.senderID = senderID
        self.text = text
        self.time = time
        self.createdAt = createdAt
    }
}


// MARK: - Conversation Read State (Phase 4)

/// When one user last read one conversation (identified by its request).
/// Messages from the other participant after `lastReadAt` are unread.
struct ConversationReadState: Equatable {

    let userID: UUID
    let requestID: UUID
    var lastReadAt: Date
}


// MARK: - Community Notification

struct CommunityNotification: Identifiable {

    let id: UUID

    var title: String
    var message: String
    var icon: String
    var date: Date
    var isRead: Bool

    // Phase 5: the ONLY account that can see this notification (nil = no
    // one), the request it is about, and the duplicate-prevention key
    // ("event|request|recipient"; nil for older seeded notifications).
    var recipientID: UUID?
    var requestID: UUID?
    var dedupeKey: String?

    init(
        id: UUID = UUID(),
        title: String,
        message: String,
        icon: String,
        date: Date = Date(),
        isRead: Bool = false,
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


// MARK: - Request Bookmark (Phase 6)

/// One account's saved (bookmarked) request. Private to that account.
struct RequestBookmark: Equatable {

    let userID: UUID
    let requestID: UUID
    var createdAt: Date
}


// MARK: - Request Report (Phase 6)

/// Why a request was reported. `rawValue` is the stable stored key.
enum ReportReason: String, CaseIterable, Identifiable {

    case spam
    case inappropriate
    case scam
    case safety
    case other

    var id: String {
        rawValue
    }

    /// Text shown in the report options.
    var title: String {

        switch self {

        case .spam:
            return "Spam or misleading"

        case .inappropriate:
            return "Inappropriate content"

        case .scam:
            return "Possible scam"

        case .safety:
            return "Safety concern"

        case .other:
            return "Something else"
        }
    }
}

/// A local report of a request by one account (kept for review; with
/// Firebase it would go to a moderation queue).
struct RequestReport: Identifiable, Equatable {

    let id: UUID
    let requestID: UUID
    let reporterID: UUID
    var reason: ReportReason
    var createdAt: Date
}