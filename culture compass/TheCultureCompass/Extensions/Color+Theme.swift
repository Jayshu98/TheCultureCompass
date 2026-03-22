import SwiftUI

extension Color {
    static let ccBrown = Color(red: 0.45, green: 0.25, blue: 0.12)
    static let ccGold = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let ccDarkBg = Color(red: 0.08, green: 0.06, blue: 0.06)
    static let ccCardBg = Color(red: 0.13, green: 0.10, blue: 0.10)
    static let ccLightText = Color(red: 0.92, green: 0.88, blue: 0.82)
    static let ccSubtext = Color(red: 0.6, green: 0.55, blue: 0.50)
}

extension LinearGradient {
    static let ccBackground = LinearGradient(
        colors: [Color.ccDarkBg, Color.black],
        startPoint: .top,
        endPoint: .bottom
    )
    static let ccCard = LinearGradient(
        colors: [Color.ccCardBg, Color.ccDarkBg],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let ccGoldShimmer = LinearGradient(
        colors: [Color.ccGold, Color.ccBrown],
        startPoint: .leading,
        endPoint: .trailing
    )
}
