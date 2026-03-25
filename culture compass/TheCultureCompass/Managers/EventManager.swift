import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class EventManager: ObservableObject {
    @Published var events: [CCEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadEvents(country: String? = nil) async {
        isLoading = true
        do {
            var query: Query = db.collection("events")
                .order(by: "date", descending: false)
                .limit(to: 30)
            if let country { query = query.whereField("country", isEqualTo: country) }

            let snapshot = try await query.getDocuments()
            events = snapshot.documents.compactMap { try? $0.data(as: CCEvent.self) }
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func createEvent(_ event: CCEvent) async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            var newEvent = event
            newEvent.organizerId = user.uid
            newEvent.organizerName = username
            newEvent.attendees = [user.uid]
            newEvent.timestamp = Date()

            try db.collection("events").addDocument(from: newEvent)
        } catch {
            errorMessage = "Failed to create event."
        }
    }

    func rsvp(_ eventId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("events").document(eventId).updateData([
                "attendees": FieldValue.arrayUnion([uid])
            ])
            if let idx = events.firstIndex(where: { $0.id == eventId }) {
                events[idx].attendees.append(uid)
            }
        } catch {
            errorMessage = "Failed to RSVP."
        }
    }

    func cancelRsvp(_ eventId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("events").document(eventId).updateData([
                "attendees": FieldValue.arrayRemove([uid])
            ])
            if let idx = events.firstIndex(where: { $0.id == eventId }) {
                events[idx].attendees.removeAll { $0 == uid }
            }
        } catch {
            errorMessage = "Failed to cancel RSVP."
        }
    }
}
