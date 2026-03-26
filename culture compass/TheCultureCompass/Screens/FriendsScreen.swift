import SwiftUI

struct FriendsScreen: View {
    let friends: [AppUser]
    let count: Int

    private let brown = Color(red: 0.35, green: 0.18, blue: 0.08)
    private let pageColor = Color(red: 0.95, green: 0.92, blue: 0.86)

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            if friends.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 48))
                        .foregroundStyle(LinearGradient.ccGoldShimmer)
                    Text("No friends yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.ccLightText)
                    Text("Visit someone's passport and add them")
                        .font(.system(size: 14))
                        .foregroundColor(.ccSubtext)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(friends) { friend in
                            NavigationLink(destination: UserPassportScreen(userId: friend.id ?? "")) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .strokeBorder(LinearGradient.ccGoldShimmer, lineWidth: 2)
                                            .frame(width: 48, height: 48)
                                        Circle()
                                            .fill(Color.ccCardBg)
                                            .frame(width: 42, height: 42)
                                            .overlay(
                                                Text(String(friend.username.prefix(1)).uppercased())
                                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                                    .foregroundColor(.ccGold)
                                            )
                                    }
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(friend.username)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.ccLightText)
                                        Text("\(friend.visitedCountries.count) countries visited")
                                            .font(.system(size: 13))
                                            .foregroundColor(.ccSubtext)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.ccSubtext)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.ccCardBg.opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                }
            }
        }
        .navigationTitle("Friends (\(count))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
