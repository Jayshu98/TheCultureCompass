import SwiftUI

struct DiscoverScreen: View {
    @StateObject private var postManager = PostDataManager()
    @State private var showCreatePost = false
    @State private var caption = ""
    @State private var imageData: Data?
    @State private var showImagePicker = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Discover")
                        .font(.title.bold())
                        .foregroundColor(.ccGold)
                    Spacer()
                    Button {
                        showImagePicker = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.ccGold)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                if postManager.isLoading && postManager.posts.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(postManager.posts) { post in
                                PostCardView(
                                    post: post,
                                    onComment: { comment in
                                        guard let id = post.id else { return }
                                        Task { await postManager.addComment(to: id, comment: comment) }
                                    },
                                    onDelete: {
                                        Task { await postManager.deletePost(post) }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await postManager.refresh()
                    }
                }
            }

            // Caption prompt overlay
            if showCreatePost {
                CaptionPromptView(
                    caption: $caption,
                    isPresented: $showCreatePost,
                    onSubmit: {
                        Task {
                            await postManager.createPost(caption: caption, imageData: imageData)
                            caption = ""
                            imageData = nil
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: showCreatePost)
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if imageData != nil {
                showCreatePost = true
            }
        }) {
            ImagePicker(imageData: $imageData)
        }
        .onAppear { postManager.startListening() }
        .onDisappear { postManager.stopListening() }
    }
}
