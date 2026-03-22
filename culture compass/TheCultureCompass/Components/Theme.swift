import SwiftUI

struct CCCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(LinearGradient.ccCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }
}

struct CCButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(LinearGradient.ccGoldShimmer)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func ccCard() -> some View {
        modifier(CCCardModifier())
    }
}
