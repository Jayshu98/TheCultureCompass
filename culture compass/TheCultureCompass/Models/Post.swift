import Foundation
import FirebaseFirestore

struct PostComment: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var user: String
    var email: String
    var userId: String
    var comment: String
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, user, email, userId, comment, timestamp
    }
}

struct Post: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var user: String
    var email: String
    var userId: String
    var caption: String
    var imageURL: String
    var timestamp: Date
    var comments: [PostComment]

    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
}
