import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @FocusState private var isInputFocused: Bool
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
                HStack(spacing: 0) {
                    Button(action: { selectedInputMode = .chat }) {
                        HStack {
                            Image(systemName: "message")
                                .font(.system(size: 16))
                            Text("Chat")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(selectedInputMode == .chat ? .white : .omniTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedInputMode == .chat ? 
                            Color.omniprimary : 
                            Color.clear
                        )
                        .cornerRadius(22, corners: [.topLeft, .bottomLeft])
                    }
                    
                    Button(action: { selectedInputMode = .voice }) {
                        HStack {
                            Image(systemName: "mic")
                                .font(.system(size: 16))
                            Text("Voice")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(selectedInputMode == .voice ? .white : .omniTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedInputMode == .voice ? 
                            Color.omniprimary :
                            Color.clear
                        )
                        .cornerRadius(22, corners: [.topRight, .bottomRight])
                    }
                }
                .background(Color.omniSecondaryBackground)
                .cornerRadius(22)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                // Messages
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
                            scrollProxy.scrollTo(messages.last?.id ?? "typing", anchor: .bottom)
                        }
                    }
                }
                
                // Input bar
                if selectedInputMode == .chat {
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
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(inputText.isEmpty ? Color.omniTextTertiary.opacity(0.3) : Color.omniprimary)
                                )
                        }
                        .disabled(inputText.isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
                    .background(Color.omniBackground)
                } else {
                    // Voice input placeholder
                    VStack(spacing: 16) {
                        Button(action: {}) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .frame(width: 80, height: 80)
                                .background(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.omniprimary, Color.omnisecondary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                        }
                        
                        Text("Tap and hold to speak")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                    }
                    .padding(.vertical, 32)
                    .background(Color.omniBackground)
                }
            }
            .navigationTitle("Chat with \(authManager.currentUser?.companionName ?? "Omni")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniprimary)
                }
            }
        }
        .onAppear {
            setupChat()
        }
    }
    
    private func setupChat() {
        // Add welcome message
        let welcomeMessage = ChatMessage(
            content: "Hi there! 👋 How are you feeling today? You can chat with me by typing below.",
            isUser: false
        )
        messages.append(welcomeMessage)
        
        // If there's an initial prompt, send it
        if let prompt = initialPrompt, !prompt.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                messages.append(ChatMessage(content: prompt, isUser: true))
                generateResponse(for: prompt)
            }
        }
    }
    
    private func sendMessage() {
        let message = ChatMessage(content: inputText, isUser: true)
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
            let responseMessage = ChatMessage(content: response, isUser: false)
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
                                colors: [Color.omniprimary, Color.omnisecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ) :
                        AnyView(Color.omniSecondaryBackground)
                    )
                    .cornerRadius(20, corners: message.isUser ? [.topLeft, .topRight, .bottomLeft] : [.topLeft, .topRight, .bottomRight])
                
                Text(formatTime(message.timestamp))
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
            }
            .frame(maxWidth: 280, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
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
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animationAmount
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.omniSecondaryBackground)
            .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
            
            Spacer()
        }
        .onAppear {
            animationAmount = 1.2
        }
    }
}

// MARK: - Corner Radius Extension
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
    ChatView()
        .environmentObject(AuthenticationManager())
}