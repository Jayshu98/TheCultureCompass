import SwiftUI

struct WelcomeScreen: View {
    @Binding var hasSeenWelcome: Bool
    @State private var currentPage = 0

    private let pages: [WelcomePage] = [
        WelcomePage(
            emoji: "🌍",
            title: "Welcome to\nThe Culture Compass",
            subtitle: "Your passport to the world.\nBuilt by Black travelers, for Black travelers.",
            color: .ccGold
        ),
        WelcomePage(
            emoji: "🗺️",
            title: "Discover",
            subtitle: "Scroll through travel posts from the community.\nShare your own photos, captions, and locations.",
            color: .ccGold
        ),
        WelcomePage(
            emoji: "💬",
            title: "Connect",
            subtitle: "Join country chat rooms to ask questions,\nshare tips, and meet fellow travelers.",
            color: .ccGold
        ),
        WelcomePage(
            emoji: "📋",
            title: "Plan",
            subtitle: "Build itineraries, find group trips,\ndiscover events, and browse Black-owned businesses.",
            color: .ccGold
        ),
        WelcomePage(
            emoji: "✉️",
            title: "Messages",
            subtitle: "DM other travelers directly.\nExchange info and plan meetups.",
            color: .ccGold
        ),
        WelcomePage(
            emoji: "📕",
            title: "Your Passport",
            subtitle: "Build your travel profile with a scrapbook,\ncountry stamps, friends, and achievements.",
            color: .ccGold
        )
    ]

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        VStack(spacing: 24) {
                            Spacer()

                            Text(page.emoji)
                                .font(.system(size: 72))
                                .shadow(color: .ccGold.opacity(0.3), radius: 20)

                            Text(page.title)
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(.ccLightText)
                                .multilineTextAlignment(.center)

                            Text(page.subtitle)
                                .font(.system(size: 15, design: .serif))
                                .foregroundColor(.ccSubtext)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentPage ? Color.ccGold : Color.ccSubtext.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(i == currentPage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button {
                            withAnimation { currentPage -= 1 }
                        } label: {
                            Text("Back")
                                .font(.system(size: 15, weight: .medium, design: .serif))
                                .foregroundColor(.ccSubtext)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.ccCardBg)
                                .clipShape(Capsule())
                        }
                    }

                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            hasSeenWelcome = true
                        }
                    } label: {
                        Text(currentPage == pages.count - 1 ? "Let's Go" : "Next")
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.ccGoldShimmer)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)

                // Skip
                if currentPage < pages.count - 1 {
                    Button {
                        hasSeenWelcome = true
                    } label: {
                        Text("Skip Tutorial")
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(.ccSubtext.opacity(0.5))
                    }
                    .padding(.bottom, 20)
                } else {
                    Spacer().frame(height: 36)
                }
            }
        }
    }
}

private struct WelcomePage {
    let emoji: String
    let title: String
    let subtitle: String
    let color: Color
}
