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
    
    let firebaseManager = FirebaseManager.shared
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
    
    func updateLocalSession(_ session: ChatSession) async {
        if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
            await MainActor.run {
                chatSessions[index] = session
            }
        }
        await MainActor.run {
            currentSession = session
        }
    }
    
    func createNewSession(userId: UUID, authUserId: String? = nil, title: String = "New Chat") async throws -> ChatSession {
        print("📝 Creating new chat session for user ID: \(userId)")
        
        // Create a new session
        let session = ChatSession(userId: userId, title: title)
        print("   - Session ID: \(session.id)")
        print("   - Title: \(title)")
        
        // Get auth user ID if not provided
        let finalAuthUserId = authUserId ?? firebaseManager.auth.currentUser?.uid ?? ""
        
        // Save to Firebase Firestore with authUserId
        do {
            try await firebaseManager.saveChatSession(session, authUserId: finalAuthUserId)
            print("✅ Session saved to Firestore with authUserId: \(finalAuthUserId)")
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
    
    func loadUserSessions(userId: UUID, authUserId: String? = nil) async {
        print("📚 Loading chat sessions for user ID: \(userId)")
        isLoading = true
        defer { isLoading = false }
        
        // Get auth user ID if not provided
        let finalAuthUserId = authUserId ?? firebaseManager.auth.currentUser?.uid ?? userId.uuidString
        
        // Load from Firebase Firestore using authUserId
        do {
            let sessions = try await firebaseManager.fetchChatSessions(authUserId: finalAuthUserId)
            chatSessions = sessions
            print("✅ Loaded \(sessions.count) sessions from Firestore for authUserId: \(finalAuthUserId)")
        } catch {
            print("⚠️ Failed to load sessions from Firestore: \(error)")
            chatSessions = []
        }
    }
    
    func selectSession(_ session: ChatSession) async {
        // Set the current session first
        currentSession = session
        
        // Clear messages and load new ones atomically to prevent race conditions
        await MainActor.run {
            messages.removeAll()
        }
        
        // Load messages and wait for completion
        await loadMessages(for: session.id)
        
        // Force UI update after messages are fully loaded
        await MainActor.run {
            self.objectWillChange.send()
        }
    }
    
    func setCurrentSession(_ session: ChatSession) async {
        await MainActor.run {
            currentSession = session
        }
    }
    
    func clearForNewChat() async {
        await MainActor.run {
            currentSession = nil
            messages.removeAll()
        }
    }
    
    // MARK: - Message Management
    
    func loadMessages(for sessionId: UUID) async {
        print("📖 Loading messages for session: \(sessionId)")
        
        // Clear existing messages to prevent duplicates
        await MainActor.run {
            messages.removeAll()
        }
        
        // Load from Firebase Firestore
        do {
            let loadedMessages = try await firebaseManager.fetchMessages(sessionId: sessionId.uuidString)
            
            // Create a Set to track message IDs and prevent duplicates
            var messageIds = Set<UUID>()
            var uniqueMessages: [ChatMessage] = []
            
            for firebaseMsg in loadedMessages {
                // Only add if we haven't seen this ID before
                if !messageIds.contains(firebaseMsg.id) {
                    messageIds.insert(firebaseMsg.id)
                    let chatMessage = ChatMessage(
                        id: firebaseMsg.id,  // Use the Firebase message ID to prevent duplicates
                        content: firebaseMsg.content,
                        isUser: firebaseMsg.role == .user,
                        sessionId: sessionId,
                        timestamp: firebaseMsg.timestamp,
                        mood: firebaseMsg.mood
                    )
                    uniqueMessages.append(chatMessage)
                }
            }
            
            // Convert Firebase messages to app messages and assign on MainActor
            await MainActor.run {
                messages = uniqueMessages
                print("✅ Loaded \(messages.count) unique messages from Firestore")
            }
            
            // Don't setup real-time listener - it causes duplicates
            // setupMessageListener(for: sessionId)
        } catch {
            print("⚠️ Failed to load messages from Firestore: \(error)")
            await MainActor.run {
                messages = []
            }
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
                        id: firebaseMsg.id,  // Use the Firebase message ID to prevent duplicates
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
                    // Only add if not already present (prevent duplicates)
                    if !messages.contains(where: { $0.id == limitMessage.id }) {
                        messages.append(limitMessage)
                    }
                    
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
        
        // Add to local messages immediately for responsive UI (check for duplicates)
        await MainActor.run {
            // Only add if not already present (prevent duplicates)
            if !messages.contains(where: { $0.id == userMessage.id }) {
                messages.append(userMessage)
            }
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
        
        // Update session timestamp, title, and lastMessage
        currentSession.updatedAt = Date()
        currentSession.lastMessage = content
        
        // Update title with first user message if it's still "New Chat"
        if currentSession.title == "New Chat" && messages.count <= 2 {
            currentSession.title = String(content.prefix(50))
        }
        
        // Update session in Firebase with authUserId
        let authUserId = firebaseManager.auth.currentUser?.uid ?? ""
        do {
            try await firebaseManager.saveChatSession(currentSession, authUserId: authUserId)
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
        
        // Try to call Firebase AI Chat Function
        do {
            try await callAIChatFunction(for: sessionId, userMessage: userMessage)
        } catch {
            print("❌ Failed to call AI Chat Function: \(error)")
            // Fall back to local response if Firebase function fails
            await handleFallbackResponse(for: sessionId, userMessage: userMessage)
        }
    }
    
    private func callAIChatFunction(for sessionId: UUID, userMessage: String) async throws {
        // Get the current user's ID token for authentication
        guard let idToken = try? await firebaseManager.auth.currentUser?.getIDToken() else {
            throw NSError(domain: "ChatService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get the latest mood for context
        let latestMood = try? await firebaseManager.getLatestMood(authUserId: firebaseManager.auth.currentUser?.uid ?? "")
        
        // Prepare the request - Firebase Functions v2 Cloud Run URL
        let url = URL(string: "https://aichat-265kkl2lea-uc.a.run.app")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Prepare request body
        var requestBody: [String: Any] = [
            "message": userMessage,
            "sessionId": sessionId.uuidString
        ]
        
        // Add mood context if available
        if let mood = latestMood {
            requestBody["mood"] = mood.mood.rawValue
            
            // Include mood note if it's recent (within last 4 hours)
            let hoursSinceMood = Date().timeIntervalSince(mood.timestamp) / 3600
            if hoursSinceMood < 4, let note = mood.note, !note.isEmpty {
                requestBody["moodContext"] = "User is feeling \(mood.mood.label). They noted: \(note)"
            }
        }
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Make the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ChatService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        if httpResponse.statusCode == 429 {
            // Handle guest limit
            if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = responseData["message"] as? String {
                await handleGuestLimitReached(["message": errorMessage])
                return
            }
        }
        
        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "ChatService", code: httpResponse.statusCode, 
                         userInfo: [NSLocalizedDescriptionKey: "AI Chat Function returned error: \(httpResponse.statusCode)"])
        }
        
        // Parse response
        guard let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let aiResponse = responseData["response"] as? String else {
            throw NSError(domain: "ChatService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
        }
        
        // Check for crisis intervention
        let requiresCrisisIntervention = responseData["requiresCrisisIntervention"] as? Bool ?? false
        if requiresCrisisIntervention {
            await handleCrisisResponse(requiresEscalation: true)
        }
        
        // Handle guest info if present
        if let guestInfo = responseData["guestInfo"] as? [String: Any] {
            await handleGuestInfo(guestInfo)
        }
        
        // Create and save the AI message
        let aiMessage = ChatMessage(content: aiResponse, isUser: false, sessionId: sessionId)
        
        // AI response is already saved by the Firebase function, no need to save again
        
        // Add to local messages (check for duplicates)
        await MainActor.run {
            // Only add if not already present (prevent duplicates)
            if !messages.contains(where: { $0.id == aiMessage.id }) {
                messages.append(aiMessage)
            }
        }
        
        // Update session's lastMessage with AI response
        if var currentSession = currentSession {
            currentSession.lastMessage = aiMessage.content
                currentSession.updatedAt = Date()
            
            // Update session in Firebase
            let authUserId = firebaseManager.auth.currentUser?.uid ?? ""
            do {
                try await firebaseManager.saveChatSession(currentSession, authUserId: authUserId)
            } catch {
                print("⚠️ Failed to update session lastMessage in Firestore: \(error)")
            }
            
            // Update local session
            if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
                chatSessions[index] = currentSession
            }
            self.currentSession = currentSession
        }
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
        
        // For fallback responses, we DO need to save since Firebase function wasn't called
        let firebaseAiMessage = FirebaseMessage(
            id: aiMessage.id,
            content: fallbackResponse,
            role: .assistant,
            timestamp: Date(),
            mood: nil
        )
        
        do {
            try await firebaseManager.saveChatMessage(firebaseAiMessage, sessionId: sessionId.uuidString)
            print("✅ Fallback AI response saved to Firestore")
        } catch {
            print("⚠️ Failed to save fallback AI response to Firestore: \(error)")
        }
        
        // Add to local messages (check for duplicates)
        await MainActor.run {
            // Only add if not already present (prevent duplicates)
            if !messages.contains(where: { $0.id == aiMessage.id }) {
                messages.append(aiMessage)
            }
        }
        
        // Update session's lastMessage with AI response
        if var currentSession = currentSession {
            currentSession.lastMessage = aiMessage.content
                currentSession.updatedAt = Date()
            
            // Update session in Firebase
            let authUserId = firebaseManager.auth.currentUser?.uid ?? ""
            do {
                try await firebaseManager.saveChatSession(currentSession, authUserId: authUserId)
            } catch {
                print("⚠️ Failed to update session lastMessage in Firestore: \(error)")
            }
            
            // Update local session
            if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
                chatSessions[index] = currentSession
            }
            self.currentSession = currentSession
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
            // Only add if not already present (prevent duplicates)
            if !messages.contains(where: { $0.id == limitMessage.id }) {
                messages.append(limitMessage)
            }
            
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
        // Delete from Firebase Firestore
        do {
            try await firebaseManager.deleteChatSession(sessionId: session.id.uuidString)
            print("✅ Chat session deleted from Firebase: \(session.id)")
        } catch {
            print("❌ Failed to delete chat session from Firebase: \(error)")
        }
        
        // Remove from local sessions
        await MainActor.run {
            chatSessions.removeAll { $0.id == session.id }
            
            if currentSession?.id == session.id {
                currentSession = nil
                messages = []
                messagesSubscription?.cancel()
            }
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