import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var participants: [String]
    var lastMessage: String
    var lastTimestamp: Date
    var participantNames: [String: String]
}

struct DirectMessage: Identifiable, Codable {
    @DocumentID var id: String?
    var senderId: String
    var senderName: String
    var text: String
    var timestamp: Date
}
