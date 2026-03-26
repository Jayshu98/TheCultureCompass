import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class AuthManager: ObservableObject {
    @Published var currentUser: FirebaseAuth.User?
    @Published var appUser: AppUser?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false

    private let db = Firestore.firestore()
    private var authListener: AuthStateDidChangeListenerHandle?

    init() {
        listenToAuthState()
    }

    deinit {
        if let listener = authListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    private func listenToAuthState() {
        authListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                if let uid = user?.uid {
                    await self?.fetchAppUser(uid: uid)
                    await NotificationManager.shared.savePendingToken()
                } else {
                    self?.appUser = nil
                }
            }
        }
    }

    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let newUser = AppUser(
                username: username,
                email: email,
                bio: "",
                profileImageURL: "",
                scrapbookPhotos: [],
                visitedCountries: [],
                friends: [],
                blockedUsers: []
            )
            try db.collection("users").document(result.user.uid).setData(from: newUser)
            appUser = newUser
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func resetPassword(email: String) async {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        Task { await NotificationManager.shared.clearToken() }
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchAppUser(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            appUser = try doc.data(as: AppUser.self)
        } catch {
            errorMessage = "Failed to load profile."
        }
    }

    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        do {
            // Delete user data from Firestore
            try await db.collection("users").document(uid).delete()

            // Delete posts by this user
            let posts = try await db.collection("posts").whereField("userId", isEqualTo: uid).getDocuments()
            for doc in posts.documents { try await doc.reference.delete() }

            // Delete itineraries by this user
            let itineraries = try await db.collection("itineraries").whereField("userId", isEqualTo: uid).getDocuments()
            for doc in itineraries.documents { try await doc.reference.delete() }

            // Delete safety ratings by this user
            let ratings = try await db.collection("safety_ratings").whereField("userId", isEqualTo: uid).getDocuments()
            for doc in ratings.documents { try await doc.reference.delete() }

            // Delete the Firebase Auth account
            try await user.delete()
        } catch {
            errorMessage = "Failed to delete account. You may need to sign in again first."
        }
    }
}
