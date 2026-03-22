import SwiftUI
import FirebaseAuth

struct BusinessDetailScreen: View {
    let business: Business
    @StateObject private var manager = BusinessManager()
    @State private var reviews: [BusinessReview] = []
    @State private var showReviewSheet = false
    @State private var showZoomImage = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Hero image
                    if !business.imageURL.isEmpty {
                        AsyncImage(url: URL(string: business.imageURL)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.ccCardBg
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .onTapGesture { showZoomImage = true }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(business.name)
                                .font(.title2.bold())
                                .foregroundColor(.ccLightText)
                            if business.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.ccGold)
                            }
                        }

                        HStack(spacing: 12) {
                            Label(business.category, systemImage: "tag")
                            Label("\(business.city), \(business.country)", systemImage: "mappin")
                        }
                        .font(.caption)
                        .foregroundColor(.ccSubtext)

                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= Int(business.rating.rounded()) ? "star.fill" : "star")
                                    .foregroundColor(.ccGold)
                                    .font(.subheadline)
                            }
                            Text(String(format: "%.1f (%d reviews)", business.rating, business.reviewCount))
                                .font(.caption)
                                .foregroundColor(.ccSubtext)
                        }

                        if !business.description.isEmpty {
                            Text(business.description)
                                .font(.subheadline)
                                .foregroundColor(.ccLightText)
                                .padding(.top, 4)
                        }

                        // Contact
                        HStack(spacing: 16) {
                            if !business.contactEmail.isEmpty {
                                Link(destination: URL(string: "mailto:\(business.contactEmail)")!) {
                                    Label("Email", systemImage: "envelope.fill")
                                        .font(.caption.bold())
                                        .foregroundColor(.ccGold)
                                }
                            }
                            if !business.website.isEmpty, let url = URL(string: business.website) {
                                Link(destination: url) {
                                    Label("Website", systemImage: "globe")
                                        .font(.caption.bold())
                                        .foregroundColor(.ccGold)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal)

                    // Review button
                    Button("Write a Review") { showReviewSheet = true }
                        .buttonStyle(CCButtonStyle())
                        .padding(.horizontal)

                    // Reviews
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Reviews")
                            .font(.headline)
                            .foregroundColor(.ccGold)
                            .padding(.horizontal)

                        if reviews.isEmpty {
                            Text("No reviews yet.")
                                .font(.caption)
                                .foregroundColor(.ccSubtext)
                                .padding(.horizontal)
                        } else {
                            ForEach(reviews) { review in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(review.username)
                                            .font(.caption.bold())
                                            .foregroundColor(.ccGold)
                                        Spacer()
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { s in
                                                Image(systemName: s <= review.rating ? "star.fill" : "star")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(.ccGold)
                                            }
                                        }
                                    }
                                    Text(review.comment)
                                        .font(.caption)
                                        .foregroundColor(.ccLightText)
                                    Text(review.timestamp, format: .dateTime.month(.abbreviated).day().year())
                                        .font(.system(size: 9))
                                        .foregroundColor(.ccSubtext)
                                }
                                .ccCard()
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(isPresented: $showZoomImage) {
            ZoomableImageView(url: business.imageURL, location: "\(business.city), \(business.country)")
        }
        .sheet(isPresented: $showReviewSheet) {
            WriteReviewSheet(businessId: business.id ?? "") {
                Task { reviews = await manager.loadReviews(businessId: business.id ?? "") }
            }
        }
        .task { reviews = await manager.loadReviews(businessId: business.id ?? "") }
    }
}

struct WriteReviewSheet: View {
    let businessId: String
    let onDone: () -> Void
    @StateObject private var manager = BusinessManager()
    @Environment(\.dismiss) private var dismiss
    @State private var rating = 3
    @State private var comment = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("Your Review")
                        .font(.title3.bold())
                        .foregroundColor(.ccGold)

                    HStack(spacing: 8) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .foregroundColor(.ccGold)
                                .font(.title2)
                                .onTapGesture { rating = star }
                        }
                    }

                    TextField("Write your review...", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                        .padding()
                        .background(Color.ccCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.ccLightText)

                    Button("Submit") {
                        Task {
                            await manager.addReview(businessId: businessId, rating: rating, comment: comment)
                            onDone()
                            dismiss()
                        }
                    }
                    .buttonStyle(CCButtonStyle())
                    .disabled(comment.trimmingCharacters(in: .whitespaces).isEmpty)

                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ccSubtext)
                }
            }
        }
    }
}

struct AddBusinessSheet: View {
    let onDone: () -> Void
    @StateObject private var manager = BusinessManager()
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "Restaurant"
    @State private var country = ""
    @State private var city = ""
    @State private var description = ""
    @State private var contactEmail = ""
    @State private var website = ""
    @State private var imageData: Data?
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("List Your Business")
                            .font(.title3.bold())
                            .foregroundColor(.ccGold)

                        TextField("Business Name", text: $name)
                            .formField()
                        Picker("Category", selection: $category) {
                            ForEach(Business.categories, id: \.self) { Text($0) }
                        }
                        .pickerStyle(.menu)
                        .tint(.ccGold)

                        TextField("Country", text: $country).formField()
                        TextField("City", text: $city).formField()
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...5).formField()
                        TextField("Contact Email", text: $contactEmail).formField()
                        TextField("Website URL", text: $website).formField()

                        Button("Add Photo") { showPicker = true }
                            .foregroundColor(.ccGold)

                        Button("Submit Listing") {
                            let biz = Business(
                                ownerId: "", name: name, category: category,
                                country: country, city: city, description: description,
                                imageURL: "", contactEmail: contactEmail, website: website,
                                isFeatured: false, isVerified: false,
                                rating: 0, reviewCount: 0, timestamp: Date()
                            )
                            Task {
                                await manager.createBusiness(biz, imageData: imageData)
                                onDone()
                                dismiss()
                            }
                        }
                        .buttonStyle(CCButtonStyle())
                        .disabled(name.isEmpty || country.isEmpty || city.isEmpty)
                    }
                    .padding()
                }
            }
            .sheet(isPresented: $showPicker) { ImagePicker(imageData: $imageData) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ccSubtext)
                }
            }
        }
    }
}

private extension View {
    func formField() -> some View {
        self
            .padding()
            .background(Color.ccCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.ccLightText)
    }
}
