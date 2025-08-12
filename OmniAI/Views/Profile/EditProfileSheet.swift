import SwiftUI

struct EditProfileSheet: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var selectedEmoji: String = "😊"
    @State private var showEmojiPicker = false
    
    let availableEmojis = ["😊", "🌟", "🦋", "🌸", "🌈", "💫", "🌙", "✨", "🌺", "🍃", "🌻", "💜", "🦄", "🎨", "🌊", "🔮"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    avatarSection
                    displayNameSection
                    bioSection
                    if showEmojiPicker {
                        emojiPickerSection
                    }
                }
                .padding()
            }
            .background(Color.omniBackground)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.omniTextSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProfile()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.omniPrimary)
                }
            }
        }
        .onAppear {
            if let user = authManager.currentUser {
                displayName = user.displayName
                if let avatar = user.avatarURL {
                    selectedEmoji = avatar
                }
            }
        }
    }
    
    private var avatarSection: some View {
        VStack(spacing: 20) {
            Button(action: { showEmojiPicker.toggle() }) {
                ZStack {
                    Circle()
                        .fill(Color.omniPrimary.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Text(selectedEmoji)
                        .font(.system(size: 50))
                }
            }
            
            Text("Tap to change avatar")
                .font(.caption)
                .foregroundColor(.omniTextTertiary)
        }
        .padding(.top)
    }
    
    private var displayNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Display Name")
                .font(.footnote)
                .foregroundColor(.omniTextSecondary)
                .fontWeight(.medium)
            
            TextField("Enter your name", text: $displayName)
                .textFieldStyle(RoundedTextFieldStyle())
        }
    }
    
    private var bioSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bio (Optional)")
                .font(.footnote)
                .foregroundColor(.omniTextSecondary)
                .fontWeight(.medium)
            
            TextEditor(text: $bio)
                .frame(minHeight: 100)
                .padding(8)
                .background(Color.omniSecondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.omniTextTertiary.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var emojiPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose Avatar")
                .font(.footnote)
                .foregroundColor(.omniTextSecondary)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                ForEach(availableEmojis, id: \.self) { emoji in
                    EmojiButton(
                        emoji: emoji,
                        isSelected: selectedEmoji == emoji,
                        action: {
                            selectedEmoji = emoji
                            withAnimation {
                                showEmojiPicker = false
                            }
                        }
                    )
                }
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    private func saveProfile() async {
        await authManager.updateProfile(
            displayName: displayName,
            avatarEmoji: selectedEmoji,
            bio: bio.isEmpty ? nil : bio
        )
    }
}

struct EmojiButton: View {
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.omniPrimary.opacity(0.2) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.omniPrimary : Color.omniTextTertiary.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.omniSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.omniTextTertiary.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    EditProfileSheet()
        .environmentObject(AuthenticationManager())
}