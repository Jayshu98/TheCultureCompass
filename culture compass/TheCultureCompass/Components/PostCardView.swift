import SwiftUI
import FirebaseAuth

struct PostCardView: View {
    let post: Post
    let onComment: (String) -> Void
    let onDelete: () -> Void
    let onTapProfile: (String) -> Void

    @State private var commentText = ""
    @State private var showComments = false
    @State private var showDeleteConfirm = false

    private var isOwner: Bool {
        Auth.auth().currentUser?.uid == post.userId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Header ──
            HStack(spacing: 10) {
                Button { onTapProfile(post.userId) } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(LinearGradient.ccGoldShimmer, lineWidth: 2)
                            .frame(width: 38, height: 38)
                        Circle()
                            .fill(Color.ccCardBg)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(post.user.prefix(1)).uppercased())
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.ccGold)
                            )
                    }
                }

                Button { onTapProfile(post.userId) } label: {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(post.user)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.ccLightText)
                        if !post.location.isEmpty {
                            Text(post.location)
                                .font(.system(size: 11))
                                .foregroundColor(.ccSubtext)
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
                            .font(.body)
                            .foregroundColor(.ccLightText)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // ── Image (edge-to-edge) ──
            if !post.imageURL.isEmpty {
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 300, maxHeight: 450)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.ccCardBg)
                            .frame(height: 300)
                            .overlay(Image(systemName: "photo").font(.title).foregroundColor(.ccSubtext))
                    default:
                        Rectangle()
                            .fill(Color.ccCardBg)
                            .frame(height: 300)
                            .overlay(ProgressView().tint(.ccGold))
                    }
                }
            }

            // ── Action buttons ──
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(response: 0.3)) { showComments.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 20))
                        if post.comments.count > 0 {
                            Text("\(post.comments.count)")
                                .font(.system(size: 13))
                        }
                    }
                    .foregroundColor(.ccLightText)
                }
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // ── Caption ──
            if !post.caption.isEmpty {
                (Text(post.user).font(.system(size: 13, weight: .semibold)).foregroundColor(.ccLightText)
                + Text(" ")
                + Text(post.caption).font(.system(size: 13)).foregroundColor(.ccLightText.opacity(0.9)))
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
            }

            // ── Comments ──
            if showComments {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(post.comments) { comment in
                        HStack(alignment: .top, spacing: 4) {
                            Button { onTapProfile(comment.userId) } label: {
                                Text(comment.user)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.ccGold)
                            }
                            Text(comment.comment)
                                .font(.system(size: 13))
                                .foregroundColor(.ccLightText.opacity(0.9))
                        }
                    }

                    HStack(spacing: 8) {
                        TextField("Add a comment...", text: $commentText)
                            .font(.system(size: 13))
                            .foregroundColor(.ccLightText)
                            .textFieldStyle(.plain)
                        Button {
                            guard !commentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            let check = ContentFilter.isCleanContent(commentText)
                            guard check.clean else { return }
                            onComment(commentText)
                            commentText = ""
                        } label: {
                            Text("Post")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.ccGold)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
                .transition(.opacity)
            } else if !post.comments.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.3)) { showComments = true }
                } label: {
                    Text("View all \(post.comments.count) comment\(post.comments.count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundColor(.ccSubtext)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 2)
            }

            // ── Timestamp ──
            Text(post.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.system(size: 11))
                .foregroundColor(.ccSubtext.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
        .background(Color.black)
        .alert("Delete Post?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This can't be undone.")
        }
    }
}
