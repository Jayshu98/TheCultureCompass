import SwiftUI
import FirebaseAuth

struct GroupTripsScreen: View {
    @StateObject private var manager = GroupTripManager()
    @State private var showCreate = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Group Trips")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.ccGold)
                    Spacer()
                    Button { showCreate = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.ccGold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Featured
                if !manager.featuredTrips.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(manager.featuredTrips) { trip in
                                NavigationLink(destination: GroupTripDetailScreen(trip: trip)) {
                                    FeaturedTripCard(trip: trip)
                                }
                            }
                        }
                        .padding()
                    }
                }

                if manager.isLoading && manager.trips.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else if manager.trips.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "airplane")
                            .font(.system(size: 40))
                            .foregroundColor(.ccBrown)
                        Text("No upcoming trips")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(manager.trips) { trip in
                                NavigationLink(destination: GroupTripDetailScreen(trip: trip)) {
                                    TripRow(trip: trip)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await manager.loadFeatured()
                        await manager.loadTrips()
                    }
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateTripSheet { Task { await manager.loadTrips() } }
        }
        .task {
            await manager.loadFeatured()
            await manager.loadTrips()
        }
    }
}

private struct FeaturedTripCard: View {
    let trip: GroupTrip

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !trip.imageURL.isEmpty {
                AsyncImage(url: URL(string: trip.imageURL)) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: { Color.ccCardBg }
                .frame(width: 240, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Text("FEATURED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.ccGold)
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(8)
                    }
                )
            }
            Text(trip.title)
                .font(.subheadline.bold())
                .foregroundColor(.ccLightText)
                .lineLimit(1)
            Text("\(trip.country) • $\(Int(trip.price))")
                .font(.caption)
                .foregroundColor(.ccGold)
            Text("\(trip.spotsLeft) spots left")
                .font(.caption2)
                .foregroundColor(.ccSubtext)
        }
        .frame(width: 240)
    }
}

private struct TripRow: View {
    let trip: GroupTrip

    var body: some View {
        HStack(spacing: 12) {
            if let country = Country.all.first(where: { $0.name == trip.country }) {
                Text(country.flag)
                    .font(.system(size: 32))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(trip.title)
                    .font(.subheadline.bold())
                    .foregroundColor(.ccLightText)
                    .lineLimit(1)
                Text("\(trip.startDate, format: .dateTime.month(.abbreviated).day()) - \(trip.endDate, format: .dateTime.month(.abbreviated).day())")
                    .font(.caption)
                    .foregroundColor(.ccSubtext)
                HStack(spacing: 8) {
                    Text("$\(Int(trip.price))")
                        .font(.caption.bold())
                        .foregroundColor(.ccGold)
                    Text("\(trip.spotsLeft) spots left")
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

struct GroupTripDetailScreen: View {
    let trip: GroupTrip
    @StateObject private var manager = GroupTripManager()
    private var uid: String? { Auth.auth().currentUser?.uid }
    private var hasJoined: Bool { uid.map { trip.participants.contains($0) } ?? false }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !trip.imageURL.isEmpty {
                        AsyncImage(url: URL(string: trip.imageURL)) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: { Color.ccCardBg }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(trip.title)
                            .font(.title2.bold())
                            .foregroundColor(.ccGold)
                        Text("Organized by \(trip.organizerName)")
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                        Text("\(trip.startDate, format: .dateTime.month(.wide).day().year()) - \(trip.endDate, format: .dateTime.month(.wide).day().year())")
                            .font(.subheadline)
                            .foregroundColor(.ccLightText)

                        HStack(spacing: 16) {
                            VStack {
                                Text("$\(Int(trip.price))")
                                    .font(.title3.bold())
                                    .foregroundColor(.ccGold)
                                Text("per person")
                                    .font(.caption2)
                                    .foregroundColor(.ccSubtext)
                            }
                            VStack {
                                Text("\(trip.spotsLeft)")
                                    .font(.title3.bold())
                                    .foregroundColor(.ccGold)
                                Text("spots left")
                                    .font(.caption2)
                                    .foregroundColor(.ccSubtext)
                            }
                            VStack {
                                Text("\(trip.participants.count)")
                                    .font(.title3.bold())
                                    .foregroundColor(.ccGold)
                                Text("going")
                                    .font(.caption2)
                                    .foregroundColor(.ccSubtext)
                            }
                        }
                        .padding(.vertical, 4)

                        Text(trip.description)
                            .font(.subheadline)
                            .foregroundColor(.ccLightText)

                        if !trip.highlights.isEmpty {
                            Text("Highlights")
                                .font(.headline)
                                .foregroundColor(.ccGold)
                                .padding(.top, 4)
                            ForEach(trip.highlights, id: \.self) { h in
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.ccGold)
                                    Text(h)
                                        .font(.subheadline)
                                        .foregroundColor(.ccLightText)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    if hasJoined {
                        Button("Leave Trip") {
                            guard let id = trip.id else { return }
                            Task { await manager.leaveTrip(id) }
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else if trip.spotsLeft > 0 {
                        Button("Join This Trip") {
                            guard let id = trip.id else { return }
                            Task { await manager.joinTrip(id) }
                        }
                        .buttonStyle(CCButtonStyle())
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct CreateTripSheet: View {
    let onDone: () -> Void
    @StateObject private var manager = GroupTripManager()
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var country = ""
    @State private var description = ""
    @State private var price = ""
    @State private var maxParticipants = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 7)
    @State private var highlights = [""]
    @State private var imageData: Data?
    @State private var showPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("Create Group Trip")
                            .font(.title3.bold())
                            .foregroundColor(.ccGold)

                        TextField("Trip Title", text: $title).tripField()
                        TextField("Country", text: $country).tripField()
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(3...5).tripField()
                        TextField("Price per person", text: $price)
                            .keyboardType(.numberPad).tripField()
                        TextField("Max participants", text: $maxParticipants)
                            .keyboardType(.numberPad).tripField()

                        DatePicker("Start", selection: $startDate, displayedComponents: .date)
                            .tint(.ccGold).foregroundColor(.ccLightText)
                        DatePicker("End", selection: $endDate, displayedComponents: .date)
                            .tint(.ccGold).foregroundColor(.ccLightText)

                        ForEach(highlights.indices, id: \.self) { idx in
                            TextField("Highlight \(idx + 1)", text: $highlights[idx]).tripField()
                        }
                        Button("+ Highlight") { highlights.append("") }
                            .font(.caption).foregroundColor(.ccGold)

                        Button("Add Cover Photo") { showPicker = true }
                            .foregroundColor(.ccGold)

                        Button("Create Trip") {
                            let trip = GroupTrip(
                                organizerId: "", organizerName: "",
                                title: title, country: country,
                                description: description, imageURL: "",
                                startDate: startDate, endDate: endDate,
                                price: Double(price) ?? 0, currency: "USD",
                                maxParticipants: Int(maxParticipants) ?? 10,
                                participants: [], highlights: highlights.filter { !$0.isEmpty },
                                isFeatured: false, timestamp: Date()
                            )
                            Task {
                                await manager.createTrip(trip, imageData: imageData)
                                onDone()
                                dismiss()
                            }
                        }
                        .buttonStyle(CCButtonStyle())
                        .disabled(title.isEmpty || country.isEmpty)
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
    func tripField() -> some View {
        self
            .padding()
            .background(Color.ccCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.ccLightText)
    }
}
