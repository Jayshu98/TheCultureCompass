import SwiftUI
import FirebaseAuth

struct GroupChatScreen: View {
    let room: ChatRoom
    @StateObject private var roomsManager = RoomsDataManager()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool

    private var currentUid: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Messages
                if roomsManager.isLoading && roomsManager.messages.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else if roomsManager.messages.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 36))
                            .foregroundColor(.ccBrown)
                        Text("Start the conversation")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(roomsManager.messages) { msg in
                                    GroupBubble(
                                        message: msg,
                                        isMe: msg.userId == currentUid
                                    )
                                    .id(msg.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: roomsManager.messages.count) { _, _ in
                            if let last = roomsManager.messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Input bar
                HStack(spacing: 10) {
                    TextField("Message...", text: $messageText)
                        .padding(10)
                        .background(Color.ccCardBg)
                        .clipShape(Capsule())
                        .foregroundColor(.ccLightText)
                        .focused($isInputFocused)

                    Button {
                        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty,
                              let roomId = room.id else { return }
                        let text = messageText
                        messageText = ""
                        Task { await roomsManager.sendGroupMessage(roomId: roomId, text: text) }
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundColor(.ccGold)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.ccDarkBg)
            }
        }
        .navigationTitle(room.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if let roomId = room.id {
                roomsManager.startListeningMessages(roomId: roomId)
            }
        }
        .onDisappear { roomsManager.stopListeningMessages() }
    }
}

private struct GroupBubble: View {
    let message: GroupMessage
    let isMe: Bool

    var body: some View {
        HStack {
            if isMe { Spacer() }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 3) {
                if !isMe {
                    Text(message.user)
                        .font(.caption2.bold())
                        .foregroundColor(.ccGold)
                }
                Text(message.message)
                    .font(.subheadline)
                    .foregroundColor(isMe ? .black : .ccLightText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(isMe ? LinearGradient.ccGoldShimmer : LinearGradient.ccCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundColor(.ccSubtext)
            }
            if !isMe { Spacer() }
        }
    }
}
