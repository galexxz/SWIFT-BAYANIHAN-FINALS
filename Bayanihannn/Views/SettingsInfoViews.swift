import SwiftUI

// MARK: - Phase 6: Privacy & Security / Help & Support screens
//
// Built ONLY from the existing Settings design: the same background
// color, SettingsSectionTitle, white rounded (15) cards, dividers, the
// 31×31 green icon tile and the 9/8-point text styles of SettingsInfoRow.
// Pushed from the existing Settings rows (no new navigation style).


// MARK: - Privacy & Security

struct PrivacySecurityView: View {

    var body: some View {
        SupportSectionsScreen(
            sections: SupportContent.privacySections
        )
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Help & Support

struct HelpSupportView: View {

    var body: some View {
        SupportSectionsScreen(
            sections: SupportContent.helpSections
        )
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}


// MARK: - Shared Screen Layout (same structure as SettingsView)

struct SupportSectionsScreen: View {

    let sections: [SupportSection]

    var body: some View {

        ZStack {

            Color(
                red: 0.95,
                green: 0.98,
                blue: 0.97
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    ForEach(
                        Array(sections.enumerated()),
                        id: \.element.id
                    ) { index, section in

                        SettingsSectionTitle(
                            title: section.title
                        )
                        .padding(.top, index == 0 ? 15 : 23)

                        VStack(spacing: 0) {

                            ForEach(
                                Array(section.items.enumerated()),
                                id: \.element.id
                            ) { itemIndex, item in

                                if itemIndex > 0 {
                                    Divider()
                                        .padding(.leading, 52)
                                }

                                SupportDetailRow(
                                    item: item
                                )
                            }
                        }
                        .background(.white)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 15
                            )
                        )
                        .padding(.top, 10)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}


// MARK: - Detail Row (SettingsInfoRow styling, multi-line text)

struct SupportDetailRow: View {

    let item: SupportItem

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 11
        ) {

            Image(
                systemName: item.icon
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
                width: 31,
                height: 31
            )
            .background(
                Color(
                    red: 0.00,
                    green: 0.55,
                    blue: 0.45
                )
                .opacity(0.10)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(item.title)
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.black)

                Text(item.detail)
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer()
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 13)
    }
}


// MARK: - Previews

#Preview("Privacy & Security") {
    NavigationStack {
        PrivacySecurityView()
    }
}

#Preview("Help & Support") {
    NavigationStack {
        HelpSupportView()
    }
}
