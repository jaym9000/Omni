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
    @State private var showJournal = false
    @State private var journalMood: MoodType?
    @State private var chatInitialPrompt = ""
    @AppStorage("todaysGratitude") private var todaysGratitude = ""
    @AppStorage("lastGratitudeDate") private var lastGratitudeDate = ""
    
    // Animation states
    @State private var welcomeOpacity = 0.0
    @State private var welcomeOffset: CGFloat = 20
    @State private var chatButtonScale = 0.95
    @State private var chatButtonPulse = false
    @State private var moodButtonsVisible = false
    @State private var cardsVisible = false
    
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
                // Welcome Header with animation
                VStack(spacing: 8) {
                    Text("Welcome to Omni!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("Your safe space is just one tap away.")
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextSecondary)
                }
                .padding(.top)
                .opacity(welcomeOpacity)
                .offset(y: welcomeOffset)
                
                // Chat with Omni Button with pulse animation
                Button(action: { 
                    chatInitialPrompt = ""
                    showChat = true 
                }) {
                    HStack {
                        Text("💬")
                            .font(.system(size: 20))
                        Text("Chat With Omni")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.omniPrimary)
                    .cornerRadius(14)
                }
                .buttonStyle(TherapeuticPressStyle())
                .scaleEffect(chatButtonScale)
                .opacity(welcomeOpacity)
                .shadow(color: chatButtonPulse ? Color.omniPrimary.opacity(0.6) : Color.omniPrimary.opacity(0.3), 
                        radius: chatButtonPulse ? 12 : 8, 
                        x: 0, 
                        y: chatButtonPulse ? 6 : 4)
                
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
                .buttonStyle(SoftPressStyle())
                
                // Mood Tracker
                VStack(alignment: .leading, spacing: 16) {
                    Text("How are you feeling today?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("(Tap to log your mood)")
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextSecondary)
                    
                    HStack(spacing: 0) {
                        ForEach(Array(MoodType.allCases.enumerated()), id: \.element) { index, mood in
                            MoodButton(
                                mood: mood,
                                isSelected: selectedMood == mood,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedMood = mood
                                    }
                                    showMoodSheet = true
                                }
                            )
                            .frame(maxWidth: .infinity)
                            .opacity(moodButtonsVisible ? 1 : 0)
                            .offset(y: moodButtonsVisible ? 0 : 20)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.08),
                                value: moodButtonsVisible
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Anxiety Card with entrance animation
                AnxietyCard(action: { showAnxietySession = true })
                    .opacity(cardsVisible ? 1 : 0)
                    .offset(y: cardsVisible ? 0 : 30)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.8)
                        .delay(0.4),
                        value: cardsVisible
                    )
                
                // Daily Prompt with entrance animation
                DailyPromptCard(
                    prompt: dailyPrompt,
                    text: $gratitudeText,
                    isCompleted: $isGratitudeCompleted,
                    charLimit: charLimit
                )
                .opacity(cardsVisible ? 1 : 0)
                .offset(y: cardsVisible ? 0 : 30)
                .animation(
                    .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(0.5),
                    value: cardsVisible
                )
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
        }
        .sheet(isPresented: $showMoodSheet) {
            MoodBottomSheet(
                selectedMood: selectedMood,
                onClose: { showMoodSheet = false },
                onTalkToOmni: { prompt in
                    chatInitialPrompt = prompt
                    showChat = true
                },
                onJournal: { mood in
                    journalMood = mood
                    showJournal = true
                }
            )
            .presentationDetents([.height(300), .medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showRecentChats) {
            RecentChatsView()
        }
        .sheet(isPresented: $showJournal) {
            JournalEntryView(mood: journalMood)
        }
        .fullScreenCover(isPresented: $showChat) {
            ChatView(initialPrompt: chatInitialPrompt)
        }
        .fullScreenCover(isPresented: $showAnxietySession) {
            AnxietySessionView()
        }
        .background(Color.omniBackground)
        .onAppear {
            checkDailyPrompt()
            animateViewEntrance()
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
    
    private func animateViewEntrance() {
        // Welcome animation
        withAnimation(.easeOut(duration: 0.6)) {
            welcomeOpacity = 1.0
            welcomeOffset = 0
        }
        
        // Chat button animation
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
            chatButtonScale = 1.0
        }
        
        // Start subtle pulse animation for chat button
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
            .delay(1.0)
        ) {
            chatButtonPulse = true
        }
        
        // Mood buttons staggered entrance
        withAnimation(.spring().delay(0.3)) {
            moodButtonsVisible = true
        }
        
        // Cards entrance
        withAnimation(.spring().delay(0.4)) {
            cardsVisible = true
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .frame(minHeight: 70)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 2)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Anxiety Card Component
struct AnxietyCard: View {
    let action: () -> Void
    @State private var breathingScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    
    var body: some View {
        VStack(spacing: 12) {
            // Header section - compact
            VStack(spacing: 8) {
                // Icon centered with breathing animation
                ZStack {
                    // Breathing glow effect
                    Circle()
                        .fill(Color.moodCalm.opacity(glowOpacity))
                        .frame(width: 50, height: 50)
                        .scaleEffect(breathingScale * 1.2)
                        .blur(radius: 4)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.moodCalm.opacity(0.3), Color.moodCalm.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .scaleEffect(breathingScale)
                    
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.moodCalm)
                        .scaleEffect(breathingScale)
                }
                
                VStack(spacing: 2) {
                    Text("Anxiety Management")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("Guided breathing & mindfulness")
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextSecondary)
                }
                .multilineTextAlignment(.center)
            }
            
            // Compact question
            Text("Ready to work on managing anxiety today?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.omniTextPrimary)
                .multilineTextAlignment(.center)
            
            // Only the button is clickable
            Button(action: action) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    Text("Let's Start")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.omniPrimary, Color.omniPrimary.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
                .shadow(color: Color.omniPrimary.opacity(0.3), radius: 3, x: 0, y: 2)
            }
            .buttonStyle(TherapeuticPressStyle())
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.omniCardLavender,
                            Color.omniPrimary.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.omniPrimary.opacity(0.2), Color.omniPrimary.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .onAppear {
            startBreathingAnimation()
        }
    }
    
    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 3.5)
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.15
            glowOpacity = 0.5
        }
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
                    .foregroundColor(.omniPrimary)
                }
                .buttonStyle(IconPressStyle())
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
            .background(Color.omniPrimary.opacity(0.08))
            .cornerRadius(12)
            
            // Input or Display
            if isCompleted {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Gratitude")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.omniPrimary)
                        .textCase(.uppercase)
                    
                    Text(text)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.omniTextPrimary)
                    
                    Button(action: { isCompleted = false }) {
                        Label("Edit", systemImage: "pencil")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniPrimary)
                    }
                    .buttonStyle(SoftPressStyle())
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.omniPrimary, lineWidth: 2)
                        .background(Color.omniPrimary.opacity(0.05))
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
                            .fill(Color.omniCardSoftBlue)
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(text.isEmpty ? Color.clear : Color.omniPrimary.opacity(0.3), lineWidth: 1)
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
                        .buttonStyle(TherapeuticPressStyle())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(text.isEmpty ? Color.gray.opacity(0.3) : Color.omniPrimary)
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