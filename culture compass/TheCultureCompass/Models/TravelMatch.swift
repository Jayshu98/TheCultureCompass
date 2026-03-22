import Foundation
import FirebaseFirestore

struct TravelMatch: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var username: String
    var profileImageURL: String
    var country: String
    var startDate: Date
    var endDate: Date
    var bio: String
    var interests: [String]
    var timestamp: Date

    static let interestOptions = [
        "Nightlife", "Food & Dining", "History & Culture",
        "Adventure", "Beach & Relaxation", "Shopping",
        "Photography", "Fitness", "Art & Museums", "Nature"
    ]
}
