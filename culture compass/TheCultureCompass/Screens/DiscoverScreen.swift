import SwiftUI

struct DiscoverScreen: View {
    @StateObject private var postManager = PostDataManager()
    @State private var showCreatePost = false
    @State private var caption = ""
    @State private var location = ""
    @State private var imageData: Data?
    @State private var showImagePicker = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Instagram-style header
                HStack {
                    Text("The Culture Compass")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundColor(.ccGold)
                    Spacer()
                    Button { showImagePicker = true } label: {
                        Image(systemName: "plus.app")
                            .font(.title2)
                            .foregroundColor(.ccLightText)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider().background(Color.ccSubtext.opacity(0.2))

                if postManager.isLoading && postManager.posts.isEmpty {
                    Spacer()
                    ProgressView().tint(.ccGold)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
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
                    }
                    .refreshable { await postManager.refresh() }
                }
            }

            // Caption prompt overlay
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
        .sheet(isPresented: $showImagePicker, onDismiss: {
            if imageData != nil { showCreatePost = true }
        }) {
            ImagePicker(imageData: $imageData)
        }
        .onAppear { postManager.startListening() }
        .onDisappear { postManager.stopListening() }
    }
}
