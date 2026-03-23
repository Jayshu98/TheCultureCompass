import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserPassportScreen: View {
    let userId: String
    @State private var user: AppUser?
    @State private var isLoading = true
    @State private var selectedPhoto: String?
    @State private var isFriend = false
    @State private var friendActionLoading = false

    private let db = Firestore.firestore()
    private let passportBrown = Color(red: 0.35, green: 0.18, blue: 0.08)
    private let passportGold = Color(red: 0.82, green: 0.68, blue: 0.21)
    private let pageColor = Color(red: 0.95, green: 0.92, blue: 0.86)
    private let stampPageColor = Color(red: 0.93, green: 0.89, blue: 0.82)

    private var isOwnProfile: Bool {
        Auth.auth().currentUser?.uid == userId
    }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.ccGold)
            } else if let user {
                ScrollView {
                    VStack(spacing: 20) {
                        // ═══════════════════════════════
                        // PASSPORT COVER
                        // ═══════════════════════════════
                        VStack(spacing: 12) {
                            Rectangle()
                                .fill(passportGold.opacity(0.4))
                                .frame(height: 1)
                                .padding(.horizontal, 40)

                            Text("PASSPORT")
                                .font(.system(size: 10, weight: .bold, design: .serif))
                                .tracking(5)
                                .foregroundColor(passportGold.opacity(0.7))

                            ZStack {
                                Circle()
                                    .stroke(passportGold.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 60, height: 60)
                                Text("🌍")
                                    .font(.system(size: 28))
                            }

                            Text(user.username.uppercased())
                                .font(.system(size: 9, weight: .bold, design: .serif))
                                .tracking(3)
                                .foregroundColor(passportGold.opacity(0.6))

                            Rectangle()
                                .fill(passportGold.opacity(0.4))
                                .frame(height: 1)
                                .padding(.horizontal, 40)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(passportBrown)
                                .shadow(color: .black.opacity(0.5), radius: 10, y: 5)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(passportGold.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)

                        // ═══════════════════════════════
                        // PAGE 1: IDENTIFICATION
                        // ═══════════════════════════════
                        VStack(spacing: 0) {
                            HStack {
                                Text("IDENTIFICATION")
                                    .font(.system(size: 8, weight: .bold, design: .serif))
                                    .tracking(3)
                                    .foregroundColor(passportBrown.opacity(0.4))
                                Spacer()
                                Text("P1")
                                    .font(.system(size: 8, weight: .light, design: .serif))
                                    .foregroundColor(passportBrown.opacity(0.3))
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 12)

                            HStack(alignment: .top, spacing: 16) {
                                // Photo
                                if !user.profileImageURL.isEmpty {
                                    AsyncImage(url: URL(string: user.profileImageURL)) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ProgressView().tint(passportBrown)
                                    }
                                    .frame(width: 90, height: 110)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(passportBrown.opacity(0.3), lineWidth: 1)
                                    )
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.5))
                                        .frame(width: 90, height: 110)
                                        .overlay(
                                            Text(String(user.username.prefix(1)).uppercased())
                                                .font(.title.bold())
                                                .foregroundColor(passportBrown.opacity(0.4))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(passportBrown.opacity(0.3), lineWidth: 1)
                                        )
                                }

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
                                        .foregroundColor(passportBrown.opacity(0.4))
                                    Text(user.bio)
                                        .font(.system(size: 12, design: .serif))
                                        .foregroundColor(passportBrown.opacity(0.8))
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                            }

                            // Friend button
                            if !isOwnProfile {
                                Button {
                                    friendActionLoading = true
                                    Task {
                                        if isFriend {
                                            await removeFriend()
                                        } else {
                                            await addFriend()
                                        }
                                        friendActionLoading = false
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        if friendActionLoading {
                                            ProgressView()
                                                .scaleEffect(0.7)
                                                .tint(isFriend ? .red : .white)
                                        } else {
                                            Image(systemName: isFriend ? "person.badge.minus" : "person.badge.plus")
                                            Text(isFriend ? "Remove Friend" : "Add Friend")
                                        }
                                    }
                                    .font(.system(size: 11, weight: .bold, design: .serif))
                                    .foregroundColor(isFriend ? .red : .white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isFriend ? Color.red.opacity(0.1) : passportBrown)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(isFriend ? Color.red.opacity(0.3) : passportGold.opacity(0.3), lineWidth: 0.5)
                                    )
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 12)
                                .disabled(friendActionLoading)
                            }

                            // MRZ
                            Text("P<CULTURECOMPASS<<\(user.username.uppercased().replacingOccurrences(of: " ", with: "<"))<<<<<<<<<<<<")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(passportBrown.opacity(0.2))
                                .lineLimit(1)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 10)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(pageColor)
                                .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(passportBrown.opacity(0.15), lineWidth: 0.5)
                        )
                        .padding(.horizontal)

                        // ═══════════════════════════════
                        // PAGE 2: VISA STAMPS
                        // ═══════════════════════════════
                        if !user.visitedCountries.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Text("VISAS & STAMPS")
                                        .font(.system(size: 8, weight: .bold, design: .serif))
                                        .tracking(3)
                                        .foregroundColor(passportBrown.opacity(0.4))
                                    Spacer()
                                    Text("P2")
                                        .font(.system(size: 8, weight: .light, design: .serif))
                                        .foregroundColor(passportBrown.opacity(0.3))
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 8)

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 12)], spacing: 14) {
                                    ForEach(user.visitedCountries, id: \.self) { code in
                                        if let country = Country.all.first(where: { $0.code == code }) {
                                            UserStampView(country: country)
                                        }
                                    }
                                }
                                .padding(16)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(stampPageColor)
                                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(passportBrown.opacity(0.15), lineWidth: 0.5)
                            )
                            .padding(.horizontal)
                        }

                        // ═══════════════════════════════
                        // PAGE 3: SCRAPBOOK
                        // ═══════════════════════════════
                        if !user.scrapbookPhotos.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                HStack {
                                    Text("TRAVEL MEMORIES")
                                        .font(.system(size: 8, weight: .bold, design: .serif))
                                        .tracking(3)
                                        .foregroundColor(passportBrown.opacity(0.4))
                                    Spacer()
                                    Text("P3")
                                        .font(.system(size: 8, weight: .light, design: .serif))
                                        .foregroundColor(passportBrown.opacity(0.3))
                                }
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 8)

                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8),
                                    GridItem(.flexible(), spacing: 8)
                                ], spacing: 8) {
                                    ForEach(user.scrapbookPhotos, id: \.self) { url in
                                        AsyncImage(url: URL(string: url)) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color(red: 0.88, green: 0.85, blue: 0.78)
                                        }
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(passportBrown.opacity(0.15), lineWidth: 0.5)
                                        )
                                        .shadow(color: passportBrown.opacity(0.15), radius: 3, y: 2)
                                        .onTapGesture { selectedPhoto = url }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(pageColor)
                                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(passportBrown.opacity(0.15), lineWidth: 0.5)
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 40)
                }
            } else {
                Text("User not found")
                    .foregroundColor(.ccSubtext)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(item: $selectedPhoto) { url in
            ZoomableImageView(url: url, location: nil)
        }
        .task {
            await loadUser()
            await checkFriendship()
        }
    }

    private func loadUser() async {
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            user = try doc.data(as: AppUser.self)
        } catch {
            user = nil
        }
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
            try await db.collection("users").document(myUid).updateData([
                "friends": FieldValue.arrayUnion([userId])
            ])
            try await db.collection("users").document(userId).updateData([
                "friends": FieldValue.arrayUnion([myUid])
            ])
            isFriend = true
        } catch {}
    }

    private func removeFriend() async {
        guard let myUid = Auth.auth().currentUser?.uid else { return }
        do {
            try await db.collection("users").document(myUid).updateData([
                "friends": FieldValue.arrayRemove([userId])
            ])
            try await db.collection("users").document(userId).updateData([
                "friends": FieldValue.arrayRemove([myUid])
            ])
            isFriend = false
        } catch {}
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}

// MARK: - Components

private struct UserPassportField: View {
    let label: String
    let value: String
    private let brown = Color(red: 0.35, green: 0.18, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(brown.opacity(0.35))
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .serif))
                .foregroundColor(brown.opacity(0.8))
            Rectangle()
                .fill(brown.opacity(0.1))
                .frame(height: 0.5)
        }
    }
}

private struct UserStampView: View {
    let country: Country
    private let brown = Color(red: 0.35, green: 0.18, blue: 0.08)

    private var rotation: Double {
        Double(country.name.count % 7) * 5 - 15
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(country.flag)
                .font(.system(size: 28))
            Text(country.name.uppercased())
                .font(.system(size: 8, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(brown.opacity(0.7))
            Text("APPROVED")
                .font(.system(size: 6, weight: .bold, design: .monospaced))
                .foregroundColor(.green.opacity(0.6))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(brown.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
        )
        .rotationEffect(.degrees(rotation))
    }
}
