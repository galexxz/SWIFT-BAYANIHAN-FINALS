import SwiftUI
import UIKit   // Phase 6: UIPasteboard for "Copy Link"

struct RequestDetailsView: View {

    @Environment(BayanihanController.self) private var controller
    @Environment(\.dismiss) private var dismiss

    // Phase 1: keep the request's ID and always read the latest version
    // from the Controller, so changes (e.g. "I Can Help") show immediately.
    // `initialRequest` is only a fallback if the request can't be found.
    private let requestID: UUID
    private let initialRequest: CommunityRequest

    private var request: CommunityRequest {
        controller.request(withID: requestID) ?? initialRequest
    }

    init(request: CommunityRequest) {
        self.requestID = request.id
        self.initialRequest = request
    }

    @State private var showHelpAlert = false

    // Phase 6: the bookmark is saved per account (was a temporary value
    // that reset every visit and was shared by all accounts).
    private var isBookmarked: Bool {
        controller.isBookmarked(request.id)
    }

    // Phase 6: "Report Request" options and the result / "Copy Link"
    // confirmation (system dialog + alert, no custom UI).
    @State private var showReportOptions = false
    @State private var showToolAlert = false
    @State private var toolAlertTitle = ""
    @State private var toolAlertMessage = ""

    private var isMyRequest: Bool {
        // Phase 2: ownership by account id.
        controller.isCurrentUserRequester(of: request)
    }

    // Phase 3: the chat shortcut is only for the helper of this request
    // (the requester reaches the chat from Help Status / Messages).
    private var canQuickChat: Bool {
        !isMyRequest && controller.canPerform(.sendMessage, on: request)
    }

    var body: some View {

        ScrollView(showsIndicators: false) {

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                // MARK: - Hero

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 18
                    )
                    .fill(
                        Color(
                            red: 0.84,
                            green: 0.93,
                            blue: 0.90
                        )
                    )

                    Image(
                        systemName: request.category.icon
                    )
                    .font(.system(size: 56))
                    .foregroundStyle(
                        Color(
                            red: 0.00,
                            green: 0.55,
                            blue: 0.45
                        )
                        .opacity(0.5)
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 160)
                .overlay(alignment: .topTrailing) {

                    HStack(spacing: 8) {

                        Button {
                            // Phase 6: saved for the signed-in account.
                            controller.toggleBookmark(request.id)
                        } label: {

                            Image(
                                systemName: isBookmarked
                                    ? "bookmark.fill"
                                    : "bookmark"
                            )
                            .font(.system(size: 11))
                            .foregroundStyle(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )
                            .frame(
                                width: 30,
                                height: 30
                            )
                            .background(.white)
                            .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        ShareLink(
                            item: shareText
                        ) {

                            Image(
                                systemName: "square.and.arrow.up"
                            )
                            .font(.system(size: 11))
                            .foregroundStyle(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )
                            .frame(
                                width: 30,
                                height: 30
                            )
                            .background(.white)
                            .clipShape(Circle())
                        }

                        Menu {

                            Button("Report Request") {
                                // Phase 6: choose a reason, then save a
                                // local report.
                                showReportOptions = true
                            }

                            Button("Copy Link") {
                                // Phase 6: copies the same text the Share
                                // button sends (no public web link exists
                                // in the local version).
                                UIPasteboard.general.string = shareText
                                showToolResult(
                                    title: "Copied",
                                    message: "The request details were copied to your clipboard."
                                )
                            }

                        } label: {

                            Image(
                                systemName: "ellipsis"
                            )
                            .font(.system(size: 11))
                            .foregroundStyle(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )
                            .frame(
                                width: 30,
                                height: 30
                            )
                            .background(.white)
                            .clipShape(Circle())
                        }
                    }
                    .padding(10)
                }
                .overlay(alignment: .bottomLeading) {

                    HStack(spacing: 6) {

                        UrgencyBadge(
                            urgency: request.urgency
                        )

                        Text(
                            request.status.rawValue.uppercased()
                        )
                        .font(
                            .system(
                                size: 10,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(
                            Color.white.opacity(0.9)
                        )
                        .clipShape(Capsule())
                    }
                    .padding(10)
                }
                .padding(.top, 12)


                // MARK: - Title

                Text(request.title)
                    .font(
                        .system(
                            size: 24,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.black)
                    .padding(.top, 14)


                // MARK: - Category & Posted Time

                HStack(spacing: 10) {

                    HStack(spacing: 5) {

                        Image(
                            systemName: request.category.icon
                        )
                        .font(.system(size: 9))

                        Text(
                            request.category.rawValue
                        )
                        .font(
                            .system(
                                size: 13,
                                weight: .semibold
                            )
                        )
                    }
                    .foregroundStyle(
                        Color(
                            red: 0.00,
                            green: 0.55,
                            blue: 0.45
                        )
                    )
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Color(
                            red: 0.00,
                            green: 0.55,
                            blue: 0.45
                        )
                        .opacity(0.10)
                    )
                    .clipShape(Capsule())

                    Text(timeAgo)
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                }
                .padding(.top, 8)


                // MARK: - Description

                Text(request.description)
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
                    .lineSpacing(3)
                    .padding(.top, 12)


                // MARK: - Request Information

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    DetailInfoRow(
                        icon: "mappin.and.ellipse",
                        title: "Location",
                        value: request.location
                    )

                    DetailInfoRow(
                        icon: "calendar",
                        title: "Date",
                        value: formattedDate
                    )

                    DetailInfoRow(
                        icon: "clock",
                        title: "Preferred Time",
                        value: request.time
                    )

                    DetailInfoRow(
                        icon: "person.2.fill",
                        title: "People Needed",
                        value: "\(request.peopleNeeded)"
                    )
                }
                .padding(14)
                .background(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                )
                .padding(.top, 20)


                // MARK: - Requester

                Text("Posted By")
                    .font(
                        .system(
                            size: 18,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.black)
                    .padding(.top, 23)

                HStack(spacing: 10) {

                    ZStack {

                        Circle()
                            .fill(
                                Color(
                                    red: 0.84,
                                    green: 0.93,
                                    blue: 0.90
                                )
                            )

                        Text(
                            initials(request.requesterName)
                        )
                        .font(
                            .system(
                                size: 15,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(
                            Color(
                                red: 0.00,
                                green: 0.55,
                                blue: 0.45
                            )
                        )
                    }
                    .frame(
                        width: 43,
                        height: 43
                    )

                    VStack(
                        alignment: .leading,
                        spacing: 3
                    ) {

                        Text(request.requesterName)
                            .font(
                                .system(
                                    size: 16,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.black)

                        Text(request.requesterUsername)
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    if canQuickChat {

                        NavigationLink {

                            ChatView(
                                request: request
                            )

                        } label: {

                            Image(
                                systemName: "message.fill"
                            )
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(
                                width: 34,
                                height: 34
                            )
                            .background(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )
                            .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(13)
                .background(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 14
                    )
                )
                .padding(.top, 10)


                // MARK: - Helper

                if let helperName = request.helperName {

                    Text("Helper")
                        .font(
                            .system(
                                size: 18,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.top, 23)

                    HStack(spacing: 10) {

                        ZStack {

                            Circle()
                                .fill(
                                    Color(
                                        red: 0.84,
                                        green: 0.93,
                                        blue: 0.90
                                    )
                                )

                            Text(
                                initials(helperName)
                            )
                            .font(
                                .system(
                                    size: 15,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )
                        }
                        .frame(
                            width: 43,
                            height: 43
                        )

                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {

                            Text(helperName)
                                .font(
                                    .system(
                                        size: 16,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.black)

                            Text("Community helper")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }

                        Spacer()
                    }
                    .padding(13)
                    .background(.white)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 14
                        )
                    )
                    .padding(.top, 10)
                }


                // MARK: - Action

                if isMyRequest {

                    NavigationLink {

                        HelpStatusView(
                            request: request
                        )

                    } label: {

                        ActionButtonLabel(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "View Help Status"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 23)

                } else if controller.canPerform(.offerHelp, on: request) {

                    // Phase 3: OPEN requests of other accounts only.
                    Button {
                        showHelpAlert = true
                    } label: {

                        ActionButtonLabel(
                            icon: "hands.sparkles.fill",
                            title: "I Can Help"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 23)

                } else if controller.isParticipant(in: request) {

                    // Phase 3: only the helper (the requester is handled
                    // above) may open this request's chat. Other accounts
                    // see no action button once someone is helping.
                    NavigationLink {

                        ChatView(
                            request: request
                        )

                    } label: {

                        ActionButtonLabel(
                            icon: "message.fill",
                            title: "Open Chat"
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 23)
                }

                Spacer(minLength: 30)
            }
            .padding(.horizontal, 20)
        }
        .background(
            Color(
                red: 0.95,
                green: 0.98,
                blue: 0.97
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Request Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            "I Can Help?",
            isPresented: $showHelpAlert
        ) {

            Button("Cancel", role: .cancel) {

            }

            Button("I Can Help") {
                iCanHelp()
            }

        } message: {

            Text(
                "You can coordinate with the requester through chat."
            )
        }
        // Phase 6: report reasons (system action sheet).
        .confirmationDialog(
            "Report Request",
            isPresented: $showReportOptions,
            titleVisibility: .visible
        ) {

            ForEach(ReportReason.allCases) { reason in

                Button(reason.title) {
                    submitReport(reason)
                }
            }

            Button("Cancel", role: .cancel) {
            }

        } message: {

            Text("Why are you reporting this request?")
        }
        // Phase 6: result of reporting / copying (system alert).
        .alert(
            toolAlertTitle,
            isPresented: $showToolAlert
        ) {

            Button("OK", role: .cancel) {
            }

        } message: {

            Text(toolAlertMessage)
        }
    }


    // MARK: - Report / Copy (Phase 6)

    private func submitReport(
        _ reason: ReportReason
    ) {

        do {
            try controller.reportRequest(request.id, reason: reason)

            showToolResult(
                title: "Report Submitted",
                message: "Thank you. Your report was saved and this request will be reviewed."
            )

        } catch {
            showToolResult(
                title: "Unable to Report",
                message: error.localizedDescription
            )
        }
    }

    private func showToolResult(
        title: String,
        message: String
    ) {
        toolAlertTitle = title
        toolAlertMessage = message
        showToolAlert = true
    }


    // MARK: - I Can Help

    private func iCanHelp() {

        // Phase 3: the Controller re-checks the rules (own request, status,
        // helper already assigned). The button is only shown when allowed,
        // so a rejection here means the state changed — nothing happens.
        try? controller.offerHelp(
            for: request.id
        )
    }


    // MARK: - Status Color

    private var statusColor: Color {

        switch request.status {

        case .open:
            return Color(
                red: 0.00,
                green: 0.55,
                blue: 0.45
            )

        case .inDiscussion:
            return .orange

        case .confirmed:
            return .orange

        case .inProgress:
            return Color(
                red: 0.00,
                green: 0.55,
                blue: 0.45
            )

        case .completed:
            return .gray
        }
    }


    // MARK: - Time Ago

    private var timeAgo: String {

        let interval = Date().timeIntervalSince(request.createdAt)

        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if minutes < 1 {
            return "Just now"

        } else if minutes < 60 {
            return "\(minutes)m ago"

        } else if hours < 24 {
            return "\(hours)h ago"

        } else if days == 1 {
            return "Yesterday"

        } else if days < 7 {
            return "\(days)d ago"

        } else {

            let formatter = DateFormatter()
            formatter.dateStyle = .medium

            return formatter.string(from: request.createdAt)
        }
    }


    // MARK: - Formatted Date

    private var formattedDate: String {

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return formatter.string(from: request.date)
    }


    // MARK: - Share Text

    // Phase 6: same text as before, now from one shared rule (used by both
    // the Share button and "Copy Link").
    private var shareText: String {
        RequestSharing.shareText(for: request)
    }


    // MARK: - Initials

    private func initials(
        _ name: String
    ) -> String {

        let words = name.split(separator: " ")

        let letters = words.prefix(2).compactMap {
            $0.first
        }

        if letters.isEmpty {
            return "?"
        }

        return String(letters)
    }
}


// MARK: - Detail Info Row

struct DetailInfoRow: View {

    let icon: String
    let title: String
    let value: String

    var body: some View {

        HStack(spacing: 10) {

            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(
                    Color(
                        red: 0.00,
                        green: 0.55,
                        blue: 0.45
                    )
                )
                .frame(width: 18)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                Text(title)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)

                Text(value)
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.black)
            }

            Spacer()
        }
    }
}


// MARK: - Action Button

struct ActionButtonLabel: View {

    let icon: String
    let title: String

    var body: some View {

        HStack(spacing: 8) {

            Image(systemName: icon)
                .font(.system(size: 10))

            Text(title)
                .font(
                    .system(
                        size: 16,
                        weight: .bold
                    )
                )
        }
        .foregroundStyle(.white)
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 50)
        .background(
            Color(
                red: 0.00,
                green: 0.55,
                blue: 0.45
            )
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
    }
}


// MARK: - Preview

#Preview {

    NavigationStack {

        RequestDetailsView(
            request: CommunityRequest(
                id: UUID(),
                title: "Help Needed",
                description: "A community member needs assistance.",
                category: .other,
                location: "Brgy. San Isidro",
                time: "9:00 AM",
                peopleNeeded: 1,
                urgency: .normal,
                requesterName: "Maria Santos",
                requesterUsername: "@maria",
                status: .open,
                helperName: nil
            )
        )
        .environment(BayanihanController())
    }
}
