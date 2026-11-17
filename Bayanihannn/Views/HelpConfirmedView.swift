import SwiftUI

struct HelpConfirmedView: View {

    @Environment(BayanihanController.self) private var controller
    @Environment(\.dismiss) private var dismiss

    // Phase 1: keep the request's ID and always read the latest version
    // from the Controller. `initialRequest` is only a fallback.
    private let requestID: UUID
    private let initialRequest: CommunityRequest

    private var request: CommunityRequest {
        controller.request(withID: requestID) ?? initialRequest
    }

    init(request: CommunityRequest) {
        self.requestID = request.id
        self.initialRequest = request
    }

    private var isRequester: Bool {
        // Phase 2: ownership by account id.
        controller.isCurrentUserRequester(of: request)
    }

    private var agreement: HelpAgreement? {
        controller.agreement(for: request.id)
    }

    private var otherPersonName: String {

        if isRequester {
            return request.helperName ?? "your helper"
        }

        return request.requesterName
    }

    var body: some View {

        ZStack {

            Color(
                red: 0.95,
                green: 0.98,
                blue: 0.97
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 0) {

                    // MARK: - Success Icon

                    ZStack {

                        Circle()
                            .fill(
                                Color(
                                    red: 0.00,
                                    green: 0.55,
                                    blue: 0.45
                                )
                            )

                        Image(
                            systemName: "checkmark"
                        )
                        .font(
                            .system(
                                size: 28,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                    }
                    .frame(
                        width: 78,
                        height: 78
                    )
                    .padding(.top, 35)

                    Text("Help Confirmed! 🎉")
                        .font(
                            .system(
                                size: 26,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.top, 16)

                    Text(
                        "You and \(otherPersonName) have agreed on the details."
                    )
                    .font(.system(size: 15))
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                    .padding(.top, 6)


                    // MARK: - Agreement Summary

                    if let agreement {

                        Text("Agreement Summary")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .bold
                                )
                            )
                            .foregroundStyle(.black)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .padding(.top, 30)

                        VStack(
                            alignment: .leading,
                            spacing: 12
                        ) {

                            DetailInfoRow(
                                icon: "text.alignleft",
                                title: "Request",
                                value: request.title
                            )

                            DetailInfoRow(
                                icon: "hands.sparkles.fill",
                                title: "Helper",
                                value: agreement.helperName
                            )

                            DetailInfoRow(
                                icon: "calendar",
                                title: "Date",
                                value: formattedDate(agreement.date)
                            )

                            DetailInfoRow(
                                icon: "clock",
                                title: "Time",
                                value: agreement.time
                            )

                            DetailInfoRow(
                                icon: "mappin.and.ellipse",
                                title: "Location",
                                value: agreement.location
                            )

                            if agreement.exchangeType != .noPayment {

                                DetailInfoRow(
                                    icon: "creditcard.fill",
                                    title: "Reimbursement",
                                    value: "\(formattedAmount(agreement.amount)) · \(agreement.paymentStatus.rawValue)"
                                )

                            } else {

                                DetailInfoRow(
                                    icon: "heart.fill",
                                    title: "Reimbursement",
                                    value: "No reimbursement"
                                )
                            }
                        }
                        .padding(14)
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 14
                            )
                        )
                        .padding(.top, 10)
                    }


                    // MARK: - View Conversation

                    NavigationLink {

                        ChatView(
                            request: request
                        )

                    } label: {

                        Text("View Conversation")
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
                            .frame(
                                maxWidth: .infinity
                            )
                            .frame(height: 48)
                            .background(.white)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                            )
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 14
                                )
                                .stroke(
                                    Color(
                                        red: 0.00,
                                        green: 0.55,
                                        blue: 0.45
                                    ),
                                    lineWidth: 1
                                )
                            }
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 26)


                    // MARK: - Done

                    Button {
                        dismiss()
                    } label: {

                        Text("Done")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .bold
                                )
                            )
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
                    .buttonStyle(.plain)
                    .padding(.top, 10)

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Help Confirmed")
        .navigationBarTitleDisplayMode(.inline)
    }


    // MARK: - Formatted Amount

    private func formattedAmount(
        _ amount: Double
    ) -> String {

        if amount == amount.rounded() {
            return "₱\(Int(amount))"
        }

        return String(format: "₱%.2f", amount)
    }


    // MARK: - Formatted Date

    private func formattedDate(
        _ date: Date
    ) -> String {

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        return formatter.string(from: date)
    }
}


// MARK: - Preview

#Preview {

    NavigationStack {

        HelpConfirmedView(
            request: CommunityRequest(
                id: UUID(),
                title: "Groceries for a Senior Citizen",
                description: "Maria needs help getting groceries for her elderly mother.",
                category: .food,
                location: "Brgy. San Isidro",
                time: "9:00 AM",
                peopleNeeded: 1,
                urgency: .urgent,
                requesterName: "Maria Santos",
                requesterUsername: "@maria",
                status: .confirmed,
                helperName: "Alex Rivera"
            )
        )
        .environment(BayanihanController())
    }
}
