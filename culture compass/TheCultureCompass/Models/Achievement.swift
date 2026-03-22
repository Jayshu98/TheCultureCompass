import Foundation

struct Achievement: Identifiable, Hashable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: Int

    static let all: [Achievement] = [
        Achievement(id: "first_post", title: "First Steps", description: "Create your first post", icon: "pencil.circle.fill", requirement: 1),
        Achievement(id: "10_posts", title: "Storyteller", description: "Create 10 posts", icon: "text.bubble.fill", requirement: 10),
        Achievement(id: "3_countries", title: "Explorer", description: "Visit 3 countries", icon: "globe.americas.fill", requirement: 3),
        Achievement(id: "10_countries", title: "World Traveler", description: "Visit 10 countries", icon: "airplane.circle.fill", requirement: 10),
        Achievement(id: "25_countries", title: "Globe Trotter", description: "Visit 25 countries", icon: "crown.fill", requirement: 25),
        Achievement(id: "first_review", title: "Community Voice", description: "Write your first safety review", icon: "star.circle.fill", requirement: 1),
        Achievement(id: "10_reviews", title: "Trusted Reviewer", description: "Write 10 safety reviews", icon: "checkmark.seal.fill", requirement: 10),
        Achievement(id: "first_itinerary", title: "Trip Planner", description: "Create your first itinerary", icon: "map.circle.fill", requirement: 1),
        Achievement(id: "5_scrapbook", title: "Photographer", description: "Add 5 scrapbook photos", icon: "camera.circle.fill", requirement: 5),
        Achievement(id: "group_trip", title: "Squad Leader", description: "Join a group trip", icon: "person.3.fill", requirement: 1),
        Achievement(id: "helper", title: "Community Helper", description: "Leave 25 comments", icon: "heart.circle.fill", requirement: 25),
    ]
}
