import Foundation
import SwiftData

// MARK: - Step 2: SwiftData Storage Layer

@MainActor
final class BayanihanDataStore {

    // MARK: - Storage

    let container: ModelContainer
    let context: ModelContext


    // MARK: - Init

    /// - Parameter inMemory: When true, uses an in-memory-only store
    ///   (useful for previews/testing). Defaults to a normal persistent
    ///   store for the real app.
    ///
    /// Throws (never force-unwraps/crashes) if no container — persistent or
    /// in-memory fallback — could be created, so a caller can decide how to
    /// handle that instead of the app terminating unexpectedly.
    init(inMemory: Bool = false) throws {

        let schema = Schema([
            PersistedUser.self,
            PersistedRequest.self,
            PersistedActivity.self,
            PersistedChatMessage.self,
            PersistedHelpAgreement.self,
            PersistedNotification.self,
            // Phase 2: new entities (adding entities is a lightweight,
            // automatic SwiftData migration — existing data is kept).
            PersistedCredential.self,
            PersistedMigrationRecord.self,
            // Phase 4: new entity (lightweight, automatic migration).
            PersistedConversationReadState.self,
            // Phase 6: new entities (lightweight, automatic migration).
            PersistedBookmark.self,
            PersistedRequestReport.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)

        do {
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {

            // The persistent store could not be created (e.g. a corrupted
            // store file). Rather than crashing the app, fall back to an
            // in-memory container so the app can still run. If that also
            // fails, propagate the error instead of force-unwrapping.
            print("BayanihanDataStore: Failed to create persistent ModelContainer (\(error)). Falling back to an in-memory store.")

            let fallbackConfiguration = ModelConfiguration(isStoredInMemoryOnly: true)

            container = try ModelContainer(
                for: schema,
                configurations: [fallbackConfiguration]
            )
        }

        context = ModelContext(container)
    }


    // MARK: - Seed Check

    /// Determine whether persistent data already exists, so a caller (the
    /// Controller, in a later step) knows whether it still needs to seed
    /// demo/user data. A single PersistedUser existing is treated as
    /// sufficient evidence that the store has been seeded before.
    func hasSeededData() -> Bool {

        var descriptor = FetchDescriptor<PersistedUser>()
        descriptor.fetchLimit = 1

        do {
            let count = try context.fetchCount(descriptor)
            return count > 0
        } catch {
            print("BayanihanDataStore: Failed to check for existing seeded data: \(error)")
            return false
        }
    }


    // MARK: - Save Context

    /// Saves the current ModelContext if it has pending changes. Safe to
    /// call after any insert/update.
    func saveContext() {

        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            print("BayanihanDataStore: Failed to save context: \(error)")
        }
    }


    // MARK: - Load Users

    func loadUsers() -> [PersistedUser] {

        do {
            return try context.fetch(FetchDescriptor<PersistedUser>())
        } catch {
            print("BayanihanDataStore: Failed to load users: \(error)")
            return []
        }
    }


    // MARK: - Load Requests

    func loadRequests() -> [PersistedRequest] {

        let descriptor = FetchDescriptor<PersistedRequest>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("BayanihanDataStore: Failed to load requests: \(error)")
            return []
        }
    }


    // MARK: - Load Activities

    func loadActivities() -> [PersistedActivity] {

        let descriptor = FetchDescriptor<PersistedActivity>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("BayanihanDataStore: Failed to load activities: \(error)")
            return []
        }
    }


    // MARK: - Load Chat Messages

    func loadChatMessages() -> [PersistedChatMessage] {

        let descriptor = FetchDescriptor<PersistedChatMessage>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("BayanihanDataStore: Failed to load chat messages: \(error)")
            return []
        }
    }


    // MARK: - Load Help Agreements

    func loadHelpAgreements() -> [PersistedHelpAgreement] {

        let descriptor = FetchDescriptor<PersistedHelpAgreement>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("BayanihanDataStore: Failed to load help agreements: \(error)")
            return []
        }
    }


    // MARK: - Load Notifications

    func loadNotifications() -> [PersistedNotification] {

        let descriptor = FetchDescriptor<PersistedNotification>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            print("BayanihanDataStore: Failed to load notifications: \(error)")
            return []
        }
    }


    // MARK: - Save User

    /// Updates the existing PersistedUser with a matching id, or inserts
    /// `user` if none exists yet.
    func saveUser(_ user: PersistedUser) {

        let userID = user.id

        let descriptor = FetchDescriptor<PersistedUser>(
            predicate: #Predicate { $0.id == userID }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.name = user.name
                existing.username = user.username
                existing.email = user.email
                existing.location = user.location
                existing.requestsPosted = user.requestsPosted
                existing.requestsHelped = user.requestsHelped
                existing.communityPoints = user.communityPoints
            } else {
                context.insert(user)
            }
        } catch {
            print("BayanihanDataStore: Failed to save user: \(error)")
            return
        }

        saveContext()
    }


    // MARK: - Save Request

    /// Updates the existing PersistedRequest with a matching id, or inserts
    /// `request` if none exists yet.
    func saveRequest(_ request: PersistedRequest) {

        let requestID = request.id

        let descriptor = FetchDescriptor<PersistedRequest>(
            predicate: #Predicate { $0.id == requestID }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.title = request.title
                existing.requestDescription = request.requestDescription
                existing.categoryKey = request.categoryKey
                existing.location = request.location
                existing.date = request.date
                existing.time = request.time
                existing.peopleNeeded = request.peopleNeeded
                existing.urgencyKey = request.urgencyKey
                existing.requesterName = request.requesterName
                existing.requesterUsername = request.requesterUsername
                existing.statusKey = request.statusKey
                existing.helperName = request.helperName
                existing.createdAt = request.createdAt
                existing.requesterID = request.requesterID
                existing.helperID = request.helperID
                existing.completionRewardGranted = request.completionRewardGranted
            } else {
                context.insert(request)
            }
        } catch {
            print("BayanihanDataStore: Failed to save request: \(error)")
            return
        }

        saveContext()
    }


    // MARK: - Save Activity

    /// Updates the existing PersistedActivity with a matching id, or
    /// inserts `activity` if none exists yet.
    func saveActivity(_ activity: PersistedActivity) {

        let activityID = activity.id

        let descriptor = FetchDescriptor<PersistedActivity>(
            predicate: #Predicate { $0.id == activityID }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.message = activity.message
                existing.date = activity.date
                existing.typeKey = activity.typeKey
                existing.actorName = activity.actorName
                existing.actorID = activity.actorID
                existing.requestID = activity.requestID
            } else {
                context.insert(activity)
            }
        } catch {
            print("BayanihanDataStore: Failed to save activity: \(error)")
            return
        }

        saveContext()
    }


    // MARK: - Save Chat Message

    /// Updates the existing PersistedChatMessage with a matching id, or
    /// inserts `message` if none exists yet.
    func saveChatMessage(_ message: PersistedChatMessage) {

        let messageID = message.id

        let descriptor = FetchDescriptor<PersistedChatMessage>(
            predicate: #Predicate { $0.id == messageID }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.requestID = message.requestID
                existing.senderUsername = message.senderUsername
                existing.text = message.text
                existing.time = message.time
                existing.senderID = message.senderID
                // Phase 2: `createdAt` is intentionally NOT overwritten on
                // update. It is the original send time used for ordering;
                // ChatMessage has no createdAt of its own, so an update
                // snapshot would otherwise replace it with "now" and
                // reorder the conversation.
            } else {
                context.insert(message)
            }
        } catch {
            print("BayanihanDataStore: Failed to save chat message: \(error)")
            return
        }

        saveContext()
    }


    // MARK: - Save Help Agreement

    /// Updates the existing PersistedHelpAgreement with a matching id, or
    /// inserts `agreement` if none exists yet.
    func saveHelpAgreement(_ agreement: PersistedHelpAgreement) {

        let agreementID = agreement.id

        let descriptor = FetchDescriptor<PersistedHelpAgreement>(
            predicate: #Predicate { $0.id == agreementID }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.requestID = agreement.requestID
                existing.requesterName = agreement.requesterName
                existing.helperName = agreement.helperName
                existing.agreementDescription = agreement.agreementDescription
                existing.date = agreement.date
                existing.time = agreement.time
                existing.location = agreement.location
                existing.exchangeTypeKey = agreement.exchangeTypeKey
                existing.amount = agreement.amount
                existing.paymentStatusKey = agreement.paymentStatusKey
                existing.isConfirmedByRequester = agreement.isConfirmedByRequester
                existing.isConfirmedByHelper = agreement.isConfirmedByHelper
                existing.requesterID = agreement.requesterID
                existing.helperID = agreement.helperID
            } else {
                context.insert(agreement)
            }
        } catch {
            print("BayanihanDataStore: Failed to save help agreement: \(error)")
            return
        }

        saveContext()
    }


    // MARK: - Save Notification

    /// Updates the existing PersistedNotification with a matching id, or
    /// inserts `notification` if none exists yet.
    func saveNotification(_ notification: PersistedNotification) {

        let notificationID = notification.id

        let descriptor = FetchDescriptor<PersistedNotification>(
            predicate: #Predicate { $0.id == notificationID }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.title = notification.title
                existing.message = notification.message
                existing.icon = notification.icon
                existing.date = notification.date
                existing.isRead = notification.isRead
                existing.recipientID = notification.recipientID
                existing.requestID = notification.requestID
                existing.dedupeKey = notification.dedupeKey
            } else {
                context.insert(notification)
            }
        } catch {
            print("BayanihanDataStore: Failed to save notification: \(error)")
            return
        }

        saveContext()
    }


    // MARK: - Credentials (Phase 2)

    /// Returns the stored sign-in credential (salted hash) for an account.
    func loadCredential(
        for userID: UUID
    ) -> PersistedCredential? {

        let descriptor = FetchDescriptor<PersistedCredential>(
            predicate: #Predicate { $0.userID == userID }
        )

        do {
            return try context.fetch(descriptor).first
        } catch {
            print("BayanihanDataStore: Failed to load credential: \(error)")
            return nil
        }
    }

    /// Updates the credential for the same account, or inserts it.
    @discardableResult
    func saveCredential(
        _ credential: PersistedCredential
    ) -> Bool {

        let userID = credential.userID

        let descriptor = FetchDescriptor<PersistedCredential>(
            predicate: #Predicate { $0.userID == userID }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.passwordHash = credential.passwordHash
                existing.passwordSalt = credential.passwordSalt
                existing.iterations = credential.iterations
                existing.algorithm = credential.algorithm
                existing.updatedAt = credential.updatedAt
            } else {
                context.insert(credential)
            }
            try context.save()
            return true
        } catch {
            print("BayanihanDataStore: Failed to save credential: \(error)")
            return false
        }
    }


    // MARK: - Migration Records (Phase 2)

    func hasCompletedMigration(
        _ name: String
    ) -> Bool {

        var descriptor = FetchDescriptor<PersistedMigrationRecord>(
            predicate: #Predicate { $0.name == name }
        )
        descriptor.fetchLimit = 1

        do {
            return try context.fetchCount(descriptor) > 0
        } catch {
            print("BayanihanDataStore: Failed to check migration \(name): \(error)")
            // Treat as completed so a failing check can never cause a
            // migration to run twice.
            return true
        }
    }

    func markMigrationCompleted(
        _ name: String
    ) {

        guard !hasCompletedMigration(name) else {
            return
        }

        context.insert(PersistedMigrationRecord(name: name))
        saveContext()
    }

    /// Phase 4: when a migration was completed (nil if it never ran).
    func migrationCompletedAt(
        _ name: String
    ) -> Date? {

        var descriptor = FetchDescriptor<PersistedMigrationRecord>(
            predicate: #Predicate { $0.name == name }
        )
        descriptor.fetchLimit = 1

        do {
            return try context.fetch(descriptor).first?.completedAt
        } catch {
            print("BayanihanDataStore: Failed to load migration \(name): \(error)")
            return nil
        }
    }


    // MARK: - Conversation Read States (Phase 4)

    func loadConversationReadStates() -> [PersistedConversationReadState] {

        do {
            return try context.fetch(FetchDescriptor<PersistedConversationReadState>())
        } catch {
            print("BayanihanDataStore: Failed to load conversation read states: \(error)")
            return []
        }
    }

    /// Updates the row for the same user + conversation, or inserts it.
    func saveConversationReadState(
        _ state: PersistedConversationReadState
    ) {

        let key = state.key

        let descriptor = FetchDescriptor<PersistedConversationReadState>(
            predicate: #Predicate { $0.key == key }
        )

        do {
            if let existing = try context.fetch(descriptor).first {
                existing.lastReadAt = state.lastReadAt
            } else {
                context.insert(state)
            }
        } catch {
            print("BayanihanDataStore: Failed to save conversation read state: \(error)")
            return
        }

        saveContext()
    }


    // MARK: - Bookmarks (Phase 6)

    func loadBookmarks() -> [PersistedBookmark] {

        do {
            return try context.fetch(FetchDescriptor<PersistedBookmark>())
        } catch {
            print("BayanihanDataStore: Failed to load bookmarks: \(error)")
            return []
        }
    }

    /// Inserts the bookmark unless the same account already saved it.
    func saveBookmark(
        _ bookmark: PersistedBookmark
    ) {

        let key = bookmark.key

        let descriptor = FetchDescriptor<PersistedBookmark>(
            predicate: #Predicate { $0.key == key }
        )

        do {
            guard try context.fetch(descriptor).isEmpty else {
                return
            }
            context.insert(bookmark)
        } catch {
            print("BayanihanDataStore: Failed to save bookmark: \(error)")
            return
        }

        saveContext()
    }

    /// Removes ONE account's bookmark of ONE request (the user un-saving
    /// it). Never touches any other record.
    func deleteBookmark(
        userID: UUID,
        requestID: UUID
    ) {

        let key = PersistedBookmark.makeKey(userID: userID, requestID: requestID)

        let descriptor = FetchDescriptor<PersistedBookmark>(
            predicate: #Predicate { $0.key == key }
        )

        do {
            for bookmark in try context.fetch(descriptor) {
                context.delete(bookmark)
            }
        } catch {
            print("BayanihanDataStore: Failed to delete bookmark: \(error)")
            return
        }

        saveContext()
    }


    // MARK: - Request Reports (Phase 6)

    func loadRequestReports() -> [PersistedRequestReport] {

        do {
            return try context.fetch(FetchDescriptor<PersistedRequestReport>())
        } catch {
            print("BayanihanDataStore: Failed to load request reports: \(error)")
            return []
        }
    }

    /// Inserts a report (reports are never edited or removed).
    func saveRequestReport(
        _ report: PersistedRequestReport
    ) {

        let reportID = report.id

        let descriptor = FetchDescriptor<PersistedRequestReport>(
            predicate: #Predicate { $0.id == reportID }
        )

        do {
            guard try context.fetch(descriptor).isEmpty else {
                return
            }
            context.insert(report)
        } catch {
            print("BayanihanDataStore: Failed to save request report: \(error)")
            return
        }

        saveContext()
    }
}
