import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class SafetyRatingManager: ObservableObject {
    @Published var ratings: [SafetyRating] = []
    @Published var countrySummary: (avg: Double, count: Int) = (0, 0)
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadRatings(for country: String) async {
        isLoading = true
        do {
            let snapshot = try await db.collection("safety_ratings")
                .whereField("country", isEqualTo: country)
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
                .getDocuments()
            ratings = snapshot.documents.compactMap { try? $0.data(as: SafetyRating.self) }

            let total = ratings.reduce(0.0) { $0 + $1.averageScore }
            countrySummary = (ratings.isEmpty ? 0 : total / Double(ratings.count), ratings.count)
        } catch {
            errorMessage = "Failed to load ratings."
        }
        isLoading = false
    }

    func submitRating(country: String, overall: Int, safety: Int, friendliness: Int, cultural: Int, review: String, tips: String) async {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            let rating = SafetyRating(
                userId: user.uid,
                username: username,
                country: country,
                overallRating: overall,
                safetyScore: safety,
                friendlinessScore: friendliness,
                culturalScore: cultural,
                review: review,
                tips: tips,
                timestamp: Date()
            )
            try db.collection("safety_ratings").addDocument(from: rating)
            await loadRatings(for: country)
        } catch {
            errorMessage = "Failed to submit rating."
        }
        isLoading = false
    }
}
