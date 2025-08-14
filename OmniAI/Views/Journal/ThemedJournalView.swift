import SwiftUI

struct ThemedJournalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var journalManager: JournalManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentPrompt = "What's one small win you had today, no matter how minor?"
    @State private var responseText = ""
    @State private var isCompleted = false
    
    let prompts = [
        "What's one small win you had today, no matter how minor?",
        "How are you feeling this morning, and what's contributing to that mood?",
        "What's something you're grateful for right now?",
        "What challenge are you facing, and how might you approach it?",
        "Describe a moment when you felt truly peaceful today."
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Themed Journal")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.omniTextPrimary)
                    }
                    .padding(.top, 16)
                    
                    // Guided Journal Prompt Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Guided Journal Prompt")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.omniTextSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Get new prompt
                                currentPrompt = prompts.randomElement() ?? prompts[0]
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14))
                                    Text("New Prompt")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.omniPrimary)
                            }
                        }
                        
                        // Prompt Display
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniPrimary)
                                
                                Text("GRATITUDE & WINS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.omniPrimary)
                                    .textCase(.uppercase)
                            }
                            
                            Text(currentPrompt)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.omniTextPrimary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.omniPrimary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.omniPrimary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Text Input Area
                    VStack(spacing: 16) {
                        ZStack(alignment: .topLeading) {
                            if responseText.isEmpty {
                                Text("Write your thoughts here...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniTextTertiary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                            }
                            
                            TextEditor(text: $responseText)
                                .font(.system(size: 16))
                                .foregroundColor(.omniTextPrimary)
                                .padding(8)
                                .frame(minHeight: 200)
                                .background(Color.clear)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(responseText.isEmpty ? Color.clear : Color.omniPrimary.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Character counter and save button
                        HStack {
                            Text("\(responseText.count) characters")
                                .font(.system(size: 12))
                                .foregroundColor(.omniTextTertiary)
                            
                            Spacer()
                            
                            Button(action: saveEntry) {
                                Text("Save Entry")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .disabled(responseText.isEmpty)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(responseText.isEmpty ? Color.gray.opacity(0.3) : Color.omniPrimary)
                            )
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
        }
    }
    
    private func saveEntry() {
        guard !responseText.isEmpty else { return }
        
        var entry = JournalEntry(
            userId: authManager.currentUser?.id ?? UUID(),
            title: "Themed Entry",
            content: responseText,
            type: .themed
        )
        
        // Set the prompt for themed entries
        entry.prompt = currentPrompt
        
        journalManager.saveEntry(entry)
        dismiss()
    }
}

#Preview {
    ThemedJournalView()
}