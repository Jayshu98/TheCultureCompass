import SwiftUI
import FirebaseFirestore

struct ConnectScreen: View {
    @State private var searchText = ""
    @State private var messageCounts: [String: Int] = [:]

    private let db = Firestore.firestore()

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
                                        NavigationLink(destination: ChatFeedScreen(country: country)) {
                                            CountryCell(country: country, messageCount: messageCounts[country.name] ?? 0)
                                        }
                                        .buttonStyle(.plain)
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
        .task { await loadMessageCounts() }
    }

    private func loadMessageCounts() async {
        do {
            let snapshot = try await db.collection("chats")
                .getDocuments()
            var counts: [String: Int] = [:]
            for doc in snapshot.documents {
                if let location = doc.data()["location"] as? String {
                    counts[location, default: 0] += 1
                }
            }
            messageCounts = counts
        } catch {}
    }
}

private struct CountryCell: View {
    let country: Country
    let messageCount: Int

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Text(country.flag)
                    .font(.system(size: 36))

                if messageCount > 0 {
                    Text("\(messageCount)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.ccGold)
                        .clipShape(Capsule())
                        .offset(x: 8, y: -4)
                }
            }

            Text(country.name)
                .font(.caption2.bold())
                .foregroundColor(.ccLightText)
                .lineLimit(1)

            if messageCount > 0 {
                Text("\(messageCount) message\(messageCount == 1 ? "" : "s")")
                    .font(.system(size: 8))
                    .foregroundColor(.ccSubtext)
            } else {
                Text("No messages yet")
                    .font(.system(size: 8))
                    .foregroundColor(.ccSubtext.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(LinearGradient.ccCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
