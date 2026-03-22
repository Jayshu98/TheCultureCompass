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
                visitedCountries: []
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

    func signOut() {
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
}
