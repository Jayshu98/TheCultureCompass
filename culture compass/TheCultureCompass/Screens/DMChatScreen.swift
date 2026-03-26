import SwiftUI
import FirebaseAuth

struct DMChatScreen: View {
    let conversationId: String
    let otherName: String
    var otherUserId: String = ""

    @StateObject private var dmManager = DirectMessageManager()
    @State private var messageText = ""
    @State private var contentWarning: String?
    @State private var profileNavUserId: String?
    @FocusState private var isInputFocused: Bool

    private var uid: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Auto-delete warning
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("Messages disappear after 24 hours")
                        .font(.system(size: 11))
                }
                .foregroundColor(.ccGold.opacity(0.7))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.ccGold.opacity(0.08))

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(dmManager.messages) { msg in
                                DMBubble(message: msg, isMe: msg.senderId == uid) {
                                    profileNavUserId = msg.senderId
                                }
                                .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: dmManager.messages.count) {
                        if let last = dmManager.messages.last?.id {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }

                // Input bar
                VStack(spacing: 4) {
                    if let contentWarning {
                        Text(contentWarning)
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                    HStack(spacing: 10) {
                        TextField("Message...", text: $messageText)
                            .padding(10)
                            .background(Color.ccCardBg)
                            .clipShape(Capsule())
                            .foregroundColor(.ccLightText)
                            .focused($isInputFocused)

                        Button {
                            let text = messageText.trimmingCharacters(in: .whitespaces)
                            guard !text.isEmpty else { return }
                            let check = ContentFilter.isCleanContent(text)
                            if !check.clean {
                                contentWarning = check.reason
                                return
                            }
                            contentWarning = nil
                            messageText = ""
                            Task { await dmManager.sendMessage(text, conversationId: conversationId) }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.ccGold)
                                .frame(width: 40, height: 40)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.ccDarkBg)
            }
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Find the other user's ID from messages or otherUserId
                    if !otherUserId.isEmpty {
                        profileNavUserId = otherUserId
                    } else if let msg = dmManager.messages.first(where: { $0.senderId != uid }) {
                        profileNavUserId = msg.senderId
                    }
                } label: {
                    Image(systemName: "person.circle")
                        .foregroundColor(.ccGold)
                }
            }
        }
        .navigationDestination(item: $profileNavUserId) { userId in
            UserPassportScreen(userId: userId)
        }
        .onAppear { dmManager.startListeningMessages(conversationId: conversationId) }
        .onDisappear { dmManager.stopListeningMessages() }
    }
}

private struct DMBubble: View {
    let message: DirectMessage
    let isMe: Bool
    let onTapProfile: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer() }

            if !isMe {
                Button(action: onTapProfile) {
                    Circle()
                        .fill(Color.ccBrown)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(message.senderName.prefix(1)).uppercased())
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.ccGold)
                        )
                }
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                Text(message.text)
                    .font(.subheadline)
                    .foregroundColor(isMe ? .black : .ccLightText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(isMe ? Color.ccGold : Color.ccCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.timestamp, format: .dateTime.hour().minute())
                    .font(.system(size: 9))
                    .foregroundColor(.ccSubtext)
            }

            if !isMe { Spacer() }
        }
    }
}
