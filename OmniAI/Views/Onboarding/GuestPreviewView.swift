import SwiftUI

struct GuestPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    @State private var userInput = ""
    @State private var selectedMood: MoodEntry = .neutral
    @State private var showingChat = false
    @State private var messages: [PreviewChatMessage] = []
    @State private var isTyping = false
    @Binding var showSignUp: Bool
    
    let previewSteps = [
        PreviewStep(
            title: "How are you feeling?",
            subtitle: "Let's start with a quick mood check-in",
            type: .moodSelection
        ),
        PreviewStep(
            title: "Tell me more",
            subtitle: "Share what's on your mind (optional)",
            type: .textInput
        ),
        PreviewStep(
            title: "Chat with Omni",
            subtitle: "Experience personalized support",
            type: .chatPreview
        )
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.omniPrimary.opacity(0.1), Color.omniSecondary.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(0..<previewSteps.count) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index <= currentStep ? Color.omniPrimary : Color.omniPrimary.opacity(0.3))
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top)
                    
                    // Content
                    TabView(selection: $currentStep) {
                        // Step 0: Mood Selection
                        MoodSelectionPreview(selectedMood: $selectedMood)
                            .tag(0)
                        
                        // Step 1: Text Input
                        TextInputPreview(userInput: $userInput, selectedMood: selectedMood)
                            .tag(1)
                        
                        // Step 2: Chat Preview
                        ChatPreviewDemo(
                            messages: $messages,
                            isTyping: $isTyping,
                            selectedMood: selectedMood,
                            userInput: userInput
                        )
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Navigation
                    if currentStep < 2 {
                        HStack {
                            if currentStep > 0 {
                                Button("Back") {
                                    withAnimation {
                                        currentStep -= 1
                                    }
                                }
                                .foregroundColor(.omniPrimary)
                            }
                            
                            Spacer()
                            
                            Button(action: nextStep) {
                                Text(currentStep == 1 ? "See Omni's Response" : "Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.omniPrimary, Color.omniSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(25)
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    } else {
                        // Call to action
                        VStack(spacing: 16) {
                            Text("Ready to continue your journey?")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.omniTextPrimary)
                                .multilineTextAlignment(.center)
                            
                            Button(action: { 
                                showSignUp = true
                                dismiss()
                            }) {
                                Text("Create Account & Keep Chatting")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.omniPrimary, Color.omniSecondary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(25)
                            }
                            
                            Button("Continue Exploring") {
                                dismiss()
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniTextSecondary)
                }
            }
        }
    }
    
    private func nextStep() {
        if currentStep < previewSteps.count - 1 {
            withAnimation {
                currentStep += 1
            }
            
            // Initialize chat when reaching step 2
            if currentStep == 2 {
                initializeChat()
            }
        }
    }
    
    private func initializeChat() {
        // Add user message if provided
        if !userInput.isEmpty {
            messages.append(PreviewChatMessage(
                content: userInput,
                isUser: true,
                timestamp: Date()
            ))
        }
        
        // Show typing indicator
        isTyping = true
        
        // Simulate AI response after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isTyping = false
            
            let response = generateContextualResponse()
            messages.append(PreviewChatMessage(
                content: response,
                isUser: false,
                timestamp: Date()
            ))
        }
    }
    
    private func generateContextualResponse() -> String {
        let moodContext = selectedMood.label.lowercased()
        let hasInput = !userInput.isEmpty
        
        if hasInput {
            switch selectedMood {
            case .overwhelmed:
                return "I hear that you're feeling \(moodContext) right now. That sounds really challenging. It's completely valid to feel this way, and I want you to know that you're not alone. Let's work through this together. Would you like to try a quick breathing exercise, or would you prefer to talk more about what's contributing to these feelings?"
            case .sad:
                return "Thank you for sharing that you're feeling \(moodContext). I can sense that things feel heavy right now. Your feelings are valid, and it takes courage to reach out. Sometimes when we're feeling down, it helps to take things one small step at a time. What's one small thing that usually brings you even a tiny bit of comfort?"
            case .anxious:
                return "I understand you're feeling \(moodContext), and I want you to know that anxiety is your mind's way of trying to protect you, even though it doesn't always feel helpful. Let's focus on the present moment together. Can you tell me three things you can see around you right now? This can help ground us when anxiety feels overwhelming."
            case .neutral:
                return "I appreciate you sharing what's on your mind. Even when we're feeling neutral, it's important to check in with ourselves. Sometimes neutral can be a peaceful place, and sometimes it might mean we're processing things beneath the surface. How are you finding this moment of checking in with yourself?"
            case .happy:
                return "It's wonderful to hear that you're feeling \(moodContext)! I love that you're taking time to reflect even when things are going well. Celebrating positive moments and understanding what contributes to them can be really valuable. What's been contributing to this positive feeling for you?"
            }
        } else {
            switch selectedMood {
            case .overwhelmed:
                return "I notice you selected that you're feeling \(moodContext). That can be such a difficult experience. When everything feels like too much, sometimes the kindest thing we can do is just acknowledge that we're struggling. You've taken a brave step by checking in here. Would you like to explore some ways to help ease that overwhelming feeling?"
            case .sad:
                return "I see you're feeling \(moodContext) right now. Sadness can feel so heavy, and I want you to know that what you're experiencing is valid. Sometimes we don't need to have all the words - just acknowledging how we feel can be a form of self-care. Is there anything specific weighing on your heart today?"
            case .anxious:
                return "Thank you for sharing that you're feeling \(moodContext). Anxiety can make everything feel uncertain and overwhelming. I want you to know that you're safe in this moment, and we can work through this together. Sometimes it helps to start with just noticing our breath. Are you open to trying a simple grounding technique?"
            case .neutral:
                return "Neutral can be such an interesting space to be in. Sometimes it means we're in a calm, balanced place, and sometimes it might mean we're still figuring out how we feel. Both are completely okay. This moment of checking in with yourself is actually a really positive step. How does it feel to pause and reflect like this?"
            case .happy:
                return "How lovely that you're feeling \(moodContext)! It's beautiful when we take time to acknowledge and celebrate positive feelings. Sometimes we rush past these moments, but they're so important to notice and appreciate. What's bringing you joy today?"
            }
        }
    }
}

// MARK: - Preview Models
struct PreviewStep {
    let title: String
    let subtitle: String
    let type: PreviewStepType
}

enum PreviewStepType {
    case moodSelection
    case textInput
    case chatPreview
}

struct PreviewChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Preview Step Views
struct MoodSelectionPreview: View {
    @Binding var selectedMood: MoodEntry
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("How are you feeling?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("This helps Omni understand your current state")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Mood selector
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    ForEach([MoodEntry.sad, MoodEntry.anxious, MoodEntry.neutral], id: \.self) { mood in
                        MoodPreviewButton(mood: mood, selectedMood: $selectedMood)
                    }
                }
                
                HStack(spacing: 20) {
                    ForEach([MoodEntry.happy, MoodEntry.overwhelmed], id: \.self) { mood in
                        MoodPreviewButton(mood: mood, selectedMood: $selectedMood)
                    }
                    
                    // Placeholder for balance
                    Color.clear
                        .frame(width: 60, height: 60)
                }
            }
            
            Spacer()
            Spacer()
        }
    }
}

struct MoodPreviewButton: View {
    let mood: MoodEntry
    @Binding var selectedMood: MoodEntry
    
    var body: some View {
        Button(action: { selectedMood = mood }) {
            VStack(spacing: 8) {
                Text(mood.emoji)
                    .font(.system(size: 32))
                    .scaleEffect(selectedMood == mood ? 1.2 : 1.0)
                
                Text(mood.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(selectedMood == mood ? .omniPrimary : .omniTextSecondary)
            }
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(selectedMood == mood ? Color.omniPrimary.opacity(0.1) : Color.clear)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: selectedMood)
    }
}

struct TextInputPreview: View {
    @Binding var userInput: String
    let selectedMood: MoodEntry
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Tell me more")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Share what's on your mind (optional)")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                // Selected mood display
                HStack {
                    Text("You're feeling")
                    Text(selectedMood.emoji + " " + selectedMood.label)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.omniPrimary)
                }
                .font(.system(size: 16))
                .foregroundColor(.omniTextSecondary)
                
                // Text input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's on your mind?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.omniTextSecondary)
                    
                    TextField("I'm feeling this way because...", text: $userInput, axis: .vertical)
                        .font(.system(size: 16))
                        .padding()
                        .background(Color.omniSecondaryBackground)
                        .cornerRadius(12)
                        .lineLimit(3...6)
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

struct ChatPreviewDemo: View {
    @Binding var messages: [PreviewChatMessage]
    @Binding var isTyping: Bool
    let selectedMood: MoodEntry
    let userInput: String
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Text("Chat with Omni")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                
                Text("See how Omni responds to your mood and thoughts")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Chat interface
            VStack(spacing: 0) {
                // Chat header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24))
                        .foregroundColor(.omniPrimary)
                    
                    Text("Omni")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Spacer()
                    
                    Text("Preview Mode")
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.omniTertiaryBackground)
                        .cornerRadius(8)
                }
                .padding()
                .background(Color.omniSecondaryBackground)
                
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(messages) { message in
                                PreviewChatBubble(message: message)
                            }
                            
                            if isTyping {
                                TypingIndicator()
                            }
                        }
                        .padding()
                    }
                    .frame(height: 300)
                    .background(Color.omniBackground)
                    .onChange(of: messages.count) { _ in
                        if let lastMessage = messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color.omniSecondaryBackground)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            
            Spacer()
        }
    }
}

struct PreviewChatBubble: View {
    let message: PreviewChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.omniPrimary)
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft])
                    .frame(maxWidth: .infinity * 0.8, alignment: .trailing)
            } else {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextPrimary)
                    .padding()
                    .background(Color.omniSecondaryBackground)
                    .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
                    .frame(maxWidth: .infinity * 0.8, alignment: .leading)
                
                Spacer()
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.omniTextTertiary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding()
            .background(Color.omniSecondaryBackground)
            .cornerRadius(16, corners: [.topLeft, .topRight, .bottomRight])
            
            Spacer()
        }
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    GuestPreviewView(showSignUp: .constant(false))
}