import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class DirectMessageManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var messages: [DirectMessage] = []
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private var convoListener: ListenerRegistration?
    private var msgListener: ListenerRegistration?

    var uid: String? { Auth.auth().currentUser?.uid }

    // MARK: - Conversations

    func startListeningConversations() {
        guard let uid else { return }
        isLoading = true
        convoListener = db.collection("conversations")
            .whereField("participants", arrayContains: uid)
            .order(by: "lastTimestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false
                    self.conversations = snapshot?.documents.compactMap {
                        try? $0.data(as: Conversation.self)
                    } ?? []
                }
            }
    }

    func stopListeningConversations() {
        convoListener?.remove()
        convoListener = nil
    }

    // MARK: - Messages

    func startListeningMessages(conversationId: String) {
        msgListener = db.collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.messages = snapshot?.documents.compactMap {
                        try? $0.data(as: DirectMessage.self)
                    } ?? []
                }
            }
    }

    func stopListeningMessages() {
        msgListener?.remove()
        msgListener = nil
    }

    func sendMessage(_ text: String, conversationId: String) async {
        guard let uid else { return }
        do {
            let userDoc = try await db.collection("users").document(uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            let msg = DirectMessage(
                senderId: uid,
                senderName: username,
                text: text,
                timestamp: Date()
            )
            try db.collection("conversations").document(conversationId)
                .collection("messages").addDocument(from: msg)

            try await db.collection("conversations").document(conversationId).updateData([
                "lastMessage": text,
                "lastTimestamp": Date()
            ])
        } catch {}
    }

    // MARK: - Start or find conversation

    func findOrCreateConversation(with otherId: String) async -> String? {
        guard let uid else { return nil }
        do {
            // Check if conversation already exists
            let snapshot = try await db.collection("conversations")
                .whereField("participants", arrayContains: uid)
                .getDocuments()

            for doc in snapshot.documents {
                let participants = doc.data()["participants"] as? [String] ?? []
                if participants.contains(otherId) {
                    return doc.documentID
                }
            }

            // Create new conversation
            let myDoc = try await db.collection("users").document(uid).getDocument()
            let myName = myDoc.data()?["username"] as? String ?? "Anonymous"
            let otherDoc = try await db.collection("users").document(otherId).getDocument()
            let otherName = otherDoc.data()?["username"] as? String ?? "User"

            let convo = Conversation(
                participants: [uid, otherId],
                lastMessage: "",
                lastTimestamp: Date(),
                participantNames: [uid: myName, otherId: otherName]
            )
            let ref = try db.collection("conversations").addDocument(from: convo)
            return ref.documentID
        } catch {
            return nil
        }
    }
}
