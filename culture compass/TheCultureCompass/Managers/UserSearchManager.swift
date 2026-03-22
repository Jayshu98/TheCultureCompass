import Foundation
import FirebaseFirestore

@MainActor
final class UserSearchManager: ObservableObject {
    @Published var results: [AppUser] = []
    @Published var isSearching = false

    private let db = Firestore.firestore()

    func search(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        isSearching = true
        do {
            let snapshot = try await db.collection("users")
                .whereField("username", isGreaterThanOrEqualTo: query.lowercased())
                .whereField("username", isLessThanOrEqualTo: query.lowercased() + "\u{f8ff}")
                .limit(to: 20)
                .getDocuments()
            results = snapshot.documents.compactMap { try? $0.data(as: AppUser.self) }
        } catch {
            results = []
        }
        isSearching = false
    }
}
