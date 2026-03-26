import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct AchievementsScreen: View {
    @State private var stats: UserStats = .empty
    @State private var isLoading = true

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    Text("Achievements")
                        .font(.title.bold())
                        .foregroundColor(.ccGold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    if isLoading {
                        ProgressView().tint(.ccGold)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(Achievement.all) { achievement in
                                let unlocked = isUnlocked(achievement)
                                AchievementCard(achievement: achievement, unlocked: unlocked)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .refreshable { await loadStats() }
        }
        .task { await loadStats() }
    }

    private func isUnlocked(_ achievement: Achievement) -> Bool {
        switch achievement.id {
        case "first_post": return stats.postCount >= 1
        case "10_posts": return stats.postCount >= 10
        case "3_countries": return stats.countryCount >= 3
        case "10_countries": return stats.countryCount >= 10
        case "25_countries": return stats.countryCount >= 25
        case "first_review": return stats.reviewCount >= 1
        case "10_reviews": return stats.reviewCount >= 10
        case "first_itinerary": return stats.itineraryCount >= 1
        case "5_scrapbook": return stats.scrapbookCount >= 5
        case "helper": return stats.commentCount >= 25
        default: return false
        }
    }

    private func loadStats() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let countries = (userDoc.data()?["visitedCountries"] as? [String])?.count ?? 0
            let scrapbook = (userDoc.data()?["scrapbookPhotos"] as? [String])?.count ?? 0

            let posts = try await db.collection("posts")
                .whereField("userId", isEqualTo: uid).getDocuments().count
            let reviews = try await db.collection("safety_ratings")
                .whereField("userId", isEqualTo: uid).getDocuments().count
            let itineraries = try await db.collection("itineraries")
                .whereField("userId", isEqualTo: uid).getDocuments().count
            let trips = try await db.collection("group_trips")
                .whereField("participants", arrayContains: uid).getDocuments().count

            stats = UserStats(
                postCount: posts, countryCount: countries,
                reviewCount: reviews, itineraryCount: itineraries,
                scrapbookCount: scrapbook, groupTripCount: trips,
                commentCount: 0
            )
        } catch {}
        isLoading = false
    }
}

private struct UserStats {
    var postCount: Int
    var countryCount: Int
    var reviewCount: Int
    var itineraryCount: Int
    var scrapbookCount: Int
    var groupTripCount: Int
    var commentCount: Int

    static let empty = UserStats(
        postCount: 0, countryCount: 0, reviewCount: 0,
        itineraryCount: 0, scrapbookCount: 0, groupTripCount: 0,
        commentCount: 0
    )
}

private struct AchievementCard: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.system(size: 32))
                .foregroundColor(unlocked ? .ccGold : .ccSubtext.opacity(0.4))

            Text(achievement.title)
                .font(.caption.bold())
                .foregroundColor(unlocked ? .ccLightText : .ccSubtext.opacity(0.5))

            Text(achievement.description)
                .font(.system(size: 9))
                .foregroundColor(.ccSubtext)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(unlocked ? LinearGradient.ccCard : LinearGradient(colors: [Color.ccDarkBg, Color.ccDarkBg], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(unlocked ? Color.ccGold.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .opacity(unlocked ? 1.0 : 0.5)
    }
}
