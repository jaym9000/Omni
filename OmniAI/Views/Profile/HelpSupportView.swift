import SwiftUI
import MessageUI

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

struct HelpSupportView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    @State private var showMailComposer = false
    @State private var showShareSheet = false
    @State private var showEvidenceSources = false
    @State private var showChatAssistant = false
    
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
                VStack(spacing: 24) {
                    // Contact Support Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Contact Support")
                            .font(.headline)
                            .foregroundColor(.omniTextPrimary)
                        
                        VStack(spacing: 12) {
                            ContactOptionCard(
                                icon: "envelope",
                                iconColor: .blue.opacity(0.8),
                                title: "Email Support",
                                subtitle: "Get help via email within 24 hours"
                            ) {
                                sendSupportEmail()
                            }
                            
                            ContactOptionCard(
                                icon: "message",
                                iconColor: .blue.opacity(0.8),
                                title: "Chat with AI Assistant",
                                subtitle: "Get immediate answers to common questions"
                            ) {
                                showChatAssistant = true
                            }
                            
                            ContactOptionCard(
                                icon: "books.vertical",
                                iconColor: .blue.opacity(0.8),
                                title: "Evidence & Sources",
                                subtitle: "View research citations and therapeutic sources"
                            ) {
                                showEvidenceSources = true
                            }
                        }
                    }
                    
                    // Frequently Asked Questions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Frequently Asked Questions")
                            .font(.headline)
                            .foregroundColor(.omniTextPrimary)
                        
                        VStack(spacing: 0) {
                            FAQRow(
                                question: "How do I reset my password?",
                                answer: "You can reset your password from the sign-in screen by tapping 'Forgot Password' and following the instructions sent to your email."
                            )
                            
                            Divider().padding(.leading, 16)
                            
                            FAQRow(
                                question: "Is my data private and secure?",
                                answer: "Yes, your data is encrypted and stored securely. We never share your personal information with third parties. All conversations remain private."
                            )
                            
                            Divider().padding(.leading, 16)
                            
                            FAQRow(
                                question: "How can I customize my AI companion?",
                                answer: "Go to Profile > Edit Companion to change your AI companion's name and personality type to better suit your preferences."
                            )
                            
                            Divider().padding(.leading, 16)
                            
                            FAQRow(
                                question: "Can I export my journal entries?",
                                answer: "Premium users can export their journal entries in PDF or text format. Go to Journal > Export to download your entries."
                            )
                            
                            Divider().padding(.leading, 16)
                            
                            FAQRow(
                                question: "How do I cancel my subscription?",
                                answer: "You can manage your subscription through your device's Settings > [Your Name] > Subscriptions. Select OmniAI and choose 'Cancel Subscription'."
                            )
                        }
                        .background(Color.omniCardBeige)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    }
                    
                    // Additional Support Options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Additional Support")
                            .font(.headline)
                            .foregroundColor(.omniTextPrimary)
                        
                        VStack(spacing: 12) {
                            Button(action: {
                                reportBug()
                            }) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "ladybug")
                                            .font(.system(size: 18))
                                            .foregroundColor(.orange)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Report a Bug")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.omniTextPrimary)
                                        
                                        Text("Help us improve the app")
                                            .font(.caption)
                                            .foregroundColor(.omniTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.omniTextTertiary)
                                }
                                .padding()
                                .background(Color.omniCardLavender)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: {
                                rateApp()
                            }) {
                                HStack {
                                    ZStack {
                                        Circle()
                                            .fill(Color.yellow.opacity(0.1))
                                            .frame(width: 40, height: 40)
                                        
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Rate the App")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.omniTextPrimary)
                                        
                                        Text("Share your feedback on the App Store")
                                            .font(.caption)
                                            .foregroundColor(.omniTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundColor(.omniTextTertiary)
                                }
                                .padding()
                                .background(Color.omniCardSoftBlue)
                                .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    
                    // App Version Info (smaller, at bottom)
                    HStack {
                        Spacer()
                        Text(appVersion)
                            .font(.caption)
                            .foregroundColor(.omniTextTertiary)
                        Spacer()
                    }
                    .padding(.top, 8)
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
        .sheet(isPresented: $showEvidenceSources) {
            EvidenceSourcesView()
        }
        .sheet(isPresented: $showChatAssistant) {
            // This would show a chat interface for support
            // For now, we'll show a placeholder
            NavigationStack {
                VStack {
                    Spacer()
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.omniPrimary)
                    Text("AI Support Assistant")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    Text("Coming soon! Our AI assistant will help answer your questions instantly.")
                        .font(.body)
                        .foregroundColor(.omniTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
                .padding()
                .navigationTitle("Chat Support")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showChatAssistant = false
                        }
                        .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                    }
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

// New Contact Option Card Component
struct ContactOptionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.omniTextPrimary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.omniTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextTertiary)
            }
            .padding()
            .background(Color.omniCardBeige)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HelpSupportView()
}