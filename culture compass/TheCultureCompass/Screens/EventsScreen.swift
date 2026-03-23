import SwiftUI
import FirebaseAuth

struct EventsScreen: View {
    @StateObject private var manager = EventManager()
    @State private var showCreate = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Events")
                        .font(.title.bold())
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

                if manager.isLoading && manager.events.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else if manager.events.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 40))
                            .foregroundColor(.ccBrown)
                        Text("No upcoming events")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(manager.events) { event in
                                EventCard(event: event) {
                                    guard let id = event.id else { return }
                                    let uid = Auth.auth().currentUser?.uid ?? ""
                                    if event.attendees.contains(uid) {
                                        Task { await manager.cancelRsvp(id) }
                                    } else {
                                        Task { await manager.rsvp(id) }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            CreateEventSheet { Task { await manager.loadEvents() } }
        }
        .task { await manager.loadEvents() }
    }
}

private struct EventCard: View {
    let event: CCEvent
    let onRSVP: () -> Void
    private var uid: String? { Auth.auth().currentUser?.uid }
    private var isAttending: Bool { uid.map { event.attendees.contains($0) } ?? false }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.subheadline.bold())
                        .foregroundColor(.ccLightText)
                    Text("\(event.city), \(event.country)")
                        .font(.caption)
                        .foregroundColor(.ccSubtext)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(event.date, format: .dateTime.month(.abbreviated).day())
                        .font(.caption.bold())
                        .foregroundColor(.ccGold)
                    Text(event.date, format: .dateTime.hour().minute())
                        .font(.caption2)
                        .foregroundColor(.ccSubtext)
                }
            }

            if !event.description.isEmpty {
                Text(event.description)
                    .font(.caption)
                    .foregroundColor(.ccLightText)
                    .lineLimit(2)
            }

            HStack {
                Text("\(event.attendees.count) going • \(event.spotsLeft) spots left")
                    .font(.caption2)
                    .foregroundColor(.ccSubtext)
                Spacer()
                Button(isAttending ? "Cancel" : "RSVP", action: onRSVP)
                    .font(.caption.bold())
                    .foregroundColor(isAttending ? .red : .black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(isAttending ? AnyShapeStyle(Color.ccCardBg) : AnyShapeStyle(LinearGradient.ccGoldShimmer))
                    .clipShape(Capsule())
            }
        }
        .ccCard()
    }
}

struct CreateEventSheet: View {
    let onDone: () -> Void
    @StateObject private var manager = EventManager()
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var country = ""
    @State private var city = ""
    @State private var date = Date()
    @State private var maxAttendees = ""

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.ccBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("Create Event")
                            .font(.title3.bold())
                            .foregroundColor(.ccGold)

                        TextField("Event Title", text: $title).eventField()
                        TextField("Description", text: $description, axis: .vertical)
                            .lineLimit(2...4).eventField()
                        TextField("Country", text: $country).eventField()
                        TextField("City", text: $city).eventField()
                        TextField("Max Attendees", text: $maxAttendees)
                            .keyboardType(.numberPad).eventField()

                        DatePicker("Date & Time", selection: $date)
                            .tint(.ccGold)
                            .foregroundColor(.ccLightText)

                        Button("Create Event") {
                            let event = CCEvent(
                                organizerId: "", organizerName: "",
                                title: title, description: description,
                                country: country, city: city, date: date,
                                imageURL: "", attendees: [],
                                maxAttendees: Int(maxAttendees) ?? 50,
                                isFeatured: false, timestamp: Date()
                            )
                            Task {
                                await manager.createEvent(event)
                                onDone()
                                dismiss()
                            }
                        }
                        .buttonStyle(CCButtonStyle())
                        .disabled(title.isEmpty || country.isEmpty || city.isEmpty)
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

private extension View {
    func eventField() -> some View {
        self
            .padding()
            .background(Color.ccCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .foregroundColor(.ccLightText)
    }
}
