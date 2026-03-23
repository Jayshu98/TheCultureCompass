import SwiftUI

struct GroupMessagesScreen: View {
    @StateObject private var roomsManager = RoomsDataManager()
    @StateObject private var searchManager = UserSearchManager()
    @StateObject private var profileManager = UserProfileManager()
    @State private var showCreateRoom = false
    @State private var roomName = ""
    @State private var searchQuery = ""
    @State private var selectedUserIds: Set<String> = []
    @State private var friends: [AppUser] = []

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Group Messages")
                        .font(.title.bold())
                        .foregroundColor(.ccGold)
                    Spacer()
                    Button { showCreateRoom = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.ccGold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if roomsManager.isLoading && roomsManager.rooms.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else if roomsManager.rooms.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.ccBrown)
                        Text("No group chats yet")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                        Text("Tap + to start one")
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(roomsManager.rooms) { room in
                                NavigationLink(destination: GroupChatScreen(room: room)) {
                                    RoomRow(room: room)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }

            // Create room overlay
            if showCreateRoom {
                ZStack {
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .onTapGesture { showCreateRoom = false }

                    ScrollView {
                        VStack(spacing: 16) {
                            Text("New Group Chat")
                                .font(.headline)
                                .foregroundColor(.ccGold)

                            TextField("Group name...", text: $roomName)
                                .padding()
                                .background(Color.ccDarkBg)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.ccLightText)

                            // Friends section
                            if !friends.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.2.fill")
                                            .font(.caption)
                                            .foregroundColor(.ccGold)
                                        Text("Your Friends")
                                            .font(.caption.bold())
                                            .foregroundColor(.ccGold)
                                    }

                                    ForEach(friends) { friend in
                                        UserSelectRow(
                                            user: friend,
                                            isSelected: friend.id.map { selectedUserIds.contains($0) } ?? false
                                        ) {
                                            if let uid = friend.id {
                                                if selectedUserIds.contains(uid) {
                                                    selectedUserIds.remove(uid)
                                                } else {
                                                    selectedUserIds.insert(uid)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.ccCardBg.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            // Search for other users
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.caption)
                                        .foregroundColor(.ccSubtext)
                                    Text("Search All Users")
                                        .font(.caption.bold())
                                        .foregroundColor(.ccSubtext)
                                }

                                TextField("Search by username...", text: $searchQuery)
                                    .padding()
                                    .background(Color.ccDarkBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .foregroundColor(.ccLightText)
                                    .onChange(of: searchQuery) { _, newValue in
                                        Task { await searchManager.search(query: newValue) }
                                    }

                                if !searchManager.results.isEmpty {
                                    let filtered = searchManager.results.filter { user in
                                        !friends.contains(where: { $0.id == user.id })
                                    }
                                    ForEach(filtered) { user in
                                        UserSelectRow(
                                            user: user,
                                            isSelected: user.id.map { selectedUserIds.contains($0) } ?? false
                                        ) {
                                            if let uid = user.id {
                                                if selectedUserIds.contains(uid) {
                                                    selectedUserIds.remove(uid)
                                                } else {
                                                    selectedUserIds.insert(uid)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            if !selectedUserIds.isEmpty {
                                Text("\(selectedUserIds.count) user(s) selected")
                                    .font(.caption)
                                    .foregroundColor(.ccGold)
                            }

                            HStack {
                                Button("Cancel") {
                                    showCreateRoom = false
                                    searchQuery = ""
                                    selectedUserIds = []
                                }
                                .foregroundColor(.ccSubtext)
                                Spacer()
                                Button("Create") {
                                    Task {
                                        await roomsManager.createRoom(
                                            name: roomName,
                                            participantIds: Array(selectedUserIds)
                                        )
                                        roomName = ""
                                        searchQuery = ""
                                        selectedUserIds = []
                                        showCreateRoom = false
                                    }
                                }
                                .buttonStyle(CCButtonStyle())
                                .disabled(roomName.trimmingCharacters(in: .whitespaces).isEmpty)
                            }
                        }
                        .padding(24)
                        .background(LinearGradient.ccCard)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.6), radius: 20)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 60)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showCreateRoom)
        .onAppear {
            roomsManager.startListeningRooms()
            Task {
                await profileManager.loadProfile()
                friends = await profileManager.loadFriends()
            }
        }
        .onDisappear { roomsManager.stopListeningRooms() }
    }
}

// MARK: - Components

private struct UserSelectRow: View {
    let user: AppUser
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if !user.profileImageURL.isEmpty {
                AsyncImage(url: URL(string: user.profileImageURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(Color.ccBrown)
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.ccBrown)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(user.username.prefix(1)).uppercased())
                            .font(.caption2.bold())
                            .foregroundColor(.ccGold)
                    )
            }

            Text(user.username)
                .font(.subheadline)
                .foregroundColor(.ccLightText)

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .ccGold : .ccSubtext)
                .font(.title3)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

private struct RoomRow: View {
    let room: ChatRoom

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(LinearGradient.ccGoldShimmer)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(.black)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(room.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.ccLightText)
                HStack(spacing: 4) {
                    if !room.lastMessage.isEmpty {
                        Text(room.lastMessage)
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                            .lineLimit(1)
                    } else {
                        Text("\(room.participants.count) members")
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                    Text(room.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.ccSubtext)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.ccSubtext)
        }
        .padding()
        .background(LinearGradient.ccCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
