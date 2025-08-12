import SwiftUI

struct CrisisResourcesView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.openURL) var openURL
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Message
                    VStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundColor(colorScheme == .dark ? .omniNeonPink : .pink)
                        
                        Text("You Are Not Alone")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("If you're experiencing a mental health crisis, these resources are here to help you 24/7.")
                            .font(.body)
                            .foregroundColor(.omniTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.omniCardLavender)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    
                    // Crisis Hotlines
                    VStack(alignment: .leading, spacing: 16) {
                        Text("CRISIS HOTLINES")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextTertiary)
                        
                        CrisisResourceCard(
                            icon: "phone.fill",
                            title: "988 Suicide & Crisis Lifeline",
                            subtitle: "24/7 confidential support",
                            phoneNumber: "988",
                            description: "Free and confidential emotional support for people in suicidal crisis or emotional distress.",
                            backgroundColor: Color.red.opacity(0.1),
                            iconColor: .red
                        )
                        
                        CrisisResourceCard(
                            icon: "message.fill",
                            title: "Crisis Text Line",
                            subtitle: "Text HOME to 741741",
                            phoneNumber: nil,
                            textNumber: "741741",
                            description: "Free, 24/7 crisis support via text message.",
                            backgroundColor: Color.blue.opacity(0.1),
                            iconColor: .blue
                        )
                        
                        CrisisResourceCard(
                            icon: "phone.fill",
                            title: "National Domestic Violence Hotline",
                            subtitle: "1-800-799-7233",
                            phoneNumber: "1-800-799-7233",
                            description: "24/7 confidential support for domestic violence survivors.",
                            backgroundColor: Color.purple.opacity(0.1),
                            iconColor: .purple
                        )
                        
                        CrisisResourceCard(
                            icon: "phone.fill",
                            title: "SAMHSA National Helpline",
                            subtitle: "1-800-662-4357",
                            phoneNumber: "1-800-662-4357",
                            description: "Treatment referral and information service for mental health and substance use disorders.",
                            backgroundColor: Color.green.opacity(0.1),
                            iconColor: .green
                        )
                    }
                    
                    // Emergency
                    VStack(alignment: .leading, spacing: 16) {
                        Text("EMERGENCY")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextTertiary)
                        
                        Button(action: {
                            if let url = URL(string: "tel://911") {
                                openURL(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Call 911")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("For immediate life-threatening emergencies")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.red)
                            .cornerRadius(16)
                            .shadow(color: Color.red.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                    }
                    
                    // Breathing Exercise
                    VStack(alignment: .leading, spacing: 16) {
                        Text("BREATHING EXERCISE")
                            .font(.footnote)
                            .fontWeight(.bold)
                            .foregroundColor(.omniTextTertiary)
                        
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "lungs.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("4-7-8 Breathing")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.omniTextPrimary)
                                    
                                    Text("A simple technique to help calm anxiety")
                                        .font(.subheadline)
                                        .foregroundColor(.omniTextSecondary)
                                }
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("1.")
                                        .fontWeight(.bold)
                                        .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                                    Text("Inhale through your nose for 4 counts")
                                        .foregroundColor(.omniTextSecondary)
                                }
                                
                                HStack {
                                    Text("2.")
                                        .fontWeight(.bold)
                                        .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                                    Text("Hold your breath for 7 counts")
                                        .foregroundColor(.omniTextSecondary)
                                }
                                
                                HStack {
                                    Text("3.")
                                        .fontWeight(.bold)
                                        .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                                    Text("Exhale through your mouth for 8 counts")
                                        .foregroundColor(.omniTextSecondary)
                                }
                                
                                HStack {
                                    Text("4.")
                                        .fontWeight(.bold)
                                        .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                                    Text("Repeat 3-4 times")
                                        .foregroundColor(.omniTextSecondary)
                                }
                            }
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

struct CrisisResourceCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let phoneNumber: String?
    let textNumber: String?
    let description: String
    let backgroundColor: Color
    let iconColor: Color
    
    @Environment(\.openURL) var openURL
    @Environment(\.colorScheme) var colorScheme
    
    init(icon: String, title: String, subtitle: String, phoneNumber: String? = nil, textNumber: String? = nil, description: String, backgroundColor: Color, iconColor: Color) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.phoneNumber = phoneNumber
        self.textNumber = textNumber
        self.description = description
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.omniTextPrimary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(iconColor)
                }
                
                Spacer()
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundColor(.omniTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                if let phoneNumber = phoneNumber {
                    Button(action: {
                        if let url = URL(string: "tel://\(phoneNumber.replacingOccurrences(of: "-", with: ""))") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 14))
                            Text("Call Now")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(iconColor)
                        .cornerRadius(20)
                    }
                }
                
                if let textNumber = textNumber {
                    Button(action: {
                        if let url = URL(string: "sms:\(textNumber)&body=HOME") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "message.fill")
                                .font(.system(size: 14))
                            Text("Text HOME")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(iconColor)
                        .cornerRadius(20)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? 
                    Color.omniGlassEffect.opacity(0.1) :
                    backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    CrisisResourcesView()
}