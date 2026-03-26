import SwiftUI

struct ChatFeedScreen: View {
    let country: Country
    @StateObject private var chatManager = ChatDataManager()
    @State private var newMessage = ""
    @State private var showCompose = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Auto-delete warning
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text("Messages disappear after 7 days")
                        .font(.system(size: 11))
                }
                .foregroundColor(.ccGold.opacity(0.7))
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity)
                .background(Color.ccGold.opacity(0.08))

                if chatManager.isLoading && chatManager.messages.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else if chatManager.messages.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text(country.flag)
                            .font(.system(size: 48))
                        Text("No messages yet")
                            .font(.subheadline)
                            .foregroundColor(.ccSubtext)
                        Text("Be the first to post in \(country.name)")
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(chatManager.messages) { msg in
                                ChatMessageView(
                                    message: msg,
                                    onReply: { reply in
                                        guard let id = msg.id else { return }
                                        Task { await chatManager.addReply(to: id, message: reply) }
                                    },
                                    onDelete: {
                                        Task { await chatManager.deleteMessage(msg) }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }

            // Floating compose button
            Button {
                showCompose = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.bold())
                    .foregroundColor(.black)
                    .frame(width: 56, height: 56)
                    .background(LinearGradient.ccGoldShimmer)
                    .clipShape(Circle())
                    .shadow(color: .ccGold.opacity(0.4), radius: 8)
            }
            .padding()

            // Compose sheet
            if showCompose {
                ComposeOverlay(
                    text: $newMessage,
                    isPresented: $showCompose,
                    onSend: {
                        Task {
                            await chatManager.sendMessage(newMessage, location: country.name)
                            newMessage = ""
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35), value: showCompose)
        .navigationTitle("\(country.flag) \(country.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: SafetyRatingsScreen(country: country)) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.ccGold)
                }
            }
        }
        .onAppear { chatManager.startListening(for: country.name) }
        .onDisappear { chatManager.stopListening() }
    }
}

private struct ComposeOverlay: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    let onSend: () -> Void
    @State private var contentWarning: String?

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                Text("New Message")
                    .font(.headline)
                    .foregroundColor(.ccGold)

                TextField("Share your experience...", text: $text, axis: .vertical)
                    .lineLimit(3...8)
                    .padding()
                    .background(Color.ccDarkBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .foregroundColor(.ccLightText)

                if let contentWarning {
                    Text(contentWarning)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                HStack {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.ccSubtext)
                    Spacer()
                    Button("Send") {
                        let check = ContentFilter.isCleanContent(text)
                        if !check.clean {
                            contentWarning = check.reason
                            return
                        }
                        contentWarning = nil
                        onSend()
                        isPresented = false
                    }
                    .buttonStyle(CCButtonStyle())
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(24)
            .background(LinearGradient.ccCard)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.5), radius: 16)
            .padding(.horizontal, 20)
        }
    }
}
