import SwiftUI
import MessageUI

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @State private var showMailComposer = false
    @State private var showShareSheet = false
    
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }
    
    private var deviceInfo: String {
        let device = UIDevice.current
        return "\(device.model) - iOS \(device.systemVersion)"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // FAQ Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("FREQUENTLY ASKED QUESTIONS")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextTertiary)
                        
                        VStack(spacing: 0) {
                            FAQRow(
                                question: "How do I reset my password?",
                                answer: "You can reset your password from the sign-in screen by tapping 'Forgot Password' and following the instructions sent to your email."
                            )
                            
                            Divider().padding(.leading, 16)
                            
                            FAQRow(
                                question: "Is my data secure and private?",
                                answer: "Yes, your data is encrypted and stored securely. We never share your personal information with third parties. All conversations remain private."
                            )
                            
                            Divider().padding(.leading, 16)
                            
                            FAQRow(
                                question: "How do I change my companion's personality?",
                                answer: "Go to Profile > Edit Companion to change your AI companion's name and personality type to better suit your preferences."
                            )
                            
                            Divider().padding(.leading, 16)
                            
                            FAQRow(
                                question: "Can I use the app offline?",
                                answer: "Some features like journaling work offline, but AI conversations require an internet connection for the best experience."
                            )
                            
                            Divider().padding(.leading, 16)
                            
                            FAQRow(
                                question: "How do I enable Face ID/Touch ID?",
                                answer: "Go to Profile > App Lock (Face ID / Touch ID) and toggle it on. This adds an extra layer of security to protect your data."
                            )
                        }
                        .background(Color.omniCardBeige)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                    
                    // Contact Support
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CONTACT SUPPORT")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextTertiary)
                        
                        VStack(spacing: 0) {
                            SupportActionRow(
                                icon: "envelope.fill",
                                title: "Email Support",
                                subtitle: "Get help via email",
                                iconColor: .blue
                            ) {
                                sendSupportEmail()
                            }
                            
                            Divider().padding(.leading, 50)
                            
                            SupportActionRow(
                                icon: "exclamationmark.triangle.fill",
                                title: "Report a Bug",
                                subtitle: "Help us improve the app",
                                iconColor: .orange
                            ) {
                                reportBug()
                            }
                            
                            Divider().padding(.leading, 50)
                            
                            SupportActionRow(
                                icon: "star.fill",
                                title: "Rate the App",
                                subtitle: "Share your feedback",
                                iconColor: .yellow
                            ) {
                                rateApp()
                            }
                        }
                        .background(Color.omniCardLavender)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                    
                    // App Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("APP INFORMATION")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextTertiary)
                        
                        VStack(spacing: 12) {
                            InfoRow(
                                icon: "app.badge.fill",
                                title: "App Version",
                                value: appVersion,
                                iconColor: colorScheme == .dark ? .omniNeonSage : .omniPrimary
                            )
                            
                            InfoRow(
                                icon: "iphone",
                                title: "Device",
                                value: deviceInfo,
                                iconColor: .gray
                            )
                            
                            InfoRow(
                                icon: "calendar.badge.clock",
                                title: "Last Updated",
                                value: getLastUpdateDate(),
                                iconColor: .purple
                            )
                        }
                        .padding()
                        .background(Color.omniCardSoftBlue)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                    
                    // Debug Information (for support)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("DEBUG INFORMATION")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextTertiary)
                        
                        Button(action: {
                            copyDebugInfo()
                        }) {
                            HStack {
                                Image(systemName: "doc.on.clipboard.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(colorScheme == .dark ? .omniNeonLavender : .purple)
                                
                                Text("Copy Debug Information")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.omniTextPrimary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(.omniTextTertiary)
                            }
                            .padding()
                            .background(Color.omniCardBeige)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("Copy this information when contacting support for faster assistance.")
                            .font(.caption)
                            .foregroundColor(.omniTextTertiary)
                    }
                }
                .padding()
            }
            .background(Color.omniBackground)
            .navigationTitle("Help & Support")
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
    
    private func sendSupportEmail() {
        let email = "support@omniapp.com"
        let subject = "OmniAI Support Request"
        let body = """
        
        
        ---
        Debug Information:
        App Version: \(appVersion)
        Device: \(deviceInfo)
        
        Please describe your issue above this line.
        """
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            openURL(url)
        }
    }
    
    private func reportBug() {
        let email = "bugs@omniapp.com"
        let subject = "Bug Report - OmniAI"
        let body = """
        
        
        Steps to reproduce:
        1. 
        2. 
        3. 
        
        Expected behavior:
        
        
        Actual behavior:
        
        
        ---
        Debug Information:
        App Version: \(appVersion)
        Device: \(deviceInfo)
        """
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            openURL(url)
        }
    }
    
    private func rateApp() {
        // In a real app, this would open the App Store review page
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            openURL(url)
        }
    }
    
    private func copyDebugInfo() {
        let debugInfo = """
        OmniAI Debug Information
        App Version: \(appVersion)
        Device: \(deviceInfo)
        Timestamp: \(Date().description)
        """
        
        UIPasteboard.general.string = debugInfo
    }
    
    private func getLastUpdateDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: Date())
    }
}

struct FAQRow: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(question)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.omniTextPrimary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextTertiary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(.subheadline)
                    .foregroundColor(.omniTextSecondary)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

struct SupportActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.omniTextPrimary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.omniTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
            }
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HelpSupportView()
}