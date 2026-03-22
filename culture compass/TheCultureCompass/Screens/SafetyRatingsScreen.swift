import SwiftUI

struct SafetyRatingsScreen: View {
    let country: Country
    @StateObject private var manager = SafetyRatingManager()
    @State private var showSubmit = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Summary card
                    VStack(spacing: 12) {
                        Text(country.flag)
                            .font(.system(size: 48))
                        Text(country.name)
                            .font(.title2.bold())
                            .foregroundColor(.ccLightText)

                        if manager.countrySummary.count > 0 {
                            HStack(spacing: 4) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= Int(manager.countrySummary.avg.rounded()) ? "star.fill" : "star")
                                        .foregroundColor(.ccGold)
                                        .font(.title3)
                                }
                            }
                            Text(String(format: "%.1f avg from %d reviews", manager.countrySummary.avg, manager.countrySummary.count))
                                .font(.caption)
                                .foregroundColor(.ccSubtext)
                        } else {
                            Text("No ratings yet. Be the first!")
                                .font(.caption)
                                .foregroundColor(.ccSubtext)
                        }

                        Button("Rate This Country") { showSubmit = true }
                            .buttonStyle(CCButtonStyle())
                    }
                    .ccCard()
                    .padding(.horizontal)

                    // Reviews
                    LazyVStack(spacing: 12) {
                        ForEach(manager.ratings) { rating in
                            SafetyReviewCard(rating: rating)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showSubmit) {
            SubmitRatingSheet(country: country.name) {
                Task { await manager.loadRatings(for: country.name) }
            }
        }
        .task { await manager.loadRatings(for: country.name) }
    }
}

private struct SafetyReviewCard: View {
    let rating: SafetyRating

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                NavigationLink(destination: UserPassportScreen(userId: rating.userId)) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.ccBrown)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Text(String(rating.username.prefix(1)).uppercased())
                                    .font(.caption2.bold())
                                    .foregroundColor(.ccGold)
                            )
                        Text(rating.username)
                            .font(.caption.bold())
                            .foregroundColor(.ccGold)
                    }
                }
                Spacer()
                Text(rating.timestamp, format: .dateTime.month(.abbreviated).day().year())
                    .font(.caption2)
                    .foregroundColor(.ccSubtext)
            }

            HStack(spacing: 16) {
                ScorePill(label: "Safety", score: rating.safetyScore)
                ScorePill(label: "Friendly", score: rating.friendlinessScore)
                ScorePill(label: "Culture", score: rating.culturalScore)
            }

            if !rating.review.isEmpty {
                Text(rating.review)
                    .font(.subheadline)
                    .foregroundColor(.ccLightText)
            }

            if !rating.tips.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.ccGold)
                    Text(rating.tips)
                        .font(.caption)
                        .foregroundColor(.ccSubtext)
                }
            }
        }
        .ccCard()
    }
}

private struct ScorePill: View {
    let label: String
    let score: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("\(score)/5")
                .font(.caption.bold())
                .foregroundColor(.ccGold)
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.ccSubtext)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.ccDarkBg)
        .clipShape(Capsule())
    }
}

struct SubmitRatingSheet: View {
    let country: String
    let onDone: () -> Void
    @StateObject private var manager = SafetyRatingManager()
    @Environment(\.dismiss) private var dismiss

    @State private var overall = 3
    @State private var safety = 3
    @State private var friendliness = 3
    @State private var cultural = 3
    @State private var review = ""
    @State private var tips = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        Text("Rate \(country)")
                            .font(.title3.bold())
                            .foregroundColor(.ccGold)

                        RatingSlider(label: "Overall", value: $overall)
                        RatingSlider(label: "Safety", value: $safety)
                        RatingSlider(label: "Friendliness", value: $friendliness)
                        RatingSlider(label: "Cultural Experience", value: $cultural)

                        TextField("Write your review...", text: $review, axis: .vertical)
                            .lineLimit(3...6)
                            .padding()
                            .background(Color.ccCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.ccLightText)

                        TextField("Any tips for travelers?", text: $tips, axis: .vertical)
                            .lineLimit(2...4)
                            .padding()
                            .background(Color.ccCardBg)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.ccLightText)

                        Button("Submit Rating") {
                            Task {
                                await manager.submitRating(
                                    country: country, overall: overall,
                                    safety: safety, friendliness: friendliness,
                                    cultural: cultural, review: review, tips: tips
                                )
                                onDone()
                                dismiss()
                            }
                        }
                        .buttonStyle(CCButtonStyle())
                        .disabled(manager.isLoading)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.ccSubtext)
                }
            }
        }
    }
}

private struct RatingSlider: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(.ccLightText)
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= value ? "star.fill" : "star")
                        .foregroundColor(.ccGold)
                        .font(.title3)
                        .onTapGesture { value = star }
                }
                Spacer()
                Text("\(value)/5")
                    .font(.caption)
                    .foregroundColor(.ccSubtext)
            }
        }
        .padding()
        .background(Color.ccCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
