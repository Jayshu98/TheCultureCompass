import SwiftUI
import Kingfisher
import FirebaseAuth
import FirebaseFirestore

struct UserPassportScreen: View {
    let userId: String
    @State private var user: AppUser?
    @State private var isLoading = true
    @State private var selectedPhoto: String?
    @State private var isFriend = false
    @State private var friendActionLoading = false
    @State private var dmConversationId: String?
    @State private var navigateToDM = false
    @State private var friendsList: [AppUser] = []
    @State private var isBlocked = false
    @State private var showBlockConfirm = false

    private let db = Firestore.firestore()
    private let dmManager = DirectMessageManager()

    static let passportBrown = Color(red: 0.35, green: 0.18, blue: 0.08)
    static let passportGold = Color(red: 0.82, green: 0.68, blue: 0.21)
    static let pageColor = Color(red: 0.95, green: 0.92, blue: 0.86)
    static let stampPageColor = Color(red: 0.93, green: 0.89, blue: 0.82)

    private var isOwnProfile: Bool {
        Auth.auth().currentUser?.uid == userId
    }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToDM) {
            DMChatScreen(conversationId: dmConversationId ?? "", otherName: user?.username ?? "")
        }
        .fullScreenCover(item: $selectedPhoto) { url in
            ZoomableImageView(url: url, location: nil)
        }
        .task {
            await loadUser()
            await checkFriendship()
            await checkBlocked()
            await loadFriends()
        }
        .alert(isBlocked ? "Unblock User?" : "Block User?", isPresented: $showBlockConfirm) {
            Button("Cancel", role: .cancel) {}
            Button(isBlocked ? "Unblock" : "Block", role: .destructive) {
                Task { await toggleBlock() }
            }
        } message: {
            Text(isBlocked ? "They will be able to see your profile again." : "They won't be able to message you.")
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView().tint(.ccGold)
        } else if let user {
            ScrollView {
                VStack(spacing: 20) {
                    PassportCoverSection(username: user.username)
                    identificationPage(user: user)
                    if !user.visitedCountries.isEmpty {
                        StampsPage(countries: user.visitedCountries)
                    }
                    if !user.scrapbookPhotos.isEmpty {
                        ScrapbookPage(photos: user.scrapbookPhotos, selectedPhoto: $selectedPhoto)
                    }
                    if !user.friends.isEmpty {
                        FriendsPage(friends: friendsList, count: user.friends.count)
                    }
                }
                .padding(.bottom, 40)
            }
        } else {
            Text("User not found").foregroundColor(.ccSubtext)
        }
    }

    private func identificationPage(user: AppUser) -> some View {
        let brown = Self.passportBrown
        let gold = Self.passportGold
        let page = Self.pageColor

        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("IDENTIFICATION")
                    .font(.system(size: 8, weight: .bold, design: .serif))
                    .tracking(3)
                    .foregroundColor(brown.opacity(0.4))
                Spacer()
                Text("P1")
                    .font(.system(size: 8, weight: .light, design: .serif))
                    .foregroundColor(brown.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Photo + fields
            HStack(alignment: .top, spacing: 16) {
                UserPhotoView(url: user.profileImageURL, initial: user.username)
                VStack(alignment: .leading, spacing: 8) {
                    UserPassportField(label: "SURNAME / NAME", value: user.username.uppercased())
                    UserPassportField(label: "COUNTRIES VISITED", value: "\(user.visitedCountries.count)")
                    UserPassportField(label: "PHOTOS", value: "\(user.scrapbookPhotos.count)")
                    UserPassportField(label: "FRIENDS", value: "\(user.friends.count)")
                }
            }
            .padding(16)

            // Bio
            if !user.bio.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("PERSONAL STATEMENT")
                        .font(.system(size: 7, weight: .bold, design: .serif))
                        .tracking(2)
                        .foregroundColor(brown.opacity(0.4))
                    Text(user.bio)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(brown.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }

            // Action buttons
            if !isOwnProfile {
                actionButtons(user: user)
            }

            // MRZ
            Text("P<CULTURECOMPASS<<\(user.username.uppercased().replacingOccurrences(of: " ", with: "<"))<<<<<<<<<<<<")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(brown.opacity(0.2))
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(page).shadow(color: .black.opacity(0.3), radius: 6, y: 3))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(brown.opacity(0.15), lineWidth: 0.5))
        .padding(.horizontal)
    }

    @ViewBuilder
    private func actionButtons(user: AppUser) -> some View {
        let brown = Self.passportBrown
        let gold = Self.passportGold

        // Friend button
        Button {
            friendActionLoading = true
            Task {
                if isFriend { await removeFriend() } else { await addFriend() }
                friendActionLoading = false
            }
        } label: {
            HStack(spacing: 6) {
                if friendActionLoading {
                    ProgressView().scaleEffect(0.7).tint(isFriend ? .red : .white)
                } else {
                    Image(systemName: isFriend ? "person.badge.minus" : "person.badge.plus")
                    Text(isFriend ? "Remove Friend" : "Add Friend")
                }
            }
            .font(.system(size: 11, weight: .bold, design: .serif))
            .foregroundColor(isFriend ? .red : .white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isFriend ? Color.red.opacity(0.1) : brown)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isFriend ? Color.red.opacity(0.3) : gold.opacity(0.3), lineWidth: 0.5))
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
        .disabled(friendActionLoading)

        Button {
            Task {
                dmConversationId = await dmManager.findOrCreateConversation(with: userId)
                if dmConversationId != nil { navigateToDM = true }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "envelope.fill")
                Text("Message")
            }
            .font(.system(size: 11, weight: .bold, design: .serif))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(gold.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(gold.opacity(0.3), lineWidth: 0.5))
        }
        .padding(.horizontal, 16).padding(.bottom, 8)

        // Block button
        Button { showBlockConfirm = true } label: {
            HStack(spacing: 6) {
                Image(systemName: isBlocked ? "hand.raised.slash" : "hand.raised.fill")
                Text(isBlocked ? "Unblock" : "Block User")
            }
            .font(.system(size: 11, weight: .bold, design: .serif))
            .foregroundColor(isBlocked ? .orange : .red.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.red.opacity(0.2), lineWidth: 0.5))
        }
        .padding(.horizontal, 16).padding(.bottom, 12)
    }

    // MARK: - Data

    private func loadUser() async {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            user = try doc.data(as: AppUser.self)
        } catch { user = nil }
        isLoading = false
    }

    private func checkFriendship() async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        do {
            let doc = try await db.collection("users").document(myUid).getDocument()
            let friends = doc.data()?["friends"] as? [String] ?? []
            isFriend = friends.contains(userId)
        } catch {}
    }

    private func addFriend() async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(myUid).updateData(["friends": FieldValue.arrayUnion([userId])])
            try await db.collection("users").document(userId).updateData(["friends": FieldValue.arrayUnion([myUid])])
            isFriend = true
        } catch {}
    }

    private func removeFriend() async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(myUid).updateData(["friends": FieldValue.arrayRemove([userId])])
            try await db.collection("users").document(userId).updateData(["friends": FieldValue.arrayRemove([myUid])])
            isFriend = false
        } catch {}
    }

    private func loadFriends() async {
        guard let user else { return }
        var loaded: [AppUser] = []
        for friendId in user.friends {
            if let doc = try? await db.collection("users").document(friendId).getDocument(),
               let friend = try? doc.data(as: AppUser.self) {
                loaded.append(friend)
            }
        }
        friendsList = loaded
    }

    private func checkBlocked() async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        if let doc = try? await db.collection("users").document(myUid).getDocument() {
            let blocked = doc.data()?["blockedUsers"] as? [String] ?? []
            isBlocked = blocked.contains(userId)
        }
    }

    private func toggleBlock() async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        if isBlocked {
            try? await db.collection("users").document(myUid).updateData(["blockedUsers": FieldValue.arrayRemove([userId])])
            isBlocked = false
        } else {
            try? await db.collection("users").document(myUid).updateData(["blockedUsers": FieldValue.arrayUnion([userId])])
            try? await db.collection("users").document(myUid).updateData(["friends": FieldValue.arrayRemove([userId])])
            try? await db.collection("users").document(userId).updateData(["friends": FieldValue.arrayRemove([myUid])])
            isBlocked = true
            isFriend = false
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

struct IdentifiableString: Identifiable {
    let id: String
    var value: String { id }
}

// MARK: - Sub Views

private struct PassportCoverSection: View {
    let username: String
    private let brown = UserPassportScreen.passportBrown
    private let gold = UserPassportScreen.passportGold

    var body: some View {
        VStack(spacing: 12) {
            Rectangle().fill(gold.opacity(0.4)).frame(height: 1).padding(.horizontal, 40)
            Text("PASSPORT")
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(5).foregroundColor(gold.opacity(0.7))
            ZStack {
                Circle().stroke(gold.opacity(0.3), lineWidth: 1.5).frame(width: 60, height: 60)
                Text("🌍").font(.system(size: 28))
            }
            Text(username.uppercased())
                .font(.system(size: 9, weight: .bold, design: .serif))
                .tracking(3).foregroundColor(gold.opacity(0.6))
            Rectangle().fill(gold.opacity(0.4)).frame(height: 1).padding(.horizontal, 40)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 8).fill(brown).shadow(color: .black.opacity(0.5), radius: 10, y: 5))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(gold.opacity(0.3), lineWidth: 1))
        .padding(.horizontal).padding(.top, 8)
    }
}

private struct UserPhotoView: View {
    let url: String
    let initial: String
    private let brown = UserPassportScreen.passportBrown

    var body: some View {
        if !url.isEmpty {
            KFImage(URL(string: url))
                .placeholder { Color(red: 0.88, green: 0.85, blue: 0.78) }
                .fade(duration: 0.25)
                .resizable()
                .aspectRatio(contentMode: .fill)
            .frame(width: 90, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(brown.opacity(0.3), lineWidth: 1))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.5))
                .frame(width: 90, height: 110)
                .overlay(
                    Text(String(initial.prefix(1)).uppercased())
                        .font(.title.bold()).foregroundColor(brown.opacity(0.4))
                )
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(brown.opacity(0.3), lineWidth: 1))
        }
    }
}

private struct StampsPage: View {
    let countries: [String]
    private let brown = UserPassportScreen.passportBrown
    private let page = UserPassportScreen.stampPageColor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("VISAS & STAMPS").font(.system(size: 8, weight: .bold, design: .serif)).tracking(3).foregroundColor(brown.opacity(0.4))
                Spacer()
                Text("P2").font(.system(size: 8, weight: .light, design: .serif)).foregroundColor(brown.opacity(0.3))
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 14) {
                ForEach(countries, id: \.self) { code in
                    if let country = Country.all.first(where: { $0.code == code }) {
                        UserStampView(country: country)
                    }
                }
            }
            .padding(16)
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(page).shadow(color: .black.opacity(0.3), radius: 6, y: 3))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(brown.opacity(0.15), lineWidth: 0.5))
        .padding(.horizontal)
    }
}

private struct ScrapbookPage: View {
    let photos: [String]
    @Binding var selectedPhoto: String?
    private let brown = UserPassportScreen.passportBrown
    private let page = UserPassportScreen.pageColor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("TRAVEL MEMORIES").font(.system(size: 8, weight: .bold, design: .serif)).tracking(3).foregroundColor(brown.opacity(0.4))
                Spacer()
                Text("P3").font(.system(size: 8, weight: .light, design: .serif)).foregroundColor(brown.opacity(0.3))
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(photos, id: \.self) { url in
                    KFImage(URL(string: url))
                        .placeholder { Color(red: 0.88, green: 0.85, blue: 0.78) }
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(brown.opacity(0.15), lineWidth: 0.5))
                    .shadow(color: brown.opacity(0.15), radius: 3, y: 2)
                    .onTapGesture { selectedPhoto = url }
                }
            }
            .padding(.horizontal, 16).padding(.bottom, 16)
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(page).shadow(color: .black.opacity(0.3), radius: 6, y: 3))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(brown.opacity(0.15), lineWidth: 0.5))
        .padding(.horizontal)
    }
}

private struct FriendsPage: View {
    let friends: [AppUser]
    let count: Int
    private let brown = UserPassportScreen.passportBrown
    private let page = UserPassportScreen.pageColor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("FRIENDS").font(.system(size: 8, weight: .bold, design: .serif)).tracking(3).foregroundColor(brown.opacity(0.4))
                Spacer()
                Text("\(count)").font(.system(size: 10, weight: .bold, design: .serif)).foregroundColor(brown.opacity(0.5))
                Text("P4").font(.system(size: 8, weight: .light, design: .serif)).foregroundColor(brown.opacity(0.3)).padding(.leading, 8)
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 8)

            if friends.isEmpty {
                ProgressView().tint(brown).frame(maxWidth: .infinity).padding(.vertical, 16)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(friends) { friend in
                        NavigationLink(destination: UserPassportScreen(userId: friend.id ?? "")) {
                            HStack(spacing: 10) {
                                Circle().fill(brown.opacity(0.2)).frame(width: 32, height: 32)
                                    .overlay(Text(String(friend.username.prefix(1)).uppercased()).font(.caption.bold()).foregroundColor(brown.opacity(0.7)))
                                Text(friend.username).font(.system(size: 12, weight: .medium, design: .serif)).foregroundColor(brown.opacity(0.8))
                                Spacer()
                                Text("\(friend.visitedCountries.count) countries").font(.system(size: 9, design: .serif)).foregroundColor(brown.opacity(0.4))
                                Image(systemName: "chevron.right").font(.system(size: 9)).foregroundColor(brown.opacity(0.3))
                            }
                            .padding(.horizontal, 16).padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 12)
            }
        }
        .background(RoundedRectangle(cornerRadius: 6).fill(page).shadow(color: .black.opacity(0.3), radius: 6, y: 3))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(brown.opacity(0.15), lineWidth: 0.5))
        .padding(.horizontal)
    }
}

private struct UserPassportField: View {
    let label: String
    let value: String
    private let brown = UserPassportScreen.passportBrown

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.system(size: 7, weight: .bold, design: .serif)).tracking(1).foregroundColor(brown.opacity(0.35))
            Text(value).font(.system(size: 12, weight: .medium, design: .serif)).foregroundColor(brown.opacity(0.8))
            Rectangle().fill(brown.opacity(0.1)).frame(height: 0.5)
        }
    }
}

private struct UserStampView: View {
    let country: Country
    private let brown = UserPassportScreen.passportBrown

    private var rotation: Double {
        Double(country.name.count % 7) * 5 - 15
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(country.flag).font(.system(size: 28))
            Text(country.name.uppercased()).font(.system(size: 8, weight: .bold, design: .serif)).tracking(1).foregroundColor(brown.opacity(0.7))
            Text("APPROVED").font(.system(size: 6, weight: .bold, design: .monospaced)).foregroundColor(.green.opacity(0.6))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.4)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(brown.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
        .rotationEffect(.degrees(rotation))
    }
}
