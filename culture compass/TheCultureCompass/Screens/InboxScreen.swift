import SwiftUI
import FirebaseAuth

struct InboxScreen: View {
    @StateObject private var dmManager = DirectMessageManager()
    @State private var showNewMessage = false

    private var uid: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Messages")
                        .font(.system(size: 28, weight: .bold, design: .serif))
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
                    .refreshable {
                        dmManager.stopListeningConversations()
                        dmManager.startListeningConversations()
                    }
                }
            }
        }
        .onAppear { dmManager.startListeningConversations() }
        .sheet(isPresented: $showNewMessage) {
            NewMessageSheet(dmManager: dmManager)
        }
    }
}

// MARK: - New Message Sheet

private struct NewMessageSheet: View {
    @ObservedObject var dmManager: DirectMessageManager
    @StateObject private var searchManager = UserSearchManager()
    @StateObject private var profileManager = UserProfileManager()
    @State private var searchQuery = ""
    @State private var friends: [AppUser] = []
    @State private var navigateConvoId: String?
    @State private var navigateOtherName: String?
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
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Show friends first when not searching
                            if searchQuery.isEmpty && !friends.isEmpty {
                                Text("FRIENDS")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.ccSubtext)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                    .padding(.bottom, 4)

                                ForEach(friends) { user in
                                    UserRow(user: user) { selectUser(user) }
                                }
                            }

                            // Search results
                            if !searchQuery.isEmpty {
                                ForEach(searchManager.results) { user in
                                    UserRow(user: user) { selectUser(user) }
                                }
                            }
                        }
                    }
                }

                if let convoId = navigateConvoId, let name = navigateOtherName {
                    NavigationLink(
                        destination: DMChatScreen(conversationId: convoId, otherName: name),
                        isActive: Binding(
                            get: { navigateConvoId != nil },
                            set: { if !$0 { navigateConvoId = nil; navigateOtherName = nil; dismiss() } }
                        )
                    ) { EmptyView() }
                    .hidden()
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
            .task {
                await profileManager.loadProfile()
                friends = await profileManager.loadFriends()
            }
        }
    }

    private func selectUser(_ user: AppUser) {
        Task {
            if let convoId = await dmManager.findOrCreateConversation(with: user.id ?? "") {
                navigateConvoId = convoId
                navigateOtherName = user.username
            }
        }
    }
}

private struct UserRow: View {
    let user: AppUser
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
