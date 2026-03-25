import SwiftUI

struct CaptionPromptView: View {
    @Binding var caption: String
    @Binding var location: String
    @Binding var isPresented: Bool
    let onSubmit: () -> Void
    @State private var contentWarning: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                Text("What's on your mind?")
                    .font(.title3.bold())
                    .foregroundColor(.ccGold)

                TextField("Write a caption...", text: $caption, axis: .vertical)
                    .lineLimit(3...6)
                    .padding()
                    .background(Color.ccDarkBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.ccLightText)

                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.ccGold)
                    TextField("Add location...", text: $location)
                        .foregroundColor(.ccLightText)
                }
                .padding()
                .background(Color.ccDarkBg)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                if let contentWarning {
                    Text(contentWarning)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.ccSubtext)

                    Button("Post") {
                        let check = ContentFilter.isCleanContent(caption)
                        if !check.clean {
                            contentWarning = check.reason
                            return
                        }
                        contentWarning = nil
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
