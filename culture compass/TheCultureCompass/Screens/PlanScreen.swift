import SwiftUI

struct PlanScreen: View {
    @State private var selectedCountry: Country?

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Plan")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.ccGold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Country Picker
                Menu {
                    ForEach(Country.all) { country in
                        Button("\(country.flag) \(country.name)") {
                            withAnimation { selectedCountry = country }
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedCountry.map { "\($0.flag) \($0.name)" } ?? "Select a country")
                            .foregroundColor(selectedCountry != nil ? .ccLightText : .ccSubtext)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.ccGold)
                    }
                    .padding()
                    .background(Color.ccCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()

                if let country = selectedCountry {
                    ScrollView {
                        VStack(spacing: 16) {
                            // In-app features
                            NavigationLink(destination: SafetyRatingsScreen(country: country)) {
                                PlanFeatureCard(icon: "shield.checkered", title: "Safety Ratings", subtitle: "Community reviews for \(country.name)")
                            }
                            NavigationLink(destination: BusinessDirectoryScreen()) {
                                PlanFeatureCard(icon: "storefront", title: "Local Businesses", subtitle: "Find businesses in \(country.name)")
                            }
                            NavigationLink(destination: EventsScreen()) {
                                PlanFeatureCard(icon: "calendar", title: "Events", subtitle: "Meetups & cultural events")
                            }
                            NavigationLink(destination: TravelMatchScreen()) {
                                PlanFeatureCard(icon: "person.2", title: "Travel Match", subtitle: "Find travel buddies")
                            }

                            // External links
                            Text("Resources")
                                .font(.caption.bold())
                                .foregroundColor(.ccSubtext)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PlanLinkCard(
                                icon: "doc.text",
                                title: "Customs & Entry Info",
                                subtitle: "Requirements for \(country.name)",
                                urlString: "https://www.google.com/search?q=\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)+entry+requirements+visa"
                            )
                            PlanLinkCard(
                                icon: "cross.case",
                                title: "Vaccine Requirements",
                                subtitle: "Health info for \(country.name)",
                                urlString: "https://wwwnc.cdc.gov/travel/destinations/traveler/none/\(country.name.lowercased().replacingOccurrences(of: " ", with: "-"))"
                            )
                            PlanLinkCard(
                                icon: "exclamationmark.triangle",
                                title: "Travel Warnings",
                                subtitle: "Advisories for \(country.name)",
                                urlString: "https://www.google.com/search?q=\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)+travel+advisory+safety"
                            )

                            // Affiliate links
                            Text("Travel Essentials")
                                .font(.caption.bold())
                                .foregroundColor(.ccSubtext)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PlanLinkCard(
                                icon: "suitcase",
                                title: "Hotels in \(country.name)",
                                subtitle: "Find the best stays",
                                urlString: "https://www.booking.com/searchresults.html?ss=\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)"
                            )
                            PlanLinkCard(
                                icon: "airplane",
                                title: "Flights to \(country.name)",
                                subtitle: "Compare flight prices",
                                urlString: "https://www.skyscanner.com/transport/flights/anywhere/\(country.code.lowercased())"
                            )
                            PlanLinkCard(
                                icon: "shield",
                                title: "Travel Insurance",
                                subtitle: "Protect your \(country.name) trip",
                                urlString: "https://www.worldnomads.com/travel-insurance/get-a-quote?country=\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)"
                            )
                            PlanLinkCard(
                                icon: "bag",
                                title: "Travel Gear",
                                subtitle: "Essentials for \(country.name)",
                                urlString: "https://www.amazon.com/s?k=travel+essentials+\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)"
                            )

                            // Excursions & Tours
                            Text("Excursions & Tours")
                                .font(.caption.bold())
                                .foregroundColor(.ccSubtext)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PlanLinkCard(
                                icon: "binoculars",
                                title: "Top Experiences",
                                subtitle: "Tours & activities in \(country.name)",
                                urlString: "https://www.viator.com/searchResults/all?text=\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)"
                            )
                            PlanLinkCard(
                                icon: "figure.walk",
                                title: "Walking Tours",
                                subtitle: "Explore \(country.name) on foot",
                                urlString: "https://www.viator.com/searchResults/all?text=\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)+walking+tour"
                            )
                            PlanLinkCard(
                                icon: "fork.knife",
                                title: "Food & Culture Tours",
                                subtitle: "Taste the local cuisine",
                                urlString: "https://www.viator.com/searchResults/all?text=\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)+food+tour"
                            )
                            PlanLinkCard(
                                icon: "sun.max",
                                title: "Day Trips",
                                subtitle: "Full-day excursions from \(country.name)",
                                urlString: "https://www.viator.com/searchResults/all?text=\(country.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? country.name)+day+trip"
                            )
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "map")
                            .font(.system(size: 48))
                            .foregroundColor(.ccBrown)
                        Text("Select a country to start planning")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                }
            }
        }
    }
}

private struct PlanFeatureCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.ccGold)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.ccLightText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.ccSubtext)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.ccSubtext)
        }
        .ccCard()
    }
}

private struct PlanLinkCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.ccGold)
                        .frame(width: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundColor(.ccLightText)
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(.ccSubtext)
                }
                .ccCard()
            }
        }
    }
}
