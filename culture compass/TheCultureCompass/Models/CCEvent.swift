import Foundation
import FirebaseFirestore

struct CCEvent: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var organizerId: String
    var organizerName: String
    var title: String
    var description: String
    var country: String
    var city: String
    var date: Date
    var imageURL: String
    var attendees: [String]
    var maxAttendees: Int
    var isFeatured: Bool
    var timestamp: Date

    var spotsLeft: Int {
        max(0, maxAttendees - attendees.count)
    }

    static func == (lhs: CCEvent, rhs: CCEvent) -> Bool {
        lhs.id == rhs.id
    }
}
