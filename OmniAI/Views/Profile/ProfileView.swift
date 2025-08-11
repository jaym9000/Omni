import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Centered Profile Title
                    Text("Profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.omniTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                    
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
                    .background(Color.omniCardSoftBlue)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                
                    // Account Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACCOUNT")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.omniTextTertiary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ProfileSettingRow(
                                icon: "person.fill",
                                iconColor: .omniprimary,
                                title: "Personal Information",
                                action: {}
                            )
                            
                            Divider().padding(.leading, 50)
                            
                            ProfileSettingRow(
                                icon: "creditcard.fill",
                                iconColor: .omniprimary,
                                title: "Subscription Management",
                                trailing: AnyView(
                                    Text("Premium")
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
                        .background(Color.omniCardSoftBlue)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    }
                
                    // App Preferences Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PREFERENCES")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.omniTextTertiary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ProfileSettingRow(
                                icon: "bell.fill",
                                iconColor: .blue,
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
                            
                            HStack {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.indigo)
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
                                    .foregroundColor(.green)
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
                                icon: "heart.fill",
                                iconColor: .pink,
                                title: "Edit Companion",
                                trailing: AnyView(
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.omniprimary)
                                ),
                                action: {}
                            )
                        }
                        .background(Color.omniCardSoftBlue)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    }
                
                    // Support & Legal Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SUPPORT & LEGAL")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.omniTextTertiary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ProfileSettingRow(
                                icon: "questionmark.circle.fill",
                                iconColor: .orange,
                                title: "Help & Support",
                                action: {}
                            )
                            
                            Divider().padding(.leading, 50)
                            
                            ProfileSettingRow(
                                icon: "shield.checkerboard",
                                iconColor: .teal,
                                title: "Privacy Policy",
                                action: {}
                            )
                            
                            Divider().padding(.leading, 50)
                            
                            ProfileSettingRow(
                                icon: "doc.text.fill",
                                iconColor: .purple,
                                title: "Terms & Conditions",
                                action: {}
                            )
                        }
                        .background(Color.omniCardSoftBlue)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    }
                
                    // Emergency Resources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("EMERGENCY")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.omniTextTertiary)
                            .padding(.horizontal)
                        
                        Button(action: {}) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Text("Crisis Resources")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.9))
                            .cornerRadius(16)
                            .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                
                    // Account Actions Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("ACCOUNT ACTIONS")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.omniTextTertiary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            ProfileSettingRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                iconColor: .gray,
                                title: "Logout",
                                action: { showSignOutAlert = true }
                            )
                            
                            Divider().padding(.leading, 50)
                            
                            ProfileSettingRow(
                                icon: "trash.fill",
                                iconColor: .red,
                                title: "Delete Account",
                                action: { showDeleteAlert = true }
                            )
                        }
                        .background(Color.omniCardSoftBlue)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    }
                    
                    // Version
                    Text(appVersion)
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextTertiary)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(Color.omniBackground)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    // Handle account deletion
                }
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
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