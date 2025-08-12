import SwiftUI

struct CompanionEditSheet: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var companionName: String = ""
    @State private var selectedPersonality: String = ""
    
    let personalityOptions = [
        ("supportive", "🤗", "Warm and understanding, always ready to listen"),
        ("motivational", "💪", "Encouraging and inspiring, helps you achieve goals"),
        ("gentle", "🌸", "Soft-spoken and calming, perfect for relaxation"),
        ("analytical", "🧠", "Thoughtful and logical, provides clear insights"),
        ("funny", "😄", "Light-hearted and humorous, brings joy to conversations")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Companion Name Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Companion Name")
                            .font(.headline)
                            .foregroundColor(.omniTextPrimary)
                        
                        TextField("Enter companion name", text: $companionName)
                            .textFieldStyle(RoundedTextFieldStyle())
                        
                        Text("Choose a name that feels personal and comforting to you.")
                            .font(.caption)
                            .foregroundColor(.omniTextTertiary)
                    }
                    .padding()
                    .background(Color.omniCardBeige)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    
                    // Personality Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Personality Type")
                            .font(.headline)
                            .foregroundColor(.omniTextPrimary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                            ForEach(personalityOptions, id: \.0) { personality in
                                PersonalityCard(
                                    personality: personality,
                                    isSelected: selectedPersonality == personality.0,
                                    colorScheme: colorScheme
                                ) {
                                    selectedPersonality = personality.0
                                }
                            }
                        }
                        
                        Text("Your companion's personality affects how they respond and interact with you.")
                            .font(.caption)
                            .foregroundColor(.omniTextTertiary)
                    }
                    .padding()
                    .background(Color.omniCardLavender)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                    
                    // Preview Section
                    if !companionName.isEmpty && !selectedPersonality.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.headline)
                                .foregroundColor(.omniTextPrimary)
                            
                            HStack {
                                Text(getPersonalityEmoji())
                                    .font(.system(size: 40))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        Circle()
                                            .fill(colorScheme == .dark ? 
                                                Color.omniNeonSage.opacity(0.2) : 
                                                Color.omniPrimary.opacity(0.2))
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hi! I'm \(companionName) 👋")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.omniTextPrimary)
                                    
                                    Text(getPersonalityPreview())
                                        .font(.subheadline)
                                        .foregroundColor(.omniTextSecondary)
                                        .lineLimit(2)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? 
                                        Color.omniGlassEffect.opacity(0.1) :
                                        Color.omniSecondaryBackground)
                            )
                        }
                        .padding()
                        .background(Color.omniCardSoftBlue)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding()
            }
            .background(Color.omniBackground)
            .navigationTitle("Edit Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(colorScheme == .dark ? .omniNeonPink : .omniTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveCompanionSettings()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                    .disabled(companionName.isEmpty || selectedPersonality.isEmpty)
                }
            }
        }
        .onAppear {
            if let user = authManager.currentUser {
                companionName = user.companionName
                selectedPersonality = user.companionPersonality
            }
        }
    }
    
    private func getPersonalityEmoji() -> String {
        return personalityOptions.first { $0.0 == selectedPersonality }?.1 ?? "🤗"
    }
    
    private func getPersonalityPreview() -> String {
        switch selectedPersonality {
        case "supportive":
            return "I'm here to listen and support you through anything. How can I help you today?"
        case "motivational":
            return "You've got this! Let's work together to achieve your goals and dreams!"
        case "gentle":
            return "Take a deep breath. I'm here with you, and we'll take things one step at a time."
        case "analytical":
            return "Let's explore this together and find clear, practical solutions that work for you."
        case "funny":
            return "Ready to brighten your day with some laughs? Life's too short not to smile!"
        default:
            return "I'm here to support you in whatever way feels best."
        }
    }
    
    private func saveCompanionSettings() async {
        await authManager.updateCompanionSettings(
            name: companionName,
            personality: selectedPersonality
        )
    }
}

struct PersonalityCard: View {
    let personality: (String, String, String)
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(personality.1)
                    .font(.system(size: 32))
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(personality.0.capitalized)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.omniTextPrimary)
                    
                    Text(personality.2)
                        .font(.caption)
                        .foregroundColor(.omniTextSecondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(colorScheme == .dark ? .omniNeonSage : .omniPrimary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? 
                        Color.omniGlassEffect.opacity(0.1) :
                        Color.omniSecondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? 
                        (colorScheme == .dark ? Color.omniNeonSage : Color.omniPrimary) :
                        Color.omniTextTertiary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CompanionEditSheet()
        .environmentObject(AuthenticationManager())
}