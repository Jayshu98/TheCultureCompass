import SwiftUI
import FirebaseFirestore

struct UserPassportScreen: View {
    let userId: String
    @State private var user: AppUser?
    @State private var isLoading = true
    @State private var selectedPhoto: String?

    private let db = Firestore.firestore()

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.ccGold)
            } else if let user {
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 12) {
                            if !user.profileImageURL.isEmpty {
                                AsyncImage(url: URL(string: user.profileImageURL)) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView().tint(.ccGold)
                                }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.ccGold, lineWidth: 2))
                            } else {
                                Circle()
                                    .fill(Color.ccBrown)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(String(user.username.prefix(1)).uppercased())
                                            .font(.title.bold())
                                            .foregroundColor(.ccGold)
                                    )
                                    .overlay(Circle().stroke(Color.ccGold, lineWidth: 2))
                            }

                            Text(user.username)
                                .font(.title2.bold())
                                .foregroundColor(.ccLightText)

                            if !user.bio.isEmpty {
                                Text(user.bio)
                                    .font(.subheadline)
                                    .foregroundColor(.ccSubtext)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.top)

                        // Country Badges
                        if !user.visitedCountries.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Country Badges")
                                    .font(.headline)
                                    .foregroundColor(.ccGold)
                                    .padding(.horizontal)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(user.visitedCountries, id: \.self) { code in
                                            if let country = Country.all.first(where: { $0.code == code }) {
                                                VStack(spacing: 4) {
                                                    Text(country.flag)
                                                        .font(.system(size: 32))
                                                    Text(country.name)
                                                        .font(.caption2)
                                                        .foregroundColor(.ccSubtext)
                                                }
                                                .padding(8)
                                                .background(LinearGradient.ccCard)
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Scrapbook
                        if !user.scrapbookPhotos.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Scrapbook")
                                    .font(.headline)
                                    .foregroundColor(.ccGold)
                                    .padding(.horizontal)

                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 4) {
                                    ForEach(user.scrapbookPhotos, id: \.self) { url in
                                        AsyncImage(url: URL(string: url)) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color.ccCardBg
                                        }
                                        .frame(height: 120)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .onTapGesture { selectedPhoto = url }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom, 32)
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
        .task { await loadUser() }
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
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
