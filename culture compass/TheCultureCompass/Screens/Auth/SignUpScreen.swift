import SwiftUI

struct SignUpScreen: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    private var isValid: Bool {
        !username.isEmpty && !email.isEmpty && password.count >= 6 && password == confirmPassword
    }

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Join the Culture")
                    .font(.largeTitle.bold())
                    .foregroundColor(.ccGold)
                Text("Create your account")
                    .font(.subheadline)
                    .foregroundColor(.ccSubtext)

                VStack(spacing: 14) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .padding()
                        .background(Color.ccCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.ccLightText)

                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.ccCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.ccLightText)

                    SecureField("Password (6+ characters)", text: $password)
                        .padding()
                        .background(Color.ccCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.ccLightText)

                    SecureField("Confirm Password", text: $confirmPassword)
                        .padding()
                        .background(Color.ccCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.ccLightText)
                }
                .padding(.horizontal)

                if let error = authManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button("Create Account") {
                    Task { await authManager.signUp(email: email, password: password, username: username) }
                }
                .buttonStyle(CCButtonStyle())
                .disabled(!isValid || authManager.isLoading)

                if authManager.isLoading {
                    ProgressView().tint(.ccGold)
                }

                Button("Already have an account? Sign In") {
                    dismiss()
                }
                .font(.footnote)
                .foregroundColor(.ccSubtext)

                Spacer()
            }
        }
    }
}
