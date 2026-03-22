import Foundation
import FirebaseFirestore

struct ChatReply: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var user: String
    var email: String
    var userId: String
    var message: String
    var timestamp: Int

    enum CodingKeys: String, CodingKey {
        case id, user, email, userId, message, timestamp
    }
}

struct ChatMessage: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var location: String
    var user: String
    var email: String
    var userId: String
    var message: String
    var timestamp: Date
    var replies: [ChatReply]

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        lhs.id == rhs.id
    }
}
