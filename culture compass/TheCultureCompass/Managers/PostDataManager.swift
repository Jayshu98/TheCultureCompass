import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

@MainActor
final class PostDataManager: ObservableObject {
    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    private var listener: ListenerRegistration?

    func startListening() {
        isLoading = true
        listener = db.collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snapshot, error in
                Task { @MainActor in
                    guard let self else { return }
                    self.isLoading = false
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    self.posts = snapshot?.documents.compactMap {
                        try? $0.data(as: Post.self)
                    } ?? []
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }

    func createPost(caption: String, imageData: Data?) async {
        guard let user = Auth.auth().currentUser else { return }
        isLoading = true
        do {
            var imageURL = ""
            if let imageData {
                let filename = UUID().uuidString + ".jpg"
                let ref = storage.reference().child("post_images/\(filename)")
                _ = try await ref.putDataAsync(imageData)
                let url = try await ref.downloadURL()
                imageURL = url.absoluteString
            }

            // Fetch username from Firestore
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            let post = Post(
                user: username,
                email: user.email ?? "",
                userId: user.uid,
                caption: caption,
                imageURL: imageURL,
                timestamp: Date(),
                comments: []
            )
            try db.collection("posts").addDocument(from: post)
        } catch {
            errorMessage = "Failed to create post."
        }
        isLoading = false
    }

    func addComment(to postId: String, comment: String) async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            let userDoc = try await db.collection("users").document(user.uid).getDocument()
            let username = userDoc.data()?["username"] as? String ?? "Anonymous"

            let newComment = PostComment(
                user: username,
                email: user.email ?? "",
                userId: user.uid,
                comment: comment,
                timestamp: Date()
            )
            let encoded = try Firestore.Encoder().encode(newComment)
            try await db.collection("posts").document(postId).updateData([
                "comments": FieldValue.arrayUnion([encoded])
            ])
        } catch {
            errorMessage = "Failed to add comment."
        }
    }

    func deletePost(_ post: Post) async {
        guard let postId = post.id else { return }
        do {
            try await db.collection("posts").document(postId).delete()
            if !post.imageURL.isEmpty {
                let ref = storage.reference(forURL: post.imageURL)
                try? await ref.delete()
            }
        } catch {
            errorMessage = "Failed to delete post."
        }
    }

    func refresh() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("posts")
                .order(by: "timestamp", descending: true)
                .limit(to: 50)
                .getDocuments()
            posts = snapshot.documents.compactMap { try? $0.data(as: Post.self) }
        } catch {
            errorMessage = "Failed to refresh."
        }
        isLoading = false
    }
}
