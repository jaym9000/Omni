import SwiftUI

struct MoodBottomSheet: View {
    let selectedMood: MoodType?
    let onClose: () -> Void
    @State private var showChat = false
    @State private var showJournal = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Safe area spacer for proper spacing
            Spacer()
                .frame(height: 16)
            // Header with close button
            HStack {
                Text("Let's explore this feeling")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.omniTextPrimary)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.omniTextTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Mood display
            if let mood = selectedMood {
                VStack(spacing: 12) {
                    Text(mood.emoji)
                        .font(.system(size: 60))
                    
                    Text(mood.label)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.omniTextPrimary)
                }
            }
            
            // Action buttons
            VStack(spacing: 12) {
                // Talk to Omni Button
                Button(action: { 
                    showChat = true
                    onClose()
                }) {
                    HStack {
                        Image(systemName: "message")
                            .font(.system(size: 16))
                        Text("Talk to Omni")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.omniprimary)
                    .cornerRadius(12)
                }
                
                // Journal Button
                Button(action: { 
                    showJournal = true
                    onClose()
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16))
                        Text("Journal about it")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.omniprimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.omniprimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(
            Color.white
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
        )
        .fullScreenCover(isPresented: $showChat) {
            ChatView(initialPrompt: generateMoodPrompt())
        }
        .sheet(isPresented: $showJournal) {
            JournalEntryView(mood: selectedMood)
        }
    }
    
    private func generateMoodPrompt() -> String {
        guard let mood = selectedMood else { return "" }
        
        switch mood {
        case .happy:
            return "I'm feeling happy today! I'd love to share what's bringing me joy."
        case .anxious:
            return "I'm feeling anxious and could use some support to work through these feelings."
        case .sad:
            return "I'm feeling sad and would like to talk about what's on my mind."
        case .overwhelmed:
            return "I'm feeling overwhelmed and need help processing everything that's going on."
        case .calm:
            return "I'm feeling calm and peaceful. It's nice to check in when things are good too."
        }
    }
}

#Preview {
    MoodBottomSheet(selectedMood: .happy, onClose: {})
        .environmentObject(PremiumManager())
}