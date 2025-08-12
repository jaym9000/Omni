import SwiftUI

struct PersonalInformationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let user = authManager.currentUser {
                        VStack(spacing: 16) {
                            InfoRow(
                                icon: "envelope.fill",
                                title: "Email Address",
                                value: user.email,
                                iconColor: .blue
                            )
                            
                            InfoRow(
                                icon: "person.fill",
                                title: "Display Name",
                                value: user.displayName,
                                iconColor: .omniPrimary
                            )
                            
                            InfoRow(
                                icon: user.emailVerified ? "checkmark.shield.fill" : "xmark.shield.fill",
                                title: "Email Verification",
                                value: user.emailVerified ? "Verified" : "Not Verified",
                                iconColor: user.emailVerified ? .green : .orange,
                                valueColor: user.emailVerified ? .omniSuccess : .omniWarning
                            )
                            
                            InfoRow(
                                icon: getAuthProviderIcon(user.authProvider),
                                title: "Sign-in Method",
                                value: getAuthProviderName(user.authProvider),
                                iconColor: getAuthProviderColor(user.authProvider)
                            )
                            
                            InfoRow(
                                icon: "calendar.badge.plus",
                                title: "Member Since",
                                value: formatDate(user.createdAt),
                                iconColor: .purple
                            )
                            
                            InfoRow(
                                icon: "clock.fill",
                                title: "Last Updated",
                                value: formatDate(user.updatedAt),
                                iconColor: .gray
                            )
                        }
                        .padding()
                        .background(Color.omniCardBeige)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        
                        // Companion Information
                        VStack(spacing: 16) {
                            Text("COMPANION SETTINGS")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.omniTextTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            InfoRow(
                                icon: "heart.fill",
                                title: "Companion Name",
                                value: user.companionName,
                                iconColor: .pink
                            )
                            
                            InfoRow(
                                icon: "sparkles",
                                title: "Personality",
                                value: user.companionPersonality.capitalized,
                                iconColor: .yellow
                            )
                        }
                        .padding()
                        .background(Color.omniCardLavender)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        
                        // Privacy & Security
                        VStack(spacing: 16) {
                            Text("PRIVACY & SECURITY")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.omniTextTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            InfoRow(
                                icon: "faceid",
                                title: "Biometric Authentication",
                                value: user.biometricAuthEnabled ? "Enabled" : "Disabled",
                                iconColor: .green,
                                valueColor: user.biometricAuthEnabled ? .omniSuccess : .omniTextTertiary
                            )
                        }
                        .padding()
                        .background(Color.omniCardSoftBlue)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .background(Color.omniBackground)
            .navigationTitle("Personal Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                }
            }
        }
    }
    
    private func getAuthProviderIcon(_ provider: AuthProvider) -> String {
        switch provider {
        case .email:
            return "envelope.fill"
        case .apple:
            return "applelogo"
        case .google:
            return "globe"
        }
    }
    
    private func getAuthProviderName(_ provider: AuthProvider) -> String {
        switch provider {
        case .email:
            return "Email & Password"
        case .apple:
            return "Sign in with Apple"
        case .google:
            return "Sign in with Google"
        }
    }
    
    private func getAuthProviderColor(_ provider: AuthProvider) -> Color {
        switch provider {
        case .email:
            return .blue
        case .apple:
            return .black
        case .google:
            return .red
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    var valueColor: Color = .omniTextPrimary
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.omniTextSecondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(valueColor)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PersonalInformationView()
        .environmentObject(AuthenticationManager())
}