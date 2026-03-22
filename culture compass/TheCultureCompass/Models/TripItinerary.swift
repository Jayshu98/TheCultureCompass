import Foundation
import FirebaseFirestore

struct ItineraryDay: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var dayNumber: Int
    var title: String
    var activities: [String]
    var notes: String

    enum CodingKeys: String, CodingKey {
        case id, dayNumber, title, activities, notes
    }
}

struct TripItinerary: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var username: String
    var country: String
    var title: String
    var description: String
    var days: [ItineraryDay]
    var isPublic: Bool
    var likes: Int
    var saves: Int
    var timestamp: Date

    static func == (lhs: TripItinerary, rhs: TripItinerary) -> Bool {
        lhs.id == rhs.id
    }
}
