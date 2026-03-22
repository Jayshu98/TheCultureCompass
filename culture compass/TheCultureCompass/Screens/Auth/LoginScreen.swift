import SwiftUI

struct LoginScreen: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var showSignUp = false

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Text("🌍")
                    .font(.system(size: 64))
                Text("The Culture Compass")
                    .font(.largeTitle.bold())
                    .foregroundColor(.ccGold)
                Text("Travel. Connect. Discover.")
                    .font(.subheadline)
                    .foregroundColor(.ccSubtext)

                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .padding()
                        .background(Color.ccCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundColor(.ccLightText)

                    SecureField("Password", text: $password)
                        .textContentType(.password)
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

                Button("Sign In") {
                    Task { await authManager.signIn(email: email, password: password) }
                }
                .buttonStyle(CCButtonStyle())
                .disabled(authManager.isLoading)

                if authManager.isLoading {
                    ProgressView().tint(.ccGold)
                }

                Button("Don't have an account? Sign Up") {
                    showSignUp = true
                }
                .font(.footnote)
                .foregroundColor(.ccSubtext)

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showSignUp) {
            SignUpScreen()
                .environmentObject(authManager)
        }
    }
}
