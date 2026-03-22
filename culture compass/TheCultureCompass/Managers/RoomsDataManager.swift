import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class RoomsDataManager: ObservableObject {
    @Published var rooms: [ChatRoom] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening() {
        isLoading = true
        listener = db.collection("rooms")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    self.rooms = snapshot?.documents.compactMap {
                        try? $0.data(as: ChatRoom.self)
                    } ?? []
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func createRoom(name: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let room = ChatRoom(name: name, participants: [uid], createdAt: Date())
            try db.collection("rooms").addDocument(from: room)
        } catch {
            errorMessage = "Failed to create room."
        }
    }

    func joinRoom(_ roomId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("rooms").document(roomId).updateData([
                "participants": FieldValue.arrayUnion([uid])
            ])
        } catch {
            errorMessage = "Failed to join room."
        }
    }
}
