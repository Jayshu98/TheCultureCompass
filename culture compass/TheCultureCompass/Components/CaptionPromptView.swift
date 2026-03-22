import SwiftUI

struct CaptionPromptView: View {
    @Binding var caption: String
    @Binding var isPresented: Bool
    let onSubmit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 20) {
                Text("What's on your mind?")
                    .font(.title3.bold())
                    .foregroundColor(.ccGold)

                TextField("Write a caption...", text: $caption, axis: .vertical)
                    .lineLimit(3...6)
                    .padding()
                    .background(Color.ccDarkBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.ccLightText)

                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.ccSubtext)

                    Button("Post") {
                        onSubmit()
                        isPresented = false
                    }
                    .buttonStyle(CCButtonStyle())
                    .disabled(caption.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(24)
            .background(LinearGradient.ccCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.6), radius: 20)
            .padding(.horizontal, 24)
        }
    }
}
