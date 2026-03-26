import SwiftUI
import Kingfisher
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

            // --- 1. HEADER (With Timestamp) ---
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(LinearGradient(colors: [.ccGold, .ccBrown], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(post.user.prefix(1)).uppercased())
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.user)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.ccLightText)

                        HStack(spacing: 6) {
                            Text(post.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                .font(.system(size: 12))
                                .foregroundColor(.ccSubtext)

                            if !post.location.isEmpty {
                                HStack(spacing: 2) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 10))
                                    Text(post.location)
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(.ccGold)
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onTapProfile(post.userId)
                }

                Spacer()

                if isOwner {
                    Menu {
                        Button(role: .destructive) { showDeleteConfirm = true } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.ccSubtext)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .highPriorityGesture(TapGesture())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            // --- 2. FULL-BLEED IMAGE ---
            if !post.imageURL.isEmpty {
                KFImage(URL(string: post.imageURL))
                    .placeholder {
                        Rectangle().fill(Color.ccCardBg).frame(height: 300)
                            .overlay(ProgressView().tint(.ccGold))
                    }
                    .fade(duration: 0.25)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minHeight: 450)
                    .clipped()
            }

            // --- 3. INTERACTION BAR ---
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            showComments.toggle()
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: showComments ? "bubble.left.fill" : "bubble.left")
                                .font(.system(size: 24))
                            Text("\(post.comments.count)")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.ccLightText)

                    Spacer()
                }
                .padding(.top, 12)

                // --- 4. CAPTION ---
                if !post.caption.isEmpty {
                    (Text(post.user).bold() + Text("  ") + Text(post.caption))
                        .font(.system(size: 15))
                        .foregroundColor(.ccLightText)
                        .lineSpacing(3)
                }

                // --- 5. COMMENTS DRAWER ---
                if showComments {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(post.comments) { comment in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(comment.user).bold()
                                        .font(.system(size: 13))
                                        .foregroundColor(.ccGold)
                                        .onTapGesture { onTapProfile(comment.userId) }

                                    Text(comment.comment)
                                        .font(.system(size: 13))
                                        .foregroundColor(.ccLightText)
                                }
                                Text(comment.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                                    .font(.system(size: 9))
                                    .foregroundColor(.ccSubtext)
                            }
                        }

                        // Input Field
                        HStack {
                            TextField("Add a comment...", text: $commentText)
                                .font(.system(size: 14))
                                .padding(.horizontal, 4)

                            if !commentText.trimmingCharacters(in: .whitespaces).isEmpty {
                                Button("Post") {
                                    onComment(commentText)
                                    commentText = ""
                                }
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.ccGold)
                            }
                        }
                        .padding(10)
                        .background(Color.ccDarkBg.opacity(0.6))
                        .cornerRadius(12)
                    }
                    .padding(.top, 8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(Color.ccCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.ccGold.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
        .padding(.vertical, 8)
        .alert("Delete Post?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}
