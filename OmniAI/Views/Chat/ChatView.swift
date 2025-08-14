import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    // TODO: Re-enable when services are added to Xcode project
    // @EnvironmentObject var chatService: ChatService
    // @EnvironmentObject var offlineManager: OfflineManager
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @FocusState private var isInputFocused: Bool
    @State private var sendButtonScale: CGFloat = 1.0
    @State private var inputFieldScale: CGFloat = 1.0
    @State private var micButtonScale: CGFloat = 1.0
    @State private var micButtonGlow: Bool = false
    let initialPrompt: String?
    
    init(initialPrompt: String? = nil) {
        self.initialPrompt = initialPrompt
    }
    
    @State private var selectedInputMode: InputMode = .chat
    
    enum InputMode {
        case chat
        case voice
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Input mode selector
                InputModeSelector(selectedMode: $selectedInputMode)
                
                // Messages
                MessagesView(messages: messages, isTyping: isTyping)
                
                // Input bar
                if selectedInputMode == .chat {
                    ChatInputView(
                        inputText: $inputText,
                        inputFieldScale: inputFieldScale,
                        sendButtonScale: sendButtonScale,
                        sendMessage: sendMessage
                    )
                } else {
                    VoiceInputView(micButtonScale: micButtonScale)
                }
            }
            .navigationTitle("Chat with \(authManager.currentUser?.companionName ?? "Omni")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
        }
        .onAppear {
            setupChat()
        }
    }
    
    private func setupChat() {
        // Add welcome message - use mood-specific prompt if available
        let welcomeContent: String
        if let prompt = initialPrompt, !prompt.isEmpty {
            // Use the mood-specific prompt as the AI's first message
            welcomeContent = prompt
        } else {
            // Generic welcome for regular chat
            welcomeContent = "Hi there! 👋 How are you feeling today? You can chat with me by typing below."
        }
        
        let welcomeMessage = ChatMessage(
            content: welcomeContent,
            isUser: false,
            sessionId: UUID() // Temporary session ID
        )
        messages.append(welcomeMessage)
    }
    
    private func sendMessage() {
        let message = ChatMessage(content: inputText, isUser: true, sessionId: UUID())
        messages.append(message)
        
        let userInput = inputText
        inputText = ""
        isInputFocused = false
        
        generateResponse(for: userInput)
    }
    
    private func generateResponse(for input: String) {
        isTyping = true
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isTyping = false
            
            let response = generateAIResponse(for: input)
            let responseMessage = ChatMessage(content: response, isUser: false, sessionId: UUID())
            messages.append(responseMessage)
        }
    }
    
    private func generateAIResponse(for input: String) -> String {
        // Simplified response generation for demo
        let lowercased = input.lowercased()
        
        if lowercased.contains("anxious") || lowercased.contains("anxiety") {
            return "I hear that you're feeling anxious. That can be really challenging. Would you like to try a breathing exercise together, or would you prefer to talk about what's making you feel this way?"
        } else if lowercased.contains("sad") || lowercased.contains("depressed") {
            return "I'm sorry you're feeling sad. It's okay to feel this way, and I'm here to listen. Would you like to share what's been weighing on your mind?"
        } else if lowercased.contains("happy") || lowercased.contains("good") {
            return "That's wonderful to hear! Celebrating positive moments is just as important as working through challenges. What's bringing you joy today?"
        } else if lowercased.contains("overwhelmed") || lowercased.contains("stressed") {
            return "Feeling overwhelmed can be exhausting. Let's break things down together. What's the biggest thing on your mind right now?"
        } else {
            return "Thank you for sharing that with me. I'm here to listen and support you. How are you feeling about what you just shared?"
        }
    }
    
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage
    @State private var messageOpacity: Double = 0
    @State private var messageOffset: CGFloat = 20
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(message.isUser ? .white : .omniTextPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser ?
                        AnyView(
                            LinearGradient(
                                colors: [Color.omniPrimary, Color.omniSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ) :
                        AnyView(Color.omniSecondaryBackground)
                    )
                    .cornerRadius(20)
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
        .opacity(messageOpacity)
        .offset(x: message.isUser ? messageOffset : -messageOffset)
        .onAppear {
            messageOpacity = 1.0
            messageOffset = 0
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.omniTextTertiary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationAmount)
                        .scaleEffect(animationAmount > 0 ? 1.2 : 1.0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.omniSecondaryBackground)
            .cornerRadius(20)
            
            Spacer()
        }
        .onAppear {
            animationAmount = 1.2
        }
    }
}

// MARK: - Subviews

struct InputModeSelector: View {
    @Binding var selectedMode: ChatView.InputMode
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: { selectedMode = .chat }) {
                HStack {
                    Image(systemName: "message")
                        .font(.system(size: 16))
                    Text("Chat")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(selectedMode == .chat ? .white : .omniTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    selectedMode == .chat ? 
                    Color.omniPrimary : 
                    Color.clear
                )
                .cornerRadius(22)
            }
            
            Button(action: { selectedMode = .voice }) {
                HStack {
                    Image(systemName: "mic")
                        .font(.system(size: 16))
                    Text("Voice")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(selectedMode == .voice ? .white : .omniTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    selectedMode == .voice ? 
                    Color.omniPrimary :
                    Color.clear
                )
                .cornerRadius(22)
            }
        }
        .background(Color.omniSecondaryBackground)
        .cornerRadius(22)
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

struct MessagesView: View {
    let messages: [ChatMessage]
    let isTyping: Bool
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    
                    if isTyping {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _ in
                withAnimation {
                    if let lastMessage = messages.last {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    } else if isTyping {
                        scrollProxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }
}

struct ChatInputView: View {
    @Binding var inputText: String
    @FocusState private var isInputFocused: Bool
    let inputFieldScale: CGFloat
    let sendButtonScale: CGFloat
    let sendMessage: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $inputText, axis: .vertical)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.omniTextTertiary.opacity(0.2), lineWidth: 1)
                )
                .focused($isInputFocused)
                .lineLimit(1...5)
                .scaleEffect(inputFieldScale)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(inputText.isEmpty ? Color.omniTextTertiary.opacity(0.3) : Color.omniPrimary)
                    )
            }
            .disabled(inputText.isEmpty)
            .scaleEffect(sendButtonScale)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
        .background(Color.omniBackground)
    }
}

struct VoiceInputView: View {
    let micButtonScale: CGFloat
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Button(action: {
                    // Voice recording logic would go here
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.omniPrimary.opacity(0.1))
                            .frame(width: 120, height: 120)
                            .blur(radius: 4)
                        
                        Circle()
                            .stroke(Color.omniPrimary.opacity(0.3), lineWidth: 2)
                            .frame(width: 100, height: 100)
                            .scaleEffect(micButtonScale)
                        
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.omniPrimary, Color.omniPrimary.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                            .shadow(color: Color.omniPrimary.opacity(0.3), 
                                    radius: 8, 
                                    x: 0, 
                                    y: 4)
                            .scaleEffect(micButtonScale)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .scaleEffect(micButtonScale)
                    }
                }
                
                Text("Tap and hold to speak")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.omniTextSecondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 32)
        .background(Color.omniBackground)
    }
}

#Preview {
    ChatView()
        .environmentObject(AuthenticationManager())
}