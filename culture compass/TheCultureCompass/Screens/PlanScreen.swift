import SwiftUI

struct PlanScreen: View {
    @State private var selectedCountry: Country?

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Plan")
                        .font(.title.bold())
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
                                PlanFeatureCard(icon: "storefront", title: "Black-Owned Businesses", subtitle: "Find businesses in \(country.name)")
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
                                urlString: "https://travel.state.gov/content/travel/en/international-travel.html"
                            )
                            PlanLinkCard(
                                icon: "cross.case",
                                title: "Vaccine Requirements",
                                subtitle: "Health info for \(country.name)",
                                urlString: "https://wwwnc.cdc.gov/travel/destinations/list"
                            )
                            PlanLinkCard(
                                icon: "exclamationmark.triangle",
                                title: "Travel Warnings",
                                subtitle: "Safety advisories",
                                urlString: "https://travel.state.gov/content/travel/en/traveladvisories/traveladvisories.html"
                            )

                            // Affiliate links
                            Text("Travel Essentials")
                                .font(.caption.bold())
                                .foregroundColor(.ccSubtext)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            PlanLinkCard(
                                icon: "suitcase",
                                title: "Book Hotels",
                                subtitle: "Find the best stays",
                                urlString: "https://www.booking.com"
                            )
                            PlanLinkCard(
                                icon: "airplane",
                                title: "Book Flights",
                                subtitle: "Compare flight prices",
                                urlString: "https://www.skyscanner.com"
                            )
                            PlanLinkCard(
                                icon: "shield",
                                title: "Travel Insurance",
                                subtitle: "Protect your trip",
                                urlString: "https://www.worldnomads.com"
                            )
                            PlanLinkCard(
                                icon: "bag",
                                title: "Travel Gear",
                                subtitle: "Recommended products",
                                urlString: "https://www.amazon.com/s?k=travel+essentials"
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
