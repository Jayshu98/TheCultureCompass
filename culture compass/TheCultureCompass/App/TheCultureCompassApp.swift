import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct TheCultureCompassApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("hasAcceptedTerms") private var hasAcceptedTerms = false

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    if !hasAcceptedTerms {
                        DisclaimerScreen(hasAcceptedTerms: $hasAcceptedTerms)
                    } else if !hasSeenWelcome {
                        WelcomeScreen(hasSeenWelcome: $hasSeenWelcome)
                    } else {
                        RootTabView()
                            .environmentObject(authManager)
                    }
                } else {
                    LoginScreen()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
