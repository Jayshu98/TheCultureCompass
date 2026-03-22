import SwiftUI

struct RootTabView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.ccDarkBg)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.ccSubtext)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.ccSubtext)]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.ccGold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.ccGold)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DiscoverScreen()
            }
            .tabItem {
                Image(systemName: "globe")
                Text("Discover")
            }
            .tag(0)

            NavigationStack {
                ConnectScreen()
            }
            .tabItem {
                Image(systemName: "message")
                Text("Connect")
            }
            .tag(1)

            NavigationStack {
                PassportScreen()
            }
            .tabItem {
                Image(systemName: "person.crop.rectangle")
                Text("Passport")
            }
            .tag(2)

            NavigationStack {
                PlanScreen()
            }
            .tabItem {
                Image(systemName: "map")
                Text("Plan")
            }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            .tag(4)
        }
    }
}
