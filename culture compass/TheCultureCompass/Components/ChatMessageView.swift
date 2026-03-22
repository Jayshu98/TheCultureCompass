import SwiftUI
import FirebaseAuth

struct ChatMessageView: View {
    let message: ChatMessage
    let onReply: (String) -> Void
    let onDelete: () -> Void

    @State private var replyText = ""
    @State private var showReplies = false

    private var isOwner: Bool {
        Auth.auth().currentUser?.uid == message.userId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(Color.ccBrown)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(message.user.prefix(1)).uppercased())
                            .font(.caption2.bold())
                            .foregroundColor(.ccGold)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(message.user)
                        .font(.caption.bold())
                        .foregroundColor(.ccGold)
                    Text(message.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.ccSubtext)
                }
                Spacer()
                if isOwner {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption2)
                            .foregroundColor(.ccSubtext)
                    }
                }
            }

            Text(message.message)
                .font(.subheadline)
                .foregroundColor(.ccLightText)

            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showReplies.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left")
                        Text("\(message.replies.count)")
                    }
                    .font(.caption2)
                    .foregroundColor(.ccSubtext)
                }
            }

            if showReplies {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(message.replies) { reply in
                        HStack(alignment: .top, spacing: 6) {
                            Text(reply.user)
                                .font(.caption2.bold())
                                .foregroundColor(.ccGold)
                            Text(reply.message)
                                .font(.caption2)
                                .foregroundColor(.ccLightText)
                        }
                        .padding(.leading, 8)
                    }

                    HStack {
                        TextField("Reply...", text: $replyText)
                            .font(.caption)
                            .foregroundColor(.ccLightText)
                            .textFieldStyle(.plain)
                        Button {
                            guard !replyText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            onReply(replyText)
                            replyText = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.caption)
                                .foregroundColor(.ccGold)
                        }
                    }
                    .padding(8)
                    .background(Color.ccDarkBg)
                    .clipShape(Capsule())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .ccCard()
    }
}
