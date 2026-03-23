import Foundation
import FirebaseFirestore

struct AppUser: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var username: String
    var email: String
    var bio: String
    var profileImageURL: String
    var scrapbookPhotos: [String]
    var visitedCountries: [String]
    var friends: [String]

    static let empty = AppUser(
        username: "",
        email: "",
        bio: "",
        profileImageURL: "",
        scrapbookPhotos: [],
        visitedCountries: [],
        friends: []
    )
}
