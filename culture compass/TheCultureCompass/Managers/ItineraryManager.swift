import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ItineraryManager: ObservableObject {
    @Published var itineraries: [TripItinerary] = []
    @Published var myItineraries: [TripItinerary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadPublicItineraries(country: String? = nil) async {
        isLoading = true
        do {
            var query: Query = db.collection("itineraries")
                .whereField("isPublic", isEqualTo: true)
            if let country { query = query.whereField("country", isEqualTo: country) }
            query = query.order(by: "likes", descending: true).limit(to: 30)

            let snapshot = try await query.getDocuments()
            itineraries = snapshot.documents.compactMap { try? $0.data(as: TripItinerary.self) }
        } catch {
            errorMessage = "Failed to load itineraries."
        }
        isLoading = false
    }

    func loadMyItineraries() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let snapshot = try await db.collection("itineraries")
                .whereField("userId", isEqualTo: uid)
                .order(by: "timestamp", descending: true)
                .getDocuments()
            myItineraries = snapshot.documents.compactMap { try? $0.data(as: TripItinerary.self) }
        } catch {
            errorMessage = "Failed to load your itineraries."
        }
    }

    func createItinerary(_ itinerary: TripItinerary) async {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            var newItinerary = itinerary
            newItinerary.userId = user.uid
            newItinerary.username = username
            newItinerary.timestamp = Date()

            try db.collection("itineraries").addDocument(from: newItinerary)
            await loadMyItineraries()
        } catch {
            errorMessage = "Failed to create itinerary."
        }
        isLoading = false
    }

    func likeItinerary(_ itineraryId: String) async {
        do {
            try await db.collection("itineraries").document(itineraryId).updateData([
                "likes": FieldValue.increment(Int64(1))
            ])
        } catch {
            errorMessage = "Failed to like."
        }
    }

    func deleteItinerary(_ itineraryId: String) async {
        do {
            try await db.collection("itineraries").document(itineraryId).delete()
            myItineraries.removeAll { $0.id == itineraryId }
        } catch {
            errorMessage = "Failed to delete."
        }
    }
}
