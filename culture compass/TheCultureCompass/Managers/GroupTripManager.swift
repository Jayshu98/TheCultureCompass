import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class GroupTripManager: ObservableObject {
    @Published var trips: [GroupTrip] = []
    @Published var featuredTrips: [GroupTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func loadTrips(country: String? = nil) async {
        isLoading = true
        do {
            var query: Query = db.collection("group_trips")
                .order(by: "startDate", descending: false)
                .limit(to: 30)
            if let country { query = query.whereField("country", isEqualTo: country) }

            let snapshot = try await query.getDocuments()
            trips = snapshot.documents.compactMap { try? $0.data(as: GroupTrip.self) }
        } catch {
            errorMessage = "Failed to load trips: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func loadFeatured() async {
        do {
            let snapshot = try await db.collection("group_trips")
                .whereField("isFeatured", isEqualTo: true)
                .limit(to: 5)
                .getDocuments()
            featuredTrips = snapshot.documents.compactMap { try? $0.data(as: GroupTrip.self) }
        } catch {
            errorMessage = "Failed to load featured trips."
        }
    }

    func createTrip(_ trip: GroupTrip, imageData: Data?) async {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            var newTrip = trip
            newTrip.organizerId = user.uid
            newTrip.organizerName = username
            newTrip.participants = [user.uid]
            newTrip.timestamp = Date()

            if let imageData {
                let filename = UUID().uuidString + ".jpg"
                let ref = storage.reference().child("trip_images/\(filename)")
                _ = try await ref.putDataAsync(imageData)
                let url = try await ref.downloadURL()
                newTrip.imageURL = url.absoluteString
            }

            try db.collection("group_trips").addDocument(from: newTrip)
        } catch {
            errorMessage = "Failed to create trip."
        }
        isLoading = false
    }

    func joinTrip(_ tripId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("group_trips").document(tripId).updateData([
                "participants": FieldValue.arrayUnion([uid])
            ])
            if let idx = trips.firstIndex(where: { $0.id == tripId }) {
                trips[idx].participants.append(uid)
            }
        } catch {
            errorMessage = "Failed to join trip."
        }
    }

    func leaveTrip(_ tripId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("group_trips").document(tripId).updateData([
                "participants": FieldValue.arrayRemove([uid])
            ])
            if let idx = trips.firstIndex(where: { $0.id == tripId }) {
                trips[idx].participants.removeAll { $0 == uid }
            }
        } catch {
            errorMessage = "Failed to leave trip."
        }
    }
}
