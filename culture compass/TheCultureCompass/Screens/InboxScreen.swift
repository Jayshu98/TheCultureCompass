import SwiftUI
import FirebaseAuth

struct InboxScreen: View {
    @StateObject private var dmManager = DirectMessageManager()

    private var uid: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Messages")
                        .font(.title.bold())
                        .foregroundColor(.ccGold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if dmManager.isLoading && dmManager.conversations.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else if dmManager.conversations.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.open")
                            .font(.system(size: 40))
                            .foregroundColor(.ccSubtext.opacity(0.4))
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                        Text("Visit someone's profile to start a conversation")
                            .font(.caption)
                            .foregroundColor(.ccSubtext.opacity(0.6))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(dmManager.conversations) { convo in
                                if let uid {
                                    let otherName = convo.participantNames.first(where: { $0.key != uid })?.value ?? "User"
                                    NavigationLink(destination: DMChatScreen(conversationId: convo.id ?? "", otherName: otherName)) {
                                        ConvoRow(name: otherName, lastMessage: convo.lastMessage, timestamp: convo.lastTimestamp)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear { dmManager.startListeningConversations() }
        .onDisappear { dmManager.stopListeningConversations() }
    }
}

private struct ConvoRow: View {
    let name: String
    let lastMessage: String
    let timestamp: Date

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.ccBrown)
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(name.prefix(1)).uppercased())
                        .font(.headline.bold())
                        .foregroundColor(.ccGold)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.bold())
                    .foregroundColor(.ccLightText)
                Text(lastMessage.isEmpty ? "New conversation" : lastMessage)
                    .font(.caption)
                    .foregroundColor(.ccSubtext)
                    .lineLimit(1)
            }

            Spacer()

            Text(timestamp, format: .dateTime.month(.abbreviated).day())
                .font(.system(size: 10))
                .foregroundColor(.ccSubtext)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.ccCardBg.opacity(0.3))
    }
}
