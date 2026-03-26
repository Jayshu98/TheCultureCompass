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
        guard let uid else {
            print("❌ Upload failed: No UID")
            return
        }
        isLoading = true
        print("📸 Starting profile image upload for \(uid), data size: \(data.count) bytes")
        do {
            let ref = storage.reference().child("profile_images/\(uid).jpg")
            _ = try await ref.putDataAsync(data)
            print("✅ Image uploaded to Storage")
            let url = try await ref.downloadURL()
            print("✅ Download URL: \(url.absoluteString)")
            try await db.collection("users").document(uid).updateData(["profileImageURL": url.absoluteString])
            print("✅ Firestore updated")
            user.profileImageURL = url.absoluteString
            print("✅ Local user updated, UI should refresh")
        } catch {
            print("❌ Upload error: \(error.localizedDescription)")
            errorMessage = "Failed to upload image: \(error.localizedDescription)"
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

    // MARK: - Friends

    func addFriend(_ friendId: String) async {
        guard let uid else { return }
        do {
            // Add to both users' friend lists
            try await db.collection("users").document(uid).updateData([
                "friends": FieldValue.arrayUnion([friendId])
            ])
            try await db.collection("users").document(friendId).updateData([
                "friends": FieldValue.arrayUnion([uid])
            ])
            if !user.friends.contains(friendId) {
                user.friends.append(friendId)
            }
        } catch {
            errorMessage = "Failed to add friend."
        }
    }

    func removeFriend(_ friendId: String) async {
        guard let uid else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "friends": FieldValue.arrayRemove([friendId])
            ])
            try await db.collection("users").document(friendId).updateData([
                "friends": FieldValue.arrayRemove([uid])
            ])
            user.friends.removeAll { $0 == friendId }
        } catch {
            errorMessage = "Failed to remove friend."
        }
    }

    func isFriend(_ userId: String) -> Bool {
        user.friends.contains(userId)
    }

    func loadFriends() async -> [AppUser] {
        guard !user.friends.isEmpty else { return [] }
        var friends: [AppUser] = []
        for friendId in user.friends {
            do {
                let doc = try await db.collection("users").document(friendId).getDocument()
                if let friend = try? doc.data(as: AppUser.self) {
                    friends.append(friend)
                }
            } catch {}
        }
        return friends
    }

    // MARK: - Block

    func blockUser(_ userId: String) async {
        guard let uid else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "blockedUsers": FieldValue.arrayUnion([userId])
            ])
            if !user.blockedUsers.contains(userId) {
                user.blockedUsers.append(userId)
            }
            // Also remove from friends if they were friends
            await removeFriend(userId)
        } catch {
            errorMessage = "Failed to block user."
        }
    }

    func unblockUser(_ userId: String) async {
        guard let uid else { return }
        do {
            try await db.collection("users").document(uid).updateData([
                "blockedUsers": FieldValue.arrayRemove([userId])
            ])
            user.blockedUsers.removeAll { $0 == userId }
        } catch {
            errorMessage = "Failed to unblock user."
        }
    }

    func isBlocked(_ userId: String) -> Bool {
        user.blockedUsers.contains(userId)
    }
}
