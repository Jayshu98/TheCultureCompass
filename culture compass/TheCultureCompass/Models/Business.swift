import Foundation
import FirebaseFirestore

struct BusinessReview: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var userId: String
    var username: String
    var rating: Int
    var comment: String
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id, userId, username, rating, comment, timestamp
    }
}

struct Business: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var ownerId: String
    var name: String
    var category: String          // restaurant, hotel, tour, salon, shop
    var country: String
    var city: String
    var description: String
    var imageURL: String
    var contactEmail: String
    var website: String
    var isFeatured: Bool
    var isVerified: Bool
    var rating: Double
    var reviewCount: Int
    var timestamp: Date

    static func == (lhs: Business, rhs: Business) -> Bool {
        lhs.id == rhs.id
    }

    static let categories = [
        "Restaurant", "Hotel", "Tour Guide", "Hair Salon",
        "Shop", "Bar & Nightlife", "Spa & Wellness",
        "Transportation", "Experience", "Other"
    ]
}
