import SwiftUI

struct CrisisResourcesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Message
                    Text("If you or someone you know is experiencing a mental health crisis or thinking about suicide, get help immediately.")
                        .font(.body)
                        .foregroundColor(.omniTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Emergency Resources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("EMERGENCY RESOURCES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.omniTextTertiary)
                            .textCase(.uppercase)
                        
                        EmergencyResourceCard(
                            title: "988 Suicide & Crisis Lifeline",
                            subtitle: "Call or text 988 to speak with a trained crisis counselor 24/7/365",
                            phoneNumber: "988",
                            textNumber: "988",
                            website: "https://988lifeline.org",
                            accentColor: .red
                        )
                        
                        EmergencyResourceCard(
                            title: "Crisis Text Line",
                            subtitle: "Text HOME to 741741 to connect with a Crisis Counselor",
                            phoneNumber: nil,
                            textNumber: "741741",
                            website: "https://www.crisistextline.org",
                            accentColor: .red
                        )
                        
                        EmergencyResourceCard(
                            title: "Emergency Services",
                            subtitle: "Call 911 for immediate emergency assistance",
                            phoneNumber: "911",
                            textNumber: nil,
                            website: nil,
                            accentColor: .red
                        )
                    }
                    
                    // Support Resources
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SUPPORT RESOURCES")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.omniTextTertiary)
                            .textCase(.uppercase)
                        
                        SupportResourceCard(
                            title: "SAMHSA National Helpline",
                            subtitle: "Treatment referral and information service (English and Spanish)",
                            phoneNumber: "1-800-662-4357",
                            textNumber: nil,
                            website: "https://www.samhsa.gov/find-help/national-helpline",
                            accentColor: .green
                        )
                        
                        SupportResourceCard(
                            title: "The Trevor Project",
                            subtitle: "Crisis intervention and suicide prevention for LGBTQ young people",
                            phoneNumber: "1-866-488-7386",
                            textNumber: "678678",
                            website: "https://www.thetrevorproject.org",
                            accentColor: .green
                        )
                        
                        SupportResourceCard(
                            title: "Veterans Crisis Line",
                            subtitle: "Connects veterans and their families with qualified responders",
                            phoneNumber: "1-800-273-8255",
                            textNumber: "838255",
                            website: "https://www.veteranscrisisline.net",
                            accentColor: .green
                        )
                        
                        SupportResourceCard(
                            title: "National Domestic Violence Hotline",
                            subtitle: "Support for anyone affected by abuse",
                            phoneNumber: "1-800-799-7233",
                            textNumber: "88788",
                            website: "https://www.thehotline.org",
                            accentColor: .green
                        )
                    }
                    
                    // Footer Message
                    Text("These resources are available to help during a crisis. If you're in immediate danger, please call emergency services immediately.")
                        .font(.caption)
                        .foregroundColor(.omniTextTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                .padding()
            }
            .background(Color.omniBackground)
            .navigationTitle("Crisis Resources")
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
}

// Emergency Resource Card with red accent
struct EmergencyResourceCard: View {
    let title: String
    let subtitle: String
    let phoneNumber: String?
    let textNumber: String?
    let website: String?
    let accentColor: Color
    
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Left border accent
            HStack(spacing: 0) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(accentColor)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.omniTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 12)
                    .padding(.top, 12)
                    
                    HStack(spacing: 12) {
                        if let phoneNumber = phoneNumber {
                            ActionButton(
                                icon: "phone.fill",
                                title: "Call",
                                color: accentColor,
                                action: {
                                    if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: "-", with: ""))") {
                                        openURL(url)
                                    }
                                }
                            )
                        }
                        
                        if let textNumber = textNumber {
                            ActionButton(
                                icon: "message.fill",
                                title: "Text",
                                color: accentColor,
                                action: {
                                    let body = textNumber == "741741" ? "HOME" : ""
                                    if let url = URL(string: "sms:\(textNumber)&body=\(body)") {
                                        openURL(url)
                                    }
                                }
                            )
                        }
                        
                        if let website = website {
                            ActionButton(
                                icon: "globe",
                                title: "Website",
                                color: accentColor,
                                action: {
                                    if let url = URL(string: website) {
                                        openURL(url)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.omniCardBeige)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// Support Resource Card with green accent
struct SupportResourceCard: View {
    let title: String
    let subtitle: String
    let phoneNumber: String?
    let textNumber: String?
    let website: String?
    let accentColor: Color
    
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Left border accent
            HStack(spacing: 0) {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.omniTextPrimary)
                        
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.omniTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.leading, 12)
                    .padding(.top, 12)
                    
                    HStack(spacing: 12) {
                        if let phoneNumber = phoneNumber {
                            ActionButton(
                                icon: "phone.fill",
                                title: "Call",
                                color: accentColor,
                                action: {
                                    if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: "-", with: ""))") {
                                        openURL(url)
                                    }
                                }
                            )
                        }
                        
                        if let textNumber = textNumber {
                            ActionButton(
                                icon: "message.fill",
                                title: "Text",
                                color: accentColor,
                                action: {
                                    let body = textNumber == "678678" ? "START" : ""
                                    if let url = URL(string: "sms:\(textNumber)&body=\(body)") {
                                        openURL(url)
                                    }
                                }
                            )
                        }
                        
                        if let website = website {
                            ActionButton(
                                icon: "globe",
                                title: "Website",
                                color: accentColor,
                                action: {
                                    if let url = URL(string: website) {
                                        openURL(url)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.omniCardLavender)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// Reusable Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(color)
            .cornerRadius(20)
        }
    }
}

#Preview {
    CrisisResourcesView()
}