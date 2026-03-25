import SwiftUI

struct DiscoverScreen: View {
    @StateObject private var postManager = PostDataManager()
    @State private var showCreatePost = false
    @State private var caption = ""
    @State private var location = ""
    @State private var imageData: Data?
    @State private var showImagePicker = false
    @State private var scrollOffset: CGFloat = 0
    @State private var selectedProfileUserId: String?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background
            Color.ccDarkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Sleek Header ──
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Discover")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(.ccLightText)
                        Text("See what the culture is up to")
                            .font(.system(size: 13))
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                    Button { showImagePicker = true } label: {
                        Image(systemName: "plus.app")
                            .font(.system(size: 24))
                            .foregroundStyle(LinearGradient.ccGoldShimmer)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 14)

                // Thin gold accent line
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, .ccGold.opacity(0.4), .ccGold.opacity(0.6), .ccGold.opacity(0.4), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)

                // ── Feed ──
                if postManager.isLoading && postManager.posts.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.ccGold)
                            .scaleEffect(1.2)
                        Text("Loading the feed...")
                            .font(.system(size: 14))
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else if postManager.posts.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "globe.americas")
                            .font(.system(size: 48))
                            .foregroundStyle(LinearGradient.ccGoldShimmer)
                        Text("No posts yet")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.ccLightText)
                        Text("Be the first to share something")
                            .font(.system(size: 14))
                            .foregroundColor(.ccSubtext)
                    }
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(postManager.posts) { post in
                                PostCardView(
                                    post: post,
                                    onComment: { comment in
                                        guard let id = post.id else { return }
                                        Task { await postManager.addComment(to: id, comment: comment) }
                                    },
                                    onDelete: {
                                        Task { await postManager.deletePost(post) }
                                    },
                                    onTapProfile: { userId in
                                        selectedProfileUserId = userId
                                    }
                                )
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 100)
                    }
                    .refreshable { await postManager.refresh() }
                }
            }

            // ── Caption Prompt Overlay ──
            if showCreatePost {
                CaptionPromptView(
                    caption: $caption,
                    location: $location,
                    isPresented: $showCreatePost,
                    onSubmit: {
                        Task {
                            await postManager.createPost(caption: caption, imageData: imageData, location: location)
                            caption = ""
                            location = ""
                            imageData = nil
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showCreatePost)
        .navigationDestination(item: $selectedProfileUserId) { userId in
            UserPassportScreen(userId: userId)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: $imageData)
        }
        .onChange(of: imageData) { _, newData in
            if newData != nil { showCreatePost = true }
        }
        .onAppear { postManager.startListening() }
        .onDisappear { postManager.stopListening() }
    }
}
