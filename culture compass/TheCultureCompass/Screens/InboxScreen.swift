import SwiftUI
import FirebaseAuth

struct InboxScreen: View {
    @StateObject private var dmManager = DirectMessageManager()
    @StateObject private var searchManager = UserSearchManager()
    @State private var showNewMessage = false
    @State private var searchQuery = ""
    @State private var navigateConvoId: String?
    @State private var navigateOtherName: String?

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
                    Button { showNewMessage = true } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundColor(.ccGold)
                    }
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
                        Text("Tap the pencil icon to start a conversation")
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

            // Navigate after creating conversation
            if let convoId = navigateConvoId, let name = navigateOtherName {
                NavigationLink(
                    destination: DMChatScreen(conversationId: convoId, otherName: name),
                    isActive: Binding(
                        get: { navigateConvoId != nil },
                        set: { if !$0 { navigateConvoId = nil; navigateOtherName = nil } }
                    )
                ) { EmptyView() }
                .hidden()
            }
        }
        .onAppear { dmManager.startListeningConversations() }
        .onDisappear { dmManager.stopListeningConversations() }
        .sheet(isPresented: $showNewMessage) {
            NewMessageSheet(searchManager: searchManager, searchQuery: $searchQuery) { selectedUser in
                showNewMessage = false
                Task {
                    if let convoId = await dmManager.findOrCreateConversation(with: selectedUser.id ?? "") {
                        navigateConvoId = convoId
                        navigateOtherName = selectedUser.username
                    }
                }
            }
        }
    }
}

// MARK: - New Message Sheet

private struct NewMessageSheet: View {
    @ObservedObject var searchManager: UserSearchManager
    @Binding var searchQuery: String
    let onSelect: (AppUser) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.ccSubtext)
                        TextField("Search by username...", text: $searchQuery)
                            .foregroundColor(.ccLightText)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .onChange(of: searchQuery) {
                                Task { await searchManager.search(query: searchQuery) }
                            }
                    }
                    .padding(10)
                    .background(Color.ccCardBg)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(searchManager.results) { user in
                                Button {
                                    onSelect(user)
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(Color.ccBrown)
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Text(String(user.username.prefix(1)).uppercased())
                                                    .font(.headline.bold())
                                                    .foregroundColor(.ccGold)
                                            )
                                        Text(user.username)
                                            .font(.subheadline.bold())
                                            .foregroundColor(.ccLightText)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ccGold)
                }
            }
        }
    }
}

// MARK: - Convo Row

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
