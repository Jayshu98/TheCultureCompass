import SwiftUI
import FirebaseAuth

struct PostCardView: View {
    let post: Post
    let onComment: (String) -> Void
    let onDelete: () -> Void

    @State private var commentText = ""
    @State private var showComments = false

    private var isOwner: Bool {
        Auth.auth().currentUser?.uid == post.userId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
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
                    Text(post.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.ccSubtext)
                }
                Spacer()
                if isOwner {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.ccSubtext)
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
                        HStack(alignment: .top, spacing: 8) {
                            Text(comment.user)
                                .font(.caption.bold())
                                .foregroundColor(.ccGold)
                            Text(comment.comment)
                                .font(.caption)
                                .foregroundColor(.ccLightText)
                        }
                    }

                    HStack {
                        TextField("Add a comment...", text: $commentText)
                            .font(.caption)
                            .foregroundColor(.ccLightText)
                            .textFieldStyle(.plain)
                        Button {
                            guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
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
    }
}
