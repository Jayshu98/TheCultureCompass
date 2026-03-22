import Foundation
import FirebaseFirestore

struct GroupMessage: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var user: String
    var userId: String
    var message: String
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, user, userId, message, timestamp
    }
}

struct ChatRoom: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var participants: [String]
    var participantNames: [String]
    var lastMessage: String
    var createdAt: Date
}
