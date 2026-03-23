import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class RoomsDataManager: ObservableObject {
    @Published var rooms: [ChatRoom] = []
    @Published var messages: [GroupMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var roomsListener: ListenerRegistration?
    private var messagesListener: ListenerRegistration?

    // MARK: - Rooms

    func startListeningRooms() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        roomsListener = db.collection("rooms")
            .whereField("participants", arrayContains: uid)
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

    func stopListeningRooms() {
        roomsListener?.remove()
        roomsListener = nil
    }

    func createRoom(name: String, participantIds: [String]) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let myName = userDoc.data()?["username"] as? String ?? "Anonymous"

            var allIds = participantIds
            if !allIds.contains(uid) { allIds.insert(uid, at: 0) }

            // Fetch all participant names
            var names: [String] = []
            for id in allIds {
                if id == uid {
                    names.append(myName)
                } else {
                    let doc = try await db.collection("users").document(id).getDocument()
                    let name = doc.data()?["username"] as? String ?? "User"
                    names.append(name)
                }
            }

            let room = ChatRoom(
                name: name,
                participants: allIds,
                participantNames: names,
                lastMessage: "",
                createdAt: Date()
            )
            try db.collection("rooms").addDocument(from: room)
        } catch {
            errorMessage = "Failed to create room."
        }
    }

    // MARK: - Messages

    func startListeningMessages(roomId: String) {
        isLoading = true
        messagesListener = db.collection("rooms").document(roomId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .limit(toLast: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    self.messages = snapshot?.documents.compactMap {
                        try? $0.data(as: GroupMessage.self)
                    } ?? []
                }
            }
    }

    func stopListeningMessages() {
        messagesListener?.remove()
        messagesListener = nil
    }

    func sendGroupMessage(roomId: String, text: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            let msg = GroupMessage(
                user: username,
                userId: uid,
                message: text,
                timestamp: Date()
            )
            try db.collection("rooms").document(roomId).collection("messages").addDocument(from: msg)

            // Update last message on room
            try await db.collection("rooms").document(roomId).updateData([
                "lastMessage": "\(username): \(text)"
            ])
        } catch {
            errorMessage = "Failed to send message."
        }
    }

    func deleteGroupMessage(roomId: String, messageId: String) async {
        do {
            try await db.collection("rooms").document(roomId)
                .collection("messages").document(messageId).delete()
        } catch {
            errorMessage = "Failed to delete message."
        }
    }

    func leaveRoom(_ roomId: String) async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("rooms").document(roomId).updateData([
                "participants": FieldValue.arrayRemove([uid])
            ])
        } catch {
            errorMessage = "Failed to leave room."
        }
    }
}
