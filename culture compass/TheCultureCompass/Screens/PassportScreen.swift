import SwiftUI

struct PassportScreen: View {
    @StateObject private var profileManager = UserProfileManager()
    @State private var showImagePicker = false
    @State private var showScrapbookPicker = false
    @State private var imageData: Data?
    @State private var scrapbookData: Data?
    @State private var isEditingBio = false
    @State private var bioText = ""
    @State private var selectedPhoto: String?

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 12) {
                        Button { showImagePicker = true } label: {
                            if !profileManager.user.profileImageURL.isEmpty {
                                AsyncImage(url: URL(string: profileManager.user.profileImageURL)) { image in
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
                                        Image(systemName: "camera.fill")
                                            .foregroundColor(.ccGold)
                                    )
                                    .overlay(Circle().stroke(Color.ccGold, lineWidth: 2))
                            }
                        }

                        Text(profileManager.user.username)
                            .font(.title2.bold())
                            .foregroundColor(.ccLightText)

                        // Bio
                        if isEditingBio {
                            HStack {
                                TextField("Write your bio...", text: $bioText)
                                    .foregroundColor(.ccLightText)
                                    .padding(8)
                                    .background(Color.ccCardBg)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Button("Save") {
                                    Task { await profileManager.updateBio(bioText) }
                                    isEditingBio = false
                                }
                                .foregroundColor(.ccGold)
                            }
                            .padding(.horizontal)
                        } else {
                            Text(profileManager.user.bio.isEmpty ? "Tap to add bio" : profileManager.user.bio)
                                .font(.subheadline)
                                .foregroundColor(.ccSubtext)
                                .onTapGesture {
                                    bioText = profileManager.user.bio
                                    isEditingBio = true
                                }
                        }
                    }
                    .padding(.top)

                    // Quick links
                    HStack(spacing: 12) {
                        NavigationLink(destination: AchievementsScreen()) {
                            QuickLinkPill(icon: "trophy.fill", label: "Achievements")
                        }
                        NavigationLink(destination: ItineraryScreen()) {
                            QuickLinkPill(icon: "map.fill", label: "Itineraries")
                        }
                        NavigationLink(destination: SettingsView()) {
                            QuickLinkPill(icon: "gearshape.fill", label: "Settings")
                        }
                    }
                    .padding(.horizontal)

                    // Country Badges
                    if !profileManager.user.visitedCountries.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Country Badges")
                                .font(.headline)
                                .foregroundColor(.ccGold)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(profileManager.user.visitedCountries, id: \.self) { code in
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
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Scrapbook")
                                .font(.headline)
                                .foregroundColor(.ccGold)
                            Spacer()
                            Button {
                                showScrapbookPicker = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.ccGold)
                            }
                        }
                        .padding(.horizontal)

                        if profileManager.user.scrapbookPhotos.isEmpty {
                            Text("No photos yet. Start building your travel scrapbook.")
                                .font(.caption)
                                .foregroundColor(.ccSubtext)
                                .padding(.horizontal)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 4) {
                                ForEach(profileManager.user.scrapbookPhotos, id: \.self) { url in
                                    AsyncImage(url: URL(string: url)) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Color.ccCardBg
                                    }
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .onTapGesture { selectedPhoto = url }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            Task { await profileManager.removeScrapbookPhoto(url) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if let data = imageData {
                Task { await profileManager.uploadProfileImage(data) }
                imageData = nil
            }
        }) {
            ImagePicker(imageData: $imageData)
        }
        .sheet(isPresented: $showScrapbookPicker, onDismiss: {
            if let data = scrapbookData {
                Task { await profileManager.addScrapbookPhoto(data) }
                scrapbookData = nil
            }
        }) {
            ImagePicker(imageData: $scrapbookData)
        }
        .task { await profileManager.loadProfile() }
        .fullScreenCover(item: $selectedPhoto) { url in
            ZoomableImageView(url: url, location: nil)
        }
    }
}

private struct QuickLinkPill: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.ccGold)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.ccSubtext)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(LinearGradient.ccCard)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
