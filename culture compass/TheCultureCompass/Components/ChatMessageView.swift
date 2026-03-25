import SwiftUI
import FirebaseAuth

struct ChatMessageView: View {
    let message: ChatMessage
    let onReply: (String) -> Void
    let onDelete: () -> Void

    @State private var replyText = ""
    @State private var showReplies = false
    @State private var showDeleteConfirm = false

    private var isOwner: Bool {
        Auth.auth().currentUser?.uid == message.userId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                NavigationLink(destination: UserPassportScreen(userId: message.userId)) {
                    Circle()
                        .fill(Color.ccBrown)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(String(message.user.prefix(1)).uppercased())
                                .font(.caption2.bold())
                                .foregroundColor(.ccGold)
                        )
                }
                VStack(alignment: .leading, spacing: 2) {
                    NavigationLink(destination: UserPassportScreen(userId: message.userId)) {
                        Text(message.user)
                            .font(.caption.bold())
                            .foregroundColor(.ccGold)
                    }
                    Text(message.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.caption2)
                        .foregroundColor(.ccSubtext)
                }
                Spacer()

                // Visible delete/actions menu
                if isOwner {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                }
            }

            Text(message.message)
                .font(.subheadline)
                .foregroundColor(.ccLightText)

            // Reply button
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3)) { showReplies.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.left")
                        Text("\(message.replies.count)")
                    }
                    .font(.caption2)
                    .foregroundColor(.ccSubtext)
                }
            }

            // Replies
            if showReplies {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(message.replies) { reply in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 6) {
                                NavigationLink(destination: UserPassportScreen(userId: reply.userId)) {
                                    Text(reply.user)
                                        .font(.caption2.bold())
                                        .foregroundColor(.ccGold)
                                }
                                Text(reply.message)
                                    .font(.caption2)
                                    .foregroundColor(.ccLightText)
                            }
                            Text(Date(timeIntervalSince1970: Double(reply.timestamp)), format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.system(size: 9))
                                .foregroundColor(.ccSubtext)
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
                            let check = ContentFilter.isCleanContent(replyText)
                            guard check.clean else { return }
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
        .alert("Delete Message?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This can't be undone.")
        }
    }
}
