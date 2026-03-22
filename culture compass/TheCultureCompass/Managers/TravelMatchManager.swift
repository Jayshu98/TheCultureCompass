import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class TravelMatchManager: ObservableObject {
    @Published var matches: [TravelMatch] = []
    @Published var myListing: TravelMatch?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadMatches(country: String, startDate: Date, endDate: Date) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        do {
            let snapshot = try await db.collection("travel_matches")
                .whereField("country", isEqualTo: country)
                .whereField("startDate", isLessThanOrEqualTo: endDate)
                .whereField("endDate", isGreaterThanOrEqualTo: startDate)
                .limit(to: 30)
                .getDocuments()
            matches = snapshot.documents.compactMap { try? $0.data(as: TravelMatch.self) }
                .filter { $0.userId != uid }
        } catch {
            errorMessage = "Failed to load matches."
        }
        isLoading = false
    }

    func postListing(country: String, startDate: Date, endDate: Date, bio: String, interests: [String]) async {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"
            let profileURL = userDoc.data()?["profileImageURL"] as? String ?? ""

            let listing = TravelMatch(
                userId: user.uid,
                username: username,
                profileImageURL: profileURL,
                country: country,
                startDate: startDate,
                endDate: endDate,
                bio: bio,
                interests: interests,
                timestamp: Date()
            )
            try db.collection("travel_matches").addDocument(from: listing)
            myListing = listing
        } catch {
            errorMessage = "Failed to post listing."
        }
        isLoading = false
    }

    func removeListing() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snapshot = try await db.collection("travel_matches")
                .whereField("userId", isEqualTo: uid)
                .getDocuments()
            for doc in snapshot.documents {
                try await doc.reference.delete()
            }
            myListing = nil
        } catch {
            errorMessage = "Failed to remove listing."
        }
    }
}
