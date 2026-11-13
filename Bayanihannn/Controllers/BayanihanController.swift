import Foundation
import SwiftUI

@MainActor
@Observable
final class BayanihanController {

    // MARK: - Session

    // Phase 2: only changed through login / register / logout below (and
    // automatic login from a remembered session in init).
    private(set) var isLoggedIn: Bool = false


    // MARK: - Current User

    // Phase 2: the signed-in account. Set on login/registration/auto-login.
    var currentUser: BayanihanUser = .signedOut


    // MARK: - Demo Accounts (local development only)

    /// The original single demo user (pre-Phase-2 "current user"). On a
    /// fresh install it is seeded exactly as before; on an existing install
    /// the already-stored record (and its id) is kept untouched.
    private static func makeLegacyDemoUser() -> BayanihanUser {
        BayanihanUser(
            id: UUID(),
            name: "Alex Rivera",
            username: "@alexrivera",
            email: "alex@example.com",
            location: "Brgy. San Isidro",
            requestsPosted: 5,
            requestsHelped: 3,
            communityPoints: 12
        )
    }

    /// Second demo account so requester ↔ helper flows can be tested on
    /// one device. Matches the seeded "Groceries for a Senior Citizen"
    /// requester, so that request becomes Maria's.
    private static func makeSecondDemoUser() -> BayanihanUser {
        BayanihanUser(
            id: UUID(),
            name: "Maria Santos",
            username: "@mariasantos",
            email: "maria@example.com",
            location: "Brgy. San Isidro",
            requestsPosted: 1,
            requestsHelped: 0,
            communityPoints: 0
        )
    }

    /// Password given to the demo accounts above (they had no password
    /// before Phase 2). Local development only — documented for testing.
    static let demoAccountPassword = "Bayanihan123"


    // MARK: - Requests

    var requests: [CommunityRequest] = [

        CommunityRequest(
            title: "Groceries for a Senior Citizen",
            description: "Maria needs help getting groceries for her elderly mother.",
            category: .food,
            location: "Brgy. San Isidro",
            date: Date(),
            time: "9:00 AM",
            peopleNeeded: 1,
            urgency: .urgent,
            requesterName: "Maria Santos",
            requesterUsername: "@mariasantos",
            status: .open
        ),

        CommunityRequest(
            title: "Medical Supplies Needed",
            description: "A family in the community needs assistance obtaining medical supplies.",
            category: .medical,
            location: "Brgy. San Jose",
            date: Date(),
            time: "10:00 AM",
            peopleNeeded: 2,
            urgency: .urgent,
            requesterName: "Juan Dela Cruz",
            requesterUsername: "@juandelacruz",
            status: .open
        ),

        CommunityRequest(
            title: "School Supplies for Children",
            description: "Three children need school supplies before the start of classes.",
            category: .education,
            location: "Brgy. San Isidro",
            date: Date(),
            time: "2:00 PM",
            peopleNeeded: 2,
            urgency: .normal,
            requesterName: "Ana Reyes",
            requesterUsername: "@anareyes",
            status: .open
        ),

        CommunityRequest(
            title: "Community Clean-up",
            description: "Volunteers are needed for a neighborhood clean-up activity.",
            category: .volunteer,
            location: "Brgy. San Jose",
            date: Date(),
            time: "8:00 AM",
            peopleNeeded: 5,
            urgency: .normal,
            requesterName: "Barangay San Jose",
            requesterUsername: "@barangaysanjose",
            status: .open
        )
    ]


    // MARK: - Activities

    // Phase 5 (L2): read-only outside the Controller. Views must use the
    // filtered `visibleActivities` (personal feed), never this raw list.
    private(set) var activities: [CommunityActivity] = [

        CommunityActivity(
            id: UUID(),
            message: "Volunteered to help Maria Santos.",
            date: Date(),
            type: .volunteered
        ),

        CommunityActivity(
            id: UUID(),
            message: "Posted “School Supplies for Children.”",
            date: Date().addingTimeInterval(-3600),
            type: .posted
        ),

        CommunityActivity(
            id: UUID(),
            message: "Completed a community helping activity.",
            date: Date().addingTimeInterval(-7200),
            type: .volunteered
        ),

        CommunityActivity(
            id: UUID(),
            message: "Volunteered to help with “Groceries for a Senior Citizen.”",
            date: Date().addingTimeInterval(-5400),
            type: .volunteered,
            actorName: "Maria Santos"
        ),

        CommunityActivity(
            id: UUID(),
            message: "Posted “Medical Supplies Needed.”",
            date: Date().addingTimeInterval(-14400),
            type: .posted,
            actorName: "Juan Dela Cruz"
        ),

        CommunityActivity(
            id: UUID(),
            message: "Completed a community clean-up.",
            date: Date().addingTimeInterval(-86400),
            type: .volunteered,
            actorName: "Ana Reyes"
        )
    ]


    // MARK: - Notifications

    // Phase 5 (L2): read-only outside the Controller. Views must use the
    // per-account `visibleNotifications`, never this raw list (it holds
    // every account's notifications on this device).
    private(set) var notifications: [CommunityNotification] = [

        CommunityNotification(
            title: "Helper Found",
            message: "Someone offered to help with “Groceries for a Senior Citizen.”",
            icon: "hands.sparkles.fill",
            date: Date().addingTimeInterval(-1800),
            isRead: false
        ),

        CommunityNotification(
            title: "Request Posted",
            message: "Your request “School Supplies for Children” is now visible to the community.",
            icon: "megaphone.fill",
            date: Date().addingTimeInterval(-5400),
            isRead: true
        )
    ]


    // MARK: - Chat Messages

    var chatMessages: [ChatMessage] = []

    // Phase 4: when each user last read each conversation (all users on
    // this device; lookups are always filtered by the signed-in user).
    private(set) var conversationReadStates: [ConversationReadState] = []

    // Phase 4: messages created before Phase 4 was installed count as read
    // for everyone (no sudden unread badges after the upgrade). Set from
    // the completion time of MessagingRules.readStateMigrationName.
    private var messageReadCutoff: Date?

    // Phase 5: account id → current display name, used to show the correct
    // person's name in the Activity feed (refreshed whenever accounts or
    // names can change). Local-only lookup; a user directory with Firebase.
    private var accountNames: [UUID: String] = [:]

    // Phase 6: every account's bookmarks and reports on this device (all
    // lookups are filtered by the signed-in account).
    private(set) var bookmarks: [RequestBookmark] = []
    private(set) var requestReports: [RequestReport] = []


    // MARK: - Help Agreements

    var helpAgreements: [HelpAgreement] = []


    // MARK: - Persistence

    // Step 3: local SwiftData-backed storage. Views never see this — the
    // Controller keeps its existing in-memory arrays/properties above as
    // the single source of truth for the UI, and mirrors changes into
    // `dataStore` so they survive relaunch.
    private let dataStore: BayanihanDataStore

    // Phase 2: accounts/sessions. The Controller uses the `AuthService`
    // protocol for everything account-related, so a Firebase implementation
    // can replace `LocalAuthService` later. `localAuth` is the same object,
    // used only for the one-time local migration of demo accounts.
    private let authService: any AuthService
    private let localAuth: LocalAuthService


    // MARK: - Init

    init() {

        let store = Self.makeDataStore()
        let auth = LocalAuthService(dataStore: store)

        dataStore = store
        localAuth = auth
        authService = auth

        if dataStore.hasSeededData() {

            // Later launch: restore everything from SwiftData instead of
            // using the demo values declared above. (Accounts themselves are
            // loaded by the AuthService when someone logs in.)

            requests = dataStore.loadRequests().map(CommunityRequest.init(persisted:))
            activities = dataStore.loadActivities().map(CommunityActivity.init(persisted:))
            chatMessages = dataStore.loadChatMessages().map(ChatMessage.init(persisted:))
            helpAgreements = dataStore.loadHelpAgreements().map(HelpAgreement.init(persisted:))
            notifications = dataStore.loadNotifications().map(CommunityNotification.init(persisted:))

        } else {

            // First launch: the demo/seed data declared above (requests,
            // activities, notifications) plus the original demo user are the
            // source of truth. Save them once so future launches load from
            // SwiftData instead of reseeding.

            dataStore.saveUser(Self.makeLegacyDemoUser().toPersisted())

            for request in requests {
                dataStore.saveRequest(request.toPersisted())
            }

            for activity in activities {
                dataStore.saveActivity(activity.toPersisted())
            }

            for notification in notifications {
                dataStore.saveNotification(notification.toPersisted())
            }

            // chatMessages and helpAgreements start empty in the demo data,
            // so there is nothing to seed for them yet.
        }

        // Phase 2: link existing data to accounts (runs once per store).
        runIdentityMigrationIfNeeded()

        // Phase 4: unread tracking. The first launch with Phase 4 records
        // the "already read" cutoff once (additive; no data is changed),
        // then saved read states are loaded.
        if !dataStore.hasCompletedMigration(MessagingRules.readStateMigrationName) {
            dataStore.markMigrationCompleted(MessagingRules.readStateMigrationName)
        }

        messageReadCutoff = dataStore.migrationCompletedAt(MessagingRules.readStateMigrationName)

        conversationReadStates = dataStore
            .loadConversationReadStates()
            .map(ConversationReadState.init(persisted:))

        // Phase 5: link older activities/notifications (runs once per store)
        // and load account names for the Activity feed.
        runActivityNotificationMigrationIfNeeded()
        refreshAccountNames()

        // Phase 6: saved bookmarks and reports.
        bookmarks = dataStore.loadBookmarks().map(RequestBookmark.init(persisted:))
        requestReports = dataStore.loadRequestReports().map(RequestReport.init(persisted:))

        // Phase 2: automatic login when "Remember Me" was used.
        if let rememberedUser = authService.restoreSession() {
            currentUser = rememberedUser
            isLoggedIn = true
        }
    }


    // MARK: - Identity Migration (Phase 2)

    /// One-time, additive migration of pre-Phase-2 data:
    ///  1. The existing local user (Alex) keeps its record and id and gets
    ///     the demo password (it had no password before).
    ///  2. A second demo account (Maria Santos) is added if missing.
    ///  3. Empty requester/helper/sender/actor ids are filled in by matching
    ///     the stored usernames/names to accounts.
    /// Nothing is deleted, reset or overwritten. Completion is recorded in
    /// the same SwiftData store, so it never runs twice.
    private func runIdentityMigrationIfNeeded() {

        guard !dataStore.hasCompletedMigration(IdentityMigrationV1.name) else {
            return
        }

        // Before Phase 2 the store only ever held one user: the local user.
        let legacyUsers = localAuth.allAccounts()
        let legacyLocalUserID = legacyUsers.first?.id

        for user in legacyUsers {
            localAuth.addCredentialIfMissing(
                for: user.id,
                password: Self.demoAccountPassword
            )
        }

        localAuth.addDemoAccountIfMissing(
            Self.makeSecondDemoUser(),
            password: Self.demoAccountPassword
        )

        let result = IdentityMigrationV1.backfill(
            requests: &requests,
            messages: &chatMessages,
            activities: &activities,
            agreements: &helpAgreements,
            accounts: localAuth.allAccounts(),
            legacyLocalUserID: legacyLocalUserID
        )

        for request in requests where result.changedRequestIDs.contains(request.id) {
            persist(request)
        }

        for message in chatMessages where result.changedMessageIDs.contains(message.id) {
            persist(message)
        }

        for activity in activities where result.changedActivityIDs.contains(activity.id) {
            persist(activity)
        }

        for agreement in helpAgreements where result.changedAgreementIDs.contains(agreement.id) {
            persist(agreement)
        }

        dataStore.markMigrationCompleted(IdentityMigrationV1.name)

        print("BayanihanController: Identity migration v1 completed (\(result.totalChanges) records linked).")
    }


    // MARK: - DataStore Creation

    /// Builds the DataStore without ever using `try!`, a force unwrap, or
    /// `fatalError()`. Tries the normal persistent store first; if that
    /// fails, falls back to an in-memory store (BayanihanDataStore already
    /// attempts this same fallback internally, so reaching the retry loop
    /// below means even a fresh in-memory container — built from this
    /// app's own valid, hardcoded schema — failed too, which is not
    /// expected to happen in practice).
    private static func makeDataStore() -> BayanihanDataStore {

        if let store = try? BayanihanDataStore(inMemory: false) {
            return store
        }

        print("BayanihanController: Persistent DataStore unavailable — falling back to an in-memory store.")

        while true {
            if let store = try? BayanihanDataStore(inMemory: true) {
                return store
            }
        }
    }


    // MARK: - Persist Helpers

    private func persist(_ request: CommunityRequest) {
        dataStore.saveRequest(request.toPersisted())
    }

    private func persist(_ activity: CommunityActivity) {
        dataStore.saveActivity(activity.toPersisted())
    }

    private func persist(_ agreement: HelpAgreement) {
        dataStore.saveHelpAgreement(agreement.toPersisted())
    }

    private func persist(_ notification: CommunityNotification) {
        dataStore.saveNotification(notification.toPersisted())
    }


    // MARK: - Activity / Notification Migration (Phase 5)

    /// Additive upgrade of older activities/notifications, in two steps.
    /// Titles, messages, dates and read states are kept; nothing is
    /// deleted or reset; no actor is invented; existing values are never
    /// overwritten.
    private func runActivityNotificationMigrationIfNeeded() {

        // Step 1 (M1): link requests by EXACT quoted title — runs once.
        if !dataStore.hasCompletedMigration(ActivityNotificationMigrationV1.name) {

            let result = ActivityNotificationMigrationV1.linkRequests(
                activities: &activities,
                notifications: &notifications,
                requests: requests
            )

            for activity in activities where result.changedActivityIDs.contains(activity.id) {
                persist(activity)
            }

            for notification in notifications where result.changedNotificationIDs.contains(notification.id) {
                persist(notification)
            }

            dataStore.markMigrationCompleted(ActivityNotificationMigrationV1.name)
        }

        // Step 2 (H1 + L1): give old notifications to the original demo
        // account. Recorded as complete ONLY when no notification is left
        // without an owner; otherwise retried safely on the next launch.
        if !dataStore.hasCompletedMigration(ActivityNotificationMigrationV1.ownerAssignmentName) {

            let changed = ActivityNotificationMigrationV1.assignOwners(
                notifications: &notifications,
                originalAccountID: originalDemoAccountID()
            )

            for notification in notifications where changed.contains(notification.id) {
                persist(notification)
            }

            if ActivityNotificationMigrationV1.needsOwnerAssignment(notifications) {
                print("BayanihanController: Some older notifications have no owner yet; will retry on next launch.")
            } else {
                dataStore.markMigrationCompleted(ActivityNotificationMigrationV1.ownerAssignmentName)
            }
        }
    }

    /// The original demo account (Alex), found by the demo username/email
    /// first; only if no such account exists, the owner of the OLDEST
    /// legacy "You" activity. Nil when neither exists.
    private func originalDemoAccountID() -> UUID? {
        ActivityNotificationMigrationV1.originalAccountID(
            accounts: localAuth.allAccounts(),
            activities: activities
        )
    }

    private func refreshAccountNames() {
        accountNames = Dictionary(
            localAuth.allAccounts().map { ($0.id, $0.name) },
            uniquingKeysWith: { first, _ in first }
        )
    }


    // MARK: - Recording Activities & Notifications (Phase 5)

    /// Adds an activity for the signed-in user about a request. Activities
    /// store the actor's real name; the feed shows "You" to the actor.
    /// Requester actions are filed under "Posted", helper actions under
    /// "Volunteered" (no new filter segments).
    private func recordActivity(
        _ message: String,
        aboutRequestAt index: Int
    ) {

        let type: ActivityType = role(in: requests[index]) == .requester
            ? .posted
            : .volunteered

        let activity = CommunityActivity(
            id: UUID(),
            message: message,
            date: Date(),
            type: type,
            actorName: currentUser.name,
            actorID: currentUser.id,
            requestID: requests[index].id
        )

        activities.insert(activity, at: 0)

        persist(activity)
    }

    /// Notifies the right participant about an action the signed-in user
    /// just completed successfully. Never notifies the actor; one-time
    /// events are never duplicated; message notifications are merged per
    /// conversation.
    private func notify(
        _ event: NotificationEvent,
        aboutRequestAt index: Int
    ) {

        guard isLoggedIn,
              let draft = NotificationRules.draft(
                for: event,
                request: requests[index],
                actorID: currentUser.id,
                actorName: currentUser.name
              ),
              let saved = NotificationRules.apply(
                draft,
                to: &notifications,
                now: Date()
              )
        else {
            return
        }

        persist(saved)
    }


    // MARK: - Notifications (Phase 5)

    /// The signed-in user's notifications only, newest first.
    var visibleNotifications: [CommunityNotification] {
        NotificationRules.visible(
            notifications,
            to: isLoggedIn ? currentUser.id : nil
        )
    }

    /// Unread notifications for the signed-in user (Home bell badge).
    var unreadNotificationCount: Int {
        NotificationRules.unreadCount(
            notifications,
            for: isLoggedIn ? currentUser.id : nil
        )
    }

    /// Marks one of the signed-in user's notifications read (tap).
    func markNotificationRead(
        _ notificationID: UUID
    ) {

        guard isLoggedIn,
              let index = notifications.firstIndex(where: {
                $0.id == notificationID && $0.recipientID == currentUser.id
              }),
              !notifications[index].isRead
        else {
            return
        }

        notifications[index].isRead = true

        persist(notifications[index])
    }

    /// Phase 5 (M2): marks the signed-in user's merged "New Message"
    /// notification for one conversation read (if it exists and is unread).
    private func markMessageNotificationRead(
        requestID: UUID
    ) {

        guard isLoggedIn else {
            return
        }

        let key = NotificationRules.dedupeKey(
            event: .newMessage,
            requestID: requestID,
            recipientID: currentUser.id
        )

        guard let index = notifications.firstIndex(where: {
            $0.dedupeKey == key && $0.recipientID == currentUser.id
        }),
              !notifications[index].isRead
        else {
            return
        }

        notifications[index].isRead = true

        persist(notifications[index])
    }

    /// Marks every unread notification of the signed-in user read (when
    /// leaving the Notifications screen).
    func markAllNotificationsRead() {

        guard isLoggedIn else {
            return
        }

        for index in notifications.indices
        where notifications[index].recipientID == currentUser.id &&
            !notifications[index].isRead {

            notifications[index].isRead = true
            persist(notifications[index])
        }
    }


    // MARK: - Activity Feed (Phase 5)

    /// PERSONAL feed: the signed-in user's own activities plus activities on
    /// requests they posted. Newest first.
    var visibleActivities: [CommunityActivity] {
        ActivityFeedRules.personalFeed(
            activities,
            for: isLoggedIn ? currentUser.id : nil,
            requests: requests
        )
    }

    /// "You" for the signed-in actor, otherwise the actor's name.
    func activityDisplayName(
        for activity: CommunityActivity
    ) -> String {
        ActivityFeedRules.displayName(
            for: activity,
            currentUserID: isLoggedIn ? currentUser.id : nil,
            accountNames: accountNames
        )
    }

    /// The request a notification or activity is about (by id only).
    func linkedRequest(
        id requestID: UUID?
    ) -> CommunityRequest? {
        requestID.flatMap { request(withID: $0) }
    }


    // MARK: - Bookmarks (Phase 6)

    /// Whether the signed-in account bookmarked this request.
    func isBookmarked(
        _ requestID: UUID
    ) -> Bool {
        BookmarkRules.isBookmarked(
            requestID,
            by: isLoggedIn ? currentUser.id : nil,
            in: bookmarks
        )
    }

    /// Saves or un-saves the request for the signed-in account only, and
    /// persists the change.
    /// - Returns: true when the request is now bookmarked.
    @discardableResult
    func toggleBookmark(
        _ requestID: UUID
    ) -> Bool {

        guard isLoggedIn, request(withID: requestID) != nil else {
            return false
        }

        let now = Date()

        let isNowBookmarked = BookmarkRules.toggle(
            requestID,
            for: currentUser.id,
            in: &bookmarks,
            now: now
        )

        if isNowBookmarked {
            dataStore.saveBookmark(
                RequestBookmark(
                    userID: currentUser.id,
                    requestID: requestID,
                    createdAt: now
                ).toPersisted()
            )
        } else {
            dataStore.deleteBookmark(
                userID: currentUser.id,
                requestID: requestID
            )
        }

        return isNowBookmarked
    }


    // MARK: - Reporting (Phase 6)

    /// Whether the signed-in account already reported this request.
    func hasReported(
        _ requestID: UUID
    ) -> Bool {
        ReportingRules.hasReported(
            requestID,
            by: isLoggedIn ? currentUser.id : nil,
            in: requestReports
        )
    }

    /// Saves a local report of someone else's request (once per account).
    /// Throws a ReportError whose message the view shows in an alert.
    func reportRequest(
        _ requestID: UUID,
        reason: ReportReason
    ) throws {

        try ReportingRules.validate(
            reporterID: isLoggedIn ? currentUser.id : nil,
            request: request(withID: requestID),
            existingReports: requestReports
        )

        let report = RequestReport(
            id: UUID(),
            requestID: requestID,
            reporterID: currentUser.id,
            reason: reason,
            createdAt: Date()
        )

        requestReports.append(report)

        dataStore.saveRequestReport(report.toPersisted())
    }


    private func persist(_ message: ChatMessage) {
        dataStore.saveChatMessage(message.toPersisted())
    }

    private func persistCurrentUser() {
        // Phase 2: the account id lives on BayanihanUser itself, so this
        // always updates the signed-in user's own PersistedUser row.
        guard isLoggedIn else {
            return
        }
        dataStore.saveUser(currentUser.toPersisted())
    }


    // MARK: - Add Request

    func addRequest(
        title: String,
        description: String,
        category: RequestCategory,
        location: String,
        date: Date,
        time: String,
        peopleNeeded: Int,
        urgency: RequestUrgency
    ) {

        let newRequest = CommunityRequest(
            title: title,
            description: description,
            category: category,
            location: location,
            date: date,
            time: time,
            peopleNeeded: peopleNeeded,
            urgency: urgency,
            requesterName: currentUser.name,
            requesterUsername: currentUser.username,
            status: .open,
            requesterID: currentUser.id
        )

        requests.insert(
            newRequest,
            at: 0
        )

        persist(newRequest)

        currentUser.requestsPosted += 1
        persistCurrentUser()

        let newActivity = CommunityActivity(
            id: UUID(),
            message: "Posted “\(newRequest.title).”",
            date: Date(),
            type: .posted,
            // Phase 5: real name (the feed shows "You" to the actor) and
            // the request id. No notification: the poster is not notified
            // about their own request.
            actorName: currentUser.name,
            actorID: currentUser.id,
            requestID: newRequest.id
        )

        activities.insert(
            newActivity,
            at: 0
        )

        persist(newActivity)
    }


    // MARK: - Get Request

    func request(
        withID id: UUID
    ) -> CommunityRequest? {

        requests.first {
            $0.id == id
        }
    }


    // MARK: - Lifecycle Permissions (Phase 3)

    // Every rule lives in RequestLifecycle (Services/RequestLifecycle.swift).
    // Views use these helpers to decide which existing buttons to show; the
    // action methods below re-check the same rules before changing data.

    /// The signed-in account's role in a request.
    func role(
        in request: CommunityRequest
    ) -> RequestRole {

        RequestLifecycle.role(
            of: isLoggedIn ? currentUser.id : nil,
            in: request
        )
    }

    /// Requester or helper of this request.
    func isParticipant(
        in request: CommunityRequest
    ) -> Bool {
        role(in: request).isParticipant
    }

    /// Whether the signed-in account may perform `action` right now.
    func canPerform(
        _ action: RequestAction,
        on request: CommunityRequest
    ) -> Bool {

        guard RequestLifecycle.isAllowed(
            action,
            role: role(in: request),
            request: request,
            agreement: agreement(for: request.id)
        ) else {
            return false
        }

        // Phase 7 (Option A): "I Can Help" only when the requester is a
        // registered account on this device.
        if action == .offerHelp {
            return hasRegisteredRequester(request)
        }

        return true
    }

    /// Phase 7 (Option A): true only when the request's requester id belongs
    /// to an existing account (stable id lookup — never by display name).
    /// Seeded community members without an account (Juan, Ana, the
    /// Barangay) have no requester id, so their requests stay visible but
    /// cannot receive help offers.
    func hasRegisteredRequester(
        _ request: CommunityRequest
    ) -> Bool {

        guard let requesterID = request.requesterID else {
            return false
        }

        return accountNames[requesterID] != nil
    }

    private func requestIndex(
        for requestID: UUID
    ) throws -> Int {

        guard let index = requests.firstIndex(where: { $0.id == requestID }) else {
            throw LifecycleError.requestNotFound
        }

        return index
    }

    /// Throws unless the signed-in account may perform `action` on the
    /// request at `index`.
    private func validate(
        _ action: RequestAction,
        requestAt index: Int
    ) throws {

        try RequestLifecycle.validate(
            action,
            role: role(in: requests[index]),
            request: requests[index],
            agreement: agreement(for: requests[index].id)
        )

        // Phase 7 (Option A): the same registered-requester rule as
        // `canPerform`, so calling `offerHelp` directly cannot bypass it.
        if action == .offerHelp && !hasRegisteredRequester(requests[index]) {
            throw LifecycleError.notAuthorized
        }
    }

    /// Moves a request exactly one step forward in the status order.
    private func advanceStatus(
        ofRequestAt index: Int,
        to newStatus: CommunityRequestStatus
    ) throws {

        guard RequestLifecycle.isValidTransition(
            from: requests[index].status,
            to: newStatus
        ) else {
            throw LifecycleError.invalidStatus(requests[index].status)
        }

        requests[index].status = newStatus

        persist(requests[index])
    }


    // MARK: - Offer Help

    /// OPEN → IN DISCUSSION. Any signed-in account except the requester;
    /// records the helper by account id.
    func offerHelp(
        for requestID: UUID
    ) throws {

        let index = try requestIndex(for: requestID)

        try validate(.offerHelp, requestAt: index)

        requests[index].helperName = currentUser.name
        requests[index].helperID = currentUser.id

        try advanceStatus(ofRequestAt: index, to: .inDiscussion)

        // Phase 5: the helper's own activity + notify the requester.
        recordActivity(
            "Offered to help with “\(requests[index].title)”.",
            aboutRequestAt: index
        )

        notify(.helpOffered, aboutRequestAt: index)
    }


    // MARK: - Get Agreement

    func agreement(
        for requestID: UUID
    ) -> HelpAgreement? {

        helpAgreements.first {
            $0.requestID == requestID
        }
    }


    // MARK: - Create Agreement

    /// IN DISCUSSION only, by the requester or the helper, once per
    /// request. Nobody is confirmed yet — each party confirms separately.
    func createAgreement(
        for requestID: UUID,
        description: String,
        date: Date,
        time: String,
        location: String,
        exchangeType: ExchangeType,
        amount: Double
    ) throws {

        let index = try requestIndex(for: requestID)

        try validate(.createAgreement, requestAt: index)

        let request = requests[index]

        let newAgreement = HelpAgreement(
            requestID: requestID,
            requesterName: request.requesterName,
            helperName: request.helperName ?? currentUser.name,
            description: description,
            date: date,
            time: time,
            location: location,
            exchangeType: exchangeType,
            amount: amount,
            paymentStatus: exchangeType == .noPayment ? .notApplicable : .pending,
            requesterID: request.requesterID,
            helperID: request.helperID ?? currentUser.id
        )

        helpAgreements.insert(
            newAgreement,
            at: 0
        )

        persist(newAgreement)

        // Phase 5: creator's activity + notify the other participant.
        recordActivity(
            "Created a help agreement for “\(requests[index].title)”.",
            aboutRequestAt: index
        )

        notify(.agreementCreated, aboutRequestAt: index)
    }


    // MARK: - Confirm Agreement

    /// Records the signed-in party's own confirmation (requester OR helper
    /// — never both at once). When both have confirmed, the request moves
    /// IN DISCUSSION → CONFIRMED.
    /// - Returns: true when this confirmation completed the agreement.
    @discardableResult
    func confirmAgreement(
        for requestID: UUID
    ) throws -> Bool {

        let index = try requestIndex(for: requestID)
        let confirmingRole = role(in: requests[index])

        try validate(.confirmAgreement, requestAt: index)

        guard let agreementIndex = helpAgreements.firstIndex(
            where: { $0.requestID == requestID }
        ) else {
            throw LifecycleError.agreementMissing
        }

        if confirmingRole == .requester {
            helpAgreements[agreementIndex].isConfirmedByRequester = true
        } else {
            helpAgreements[agreementIndex].isConfirmedByHelper = true
        }

        persist(helpAgreements[agreementIndex])

        // Phase 5: the confirmer's activity.
        recordActivity(
            "Confirmed the agreement for “\(requests[index].title)”.",
            aboutRequestAt: index
        )

        guard helpAgreements[agreementIndex].isConfirmed else {
            // First confirmation: ask the other participant to confirm.
            notify(.agreementConfirmedByOther, aboutRequestAt: index)
            return false
        }

        try advanceStatus(ofRequestAt: index, to: .confirmed)

        // Second confirmation: tell the participant who confirmed first.
        notify(.agreementFullyConfirmed, aboutRequestAt: index)

        return true
    }


    // MARK: - Update Payment Status

    /// Requester only, after both parties confirmed, for Cash/Goods
    /// agreements. Only PENDING → PAID is allowed.
    func updatePaymentStatus(
        for requestID: UUID,
        status: PaymentStatus
    ) throws {

        let index = try requestIndex(for: requestID)

        try validate(.markPaid, requestAt: index)

        guard status == .paid,
              let agreementIndex = helpAgreements.firstIndex(
                where: { $0.requestID == requestID }
              )
        else {
            throw LifecycleError.notAuthorized
        }

        helpAgreements[agreementIndex].paymentStatus = .paid

        persist(helpAgreements[agreementIndex])

        // Phase 5: requester's activity + notify the helper.
        recordActivity(
            "Marked the payment for “\(requests[index].title)” as paid.",
            aboutRequestAt: index
        )

        notify(.paymentMarkedPaid, aboutRequestAt: index)
    }


    // MARK: - Start Help

    /// CONFIRMED → IN PROGRESS, by the helper.
    func startHelp(
        for requestID: UUID
    ) throws {

        let index = try requestIndex(for: requestID)

        try validate(.startHelp, requestAt: index)

        try advanceStatus(ofRequestAt: index, to: .inProgress)

        // Phase 5: helper's activity + notify the requester.
        recordActivity(
            "Started helping with “\(requests[index].title)”.",
            aboutRequestAt: index
        )

        notify(.helpStarted, aboutRequestAt: index)
    }


    // MARK: - Complete Help

    /// IN PROGRESS → COMPLETED, by the requester (confirming the help was
    /// received). The HELPER is credited: +1 helped and
    /// `RequestLifecycle.pointsPerCompletedHelp` points, exactly once.
    func completeHelp(
        for requestID: UUID
    ) throws {

        let index = try requestIndex(for: requestID)

        try validate(.completeHelp, requestAt: index)

        guard let helperID = requests[index].helperID else {
            throw LifecycleError.invalidStatus(requests[index].status)
        }

        requests[index].completionRewardGranted = true

        try advanceStatus(ofRequestAt: index, to: .completed)

        awardCompletedHelp(toHelperWithID: helperID)

        // The activity belongs to the helper (they did the helping).
        let newActivity = CommunityActivity(
            id: UUID(),
            message: "Completed “\(requests[index].title)”.",
            date: Date(),
            type: .volunteered,
            actorName: requests[index].helperName ?? "Community Helper",
            actorID: helperID,
            requestID: requests[index].id
        )

        activities.insert(
            newActivity,
            at: 0
        )

        persist(newActivity)

        // Phase 5: notify the helper (who earned the reward).
        notify(.helpCompleted, aboutRequestAt: index)
    }

    /// Adds the completion reward to the helper's own account. The helper
    /// is usually NOT the signed-in user (the requester completes), so
    /// their stored profile is updated directly; they see the new totals
    /// the next time they log in. (With Firebase this becomes a server-side
    /// transaction.)
    private func awardCompletedHelp(
        toHelperWithID helperID: UUID
    ) {

        let points = RequestLifecycle.pointsPerCompletedHelp

        if isLoggedIn && helperID == currentUser.id {
            currentUser.requestsHelped += 1
            currentUser.communityPoints += points
            persistCurrentUser()
            return
        }

        guard let stored = dataStore.loadUsers().first(where: { $0.id == helperID }) else {
            print("BayanihanController: Helper account \(helperID) not found; no reward saved.")
            return
        }

        var helper = BayanihanUser(persisted: stored)
        helper.requestsHelped += 1
        helper.communityPoints += points

        dataStore.saveUser(helper.toPersisted())
    }


    // MARK: - Messages

    /// Phase 4: a conversation's messages, oldest first — ONLY for the
    /// request's requester or helper. Anyone else gets an empty list.
    func messages(
        for requestID: UUID
    ) -> [ChatMessage] {

        guard let request = request(withID: requestID),
              canPerform(.readMessages, on: request)
        else {
            return []
        }

        return chatMessages
            .filter { $0.requestID == requestID }
            .sorted { $0.createdAt < $1.createdAt }
    }


    // MARK: - Conversations & Unread (Phase 4)

    /// The signed-in user's conversations (requests they are part of that
    /// have a helper), most recent message activity first.
    var messageConversations: [CommunityRequest] {

        let mine = requests.filter {
            $0.helperName != nil && isParticipant(in: $0)
        }

        return MessagingRules.sortedByRecentActivity(
            mine,
            messages: chatMessages
        )
    }

    /// Unread messages for the signed-in user in one conversation.
    func unreadMessageCount(
        for requestID: UUID
    ) -> Int {

        guard let request = request(withID: requestID),
              canPerform(.readMessages, on: request)
        else {
            return 0
        }

        return MessagingRules.unreadCount(
            in: requestID,
            messages: chatMessages,
            for: currentUser.id,
            lastReadAt: lastReadAt(for: requestID),
            readCutoff: messageReadCutoff
        )
    }

    /// Unread messages for the signed-in user across all their
    /// conversations (Home / Profile badges).
    var totalUnreadMessageCount: Int {
        messageConversations.reduce(0) {
            $0 + unreadMessageCount(for: $1.id)
        }
    }

    private func lastReadAt(
        for requestID: UUID
    ) -> Date? {

        conversationReadStates.first {
            $0.userID == currentUser.id && $0.requestID == requestID
        }?.lastReadAt
    }

    /// Marks everything currently in the conversation as read for the
    /// signed-in participant. Called when the chat opens and whenever a
    /// message arrives while it is open. Does nothing for non-participants
    /// and skips the save when nothing is unread.
    func markConversationRead(
        requestID: UUID
    ) {

        guard let request = request(withID: requestID),
              canPerform(.readMessages, on: request)
        else {
            return
        }

        // Phase 5 (M2): reading the chat also reads its "New Message"
        // notification, so the bell badge matches the chat badge. Done
        // before the early return below so it always stays in sync.
        markMessageNotificationRead(requestID: requestID)

        let existing = lastReadAt(for: requestID)

        guard existing == nil || unreadMessageCount(for: requestID) > 0 else {
            return
        }

        let readAt = MessagingRules.readTimestamp(
            now: Date(),
            conversationMessages: chatMessages.filter { $0.requestID == requestID }
        )

        let state = ConversationReadState(
            userID: currentUser.id,
            requestID: requestID,
            lastReadAt: readAt
        )

        if let index = conversationReadStates.firstIndex(where: {
            $0.userID == state.userID && $0.requestID == state.requestID
        }) {
            conversationReadStates[index].lastReadAt = readAt
        } else {
            conversationReadStates.append(state)
        }

        dataStore.saveConversationReadState(state.toPersisted())
    }


    // MARK: - Send Message

    /// Phase 4: throws (and changes nothing) when the message cannot be
    /// sent — not a participant, request still OPEN (Phase 3 rules), empty
    /// text, or more than `MessagingRules.maximumMessageLength` characters.
    /// The view only clears its text field after a successful send.
    func sendMessage(
        text: String,
        requestID: UUID
    ) throws {

        let index = try requestIndex(for: requestID)

        try validate(.sendMessage, requestAt: index)

        let cleanText = try MessagingRules.validatedText(text)

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        let now = Date()

        let newMessage = ChatMessage(
            requestID: requestID,
            senderUsername: currentUser.username,
            text: cleanText,
            time: formatter.string(from: now),
            senderID: currentUser.id,
            createdAt: now
        )

        chatMessages.append(newMessage)

        dataStore.saveChatMessage(newMessage.toPersisted())

        // Phase 5: one merged notification per conversation for the other
        // participant (never the sender).
        notify(.newMessage, aboutRequestAt: index)
    }


    // MARK: - Update Profile

    /// Phase 2: validates (format + duplicate email/username) through the
    /// AuthService and saves to the same account id. Throws an AuthError
    /// whose message the view shows in its existing alert.
    func updateProfile(
        name: String,
        username: String,
        email: String,
        location: String
    ) async throws {

        guard isLoggedIn else {
            throw AuthError.notSignedIn
        }

        var edited = currentUser
        edited.name = name
        edited.username = username
        edited.email = email
        edited.location = location

        let saved = try await authService.updateAccount(edited)

        currentUser = saved

        propagateProfileChanges(of: saved)

        // Phase 5: the Activity feed shows the new name to others.
        refreshAccountNames()
    }

    /// Ownership is by id, so editing a profile can never break it. This
    /// only refreshes the *display copies* of the name/username stored on
    /// the user's own records so they show the new values.
    private func propagateProfileChanges(
        of user: BayanihanUser
    ) {

        for index in requests.indices {

            var changed = false

            if requests[index].requesterID == user.id,
               requests[index].requesterName != user.name ||
                requests[index].requesterUsername != user.username {
                requests[index].requesterName = user.name
                requests[index].requesterUsername = user.username
                changed = true
            }

            if requests[index].helperID == user.id,
               requests[index].helperName != user.name {
                requests[index].helperName = user.name
                changed = true
            }

            if changed {
                persist(requests[index])
            }
        }

        for index in helpAgreements.indices {

            var changed = false

            if helpAgreements[index].requesterID == user.id,
               helpAgreements[index].requesterName != user.name {
                helpAgreements[index].requesterName = user.name
                changed = true
            }

            if helpAgreements[index].helperID == user.id,
               helpAgreements[index].helperName != user.name {
                helpAgreements[index].helperName = user.name
                changed = true
            }

            if changed {
                persist(helpAgreements[index])
            }
        }

        for index in chatMessages.indices
        where chatMessages[index].senderID == user.id &&
            chatMessages[index].senderUsername != user.username {

            chatMessages[index].senderUsername = user.username
            persist(chatMessages[index])
        }

        // Activities written as "You" keep that label; named ones follow
        // the new name.
        for index in activities.indices
        where activities[index].actorID == user.id &&
            activities[index].actorName != "You" &&
            activities[index].actorName != user.name {

            activities[index].actorName = user.name
            persist(activities[index])
        }
    }


    // MARK: - Login / Registration (Phase 2)

    func login(
        identifier: String,
        password: String,
        rememberMe: Bool
    ) async throws {

        let user = try await authService.signIn(
            identifier: identifier,
            password: password,
            rememberMe: rememberMe
        )

        currentUser = user
        isLoggedIn = true

        // Phase 5: keep Activity names current (new/renamed accounts).
        refreshAccountNames()
    }

    /// Creates the account and signs it in. New accounts are not
    /// remembered (there is no Remember Me box on Sign Up); the next app
    /// launch asks for the password.
    func register(
        fullName: String,
        email: String,
        password: String,
        confirmPassword: String,
        location: String,
        agreedToTerms: Bool
    ) async throws {

        let user = try await authService.register(
            AccountRegistration(
                fullName: fullName,
                email: email,
                password: password,
                confirmPassword: confirmPassword,
                location: location,
                agreedToTerms: agreedToTerms
            ),
            rememberMe: false
        )

        currentUser = user
        isLoggedIn = true

        // Phase 5: keep Activity names current (new/renamed accounts).
        refreshAccountNames()
    }


    // MARK: - Ownership (Phase 2)

    // Views use these instead of comparing names/usernames, so ownership
    // survives profile edits and works for multiple local accounts.

    func isCurrentUserRequester(
        of request: CommunityRequest
    ) -> Bool {
        isLoggedIn && request.requesterID == currentUser.id
    }

    func isCurrentUserHelper(
        of request: CommunityRequest
    ) -> Bool {
        isLoggedIn && request.helperID == currentUser.id
    }

    func isCurrentUserSender(
        of message: ChatMessage
    ) -> Bool {
        isLoggedIn && message.senderID == currentUser.id
    }


    // MARK: - Logout

    func logout() {
        // Phase 2: ends the session and forgets any remembered account, so
        // the next launch shows Login instead of logging in automatically.
        // Persisted data intentionally stays in SwiftData. `currentUser` is
        // replaced on the next login; while logged out no screen shows it
        // and every ownership check above returns false.
        authService.signOut()
        isLoggedIn = false
    }
}
