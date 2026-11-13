import Foundation

// MARK: - Phase 6: Privacy & Security / Help & Support content
//
// Plain data (no SwiftUI) so the screens stay simple and the statements
// can be unit-tested against the real app rules (points, message limit,
// session behavior). Every statement describes how THIS local version
// actually works — no invented contact details or online services.

struct SupportItem: Identifiable, Equatable {

    let icon: String
    let title: String
    let detail: String

    var id: String {
        title
    }
}

struct SupportSection: Identifiable, Equatable {

    let title: String
    let items: [SupportItem]

    var id: String {
        title
    }
}

enum SupportContent {

    // MARK: Privacy & Security

    static let privacySections: [SupportSection] = [

        SupportSection(
            title: "Your Data",
            items: [
                SupportItem(
                    icon: "iphone",
                    title: "Stored on this device",
                    detail: "Your account, requests, messages, notifications and activity are saved only on this device. Nothing is uploaded to a server."
                ),
                SupportItem(
                    icon: "key.fill",
                    title: "Password protection",
                    detail: "Your password is never saved. Bayanihan keeps only a secure, salted hash of it."
                ),
                SupportItem(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Private conversations",
                    detail: "Only the person who posted a request and the person helping can read its messages."
                ),
                SupportItem(
                    icon: "bell.fill",
                    title: "Private notifications",
                    detail: "Your notifications, bookmarks and Activity feed are visible only to your account."
                )
            ]
        ),

        SupportSection(
            title: "Session & Safety",
            items: [
                SupportItem(
                    icon: "checkmark.square.fill",
                    title: "Remember Me",
                    detail: "When Remember Me is checked, this device logs you in automatically. Signing out turns it off."
                ),
                SupportItem(
                    icon: "rectangle.portrait.and.arrow.right",
                    title: "Signing out",
                    detail: "Sign out from Profile or Settings, especially when other people use this device."
                ),
                SupportItem(
                    icon: "flag.fill",
                    title: "Reporting",
                    detail: "Use Report Request from a request's menu if it looks unsafe, misleading or inappropriate."
                )
            ]
        )
    ]


    // MARK: Help & Support

    static let helpSections: [SupportSection] = [

        SupportSection(
            title: "Getting Started",
            items: [
                SupportItem(
                    icon: "plus.circle.fill",
                    title: "Post a request",
                    detail: "Tap the + button, describe what you need, then post it for your community."
                ),
                SupportItem(
                    icon: "hands.sparkles.fill",
                    title: "Offer help",
                    detail: "Open someone's request and tap I Can Help. You can then chat with them."
                ),
                SupportItem(
                    icon: "doc.text.fill",
                    title: "Agree on the details",
                    detail: "Either of you can create the help agreement. Both of you must confirm it."
                ),
                SupportItem(
                    icon: "figure.walk",
                    title: "Start and complete",
                    detail: "The helper taps Start Help. The person who asked for help marks it completed, and the helper earns \(RequestLifecycle.pointsPerCompletedHelp) points."
                )
            ]
        ),

        SupportSection(
            title: "Using Bayanihan",
            items: [
                SupportItem(
                    icon: "message.fill",
                    title: "Messages",
                    detail: "Messages can be up to \(MessagingRules.maximumMessageLength) characters. New messages show a badge until you open the chat."
                ),
                SupportItem(
                    icon: "bell.fill",
                    title: "Notifications",
                    detail: "The bell shows updates about your requests and the help you offered. Opening the list marks them as read."
                ),
                SupportItem(
                    icon: "bookmark.fill",
                    title: "Bookmarks",
                    detail: "Tap the bookmark on a request to save it. Your bookmarks are kept for your account."
                )
            ]
        ),

        SupportSection(
            title: "Need More Help?",
            items: [
                SupportItem(
                    icon: "person.2.fill",
                    title: "Ask your community",
                    detail: "For urgent needs, also contact your barangay office or local emergency services directly."
                ),
                SupportItem(
                    icon: "flag.fill",
                    title: "Report a problem",
                    detail: "If a request seems wrong or unsafe, open it and choose Report Request from the menu."
                )
            ]
        )
    ]
}
