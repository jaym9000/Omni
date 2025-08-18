import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var offlineManager: OfflineManager
    @State private var inputText = ""
    @State private var currentSessionId: UUID?
    @FocusState private var isInputFocused: Bool
    @State private var sendButtonScale: CGFloat = 1.0
    @State private var inputFieldScale: CGFloat = 1.0
    @State private var micButtonScale: CGFloat = 1.0
    @State private var micButtonGlow: Bool = false
    let initialPrompt: String?
    let existingSessionId: UUID? // For continuing existing conversations
    
    init(initialPrompt: String? = nil, existingSessionId: UUID? = nil) {
        self.initialPrompt = initialPrompt
        self.existingSessionId = existingSessionId
    }
    
    @State private var selectedInputMode: InputMode = .chat
    
    enum InputMode {
        case chat
        case voice
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Guest conversation counter (only show for guest users)
                if let user = authManager.currentUser, user.isGuest {
                    GuestConversationCounter(
                        conversationsUsed: user.guestConversationCount,
                        maxConversations: user.maxGuestConversations
                    )
                }
                
                // Input mode selector
                InputModeSelector(selectedMode: $selectedInputMode)
                
                // Messages
                MessagesView(messages: chatService.messages, isTyping: chatService.isTyping)
                
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
        Task {
            guard let userId = authManager.currentUser?.id else { return }
            
            // First load user's existing sessions for history
            await chatService.loadUserSessions(userId: userId)
            
            var sessionToUse: ChatSession?
            
            // Check if we're continuing an existing session or creating a new one
            if let existingId = existingSessionId {
                // Continue existing session from chat history
                if let existingSession = chatService.chatSessions.first(where: { $0.id == existingId }) {
                    sessionToUse = existingSession
                    currentSessionId = existingSession.id
                    await chatService.selectSession(existingSession)
                }
            } else {
                // Always create a new session when opening from home
                do {
                    let title = initialPrompt?.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines) ?? "New Chat"
                    let session = try await chatService.createNewSession(
                        userId: userId,
                        title: title
                    )
                    sessionToUse = session
                    currentSessionId = session.id
                } catch {
                    print("Failed to create chat session: \(error)")
                    return
                }
            }
            
            // Only add welcome message if this is a new session with no messages
            if chatService.messages.isEmpty, let session = sessionToUse, existingSessionId == nil {
                let welcomeContent: String
                if let prompt = initialPrompt, !prompt.isEmpty {
                    // If there's an initial prompt (from mood selection), use it as the first message
                    welcomeContent = "I see you're feeling \(prompt). I'm here to listen and support you. What's on your mind?"
                } else {
                    welcomeContent = "Hi there! 👋 How are you feeling today? I'm here to listen and support you."
                }
                
                let welcomeMessage = ChatMessage(
                    content: welcomeContent,
                    isUser: false,
                    sessionId: session.id
                )
                
                await MainActor.run {
                    chatService.messages.append(welcomeMessage)
                }
                
                // Save welcome message to database
                do {
                    try await SupabaseManager.shared.client
                        .from("chat_messages")
                        .insert(welcomeMessage)
                        .execute()
                } catch {
                    print("Failed to save welcome message: \(error)")
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let sessionId = currentSessionId else { return }
        
        let userInput = inputText
        inputText = ""
        isInputFocused = false
        
        Task {
            do {
                try await chatService.sendMessage(content: userInput, sessionId: sessionId)
            } catch {
                print("Failed to send message: \(error)")
                // Show error to user
                await MainActor.run {
                    // You could show an alert here
                }
            }
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
            .onAppear {
                // Scroll to bottom when view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        if let lastMessage = messages.last {
                            scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: messages.count) { _ in
                // Scroll to bottom when messages change
                withAnimation(.easeInOut(duration: 0.3)) {
                    if let lastMessage = messages.last {
                        scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: isTyping) { newValue in
                // Scroll to typing indicator when it appears
                if newValue {
                    withAnimation(.easeInOut(duration: 0.3)) {
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
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = true
                }
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isInputFocused = false
                        }
                        .foregroundColor(.omniPrimary)
                        .fontWeight(.medium)
                    }
                }
            
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

// MARK: - Guest Conversation Counter

struct GuestConversationCounter: View {
    let conversationsUsed: Int
    let maxConversations: Int
    
    private var conversationsRemaining: Int {
        max(0, maxConversations - conversationsUsed)
    }
    
    private var isLowOnConversations: Bool {
        conversationsRemaining <= 1
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: isLowOnConversations ? "exclamationmark.triangle.fill" : "message.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(isLowOnConversations ? .orange : .omniPrimary)
            
            // Counter text
            VStack(alignment: .leading, spacing: 2) {
                Text("Guest Trial")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.omniTextSecondary)
                
                if conversationsRemaining > 0 {
                    Text("\(conversationsRemaining) of \(maxConversations) conversations remaining")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isLowOnConversations ? .orange : .omniTextPrimary)
                } else {
                    Text("Trial limit reached")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            // Upgrade button for low conversations
            if conversationsRemaining <= 1 {
                Button("Upgrade") {
                    // This would trigger signup modal
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowGuestUpgradeModal"),
                        object: nil,
                        userInfo: [
                            "conversationsUsed": conversationsUsed,
                            "conversationsRemaining": conversationsRemaining
                        ]
                    )
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color.omniPrimary, Color.omniSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isLowOnConversations ? Color.orange.opacity(0.1) : Color.omniSecondaryBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isLowOnConversations ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

#Preview {
    ChatView()
        .environmentObject(AuthenticationManager())
}