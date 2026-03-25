import SwiftUI
import FirebaseAuth

struct ItineraryScreen: View {
    @StateObject private var manager = ItineraryManager()
    @State private var showCreate = false
    @State private var showMine = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Itineraries")
                        .font(.title.bold())
                        .foregroundColor(.ccGold)
                    Spacer()
                    Button { showMine.toggle() } label: {
                        Text(showMine ? "Explore" : "My Trips")
                            .font(.caption.bold())
                            .foregroundColor(.ccGold)
                    }
                    Button { showCreate = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.ccGold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if manager.isLoading {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else {
                    let items = showMine ? manager.myItineraries : manager.itineraries
                    if items.isEmpty {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(.ccBrown)
                            Text(showMine ? "You haven't created any itineraries" : "No itineraries yet")
                                .font(.subheadline)
                                .foregroundColor(.ccSubtext)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(items) { itinerary in
                                    NavigationLink(destination: ItineraryDetailScreen(itinerary: itinerary)) {
                                        ItineraryCard(
                                            itinerary: itinerary,
                                            showDelete: showMine,
                                            onDelete: {
                                                guard let id = itinerary.id else { return }
                                                Task { await manager.deleteItinerary(id) }
                                            }
                                        )
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateItinerarySheet {
                Task {
                    await manager.loadMyItineraries()
                    await manager.loadPublicItineraries()
                }
            }
        }
        .task {
            await manager.loadPublicItineraries()
            await manager.loadMyItineraries()
        }
    }
}

private struct ItineraryCard: View {
    let itinerary: TripItinerary
    var showDelete: Bool = false
    var onDelete: (() -> Void)? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let country = Country.all.first(where: { $0.name == itinerary.country }) {
                    Text(country.flag)
                        .font(.title2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(itinerary.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.ccLightText)
                        .lineLimit(1)
                    Text("\(itinerary.country) • \(itinerary.days.count) days")
                        .font(.caption)
                        .foregroundColor(.ccSubtext)
                }
                Spacer()
                if showDelete {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .highPriorityGesture(TapGesture().onEnded { showDeleteConfirm = true })
                }
                VStack(spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.ccGold)
                        Text("\(itinerary.likes)")
                            .font(.caption2)
                            .foregroundColor(.ccSubtext)
                    }
                }
            }
            Text("by \(itinerary.username)")
                .font(.caption2)
                .foregroundColor(.ccSubtext)
        }
        .ccCard()
        .alert("Delete Itinerary?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete?() }
        } message: {
            Text("This can't be undone.")
        }
    }
}

struct ItineraryDetailScreen: View {
    let itinerary: TripItinerary
    @StateObject private var manager = ItineraryManager()

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(itinerary.title)
                            .font(.title2.bold())
                            .foregroundColor(.ccGold)
                        Text("\(itinerary.country) • \(itinerary.days.count) days • by \(itinerary.username)")
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                        if !itinerary.description.isEmpty {
                            Text(itinerary.description)
                                .font(.subheadline)
                                .foregroundColor(.ccLightText)
                        }
                    }
                    .padding(.horizontal)

                    Button {
                        guard let id = itinerary.id else { return }
                        Task { await manager.likeItinerary(id) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                            Text("\(itinerary.likes) likes")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.ccGold)
                    }
                    .padding(.horizontal)

                    ForEach(itinerary.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Day \(day.dayNumber): \(day.title)")
                                .font(.headline)
                                .foregroundColor(.ccGold)
                            ForEach(day.activities, id: \.self) { activity in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Color.ccGold)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)
                                    Text(activity)
                                        .font(.subheadline)
                                        .foregroundColor(.ccLightText)
                                }
                            }
                            if !day.notes.isEmpty {
                                Text(day.notes)
                                    .font(.caption)
                                    .foregroundColor(.ccSubtext)
                                    .italic()
                            }
                        }
                        .ccCard()
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct CreateItinerarySheet: View {
    let onDone: () -> Void
    @StateObject private var manager = ItineraryManager()
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var country = ""
    @State private var description = ""
    @State private var isPublic = true
    @State private var days: [ItineraryDay] = [ItineraryDay(dayNumber: 1, title: "", activities: [""], notes: "")]

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("Create Itinerary")
                            .font(.title3.bold())
                            .foregroundColor(.ccGold)

                        TextField("Trip Title", text: $title).formFieldStyle()
                        TextField("Country", text: $country).formFieldStyle()
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(2...4).formFieldStyle()

                        Toggle("Share publicly", isOn: $isPublic)
                            .tint(.ccGold)
                            .foregroundColor(.ccLightText)
                            .padding(.horizontal)

                        ForEach($days) { $day in
                            DayEditor(day: $day)
                        }

                        Button("+ Add Day") {
                            days.append(ItineraryDay(dayNumber: days.count + 1, title: "", activities: [""], notes: ""))
                        }
                        .foregroundColor(.ccGold)

                        Button("Create") {
                            let itinerary = TripItinerary(
                                userId: "", username: "", country: country,
                                title: title, description: description,
                                days: days, isPublic: isPublic,
                                likes: 0, saves: 0, timestamp: Date()
                            )
                            Task {
                                await manager.createItinerary(itinerary)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundColor(.ccSubtext)
                }
            }
        }
    }
}

private struct DayEditor: View {
    @Binding var day: ItineraryDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Day \(day.dayNumber)")
                .font(.caption.bold())
                .foregroundColor(.ccGold)
            TextField("Day title", text: $day.title).formFieldStyle()
            ForEach(day.activities.indices, id: \.self) { idx in
                TextField("Activity \(idx + 1)", text: $day.activities[idx]).formFieldStyle()
            }
            Button("+ Activity") { day.activities.append("") }
                .font(.caption)
                .foregroundColor(.ccGold)
            TextField("Notes", text: $day.notes).formFieldStyle()
        }
        .padding()
        .background(Color.ccCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension View {
    func formFieldStyle() -> some View {
        self
            .padding()
            .background(Color.ccDarkBg)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .foregroundColor(.ccLightText)
    }
}
