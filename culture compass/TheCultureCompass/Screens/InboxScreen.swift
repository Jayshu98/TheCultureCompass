import SwiftUI
import FirebaseAuth

struct InboxScreen: View {
    @StateObject private var dmManager = DirectMessageManager()
    @State private var showNewMessage = false

    private var uid: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        ZStack {
            Color.ccDarkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Messages")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.ccLightText)
                        if !dmManager.conversations.isEmpty {
                            Text("\(dmManager.conversations.count) conversation\(dmManager.conversations.count == 1 ? "" : "s")")
                                .font(.system(size: 13))
                                .foregroundColor(.ccSubtext)
                        }
                    }
                    Spacer()
                    Button { showNewMessage = true } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundStyle(LinearGradient.ccGoldShimmer)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 14)

                // Gold accent line
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, .ccGold.opacity(0.4), .ccGold.opacity(0.6), .ccGold.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)

                // ── Content ──
                if dmManager.isLoading && dmManager.conversations.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.ccGold)
                            .scaleEffect(1.2)
                        Text("Loading messages...")
                            .font(.system(size: 14))
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else if dmManager.conversations.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(LinearGradient.ccGoldShimmer)
                        Text("No messages yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.ccLightText)
                        Text("Start a conversation with someone")
                            .font(.system(size: 14))
                            .foregroundColor(.ccSubtext)
                        Button {
                            showNewMessage = true
                        } label: {
                            Text("New Message")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(LinearGradient.ccGoldShimmer)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(dmManager.conversations) { convo in
                            if let uid {
                                let otherName = convo.participantNames.first(where: { $0.key != uid })?.value ?? "User"
                                let otherUserId = convo.participants.first(where: { $0 != uid }) ?? ""
                                NavigationLink(destination: DMChatScreen(conversationId: convo.id ?? "", otherName: otherName, otherUserId: otherUserId)) {
                                    ConvoRow(name: otherName, lastMessage: convo.lastMessage, timestamp: convo.lastTimestamp)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        guard let id = convo.id else { return }
                                        Task { await dmManager.deleteConversation(id) }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
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


// MARK: - Conversation Row

private struct ConvoRow: View {
    let name: String
    let lastMessage: String
    let timestamp: Date

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        if interval < 604800 { return "\(Int(interval / 86400))d" }
        return timestamp.formatted(.dateTime.month(.abbreviated).day())
    }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar with gradient ring
            ZStack {
                Circle()
                    .strokeBorder(LinearGradient.ccGoldShimmer, lineWidth: 2)
                    .frame(width: 52, height: 52)
                Circle()
                    .fill(Color.ccCardBg)
                    .frame(width: 46, height: 46)
                    .overlay(
                        Text(String(name.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.ccGold)
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.ccLightText)
                    Spacer()
                    Text(timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.ccSubtext)
                }
                Text(lastMessage.isEmpty ? "New conversation" : lastMessage)
                    .font(.system(size: 14))
                    .foregroundColor(.ccSubtext)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color.ccCardBg.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
