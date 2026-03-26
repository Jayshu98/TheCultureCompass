import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private let db = Firestore.firestore()

    private init() {}

    /// Save the FCM token to the user's Firestore document
    func saveFCMToken(_ token: String) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            // User not logged in yet — store locally and save after login
            UserDefaults.standard.set(token, forKey: "pendingFCMToken")
            return
        }
        do {
            try await db.collection("users").document(uid).updateData([
                "fcmToken": token
            ])
            UserDefaults.standard.removeObject(forKey: "pendingFCMToken")
            print("📬 FCM token saved to Firestore")
        } catch {
            print("📬 Failed to save FCM token: \(error.localizedDescription)")
        }
    }

    /// Call after login to save any pending token
    func savePendingToken() async {
        if let token = UserDefaults.standard.string(forKey: "pendingFCMToken") {
            await saveFCMToken(token)
        }
    }

    /// Remove token on logout
    func clearToken() async {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        try? await db.collection("users").document(uid).updateData([
            "fcmToken": FieldValue.delete()
        ])
    }
}
