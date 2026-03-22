import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class ChatDataManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    func startListening(for location: String) {
        isLoading = true
        listener = db.collection("chats")
            .whereField("location", isEqualTo: location)
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    self.messages = snapshot?.documents.compactMap {
                        try? $0.data(as: ChatMessage.self)
                    } ?? []
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func sendMessage(_ text: String, location: String) async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            let msg = ChatMessage(
                location: location,
                user: username,
                email: user.email ?? "",
                userId: user.uid,
                message: text,
                timestamp: Date(),
                replies: []
            )
            try db.collection("chats").addDocument(from: msg)
        } catch {
            errorMessage = "Failed to send message."
        }
    }

    func addReply(to chatId: String, message: String) async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            let reply = ChatReply(
                user: username,
                email: user.email ?? "",
                userId: user.uid,
                message: message,
                timestamp: Int(Date().timeIntervalSince1970)
            )
            let encoded = try Firestore.Encoder().encode(reply)
            try await db.collection("chats").document(chatId).updateData([
                "replies": FieldValue.arrayUnion([encoded])
            ])
        } catch {
            errorMessage = "Failed to add reply."
        }
    }

    func deleteMessage(_ message: ChatMessage) async {
        guard let msgId = message.id else { return }
        do {
            try await db.collection("chats").document(msgId).delete()
        } catch {
            errorMessage = "Failed to delete message."
        }
    }
}
