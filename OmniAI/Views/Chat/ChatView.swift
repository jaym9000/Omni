import SwiftUI
import RevenueCatUI

struct ChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var offlineManager: OfflineManager
    
    @State private var inputText = ""
    @State private var currentSessionId: UUID?
    @FocusState private var isInputFocused: Bool
    @State private var isSessionSaved = false
    @State private var selectedInputMode: InputMode = .chat
    @State private var dragOffset = CGSize.zero
    @State private var sendButtonScale: CGFloat = 1.0
    @State private var micButtonScale: CGFloat = 1.0
    @State private var isSettingUp = false
    @State private var showVoiceComingSoon = false
    
    let initialPrompt: String?
    let existingSessionId: UUID?
    
    init(initialPrompt: String? = nil, existingSessionId: UUID? = nil) {
        self.initialPrompt = initialPrompt
        self.existingSessionId = existingSessionId
    }
    
    enum InputMode {
        case chat
        case voice
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Input mode selector
                InputModeSelector(selectedMode: $selectedInputMode, showVoiceComingSoon: $showVoiceComingSoon)
                
                // Messages ScrollView
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(chatService.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if chatService.isTyping {
                                TypingIndicator()
                                    .id("typing")
                            }
                            
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                        }
                        .padding(.vertical)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: chatService.messages.count) { _ in
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
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
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                    if selectedInputMode == .chat {
                        ChatInputView(
                            inputText: $inputText,
                            isInputFocused: _isInputFocused,
                            sendButtonScale: sendButtonScale,
                            sendMessage: sendMessage
                        )
                        .background(Color.omniBackground)
                    } else {
                        VoiceInputView(micButtonScale: micButtonScale)
                            .background(Color.omniBackground)
                    }
                }
                .background(.regularMaterial)
            }
        }
        .offset(x: dragOffset.width)
        .opacity(1 - Double(abs(dragOffset.width / 300)))
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow right swipe (positive translation)
                    if value.translation.width > 0 {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    // Dismiss if swiped more than 40% of screen width
                    if value.translation.width > UIScreen.main.bounds.width * 0.4 {
                        withAnimation(.easeOut(duration: 0.3)) {
                            dragOffset.width = UIScreen.main.bounds.width
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            dismiss()
                        }
                    } else {
                        // Bounce back
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = .zero
                        }
                    }
                }
        )
        .alert("Voice Mode Coming Soon!", isPresented: $showVoiceComingSoon) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We're working on bringing you voice conversations with Omni. This feature will be available in a future update!")
        }
        .task {
            await setupChatSafely()
            // Auto-focus for better UX
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isInputFocused = true
                }
            }
        }
    }
    
    private func setupChatSafely() async {
        // Prevent concurrent setup calls
        guard !isSettingUp else { return }
        
        await MainActor.run {
            isSettingUp = true
        }
        
        defer {
            Task { @MainActor in
                isSettingUp = false
            }
        }
        
        await setupChat()
    }
    
    private func setupChat() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        let authUserId = authManager.currentUser?.authUserId ?? ""
        
        await chatService.loadUserSessions(userId: userId, authUserId: authUserId)
        
        var sessionToUse: ChatSession?
        
        if let existingId = existingSessionId {
            isSessionSaved = true
            if let existingSession = chatService.chatSessions.first(where: { $0.id == existingId }) {
                sessionToUse = existingSession
                currentSessionId = existingSession.id
                // Wait for messages to fully load before proceeding
                await chatService.selectSession(existingSession)
                // Add a small delay to ensure UI is updated
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        } else {
            // For new chats, clear any existing state
            await chatService.clearForNewChat()
            let title = initialPrompt?.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines) ?? "New Chat"
            let session = ChatSession(
                id: UUID(),
                userId: userId,
                title: title,
                createdAt: Date(),
                updatedAt: Date()
            )
            sessionToUse = session
            currentSessionId = session.id
            await chatService.setCurrentSession(session)
        }
        
        // Only add welcome message for NEW chats, never for existing sessions
        if existingSessionId == nil && chatService.messages.isEmpty, let session = sessionToUse {
            let welcomeContent = if let prompt = initialPrompt, !prompt.isEmpty {
                "I see you're feeling \(prompt). I'm here to listen and support you. What's on your mind?"
            } else {
                "Hi there! How are you feeling today? I'm here to listen and support you."
            }
            
            let welcomeMessage = ChatMessage(
                content: welcomeContent,
                isUser: false,
                sessionId: session.id
            )
            
            await MainActor.run {
                chatService.messages.append(welcomeMessage)
            }
        }
    }
    
    private func sendMessage() {
        guard let sessionId = currentSessionId else { return }
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Check if free user has hit limit (show paywall after 1 message)
        
        let userInput = inputText
        inputText = ""
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        Task {
            do {
                if !isSessionSaved {
                    if let userId = authManager.currentUser?.id,
                       let authUserId = authManager.currentUser?.authUserId {
                        
                        let title = initialPrompt?.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines) ?? "New Chat"
                        let session = ChatSession(
                            id: sessionId,
                            userId: userId,
                            title: title,
                            createdAt: Date(),
                            updatedAt: Date()
                        )
                        
                        try await chatService.firebaseManager.saveChatSession(session, authUserId: authUserId)
                        
                        if !chatService.chatSessions.contains(where: { $0.id == sessionId }) {
                            await MainActor.run {
                                chatService.chatSessions.insert(session, at: 0)
                            }
                        }
                        
                        isSessionSaved = true
                        
                        if let welcomeMessage = chatService.messages.first(where: { !$0.isUser }) {
                            let firebaseWelcomeMessage = FirebaseMessage(
                                id: welcomeMessage.id,
                                content: welcomeMessage.content,
                                role: .assistant,
                                timestamp: welcomeMessage.timestamp,
                                mood: nil
                            )
                            try await chatService.firebaseManager.saveChatMessage(firebaseWelcomeMessage, sessionId: sessionId.uuidString)
                        }
                    }
                }
                
                try await chatService.sendMessage(content: userInput, sessionId: sessionId)
            } catch {
                print("Failed to send message: \(error)")
            }
        }
    }
}

// MARK: - Input Mode Selector
struct InputModeSelector: View {
    @Binding var selectedMode: ChatView.InputMode
    @Binding var showVoiceComingSoon: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
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
            
            Button(action: { 
                // Show coming soon alert for voice feature
                showVoiceComingSoon = true
            }) {
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

// MARK: - Chat Input View
struct ChatInputView: View {
    @Binding var inputText: String
    @FocusState var isInputFocused: Bool
    let sendButtonScale: CGFloat
    let sendMessage: () -> Void
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Type your message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .foregroundColor(Color.omniTextPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.omniSecondaryBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(UIColor.separator).opacity(0.3), lineWidth: 1)
                        )
                )
                .focused($isInputFocused)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.send)
                .onSubmit {
                    if !inputText.isEmpty {
                        sendMessage()
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
        .padding(.vertical, 8)
    }
}

// MARK: - Voice Input View
struct VoiceInputView: View {
    let micButtonScale: CGFloat
    @State private var isRecording = false
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Button(action: {
                // Voice recording logic would go here
                isRecording.toggle()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.omniPrimary.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .blur(radius: 4)
                    
                    Circle()
                        .stroke(Color.omniPrimary.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isRecording)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.omniPrimary, Color.omniPrimary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.omniPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(micButtonScale)
                    
                    Image(systemName: isRecording ? "mic.fill" : "mic")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                        .scaleEffect(isRecording ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isRecording)
                }
            }
            
            Text(isRecording ? "Recording..." : "Tap and hold to speak")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.omniTextSecondary)
            
            Spacer()
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
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
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal)
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
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: animationAmount
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.omniSecondaryBackground)
            .cornerRadius(20)
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            animationAmount = 1.2
        }
    }
}


#Preview {
    ChatView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ChatService())
        .environmentObject(OfflineManager())
}