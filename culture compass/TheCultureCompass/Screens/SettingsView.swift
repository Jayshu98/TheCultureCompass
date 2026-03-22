import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ZStack {
            LinearGradient.ccBackground.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Text("Settings")
                        .font(.title.bold())
                        .foregroundColor(.ccGold)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

                VStack(spacing: 0) {
                    SettingsRow(icon: "person.circle", title: "Account", subtitle: authManager.appUser?.email ?? "")
                    Divider().background(Color.ccCardBg)
                    SettingsRow(icon: "bell", title: "Notifications", subtitle: "Manage alerts")
                    Divider().background(Color.ccCardBg)
                    SettingsRow(icon: "lock.shield", title: "Privacy", subtitle: "Data & security")
                    Divider().background(Color.ccCardBg)
                    SettingsRow(icon: "info.circle", title: "About", subtitle: "The Culture Compass v1.0")
                }
                .background(Color.ccCardBg)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                Button {
                    authManager.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Sign Out")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ccCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                Spacer()
            }
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.ccGold)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.ccLightText)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.ccSubtext)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.ccSubtext)
        }
        .padding()
    }
}
