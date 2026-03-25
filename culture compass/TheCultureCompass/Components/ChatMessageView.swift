import SwiftUI
import FirebaseAuth

struct ChatMessageView: View {
    let message: ChatMessage
    let onReply: (String) -> Void
    let onDelete: () -> Void

    @State private var replyText = ""
    @State private var showReplies = false
    @State private var showActions = false
    @State private var showDeleteConfirm = false

    private var isOwner: Bool {
        Auth.auth().currentUser?.uid == message.userId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

            // Instagram-style action bar (shows on long press)
            if showActions {
                HStack(spacing: 0) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showReplies = true
                            showActions = false
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .font(.caption)
                            Text("Reply")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.ccLightText)
                        .frame(maxWidth: .infinity)
                    }

                    if isOwner {
                        Divider()
                            .frame(height: 30)
                            .background(Color.ccSubtext.opacity(0.3))

                        Button {
                            showActions = false
                            showDeleteConfirm = true
                        } label: {
                            VStack(spacing: 3) {
                                Image(systemName: "trash.fill")
                                    .font(.caption)
                                Text("Delete")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                        }
                    }

                    Divider()
                        .frame(height: 30)
                        .background(Color.ccSubtext.opacity(0.3))

                    Button {
                        UIPasteboard.general.string = message.message
                        withAnimation { showActions = false }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.caption)
                            Text("Copy")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.ccLightText)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 8)
                .background(Color.ccDarkBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .ccCard()
        .onLongPressGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            withAnimation(.spring(response: 0.25)) {
                showActions.toggle()
            }
        }
        .onTapGesture {
            if showActions {
                withAnimation(.spring(response: 0.25)) {
                    showActions = false
                }
            }
        }
        .alert("Delete Message?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This can't be undone.")
        }
    }
}
