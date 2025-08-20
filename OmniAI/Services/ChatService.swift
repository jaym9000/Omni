import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ChatService: ObservableObject {
    @Published var currentSession: ChatSession?
    @Published var messages: [ChatMessage] = []
    @Published var chatSessions: [ChatSession] = []
    @Published var isLoading = false
    @Published var isTyping = false
    
    private let firebaseManager = FirebaseManager.shared
    private var messagesListener: ListenerRegistration?
    private var sessionsListener: ListenerRegistration?
    private var messagesSubscription: Task<Void, Never>?
    private weak var authManager: AuthenticationManager?
    
    func setAuthManager(_ manager: AuthenticationManager) {
        self.authManager = manager
    }
    
    private func getAuthManager() async -> AuthenticationManager? {
        return authManager
    }
    
    deinit {
        messagesSubscription?.cancel()
    }
    
    // MARK: - Session Management
    
    func createNewSession(userId: UUID, title: String = "New Chat") async throws -> ChatSession {
        print("📝 Creating new chat session for user ID: \(userId)")
        
        // Create a new session
        let session = ChatSession(userId: userId, title: title)
        print("   - Session ID: \(session.id)")
        print("   - Title: \(title)")
        
        // Save to Firebase Firestore
        do {
            try await firebaseManager.saveChatSession(session)
            print("✅ Session saved to Firestore")
        } catch {
            print("⚠️ Failed to save session to Firestore: \(error)")
            // Continue anyway for offline support
        }
        
        // Add to local sessions
        chatSessions.insert(session, at: 0)
        currentSession = session
        messages = []
        
        // Force UI update
        await MainActor.run {
            self.objectWillChange.send()
        }
        
        print("📋 Current sessions count: \(chatSessions.count)")
        
        return session
    }
    
    func loadUserSessions(userId: UUID) async {
        print("📚 Loading chat sessions for user ID: \(userId)")
        isLoading = true
        defer { isLoading = false }
        
        // Load from Firebase Firestore
        do {
            let sessions = try await firebaseManager.fetchChatSessions(userId: userId.uuidString)
            chatSessions = sessions
            print("✅ Loaded \(sessions.count) sessions from Firestore")
        } catch {
            print("⚠️ Failed to load sessions from Firestore: \(error)")
            chatSessions = []
        }
    }
    
    func selectSession(_ session: ChatSession) async {
        currentSession = session
        await loadMessages(for: session.id)
    }
    
    // MARK: - Message Management
    
    func loadMessages(for sessionId: UUID) async {
        print("📖 Loading messages for session: \(sessionId)")
        
        // Load from Firebase Firestore
        do {
            let loadedMessages = try await firebaseManager.fetchMessages(sessionId: sessionId.uuidString)
            
            // Convert Firebase messages to app messages
            messages = loadedMessages.map { firebaseMsg in
                ChatMessage(
                    content: firebaseMsg.content,
                    isUser: firebaseMsg.role == .user,
                    sessionId: sessionId,
                    timestamp: firebaseMsg.timestamp,
                    mood: firebaseMsg.mood
                )
            }
            
            print("✅ Loaded \(messages.count) messages from Firestore")
            
            // Setup real-time listener for new messages
            setupMessageListener(for: sessionId)
        } catch {
            print("⚠️ Failed to load messages from Firestore: \(error)")
            messages = []
        }
    }
    
    private func setupMessageListener(for sessionId: UUID) {
        // Cancel previous listener
        messagesListener?.remove()
        
        // Setup new listener
        messagesListener = firebaseManager.listenToMessages(sessionId: sessionId.uuidString) { [weak self] firebaseMessages in
            guard let self = self else { return }
            
            Task { @MainActor in
                // Convert and update messages  
                self.messages = firebaseMessages.map { firebaseMsg in
                    ChatMessage(
                        content: firebaseMsg.content,
                        isUser: firebaseMsg.role == .user,
                        sessionId: sessionId,
                        timestamp: firebaseMsg.timestamp,
                        mood: firebaseMsg.mood
                    )
                }
            }
        }
    }
    
    func sendMessage(content: String, sessionId: UUID) async throws {
        guard var currentSession = currentSession else { return }
        
        // Check if guest user has reached message limit BEFORE creating message
        if let authManager = await getAuthManager(),
           let user = authManager.currentUser,
           user.isGuest {
            // Check guest message count for today
            let maxMessages = 5 // 5 free messages per day
            
            // Count today's messages from this guest user
            let today = Calendar.current.startOfDay(for: Date())
            let todayMessages = messages.filter { message in
                message.isUser && // Only count user messages
                message.timestamp >= today
            }.count
            
            if todayMessages >= maxMessages {
                // Create limit reached message
                let limitMessage = ChatMessage(
                    content: "🔒 You've reached your daily limit of 5 free messages! Sign up to continue chatting with Omni and unlock unlimited conversations.",
                    isUser: false,
                    sessionId: sessionId
                )
                
                await MainActor.run {
                    messages.append(limitMessage)
                    
                    // Post notification to show signup modal
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowGuestUpgradeModal"),
                        object: nil,
                        userInfo: ["messagesUsed": todayMessages, "maxMessages": maxMessages]
                    )
                }
                return
            }
        }
        
        // Create user message
        let userMessage = ChatMessage(content: content, isUser: true, sessionId: sessionId)
        
        // Add to local messages immediately for responsive UI
        await MainActor.run {
            messages.append(userMessage)
        }
        
        // Save to Firebase Firestore
        let firebaseMessage = FirebaseMessage(
            id: userMessage.id,
            content: content,
            role: .user,
            timestamp: Date(),
            mood: nil
        )
        
        do {
            try await firebaseManager.saveChatMessage(firebaseMessage, sessionId: sessionId.uuidString)
            print("✅ User message saved to Firestore")
        } catch {
            print("⚠️ Failed to save user message to Firestore: \(error)")
            // Continue anyway for offline support
        }
        
        // Update session timestamp and title if first message
        currentSession.updatedAt = Date()
        
        // Update title with first user message if it's still "New Chat"
        if currentSession.title == "New Chat" && messages.count <= 2 {
            currentSession.title = String(content.prefix(50))
        }
        
        // Update session in Firebase
        do {
            try await firebaseManager.saveChatSession(currentSession)
        } catch {
            print("⚠️ Failed to update session in Firestore: \(error)")
        }
        
        // Update local session
        if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
            chatSessions[index] = currentSession
        }
        self.currentSession = currentSession
        
        // Generate AI response
        await generateAIResponse(for: sessionId, userMessage: content)
    }
    
    private func generateAIResponse(for sessionId: UUID, userMessage: String) async {
        await MainActor.run {
            isTyping = true
        }
        defer { 
            Task { @MainActor in
                isTyping = false
            }
        }
        
        // TODO: Implement Firebase Functions for AI chat
        // For now, use a fallback response
        await handleFallbackResponse(for: sessionId, userMessage: userMessage)
    }
    
    private func handleFallbackResponse(for sessionId: UUID, userMessage: String) async {
        // Enhanced therapeutic responses
        let therapeuticResponses = [
            "I hear you and I'm here to support you. Your feelings are completely valid, and it takes courage to express them. What's on your mind today?",
            "It sounds like you're going through something challenging. Would you like to talk more about what you're experiencing?",
            "What you're sharing sounds important. Can you tell me more about how you're feeling right now?",
            "Remember, your feelings are valid and it's okay to take things one step at a time. What would help you feel supported right now?",
            "Your emotional well-being is important. How are you taking care of yourself today?",
            "What you're experiencing sounds difficult. What has helped you cope with challenging emotions before?"
        ]
        
        let fallbackResponse = therapeuticResponses.randomElement() ?? therapeuticResponses[0]
        
        let aiMessage = ChatMessage(content: fallbackResponse, isUser: false, sessionId: sessionId)
        
        // Save AI response to Firestore
        let firebaseAiMessage = FirebaseMessage(
            id: aiMessage.id,
            content: fallbackResponse,
            role: .assistant,
            timestamp: Date(),
            mood: nil
        )
        
        do {
            try await firebaseManager.saveChatMessage(firebaseAiMessage, sessionId: sessionId.uuidString)
            print("✅ AI response saved to Firestore")
        } catch {
            print("⚠️ Failed to save AI response to Firestore: \(error)")
        }
        
        // Add to local messages
        await MainActor.run {
            messages.append(aiMessage)
        }
    }
    
    private func handleCrisisResponse(requiresEscalation: Bool) async {
        if requiresEscalation {
            // Show immediate crisis resources
            await MainActor.run {
                // This would trigger a crisis intervention UI
                // For now, we'll just log it
                print("CRISIS INTERVENTION TRIGGERED - User needs immediate support")
            }
        }
    }
    
    private func handleGuestInfo(_ guestInfo: [String: Any]) async {
        guard let messagesUsed = guestInfo["messagesUsed"] as? Int,
              let messagesRemaining = guestInfo["messagesRemaining"] as? Int else { return }
        
        await MainActor.run {
            // Update local user object with message count
            // This could trigger UI updates showing remaining messages
            print("👤 Guest messages: \(messagesUsed) used, \(messagesRemaining) remaining")
            
            // You could post a notification to update UI
            NotificationCenter.default.post(
                name: NSNotification.Name("GuestMessageCountUpdated"),
                object: nil,
                userInfo: guestInfo
            )
        }
    }
    
    private func handleGuestLimitReached(_ errorResponse: [String: Any]) async {
        let upgradeMessage = errorResponse["message"] as? String ?? "You've reached your conversation limit! Sign up to continue."
        
        let limitMessage = ChatMessage(
            content: "🔒 " + upgradeMessage + "\n\nSign up now to get unlimited conversations with Omni and unlock all premium features!",
            isUser: false,
            sessionId: currentSession?.id ?? UUID()
        )
        
        await MainActor.run {
            messages.append(limitMessage)
            
            // Post notification to show signup modal
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowGuestUpgradeModal"),
                object: nil,
                userInfo: errorResponse
            )
        }
    }
    
    // MARK: - Chat Actions
    
    func deleteSession(_ session: ChatSession) async {
        // TODO: Delete from Firebase Firestore
        
        // Remove from local sessions
        chatSessions.removeAll { $0.id == session.id }
        
        if currentSession?.id == session.id {
            currentSession = nil
            messages = []
            messagesSubscription?.cancel()
        }
    }
    
    func updateSessionTitle(_ session: ChatSession, newTitle: String) async {
        // TODO: Update in Firebase Firestore
        
        // Update local session
        if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
            chatSessions[index].title = newTitle
            chatSessions[index].updatedAt = Date()
        }
        
        if currentSession?.id == session.id {
            currentSession?.title = newTitle
            currentSession?.updatedAt = Date()
        }
    }
    
    // MARK: - Voice Support
    
    func sendVoiceMessage(audioData: Data, sessionId: UUID) async throws {
        // Placeholder for voice message processing
        // In a real implementation, this would:
        // 1. Upload audio to Firebase Storage
        // 2. Convert speech to text using OpenAI Whisper
        // 3. Send the transcribed text as a regular message
        
        let transcription = "Voice message transcription would go here"
        try await sendMessage(content: transcription, sessionId: sessionId)
    }
}