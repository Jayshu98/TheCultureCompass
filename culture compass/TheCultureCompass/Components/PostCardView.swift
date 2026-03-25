import SwiftUI
import FirebaseAuth

struct PostCardView: View {
    let post: Post
    let onComment: (String) -> Void
    let onDelete: () -> Void

    @State private var commentText = ""
    @State private var showComments = false
    @State private var showDeleteConfirm = false
    @State private var profileNavUserId: String?

    private var isOwner: Bool {
        Auth.auth().currentUser?.uid == post.userId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Button {
                    profileNavUserId = post.userId
                } label: {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.ccBrown)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(String(post.user.prefix(1)).uppercased())
                                    .font(.caption.bold())
                                    .foregroundColor(.ccGold)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(post.user)
                                .font(.subheadline.bold())
                                .foregroundColor(.ccLightText)
                            HStack(spacing: 6) {
                                Text(post.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.caption2)
                                    .foregroundColor(.ccSubtext)
                                if !post.location.isEmpty {
                                    HStack(spacing: 2) {
                                        Image(systemName: "mappin")
                                            .font(.system(size: 8))
                                        Text(post.location)
                                            .font(.caption2)
                                    }
                                    .foregroundColor(.ccGold)
                                }
                            }
                        }
                    }
                }

                Spacer()

                if isOwner {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.body.bold())
                            .foregroundColor(.ccSubtext)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }

            // Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.body)
                    .foregroundColor(.ccLightText)
            }

            // Image
            if !post.imageURL.isEmpty {
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.ccCardBg)
                            .frame(height: 200)
                            .overlay(Image(systemName: "photo").foregroundColor(.ccSubtext))
                    default:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.ccCardBg)
                            .frame(height: 200)
                            .overlay(ProgressView().tint(.ccGold))
                    }
                }
            }

            // Actions
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showComments.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments.count)")
                    }
                    .font(.caption)
                    .foregroundColor(.ccSubtext)
                }
                Spacer()
            }

            // Comments
            if showComments {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments) { comment in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .top, spacing: 8) {
                                Button {
                                    profileNavUserId = comment.userId
                                } label: {
                                    Text(comment.user)
                                        .font(.caption.bold())
                                        .foregroundColor(.ccGold)
                                }
                                Text(comment.comment)
                                    .font(.caption)
                                    .foregroundColor(.ccLightText)
                            }
                            Text(comment.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.system(size: 9))
                                .foregroundColor(.ccSubtext)
                        }
                    }

                    HStack {
                        TextField("Add a comment...", text: $commentText)
                            .font(.caption)
                            .foregroundColor(.ccLightText)
                            .textFieldStyle(.plain)
                        Button {
                            guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let check = ContentFilter.isCleanContent(commentText)
                            guard check.clean else { return }
                            onComment(commentText)
                            commentText = ""
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.ccGold)
                        }
                    }
                    .padding(8)
                    .background(Color.ccDarkBg)
                    .clipShape(Capsule())
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .ccCard()
        .navigationDestination(item: $profileNavUserId) { userId in
            UserPassportScreen(userId: userId)
        }
        .alert("Delete Post?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This can't be undone.")
        }
    }
}
