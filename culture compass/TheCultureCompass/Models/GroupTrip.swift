import Foundation
import FirebaseFirestore

struct GroupTrip: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var organizerId: String
    var organizerName: String
    var title: String
    var country: String
    var description: String
    var imageURL: String
    var startDate: Date
    var endDate: Date
    var price: Double
    var currency: String
    var maxParticipants: Int
    var participants: [String]
    var highlights: [String]
    var isFeatured: Bool
    var timestamp: Date

    var spotsLeft: Int {
        max(0, maxParticipants - participants.count)
    }

    static func == (lhs: GroupTrip, rhs: GroupTrip) -> Bool {
        lhs.id == rhs.id
    }
}
