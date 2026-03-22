import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class UserProfileManager: ObservableObject {
    @Published var user: AppUser = .empty
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var uid: String? { Auth.auth().currentUser?.uid }

    func loadProfile() async {
        guard let uid else { return }
        isLoading = true
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            if let loaded = try? doc.data(as: AppUser.self) {
                user = loaded
            }
        } catch {
            errorMessage = "Failed to load profile."
        }
        isLoading = false
    }

    func updateBio(_ bio: String) async {
        guard let uid else { return }
        do {
            try await db.collection("users").document(uid).updateData(["bio": bio])
            user.bio = bio
        } catch {
            errorMessage = "Failed to update bio."
        }
    }

    func uploadProfileImage(_ data: Data) async {
        guard let uid else { return }
        isLoading = true
        do {
            let ref = storage.reference().child("profile_images/\(uid).jpg")
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()
            try await db.collection("users").document(uid).updateData(["profileImageURL": url.absoluteString])
            user.profileImageURL = url.absoluteString
        } catch {
            errorMessage = "Failed to upload image."
        }
        isLoading = false
    }

    func addScrapbookPhoto(_ data: Data) async {
        guard let uid else { return }
        isLoading = true
        do {
            let filename = UUID().uuidString + ".jpg"
            let ref = storage.reference().child("scrapbook/\(uid)/\(filename)")
            _ = try await ref.putDataAsync(data)
            let url = try await ref.downloadURL()
            try await db.collection("users").document(uid).updateData([
                "scrapbookPhotos": FieldValue.arrayUnion([url.absoluteString])
            ])
            user.scrapbookPhotos.append(url.absoluteString)
        } catch {
            errorMessage = "Failed to upload scrapbook photo."
        }
        isLoading = false
    }

    func removeScrapbookPhoto(_ urlString: String) async {
        guard let uid else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "scrapbookPhotos": FieldValue.arrayRemove([urlString])
            ])
            user.scrapbookPhotos.removeAll { $0 == urlString }
            // Delete from storage
            let ref = storage.reference(forURL: urlString)
            try? await ref.delete()
        } catch {
            errorMessage = "Failed to remove photo."
        }
    }

    func addVisitedCountry(_ country: String) async {
        guard let uid else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "visitedCountries": FieldValue.arrayUnion([country])
            ])
            if !user.visitedCountries.contains(country) {
                user.visitedCountries.append(country)
            }
        } catch {
            errorMessage = "Failed to add country."
        }
    }
}
