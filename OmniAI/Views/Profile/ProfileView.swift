import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // User Profile Card
                    VStack(spacing: 24) {
                        HStack {
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniTextSecondary)
                            }
                        }
                        
                        VStack(spacing: 16) {
                            // User Avatar/Initials
                            ZStack {
                                Circle()
                                    .fill(Color.omniTextTertiary.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Text(getInitials())
                                    .font(.system(size: 32, weight: .semibold))
                                    .foregroundColor(.omniTextPrimary)
                            }
                            
                            // Daily Affirmations Feature Card
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniprimary)
                                
                                Text("Receive daily positive affirmations")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.omniTextSecondary)
                                
                                Spacer()
                                
                                Text("Coming Soon")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.omniTextTertiary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.omniTextTertiary.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                
                    // Preferences Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PREFERENCES")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.omniTextTertiary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ProfileSettingRow(
                                icon: "person.fill",
                                iconColor: .brown,
                                title: "Personal Information",
                                action: {}
                            )
                            
                            Divider().padding(.leading, 50)
                            
                            ProfileSettingRow(
                                icon: "bell.fill",
                                iconColor: .brown,
                                title: "Notifications",
                                trailing: AnyView(
                                    Text("Coming Soon")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.omniTextTertiary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.omniTextTertiary.opacity(0.1))
                                        .cornerRadius(8)
                                ),
                                action: {}
                            )
                            
                            Divider().padding(.leading, 50)
                            
                            ProfileSettingRow(
                                icon: "heart.fill",
                                iconColor: .brown,
                                title: "Edit Companion",
                                trailing: AnyView(
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.omniprimary)
                                ),
                                action: {}
                            )
                            
                            Divider().padding(.leading, 50)
                            
                            HStack {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.brown)
                                    .frame(width: 24)
                                
                                Text("Dark Mode")
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniTextPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: $themeManager.isDarkMode)
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                            }
                            .padding()
                            
                            Divider().padding(.leading, 50)
                            
                            HStack {
                                Image(systemName: "faceid")
                                    .font(.system(size: 16))
                                    .foregroundColor(.brown)
                                    .frame(width: 24)
                                
                                Text("App Lock (Face ID / Touch ID)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniTextPrimary)
                                
                                Spacer()
                                
                                Toggle("", isOn: .constant(false))
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                            }
                            .padding()
                            
                            Divider().padding(.leading, 50)
                            
                            ProfileSettingRow(
                                icon: "creditcard.fill",
                                iconColor: .brown,
                                title: "Subscription Management",
                                trailing: AnyView(
                                    Text("Free")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.omniprimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.omniprimary.opacity(0.1))
                                        .cornerRadius(8)
                                ),
                                action: {}
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                
                }
                .padding()
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    private func getInitials() -> String {
        let displayName = authManager.currentUser?.displayName ?? "User"
        let components = displayName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }.joined()
        return String(initials.prefix(2)).uppercased()
    }
}

// MARK: - Profile Setting Row
struct ProfileSettingRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var trailing: AnyView? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextPrimary)
                
                Spacer()
                
                if let trailing = trailing {
                    trailing
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextTertiary)
                }
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
        .environmentObject(PremiumManager())
        .environmentObject(ThemeManager())
}