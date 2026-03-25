import SwiftUI

struct DisclaimerScreen: View {
    @Binding var hasAcceptedTerms: Bool
    @State private var scrolledToBottom = false

    private let passportBrown = Color(red: 0.35, green: 0.18, blue: 0.08)

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("🌍")
                        .font(.system(size: 40))
                    Text("Terms & Disclaimer")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.ccGold)
                    Text("Please read before continuing")
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(.ccSubtext)
                }
                .padding(.top, 40)
                .padding(.bottom, 20)

                // Scrollable terms
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        disclaimerSection(
                            title: "User-Generated Content",
                            body: "The Culture Compass is a platform for community-shared travel content. All posts, messages, reviews, safety ratings, and recommendations are created by users and do not represent the views, opinions, or endorsements of The Culture Compass or its developers. We do not verify the accuracy, reliability, or completeness of any user-generated content."
                        )
                        disclaimerSection(
                            title: "Travel Information",
                            body: "Travel information, safety ratings, customs details, and destination recommendations provided within this app are for general informational purposes only. They should not be relied upon as the sole basis for travel decisions. Always consult official government travel advisories, embassies, and licensed travel professionals before traveling."
                        )
                        disclaimerSection(
                            title: "No Liability",
                            body: "The Culture Compass and its developers shall not be held liable for any damages, losses, injuries, or negative experiences arising from the use of this app, including but not limited to: reliance on user-generated content, travel decisions made based on app information, interactions with other users, or transactions with businesses listed in the app."
                        )
                        disclaimerSection(
                            title: "Business Listings",
                            body: "Business listings and reviews are community-contributed. The Culture Compass does not endorse, guarantee, or verify any business listed within the app. Any transactions or interactions with listed businesses are solely between you and the business."
                        )
                        disclaimerSection(
                            title: "User Interactions & Safety",
                            body: "You are solely responsible for your interactions with other users. The Culture Compass does not conduct background checks or verify the identity of users. Exercise caution when sharing personal information, meeting other users, or exchanging contact details through the app."
                        )
                        disclaimerSection(
                            title: "Privacy & Data",
                            body: "By using this app, you consent to the collection and storage of your profile information, posts, messages, and activity data as necessary to provide the service. We do not sell your personal data to third parties. You may delete your account and associated data at any time through Settings."
                        )
                        disclaimerSection(
                            title: "Affiliate Links",
                            body: "This app may contain affiliate links to third-party products and services. The Culture Compass may earn a commission from purchases made through these links at no additional cost to you. These links are provided for convenience and do not constitute an endorsement."
                        )
                        disclaimerSection(
                            title: "Content Moderation",
                            body: "While we strive to maintain a safe and respectful community, we cannot monitor all content in real time. Users are responsible for the content they post. We reserve the right to remove content or suspend accounts that violate community standards without prior notice."
                        )
                        disclaimerSection(
                            title: "Age Requirement",
                            body: "You must be at least 17 years of age to use The Culture Compass. By accepting these terms, you confirm that you meet this age requirement."
                        )

                        // Bottom marker
                        Color.clear.frame(height: 1)
                            .onAppear { scrolledToBottom = true }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .background(Color.ccCardBg.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16)

                // Accept button
                VStack(spacing: 10) {
                    Button {
                        hasAcceptedTerms = true
                    } label: {
                        Text("I Accept the Terms & Conditions")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(scrolledToBottom ? LinearGradient.ccGoldShimmer : LinearGradient(colors: [Color.ccSubtext.opacity(0.3), Color.ccSubtext.opacity(0.2)], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    }
                    .disabled(!scrolledToBottom)

                    if !scrolledToBottom {
                        Text("Scroll to the bottom to accept")
                            .font(.system(size: 11, design: .serif))
                            .foregroundColor(.ccSubtext.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
    }

    private func disclaimerSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(.ccGold.opacity(0.8))
            Text(body)
                .font(.system(size: 13, design: .serif))
                .foregroundColor(.ccLightText.opacity(0.85))
                .lineSpacing(3)
        }
    }
}
