import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showFullPolicy = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("Last Updated: January 24, 2025")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                    }
                    .padding(.bottom)
                    
                    // Key Privacy Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Privacy, Protected")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                        
                        PrivacyFeatureRow(
                            icon: "lock.shield.fill",
                            title: "AES-256 Encryption",
                            description: "Your sensitive messages are encrypted using military-grade AES-256 encryption."
                        )
                        
                        PrivacyFeatureRow(
                            icon: "eye.slash.fill",
                            title: "Privacy by Design",
                            description: "Your encrypted data is protected with keys stored securely in iOS Keychain."
                        )
                        
                        PrivacyFeatureRow(
                            icon: "hand.raised.fill",
                            title: "No Data Selling",
                            description: "We never sell or share your personal health information with third parties."
                        )
                        
                        PrivacyFeatureRow(
                            icon: "person.badge.shield.checkmark.fill",
                            title: "Your Data, Your Control",
                            description: "Delete or export your data anytime. You own your information."
                        )
                    }
                    .padding()
                    .background(Color.omniSecondaryBackground.opacity(0.5))
                    .cornerRadius(12)
                    
                    // Privacy Details
                    Group {
                        PrivacySection(
                            title: "Information We Collect",
                            content: """
                            • Account information (email, display name)
                            • Health & wellness data (mood tracking, journal entries, AI chat conversations)
                            • Usage analytics (feature engagement, session duration)
                            • Device information (device type, OS version, app version)
                            • Subscription status (via RevenueCat and App Store)
                            """
                        )
                        
                        PrivacySection(
                            title: "How We Protect Your Data",
                            content: """
                            • AES-256 client-side encryption for sensitive data
                            • HTTPS/TLS for all data transmission
                            • Secure key storage in iOS Keychain
                            • Firebase security rules with user-level access control
                            • Rate limiting and audit logging
                            • Regular security updates and monitoring
                            """
                        )
                        
                        PrivacySection(
                            title: "Your Rights",
                            content: """
                            • Access all your personal information
                            • Edit or delete chat messages and journal entries
                            • Request complete account deletion (30-day processing)
                            • Export your data in portable format
                            • Cancel subscription at any time
                            • Disable analytics tracking
                            • GDPR/CCPA rights for EU/California residents
                            """
                        )
                        
                        PrivacySection(
                            title: "Third-Party Services",
                            content: """
                            We use these trusted services:
                            • Firebase (Google) - Backend infrastructure
                            • OpenAI GPT-4 - AI chat processing
                            • RevenueCat - Subscription management
                            • Apple - Sign in & payments
                            
                            We never sell your personal data to third parties.
                            """
                        )
                        
                        PrivacySection(
                            title: "Compliance & Age Requirements",
                            content: """
                            • GDPR compliant (EU residents)
                            • CCPA compliant (California residents)
                            • COPPA compliant (13+ age requirement)
                            • Apple App Store Guidelines
                            • HIPAA-aligned security practices
                            """
                        )
                    }
                    
                    // View Full Policy Button
                    Button(action: {
                        showFullPolicy = true
                    }) {
                        HStack {
                            Text("View Complete Privacy Policy")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.omniPrimary)
                        .cornerRadius(12)
                    }
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Questions?")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("For privacy inquiries or to exercise your rights:")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                        
                        Link("support@omnitherapy.co", destination: URL(string: "mailto:support@omnitherapy.co")!)
                            .font(.system(size: 14))
                            .foregroundColor(.omniPrimary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.omniCardBeige)
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
            .sheet(isPresented: $showFullPolicy) {
                FullPrivacyPolicyView()
            }
        }
    }
}

struct FullPrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            WebView(url: URL(string: "http://omnitherapy.co/privacy.html")!)
                .navigationTitle("Privacy Policy")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundColor(.omniPrimary)
                    }
                }
        }
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.omniPrimary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.omniTextPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct PrivacySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.omniTextPrimary)
            
            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.omniTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PrivacyPolicyView()
}