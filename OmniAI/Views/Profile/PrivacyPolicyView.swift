import SwiftUI
import WebKit

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Privacy Policy")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("Effective Date: January 1, 2025")
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
                            title: "End-to-End Encryption",
                            description: "Your chat messages are encrypted on your device before being stored."
                        )
                        
                        PrivacyFeatureRow(
                            icon: "eye.slash.fill",
                            title: "Zero-Knowledge Architecture",
                            description: "We cannot read your encrypted messages, even in our database."
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
                            • Account information (email, name)
                            • Health information (mood entries, journal entries, chat conversations)
                            • Usage information (app interactions, timestamps)
                            • Device information (device type, OS version)
                            """
                        )
                        
                        PrivacySection(
                            title: "How We Protect Your Data",
                            content: """
                            • AES-256 encryption for data at rest
                            • TLS 1.3 for data in transit
                            • Encryption keys stored in iOS Keychain
                            • Strict Firebase Security Rules
                            • Regular security audits
                            """
                        )
                        
                        PrivacySection(
                            title: "Your Rights",
                            content: """
                            • Access your personal information
                            • Correct inaccurate information
                            • Delete your account and all data
                            • Export your data in portable format
                            • Withdraw consent at any time
                            """
                        )
                        
                        PrivacySection(
                            title: "Compliance",
                            content: """
                            We comply with:
                            • Canada's PIPEDA
                            • New Brunswick's PHIPAA
                            • Apple App Store Guidelines
                            • Industry best practices
                            """
                        )
                    }
                    
                    // Contact Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Questions?")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("For privacy-related questions or to exercise your rights:")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                        
                        Link("privacy@omniapp.com", destination: URL(string: "mailto:privacy@omniapp.com")!)
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