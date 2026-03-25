import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class BusinessManager: ObservableObject {
    @Published var businesses: [Business] = []
    @Published var featuredBusinesses: [Business] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func loadBusinesses(country: String? = nil, category: String? = nil) async {
        isLoading = true
        do {
            var query: Query = db.collection("businesses")
            if let country { query = query.whereField("country", isEqualTo: country) }
            if let category { query = query.whereField("category", isEqualTo: category) }
            query = query.order(by: "rating", descending: true).limit(to: 50)

            let snapshot = try await query.getDocuments()
            businesses = snapshot.documents.compactMap { try? $0.data(as: Business.self) }
        } catch {
            errorMessage = "Failed to load businesses."
        }
        isLoading = false
    }

    func loadFeatured() async {
        do {
            let snapshot = try await db.collection("businesses")
                .whereField("isFeatured", isEqualTo: true)
                .limit(to: 10)
                .getDocuments()
            featuredBusinesses = snapshot.documents.compactMap { try? $0.data(as: Business.self) }
        } catch {
            errorMessage = "Failed to load featured."
        }
    }

    func createBusiness(_ biz: Business, imageData: Data?) async {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        do {
            var newBiz = biz
            newBiz.ownerId = user.uid
            newBiz.timestamp = Date()

            if let imageData {
                let filename = UUID().uuidString + ".jpg"
                let ref = storage.reference().child("business_images/\(filename)")
                _ = try await ref.putDataAsync(imageData)
                let url = try await ref.downloadURL()
                newBiz.imageURL = url.absoluteString
            }

            try db.collection("businesses").addDocument(from: newBiz)
        } catch {
            errorMessage = "Failed to create listing."
        }
        isLoading = false
    }

    func addReview(businessId: String, rating: Int, comment: String) async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            let review = BusinessReview(
                userId: user.uid,
                username: username,
                rating: rating,
                comment: comment,
                timestamp: Date()
            )

            // Get current business to recalculate rating
            let bizDoc = try await db.collection("businesses").document(businessId).getDocument()
            let currentRating = bizDoc.data()?["rating"] as? Double ?? 0
            let currentCount = bizDoc.data()?["reviewCount"] as? Int ?? 0
            let newCount = currentCount + 1
            let newRating = ((currentRating * Double(currentCount)) + Double(rating)) / Double(newCount)

            try await db.collection("businesses").document(businessId).updateData([
                "rating": newRating,
                "reviewCount": newCount
            ])

            // Store review in subcollection
            try db.collection("businesses").document(businessId)
                .collection("reviews").addDocument(from: review)
        } catch {
            errorMessage = "Failed to add review."
        }
    }

    func loadReviews(businessId: String) async -> [BusinessReview] {
        do {
            let snapshot = try await db.collection("businesses").document(businessId)
                .collection("reviews")
                .order(by: "timestamp", descending: true)
                .limit(to: 30)
                .getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: BusinessReview.self) }
        } catch {
            return []
        }
    }
}
