import SwiftUI

struct MessagesView: View {

    @Environment(BayanihanController.self) private var controller

    // Phase 4: the signed-in user's conversations (requester or helper,
    // by account id), sorted by most recent message activity.
    private var messageRequests: [CommunityRequest] {
        controller.messageConversations
    }

    var body: some View {

        ZStack {

            Color(
                red: 0.95,
                green: 0.98,
                blue: 0.97
            )
            .ignoresSafeArea()

                if messageRequests.isEmpty {

                    EmptyMessagesView()

                } else {

                    ScrollView(showsIndicators: false) {

                        VStack(
                            alignment: .leading,
                            spacing: 0
                        ) {

                            Text("Messages")
                                .font(
                                    .system(
                                        size: 28,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.black)
                                .padding(.top, 15)

                            Text(
                                "Stay connected while helping your community."
                            )
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                            .padding(.top, 4)

                            LazyVStack(
                                spacing: 9
                            ) {

                                ForEach(messageRequests) { request in

                                    NavigationLink {

                                        ChatView(
                                            request: request
                                        )

                                    } label: {

                                        MessageConversationRow(
                                            request: request,
                                            isCurrentUserRequester:
                                                controller.isCurrentUserRequester(
                                                    of: request
                                                ),
                                            lastMessage:
                                                controller.messages(
                                                    for: request.id
                                                ).last,
                                            unreadCount:
                                                controller.unreadMessageCount(
                                                    for: request.id
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 18)

                            Spacer(minLength: 30)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Conversation Row

struct MessageConversationRow: View {

    let request: CommunityRequest
    // Phase 2: decided by account id in the Controller.
    let isCurrentUserRequester: Bool
    let lastMessage: ChatMessage?
    // Phase 4: real unread messages for the signed-in user.
    let unreadCount: Int

    private var otherPersonName: String {

        if isCurrentUserRequester {
            return request.helperName ?? "Community Helper"
        }

        return request.requesterName
    }

    private var previewText: String {

        if let lastMessage {
            return lastMessage.text
        }

        if request.status == .completed {
            return "Request completed"
        }

        return "Say hello to start the conversation."
    }

    // Phase 4: unread = the other participant sent messages this user has
    // not opened yet (per user, per conversation). Same existing dot.
    private var isUnread: Bool {
        unreadCount > 0
    }

    var body: some View {

        HStack(alignment: .top, spacing: 11) {

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
                    initials(otherPersonName)
                )
                .font(
                    .system(
                        size: 16,
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
                width: 45,
                height: 45
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                HStack {

                    Text(otherPersonName)
                        .font(
                            .system(
                                size: 16,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)
                        // Typography fix: long names truncate instead of
                        // pushing the time onto a second line.
                        .lineLimit(1)

                    Spacer()

                    if let lastMessage {

                        Text(lastMessage.time)
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                }

                Text(previewText)
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .lineLimit(1)

                HStack(spacing: 5) {

                    Image(
                        systemName: request.category.icon
                    )
                    .font(.system(size: 7))

                    Text(request.category.rawValue)
                        .font(.system(size: 12))

                    Text("·")
                        .font(.system(size: 12))

                    Text(request.title)
                        .font(.system(size: 12))
                        .lineLimit(1)
                }
                .foregroundStyle(
                    Color(
                        red: 0.00,
                        green: 0.55,
                        blue: 0.45
                    )
                )
            }

            if isUnread {

                Circle()
                    .fill(
                        Color(
                            red: 0.00,
                            green: 0.55,
                            blue: 0.45
                        )
                    )
                    .frame(
                        width: 8,
                        height: 8
                    )
                    .padding(.top, 3)

            } else {

                Image(
                    systemName: "chevron.right"
                )
                .font(
                    .system(
                        size: 9,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.gray.opacity(0.6))
                .padding(.top, 3)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 13)
        .background(
            isUnread
                ? Color(
                    red: 0.00,
                    green: 0.55,
                    blue: 0.45
                ).opacity(0.05)
                : Color.white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 14
            )
        )
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


// MARK: - Empty Messages

struct EmptyMessagesView: View {

    var body: some View {

        VStack(spacing: 10) {

            Image(
                systemName: "bubble.left.and.bubble.right"
            )
            .font(.system(size: 34))
            .foregroundStyle(
                .gray.opacity(0.45)
            )

            Text("No Messages Yet")
                .font(
                    .system(
                        size: 17,
                        weight: .bold
                    )
                )
                .foregroundStyle(.black)

            Text(
                "Your conversations with the community will appear here."
            )
            .font(.system(size: 14))
            .foregroundStyle(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 35)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}


// MARK: - Preview

#Preview {

    MessagesView()
        .environment(BayanihanController())
}
