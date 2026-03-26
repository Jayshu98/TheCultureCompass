import SwiftUI

struct TravelMatchScreen: View {
    @StateObject private var manager = TravelMatchManager()
    @State private var selectedCountry: Country?
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7)
    @State private var hasSearched = false
    @State private var showPostListing = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Travel Match")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.ccGold)
                    Spacer()
                    Button { showPostListing = true } label: {
                        Text("Post Trip")
                            .font(.caption.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(LinearGradient.ccGoldShimmer)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Search
                VStack(spacing: 10) {
                    Menu {
                        ForEach(Country.all) { country in
                            Button("\(country.flag) \(country.name)") {
                                selectedCountry = country
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCountry.map { "\($0.flag) \($0.name)" } ?? "Where are you going?")
                                .foregroundColor(selectedCountry != nil ? .ccLightText : .ccSubtext)
                            Spacer()
                            Image(systemName: "chevron.down").foregroundColor(.ccGold)
                        }
                        .padding()
                        .background(Color.ccCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    HStack {
                        DatePicker("From", selection: $startDate, displayedComponents: .date)
                        DatePicker("To", selection: $endDate, displayedComponents: .date)
                    }
                    .font(.caption)
                    .tint(.ccGold)
                    .foregroundColor(.ccLightText)

                    Button("Find Travel Buddies") {
                        guard let country = selectedCountry else { return }
                        hasSearched = true
                        Task { await manager.loadMatches(country: country.name, startDate: startDate, endDate: endDate) }
                    }
                    .buttonStyle(CCButtonStyle())
                    .disabled(selectedCountry == nil)
                }
                .padding()

                if manager.isLoading {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else if hasSearched && manager.matches.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.ccBrown)
                        Text("No matches found")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                        Text("Post your trip so others can find you")
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(manager.matches) { match in
                                MatchCard(match: match)
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        guard let country = selectedCountry else { return }
                        await manager.loadMatches(country: country.name, startDate: startDate, endDate: endDate)
                    }
                }
            }
        }
        .sheet(isPresented: $showPostListing) {
            PostTravelListingSheet()
        }
    }
}

private struct MatchCard: View {
    let match: TravelMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                NavigationLink(destination: UserPassportScreen(userId: match.userId)) {
                    if !match.profileImageURL.isEmpty {
                        AsyncImage(url: URL(string: match.profileImageURL)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: { Color.ccBrown }
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.ccGold, lineWidth: 1.5))
                    } else {
                        Circle()
                            .fill(Color.ccBrown)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(String(match.username.prefix(1)).uppercased())
                                    .font(.headline.bold())
                                    .foregroundColor(.ccGold)
                            )
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(match.username)
                        .font(.subheadline.bold())
                        .foregroundColor(.ccLightText)
                    Text("\(match.startDate, format: .dateTime.month(.abbreviated).day()) - \(match.endDate, format: .dateTime.month(.abbreviated).day())")
                        .font(.caption)
                        .foregroundColor(.ccSubtext)
                }
                Spacer()
            }

            if !match.bio.isEmpty {
                Text(match.bio)
                    .font(.caption)
                    .foregroundColor(.ccLightText)
            }

            if !match.interests.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(match.interests, id: \.self) { interest in
                            Text(interest)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.ccGold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.ccDarkBg)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            NavigationLink(destination: UserPassportScreen(userId: match.userId)) {
                Text("View Profile")
                    .font(.caption.bold())
                    .foregroundColor(.ccGold)
            }
        }
        .ccCard()
    }
}

struct PostTravelListingSheet: View {
    @StateObject private var manager = TravelMatchManager()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCountry: Country?
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7)
    @State private var bio = ""
    @State private var selectedInterests: Set<String> = []

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("Post Your Trip")
                            .font(.title3.bold())
                            .foregroundColor(.ccGold)

                        Menu {
                            ForEach(Country.all) { country in
                                Button("\(country.flag) \(country.name)") {
                                    selectedCountry = country
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCountry.map { "\($0.flag) \($0.name)" } ?? "Select country")
                                    .foregroundColor(selectedCountry != nil ? .ccLightText : .ccSubtext)
                                Spacer()
                                Image(systemName: "chevron.down").foregroundColor(.ccGold)
                            }
                            .padding()
                            .background(Color.ccCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                            .tint(.ccGold).foregroundColor(.ccLightText)
                        DatePicker("End", selection: $endDate, displayedComponents: .date)
                            .tint(.ccGold).foregroundColor(.ccLightText)

                        TextField("Tell people about your trip plans...", text: $bio, axis: .vertical)
                            .lineLimit(3...5)
                            .padding()
                            .background(Color.ccCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.ccLightText)

                        Text("Interests")
                            .font(.caption.bold())
                            .foregroundColor(.ccGold)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(TravelMatch.interestOptions, id: \.self) { interest in
                                Button {
                                    if selectedInterests.contains(interest) {
                                        selectedInterests.remove(interest)
                                    } else {
                                        selectedInterests.insert(interest)
                                    }
                                } label: {
                                    Text(interest)
                                        .font(.caption)
                                        .foregroundColor(selectedInterests.contains(interest) ? .black : .ccLightText)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedInterests.contains(interest) ? LinearGradient.ccGoldShimmer : LinearGradient.ccCard)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        Button("Post Listing") {
                            guard let country = selectedCountry else { return }
                            Task {
                                await manager.postListing(
                                    country: country.name,
                                    startDate: startDate,
                                    endDate: endDate,
                                    bio: bio,
                                    interests: Array(selectedInterests)
                                )
                                dismiss()
                            }
                        }
                        .buttonStyle(CCButtonStyle())
                        .disabled(selectedCountry == nil)
                    }
                    .padding()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ccSubtext)
                }
            }
        }
    }
}
