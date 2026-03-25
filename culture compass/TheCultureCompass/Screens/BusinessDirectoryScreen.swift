import SwiftUI
import FirebaseAuth

struct BusinessDirectoryScreen: View {
    @StateObject private var manager = BusinessManager()
    @State private var selectedCategory: String?
    @State private var selectedCountry: Country?
    @State private var showAddBusiness = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Black-Owned")
                        .font(.title.bold())
                        .foregroundColor(.ccGold)
                    Spacer()
                    Button { showAddBusiness = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.ccGold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryPill(name: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                            Task { await reload() }
                        }
                        ForEach(Business.categories, id: \.self) { cat in
                            CategoryPill(name: cat, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                                Task { await reload() }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                // Featured
                if !manager.featuredBusinesses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.ccGold)
                            Text("Featured")
                                .font(.subheadline.bold())
                                .foregroundColor(.ccGold)
                        }
                        .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(manager.featuredBusinesses) { biz in
                                    NavigationLink(destination: BusinessDetailScreen(business: biz)) {
                                        FeaturedBusinessCard(business: biz)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 8)
                }

                // Business list
                if manager.isLoading && manager.businesses.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else if manager.businesses.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "storefront")
                            .font(.system(size: 40))
                            .foregroundColor(.ccBrown)
                        Text("No businesses listed yet")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(manager.businesses) { biz in
                                NavigationLink(destination: BusinessDetailScreen(business: biz)) {
                                    BusinessRow(business: biz)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await manager.loadFeatured()
                        await reload()
                    }
                }
            }
        }
        .sheet(isPresented: $showAddBusiness) {
            AddBusinessSheet { Task { await reload() } }
        }
        .task {
            await manager.loadFeatured()
            await reload()
        }
    }

    private func reload() async {
        await manager.loadBusinesses(country: selectedCountry?.name, category: selectedCategory)
    }
}

private struct CategoryPill: View {
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .black : .ccLightText)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? LinearGradient.ccGoldShimmer : LinearGradient.ccCard)
                .clipShape(Capsule())
        }
    }
}

private struct FeaturedBusinessCard: View {
    let business: Business

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !business.imageURL.isEmpty {
                AsyncImage(url: URL(string: business.imageURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.ccCardBg
                }
                .frame(width: 200, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text(business.name)
                .font(.subheadline.bold())
                .foregroundColor(.ccLightText)
                .lineLimit(1)
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.ccGold)
                Text(String(format: "%.1f", business.rating))
                    .font(.caption2)
                    .foregroundColor(.ccGold)
                Text("• \(business.city)")
                    .font(.caption2)
                    .foregroundColor(.ccSubtext)
            }
        }
        .frame(width: 200)
    }
}

private struct BusinessRow: View {
    let business: Business

    var body: some View {
        HStack(spacing: 12) {
            if !business.imageURL.isEmpty {
                AsyncImage(url: URL(string: business.imageURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.ccCardBg
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.ccBrown)
                    .frame(width: 60, height: 60)
                    .overlay(Image(systemName: "storefront").foregroundColor(.ccGold))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(business.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.ccLightText)
                    if business.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundColor(.ccGold)
                    }
                }
                Text("\(business.category) • \(business.city), \(business.country)")
                    .font(.caption)
                    .foregroundColor(.ccSubtext)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.ccGold)
                    Text(String(format: "%.1f (%d)", business.rating, business.reviewCount))
                        .font(.caption2)
                        .foregroundColor(.ccSubtext)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.ccSubtext)
        }
        .padding()
        .background(LinearGradient.ccCard)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
