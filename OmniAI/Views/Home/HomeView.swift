import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var selectedMood: MoodType?
    @State private var showMoodSheet = false
    @State private var gratitudeText = ""
    @State private var isGratitudeCompleted = false
    @State private var showRecentChats = false
    @State private var showChat = false
    @State private var showAnxietySession = false
    @AppStorage("todaysGratitude") private var todaysGratitude = ""
    @AppStorage("lastGratitudeDate") private var lastGratitudeDate = ""
    
    private let dailyPrompt = "What's one thing you're grateful for today?"
    private let charLimit = 280
    
    private var charsRemaining: Int {
        charLimit - gratitudeText.count
    }
    
    private var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Welcome Header
                VStack(spacing: 8) {
                    Text("Welcome to Omni!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("Your safe space is just one tap away.")
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextSecondary)
                }
                .padding(.top)
                
                // Chat with Omni Button
                Button(action: { showChat = true }) {
                    HStack {
                        Text("💬")
                            .font(.system(size: 20))
                        Text("Chat With Omni")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.omniprimary)
                    .cornerRadius(14)
                }
                
                // View Chat History
                Button(action: { showRecentChats = true }) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                        Text("View chat history")
                            .font(.system(size: 16, weight: .medium))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.omniTextSecondary)
                    .padding(.horizontal, 8)
                }
                
                // Mood Tracker
                VStack(alignment: .leading, spacing: 16) {
                    Text("How are you feeling today?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("(Tap to log your mood)")
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextSecondary)
                    
                    HStack(spacing: 16) {
                        ForEach(MoodType.allCases, id: \.self) { mood in
                            MoodButton(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                action: {
                                    selectedMood = mood
                                    showMoodSheet = true
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Anxiety Card
                AnxietyCard(action: { showAnxietySession = true })
                
                // Daily Prompt
                DailyPromptCard(
                    prompt: dailyPrompt,
                    text: $gratitudeText,
                    isCompleted: $isGratitudeCompleted,
                    charLimit: charLimit
                )
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showMoodSheet) {
            MoodBottomSheet(
                selectedMood: selectedMood,
                onClose: { showMoodSheet = false }
            )
            .presentationDetents([.height(300), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRecentChats) {
            RecentChatsView()
        }
        .fullScreenCover(isPresented: $showChat) {
            ChatView()
        }
        .fullScreenCover(isPresented: $showAnxietySession) {
            AnxietySessionView()
        }
        .onAppear {
            checkDailyPrompt()
        }
    }
    
    private func checkDailyPrompt() {
        if lastGratitudeDate == todayDateString && !todaysGratitude.isEmpty {
            gratitudeText = todaysGratitude
            isGratitudeCompleted = true
        } else if lastGratitudeDate != todayDateString {
            // New day, reset
            gratitudeText = ""
            isGratitudeCompleted = false
            todaysGratitude = ""
        }
    }
}

// MARK: - Mood Button Component
struct MoodButton: View {
    let mood: MoodType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(mood.emoji)
                    .font(.system(size: 36))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: isSelected)
                
                Text(mood.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? mood.color : .omniTextSecondary)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
            }
            .frame(width: 70, height: 70)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Anxiety Card Component
struct AnxietyCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Meditation illustration
                Image("anxiety-management")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.moodCalm.opacity(0.2), Color.moodCalm.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Ready to work on managing anxiety today?")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Text("Let's Start")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniprimary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.omniprimary, lineWidth: 1.5)
                            )
                        
                        Spacer()
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.omniCardBeige.opacity(0.6), Color.omniCardBeige.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Daily Prompt Card
struct DailyPromptCard: View {
    let prompt: String
    @Binding var text: String
    @Binding var isCompleted: Bool
    let charLimit: Int
    @State private var isSaving = false
    
    private var charsRemaining: Int {
        charLimit - text.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Prompt")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("Take a moment to reflect on your day")
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextSecondary)
                }
                
                Spacer()
                
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12))
                        Text("REFLECT")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.omniprimary)
                }
            }
            
            // Prompt
            HStack {
                Text("💭")
                    .font(.system(size: 24))
                
                Text("\"\(prompt)\"")
                    .font(.system(size: 16, weight: .medium))
                    .italic()
                    .foregroundColor(.omniTextPrimary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.omniprimary.opacity(0.08))
            .cornerRadius(12)
            
            // Input or Display
            if isCompleted {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Gratitude")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.omniprimary)
                        .textCase(.uppercase)
                    
                    Text(text)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.omniTextPrimary)
                    
                    Button(action: { isCompleted = false }) {
                        Label("Edit", systemImage: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniprimary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.omniprimary, lineWidth: 2)
                        .background(Color.omniprimary.opacity(0.05))
                )
            } else {
                VStack(spacing: 16) {
                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Share what you're grateful for today...")
                                .font(.system(size: 16))
                                .foregroundColor(.omniTextTertiary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                        }
                        
                        TextEditor(text: $text)
                            .font(.system(size: 16))
                            .foregroundColor(.omniTextPrimary)
                            .padding(8)
                            .frame(minHeight: 100)
                            .background(Color.clear)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(text.isEmpty ? Color.clear : Color.omniprimary.opacity(0.3), lineWidth: 1)
                    )
                    
                    HStack {
                        Text("\(charsRemaining) characters left")
                            .font(.system(size: 12))
                            .foregroundColor(charsRemaining < 50 ? .omniError : .omniTextTertiary)
                        
                        Spacer()
                        
                        Button(action: saveGratitude) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save Entry")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(text.isEmpty || isSaving)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(text.isEmpty ? Color.gray.opacity(0.3) : Color.omniprimary)
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.omniSecondaryBackground)
        .cornerRadius(16)
    }
    
    private func saveGratitude() {
        isSaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCompleted = true
            isSaving = false
            // Save to app storage
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            UserDefaults.standard.set(text, forKey: "todaysGratitude")
            UserDefaults.standard.set(formatter.string(from: Date()), forKey: "lastGratitudeDate")
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthenticationManager())
        .environmentObject(PremiumManager())
        .environmentObject(ThemeManager())
}