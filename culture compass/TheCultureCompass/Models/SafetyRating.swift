import Foundation
import FirebaseFirestore

struct SafetyRating: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var username: String
    var country: String
    var overallRating: Int        // 1-5
    var safetyScore: Int          // 1-5
    var friendlinessScore: Int    // 1-5
    var culturalScore: Int        // 1-5
    var review: String
    var tips: String
    var timestamp: Date

    var averageScore: Double {
        Double(safetyScore + friendlinessScore + culturalScore) / 3.0
    }
}
