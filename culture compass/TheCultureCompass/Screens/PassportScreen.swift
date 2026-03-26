import SwiftUI

struct PassportScreen: View {
    @StateObject private var profileManager = UserProfileManager()
    @State private var showImagePicker = false
    @State private var showScrapbookPicker = false
    @State private var showProfileConfirm = false
    @State private var imageData: Data?
    @State private var scrapbookData: Data?
    @State private var isEditingBio = false
    @State private var bioText = ""
    @State private var selectedPhoto: String?
    @State private var currentPage = 0
    @State private var myFriends: [AppUser] = []
    @State private var showCountryPicker = false

    private let passportBrown = Color(red: 0.35, green: 0.18, blue: 0.08)
    private let passportGold = Color(red: 0.82, green: 0.68, blue: 0.21)
    private let pageColor = Color(red: 0.95, green: 0.92, blue: 0.86)
    private let stampPageColor = Color(red: 0.93, green: 0.89, blue: 0.82)

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // ═══════════════════════════════════
                    // PASSPORT COVER
                    // ═══════════════════════════════════
                    VStack(spacing: 16) {
                        // Embossed top line
                        Rectangle()
                            .fill(passportGold.opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 40)

                        Text("PASSPORT")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .tracking(6)
                            .foregroundColor(passportGold.opacity(0.7))

                        // Passport emblem
                        ZStack {
                            Circle()
                                .stroke(passportGold.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 110, height: 110)
                            Circle()
                                .stroke(passportGold.opacity(0.2), lineWidth: 1)
                                .frame(width: 124, height: 124)
                            Text("🌍")
                                .font(.system(size: 58))
                        }

                        Text("THE CULTURE COMPASS")
                            .font(.system(size: 12, weight: .bold, design: .serif))
                            .tracking(4)
                            .foregroundColor(passportGold.opacity(0.6))

                        Rectangle()
                            .fill(passportGold.opacity(0.4))
                            .frame(height: 1)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 24)
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

                    // ═══════════════════════════════════
                    // PAGE 1: IDENTIFICATION
                    // ═══════════════════════════════════
                    VStack(spacing: 0) {
                        // Page header
                        HStack {
                            Text("IDENTIFICATION")
                                .font(.system(size: 10, weight: .bold, design: .serif))
                                .tracking(3)
                                .foregroundColor(passportBrown.opacity(0.4))
                            Spacer()
                            Text("P1")
                                .font(.system(size: 10, weight: .light, design: .serif))
                                .foregroundColor(passportBrown.opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        HStack(alignment: .top, spacing: 16) {
                            // Photo
                            Button { showImagePicker = true } label: {
                                if !profileManager.user.profileImageURL.isEmpty {
                                    AsyncImage(url: URL(string: profileManager.user.profileImageURL)) { image in
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ProgressView().tint(passportBrown)
                                    }
                                    .frame(width: 100, height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(passportBrown.opacity(0.3), lineWidth: 1)
                                    )
                                } else {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.5))
                                        .frame(width: 100, height: 120)
                                        .overlay(
                                            VStack(spacing: 4) {
                                                Image(systemName: "camera.fill")
                                                    .foregroundColor(passportBrown.opacity(0.4))
                                                Text("TAP")
                                                    .font(.system(size: 7, weight: .bold))
                                                    .foregroundColor(passportBrown.opacity(0.3))
                                            }
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(passportBrown.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }

                            // Info fields
                            VStack(alignment: .leading, spacing: 8) {
                                PassportField(label: "SURNAME / NAME", value: profileManager.user.username.uppercased(), valueSize: 15)
                                PassportField(label: "NATIONALITY", value: "CULTURE COMPASS CITIZEN", valueSize: 14)
                                PassportField(label: "COUNTRIES VISITED", value: "\(profileManager.user.visitedCountries.count)", valueSize: 14)
                                PassportField(label: "PHOTOS", value: "\(profileManager.user.scrapbookPhotos.count)", valueSize: 14)
                            }
                        }
                        .padding(16)

                        // Bio section
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PERSONAL STATEMENT")
                                .font(.system(size: 9, weight: .bold, design: .serif))
                                .tracking(2)
                                .foregroundColor(passportBrown.opacity(0.4))

                            if isEditingBio {
                                HStack {
                                    TextField("Write your bio...", text: $bioText)
                                        .font(.system(size: 14, design: .serif))
                                        .foregroundColor(passportBrown)
                                        .padding(8)
                                        .background(Color.white.opacity(0.5))
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Button {
                                        Task { await profileManager.updateBio(bioText) }
                                        isEditingBio = false
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(passportBrown)
                                    }
                                }
                            } else {
                                Text(profileManager.user.bio.isEmpty ? "Tap to add your personal statement..." : profileManager.user.bio)
                                    .font(.system(size: 14, design: .serif))
                                    .foregroundColor(profileManager.user.bio.isEmpty ? passportBrown.opacity(0.3) : passportBrown.opacity(0.8))
                                    .italic(profileManager.user.bio.isEmpty)
                                    .onTapGesture {
                                        bioText = profileManager.user.bio
                                        isEditingBio = true
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)

                        // MRZ-style code at bottom
                        Text("P<CULTURECOMPASS<<\(profileManager.user.username.uppercased().replacingOccurrences(of: " ", with: "<"))<<<<<<<<<<<<")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(passportBrown.opacity(0.25))
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 12)
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

                    // Quick links
                    HStack(spacing: 10) {
                        NavigationLink(destination: FriendsScreen(friends: myFriends, count: profileManager.user.friends.count)) {
                            PassportActionPill(icon: "person.2.fill", label: "Friends")
                        }
                        NavigationLink(destination: AchievementsScreen()) {
                            PassportActionPill(icon: "trophy.fill", label: "Achievements")
                        }
                        NavigationLink(destination: ItineraryScreen()) {
                            PassportActionPill(icon: "map.fill", label: "Itineraries")
                        }
                        NavigationLink(destination: SettingsView()) {
                            PassportActionPill(icon: "gearshape.fill", label: "Settings")
                        }
                    }
                    .padding(.horizontal)

                    // ═══════════════════════════════════
                    // PAGE 2: VISA STAMPS (Countries)
                    // ═══════════════════════════════════
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("VISAS & STAMPS")
                                .font(.system(size: 10, weight: .bold, design: .serif))
                                .tracking(3)
                                .foregroundColor(passportBrown.opacity(0.4))
                            Spacer()
                            Button { showCountryPicker = true } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 9))
                                    Text("ADD")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(passportBrown)
                                .clipShape(Capsule())
                            }
                            Text("P2")
                                .font(.system(size: 10, weight: .light, design: .serif))
                                .foregroundColor(passportBrown.opacity(0.3))
                                .padding(.leading, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        if profileManager.user.visitedCountries.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "globe.americas")
                                    .font(.system(size: 32))
                                    .foregroundColor(passportBrown.opacity(0.2))
                                Text("No stamps yet — add your first country")
                                    .font(.system(size: 11, design: .serif))
                                    .foregroundColor(passportBrown.opacity(0.3))
                                    .italic()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            // Stamps grid — scattered like real passport stamps
                            let columns = [GridItem(.adaptive(minimum: 90), spacing: 12)]
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(profileManager.user.visitedCountries, id: \.self) { code in
                                    if let country = Country.all.first(where: { $0.code == code }) {
                                        StampView(country: country)
                                    }
                                }
                            }
                            .padding(16)
                        }
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

                    // ═══════════════════════════════════
                    // PAGE 3: SCRAPBOOK
                    // ═══════════════════════════════════
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text("TRAVEL MEMORIES")
                                .font(.system(size: 10, weight: .bold, design: .serif))
                                .tracking(3)
                                .foregroundColor(passportBrown.opacity(0.4))
                            Spacer()
                            Button {
                                showScrapbookPicker = true
                            } label: {
                                HStack(spacing: 3) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 9))
                                    Text("ADD")
                                        .font(.system(size: 8, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(passportBrown)
                                .clipShape(Capsule())
                            }
                            .disabled(profileManager.user.scrapbookPhotos.count >= 10)
                            Text("\(profileManager.user.scrapbookPhotos.count)/10")
                                .font(.system(size: 8, weight: .medium, design: .serif))
                                .foregroundColor(passportBrown.opacity(0.4))
                            Text("P3")
                                .font(.system(size: 8, weight: .light, design: .serif))
                                .foregroundColor(passportBrown.opacity(0.3))
                                .padding(.leading, 8)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        if profileManager.user.scrapbookPhotos.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(passportBrown.opacity(0.2))
                                Text("No memories yet — start your collection")
                                    .font(.system(size: 11, design: .serif))
                                    .foregroundColor(passportBrown.opacity(0.3))
                                    .italic()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 10),
                                GridItem(.flexible(), spacing: 10)
                            ], spacing: 10) {
                                ForEach(profileManager.user.scrapbookPhotos, id: \.self) { url in
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: url)) { image in
                                            image.resizable().aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color(red: 0.88, green: 0.85, blue: 0.78)
                                        }
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(passportBrown.opacity(0.15), lineWidth: 0.5)
                                        )
                                        // Polaroid shadow effect
                                        .shadow(color: passportBrown.opacity(0.15), radius: 3, y: 2)
                                        .onTapGesture { selectedPhoto = url }

                                        // Delete button
                                        Button {
                                            Task { await profileManager.removeScrapbookPhoto(url) }
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.red)
                                                    .frame(width: 22, height: 22)
                                                Image(systemName: "xmark")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            .shadow(color: .black.opacity(0.3), radius: 2)
                                        }
                                        .padding(4)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
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
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: $imageData)
        }
        .sheet(isPresented: $showScrapbookPicker) {
            ImagePicker(imageData: $scrapbookData)
        }
        .onChange(of: imageData) { _, newData in
            if newData != nil {
                showProfileConfirm = true
            }
        }
        .onChange(of: scrapbookData) { _, newData in
            if let data = newData {
                Task {
                    await profileManager.addScrapbookPhoto(data)
                    scrapbookData = nil
                }
            }
        }
        .sheet(isPresented: $showProfileConfirm) {
            ProfilePhotoConfirmSheet(
                imageData: $imageData,
                onAccept: {
                    print("📸 Accept tapped, imageData exists: \(imageData != nil)")
                    if let data = imageData {
                        Task {
                            await profileManager.uploadProfileImage(data)
                            imageData = nil
                        }
                    }
                    showProfileConfirm = false
                },
                onCancel: {
                    imageData = nil
                    showProfileConfirm = false
                }
            )
        }
        .task {
            await profileManager.loadProfile()
            myFriends = await profileManager.loadFriends()
        }
        .fullScreenCover(item: $selectedPhoto) { url in
            ZoomableImageView(url: url, location: nil)
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(
                alreadyVisited: profileManager.user.visitedCountries,
                onSelect: { code in
                    Task { await profileManager.addVisitedCountry(code) }
                }
            )
        }
    }
}

// MARK: - Passport Components

private struct PassportField: View {
    let label: String
    let value: String
    var valueSize: CGFloat = 14
    private let brown = Color(red: 0.35, green: 0.18, blue: 0.08)

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(brown.opacity(0.35))
            Text(value)
                .font(.system(size: valueSize, weight: .medium, design: .serif))
                .foregroundColor(brown.opacity(0.8))
            Rectangle()
                .fill(brown.opacity(0.1))
                .frame(height: 0.5)
        }
    }
}

private struct StampView: View {
    let country: Country
    private let brown = Color(red: 0.35, green: 0.18, blue: 0.08)

    // Random-ish rotation for each stamp
    private var rotation: Double {
        Double(country.name.count % 7) * 5 - 15
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(country.flag)
                .font(.system(size: 32))
            Text(country.name.uppercased())
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(brown.opacity(0.7))
            Text("APPROVED")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
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

private struct PassportActionPill: View {
    let icon: String
    let label: String
    private let brown = Color(red: 0.35, green: 0.18, blue: 0.08)
    private let gold = Color(red: 0.82, green: 0.68, blue: 0.21)

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(gold)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .serif))
                .foregroundColor(.ccLightText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(brown.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(gold.opacity(0.25), lineWidth: 0.5)
        )
    }
}

// MARK: - Profile Photo Confirmation

private struct ProfilePhotoConfirmSheet: View {
    @Binding var imageData: Data?
    let onAccept: () -> Void
    let onCancel: () -> Void

    private let brown = Color(red: 0.35, green: 0.18, blue: 0.08)
    private let gold = Color(red: 0.82, green: 0.68, blue: 0.21)

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("New Profile Photo")
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.ccGold)

                if let data = imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(gold.opacity(0.4), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
                }

                Text("Use this as your passport photo?")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(.ccSubtext)

                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 14, weight: .semibold, design: .serif))
                            .foregroundColor(.ccSubtext)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.ccCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Button(action: onAccept) {
                        Text("Accept")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(gold)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(24)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Country Picker

private struct CountryPickerSheet: View {
    let alreadyVisited: [String]
    let onSelect: (String) -> Void
    @State private var search = ""
    @Environment(\.dismiss) private var dismiss

    private let brown = Color(red: 0.35, green: 0.18, blue: 0.08)

    private var available: [Country] {
        let unvisited = Country.all.filter { !alreadyVisited.contains($0.code) }
        if search.isEmpty { return unvisited }
        return unvisited.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.ccSubtext)
                        TextField("Search countries...", text: $search)
                            .foregroundColor(.ccLightText)
                    }
                    .padding(10)
                    .background(Color.ccCardBg)
                    .clipShape(Capsule())
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(available) { country in
                                Button {
                                    onSelect(country.code)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(country.flag)
                                            .font(.system(size: 28))
                                        Text(country.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.ccLightText)
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(.ccGold)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ccGold)
                }
            }
        }
    }
}
