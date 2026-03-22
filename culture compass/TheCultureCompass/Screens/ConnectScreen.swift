import SwiftUI

struct ConnectScreen: View {
    @State private var searchText = ""

    private var filteredCountries: [Country] {
        if searchText.isEmpty { return Country.all }
        return Country.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.region.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var grouped: [String: [Country]] {
        Dictionary(grouping: filteredCountries, by: \.region)
    }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Connect")
                        .font(.title.bold())
                        .foregroundColor(.ccGold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.ccSubtext)
                    TextField("Search countries...", text: $searchText)
                        .foregroundColor(.ccLightText)
                }
                .padding(10)
                .background(Color.ccCardBg)
                .clipShape(Capsule())
                .padding(.horizontal)
                .padding(.vertical, 8)

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(grouped.keys.sorted(), id: \.self) { region in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(region)
                                    .font(.caption.bold())
                                    .foregroundColor(.ccSubtext)
                                    .padding(.horizontal)

                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(grouped[region] ?? []) { country in
                                        CountryCell(country: country)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}

private struct CountryCell: View {
    let country: Country

    var body: some View {
        VStack(spacing: 6) {
            Text(country.flag)
                .font(.system(size: 36))
            Text(country.name)
                .font(.caption2.bold())
                .foregroundColor(.ccLightText)
                .lineLimit(1)

            HStack(spacing: 12) {
                NavigationLink(destination: ChatFeedScreen(country: country)) {
                    Image(systemName: "bubble.left.fill")
                        .font(.caption2)
                        .foregroundColor(.ccGold)
                }
                NavigationLink(destination: SafetyRatingsScreen(country: country)) {
                    Image(systemName: "shield.fill")
                        .font(.caption2)
                        .foregroundColor(.ccGold)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(LinearGradient.ccCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
