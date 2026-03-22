import Foundation
import FirebaseFirestore

struct ChatRoom: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var name: String
    var participants: [String]
    var createdAt: Date
}
