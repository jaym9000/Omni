import Foundation
import Supabase
import Realtime
import SwiftUI
import PostgREST
import Functions

@MainActor
class ChatService: ObservableObject {
    @Published var currentSession: ChatSession?
    @Published var messages: [ChatMessage] = []
    @Published var chatSessions: [ChatSession] = []
    @Published var isLoading = false
    @Published var isTyping = false
    
    private let supabase = SupabaseManager.shared.client
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
        // Always create a new session
        let session = ChatSession(userId: userId, title: title)
        
        do {
            // Insert session into Supabase
            try await supabase
                .from("chat_sessions")
                .insert(session)
                .execute()
            
            // Add to local sessions
            chatSessions.insert(session, at: 0)
            currentSession = session
            messages = []
            
            return session
        } catch {
            // Fallback to local session for development
            chatSessions.insert(session, at: 0)
            currentSession = session
            messages = []
            return session
        }
    }
    
    func loadUserSessions(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let sessions: [ChatSession] = try await supabase
                .from("chat_sessions")
                .select()
                .eq("user_id", value: userId)
                .order("updated_at", ascending: false)
                .execute()
                .value
            
            chatSessions = sessions
        } catch {
            // Fallback to mock sessions for development
            chatSessions = []
        }
    }
    
    func selectSession(_ session: ChatSession) async {
        currentSession = session
        await loadMessages(for: session.id)
        subscribeToMessages(sessionId: session.id)
    }
    
    // MARK: - Message Management
    
    func loadMessages(for sessionId: UUID) async {
        do {
            let sessionMessages: [ChatMessage] = try await supabase
                .from("chat_messages")
                .select()
                .eq("session_id", value: sessionId)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            messages = sessionMessages
        } catch {
            // Fallback to empty messages for development
            messages = []
        }
    }
    
    func sendMessage(content: String, sessionId: UUID) async throws {
        guard let currentSession = currentSession else { return }
        
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
        
        do {
            // Insert user message into Supabase
            try await supabase
                .from("chat_messages")
                .insert(userMessage)
                .execute()
            
            // Add to local messages
            await MainActor.run {
                messages.append(userMessage)
            }
            
            // Update session timestamp
            var updatedSession = currentSession
            updatedSession.updatedAt = Date()
            
            try await supabase
                .from("chat_sessions")
                .update(updatedSession)
                .eq("id", value: sessionId)
                .execute()
            
            // Generate AI response
            await generateAIResponse(for: sessionId, userMessage: content)
            
        } catch {
            // Fallback to local message for development
            await MainActor.run {
                messages.append(userMessage)
            }
            await generateAIResponse(for: sessionId, userMessage: content)
        }
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
        
        var fallbackResponseSent = false
        
        do {
            // Get current user session for authentication
            print("🔐 Getting user session for authentication...")
            let session = try await supabase.auth.session
            print("✅ Got user session:")
            print("   - User ID: \(session.user.id)")
            print("   - Is Anonymous: \(session.user.isAnonymous)")
            print("   - Email: \(session.user.email ?? "none")")
            print("   - Access token prefix: \(session.accessToken.prefix(20))...")
            
            // Prepare conversation history (last 10 messages for context)
            let recentMessages = messages.suffix(10).map { message in
                return [
                    "role": message.isUser ? "user" : "assistant",
                    "content": message.content
                ]
            }
            
            // Call Supabase Edge Function for AI response
            let isGuestUser = session.user.isAnonymous || session.user.email == nil || session.user.email?.isEmpty == true
            let requestBody: [String: Any] = [
                "message": userMessage,
                "sessionId": sessionId.uuidString,
                "conversationHistory": recentMessages,
                "isGuest": isGuestUser
            ]
            
            // Convert to JSON Data
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            print("📝 Request body prepared:")
            print("   - Message: \(userMessage.prefix(30))...")
            print("   - Is Guest: \(isGuestUser)")
            print("   - Session ID: \(sessionId.uuidString)")
            print("   - Conversation History: \(recentMessages.count) messages")
            
            // Create URL request manually for Edge Function
            let url = URL(string: "https://rchropdkyqpfyjwgdudv.supabase.co/functions/v1/ai-chat")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("omni-ai-ios/1.1", forHTTPHeaderField: "x-client-info")
            request.httpBody = jsonData
            request.timeoutInterval = 30.0 // 30 second timeout
            
            print("🚀 Calling Edge Function at: \(url.absoluteString)")
            
            // Make the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Edge Function Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Parse AI response
                    let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                    print("📦 Raw response data: \(responseString.prefix(200))...")
                    
                    if let aiResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let content = aiResponse["content"] as? String {
                        
                        // Check for crisis detection
                        let crisisDetected = aiResponse["crisisDetected"] as? Bool ?? false
                        let requiresEscalation = aiResponse["requiresEscalation"] as? Bool ?? false
                        
                        // Handle guest info if present
                        if let guestInfo = aiResponse["guestInfo"] as? [String: Any] {
                            await handleGuestInfo(guestInfo)
                        }
                        
                        // Create AI message
                        let aiMessage = ChatMessage(content: content, isUser: false, sessionId: sessionId)
                        
                        // Add to local messages (Edge Function already stored in DB)
                        await MainActor.run {
                            messages.append(aiMessage)
                        }
                        
                        // Handle crisis situation if detected
                        if crisisDetected || requiresEscalation {
                            await handleCrisisResponse(requiresEscalation: requiresEscalation)
                        }
                        
                        print("✅ OpenAI Response Received: \(content.prefix(50))...")
                        return
                    } else {
                        print("❌ Failed to parse JSON response: \(responseString)")
                    }
                } else if httpResponse.statusCode == 403 {
                    // Handle guest limit reached
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                    if let errorResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let guestLimitReached = errorResponse["guestLimitReached"] as? Bool,
                       guestLimitReached {
                        await handleGuestLimitReached(errorResponse)
                        return
                    }
                    print("❌ Edge Function Error (\(httpResponse.statusCode)): \(errorString)")
                } else {
                    let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ Edge Function Error (\(httpResponse.statusCode)): \(errorString)")
                    print("   - Request URL: \(url.absoluteString)")
                    print("   - Headers: \(request.allHTTPHeaderFields ?? [:])")
                    print("   - User ID: \(session.user.id)")
                    print("   - Is Anonymous: \(session.user.isAnonymous)")
                }
            }
            
            // Fallback if response parsing fails - only if not already sent
            if !fallbackResponseSent {
                print("⚠️ Edge Function response parsing failed, using fallback")
                fallbackResponseSent = true
                await handleFallbackResponse(for: sessionId, userMessage: userMessage)
            }
            
        } catch {
            print("❌ AI Chat Error: \(error.localizedDescription)")
            print("   - Error Type: \(type(of: error))")
            if let urlError = error as? URLError {
                print("   - URL Error Code: \(urlError.code)")
                print("   - URL Error Description: \(urlError.localizedDescription)")
            }
            print("   - Falling back to local response")
            
            // Fallback to supportive response if Edge Function fails - only if not already sent
            if !fallbackResponseSent {
                fallbackResponseSent = true
                await handleFallbackResponse(for: sessionId, userMessage: userMessage)
            }
        }
    }
    
    private func handleFallbackResponse(for sessionId: UUID, userMessage: String) async {
        // Enhanced therapeutic responses with connection issue indication
        let therapeuticResponses = [
            "⚠️ I'm having trouble connecting to my AI service right now, but I'm still here to support you. Your feelings are completely valid, and it takes courage to express them. What's on your mind today?",
            "⚠️ There's a temporary connection issue, but I want you to know I'm listening. It sounds like you're going through something challenging. Would you like to talk more about what you're experiencing?",
            "⚠️ I'm experiencing some technical difficulties, but your mental health matters. What you're sharing sounds important. Can you tell me more about how you're feeling right now?",
            "⚠️ My connection is unstable at the moment, but I'm here for you. Remember, your feelings are valid and it's okay to take things one step at a time. What would help you feel supported right now?",
            "⚠️ I'm having connectivity issues but want to acknowledge what you've shared. Your emotional well-being is important. How are you taking care of yourself today?",
            "⚠️ There's a temporary technical issue on my end, but I hear you. What you're experiencing sounds difficult. What has helped you cope with challenging emotions before?"
        ]
        
        let fallbackResponse = therapeuticResponses.randomElement() ?? therapeuticResponses[0]
        
        let aiMessage = ChatMessage(content: fallbackResponse, isUser: false, sessionId: sessionId)
        
        do {
            // Insert fallback message into Supabase
            try await supabase
                .from("chat_messages")
                .insert(aiMessage)
                .execute()
            
            // Add to local messages
            await MainActor.run {
                messages.append(aiMessage)
            }
        } catch {
            // Local-only fallback
            await MainActor.run {
                messages.append(aiMessage)
            }
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
        guard let conversationsUsed = guestInfo["conversationsUsed"] as? Int,
              let conversationsRemaining = guestInfo["conversationsRemaining"] as? Int else { return }
        
        await MainActor.run {
            // Update local user object with conversation count
            // This could trigger UI updates showing remaining conversations
            print("👤 Guest conversations: \(conversationsUsed) used, \(conversationsRemaining) remaining")
            
            // You could post a notification to update UI
            NotificationCenter.default.post(
                name: NSNotification.Name("GuestConversationCountUpdated"),
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
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToMessages(sessionId: UUID) {
        messagesSubscription?.cancel()
        
        // TODO: Implement real-time subscription when Supabase Realtime API is properly configured
        // For now, we'll poll for new messages or rely on manual refresh
        print("Real-time subscription for session \(sessionId) - to be implemented")
    }
    
    private func handleMessageUpdate(_ payload: [String: Any]) async {
        // Handle real-time message updates
        guard let eventType = payload["eventType"] as? String else { return }
        
        switch eventType {
        case "INSERT":
            if let newData = payload["new"] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: newData),
               let newMessage = try? JSONDecoder().decode(ChatMessage.self, from: jsonData) {
                if !messages.contains(where: { $0.id == newMessage.id }) {
                    messages.append(newMessage)
                }
            }
        case "UPDATE":
            if let newData = payload["new"] as? [String: Any],
               let jsonData = try? JSONSerialization.data(withJSONObject: newData),
               let updatedMessage = try? JSONDecoder().decode(ChatMessage.self, from: jsonData) {
                if let index = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    messages[index] = updatedMessage
                }
            }
        case "DELETE":
            if let oldData = payload["old"] as? [String: Any],
               let deletedId = oldData["id"] as? String,
               let uuid = UUID(uuidString: deletedId) {
                messages.removeAll { $0.id == uuid }
            }
        default:
            break
        }
    }
    
    // MARK: - Chat Actions
    
    func deleteSession(_ session: ChatSession) async {
        do {
            // Hard delete in Supabase
            try await supabase
                .from("chat_sessions")
                .delete()
                .eq("id", value: session.id)
                .execute()
            
            // Remove from local sessions
            chatSessions.removeAll { $0.id == session.id }
            
            if currentSession?.id == session.id {
                currentSession = nil
                messages = []
                messagesSubscription?.cancel()
            }
        } catch {
            // Fallback to local deletion for development
            chatSessions.removeAll { $0.id == session.id }
            
            if currentSession?.id == session.id {
                currentSession = nil
                messages = []
            }
        }
    }
    
    func updateSessionTitle(_ session: ChatSession, newTitle: String) async {
        do {
            var updatedSession = session
            updatedSession.title = newTitle
            updatedSession.updatedAt = Date()
            
            try await supabase
                .from("chat_sessions")
                .update(updatedSession)
                .eq("id", value: session.id)
                .execute()
            
            // Update local session
            if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
                chatSessions[index] = updatedSession
            }
            
            if currentSession?.id == session.id {
                currentSession = updatedSession
            }
        } catch {
            // Fallback to local update for development
            if let index = chatSessions.firstIndex(where: { $0.id == session.id }) {
                chatSessions[index].title = newTitle
                chatSessions[index].updatedAt = Date()
            }
            
            if currentSession?.id == session.id {
                currentSession?.title = newTitle
                currentSession?.updatedAt = Date()
            }
        }
    }
    
    // MARK: - Voice Support
    
    func sendVoiceMessage(audioData: Data, sessionId: UUID) async throws {
        // Placeholder for voice message processing
        // In a real implementation, this would:
        // 1. Upload audio to Supabase Storage
        // 2. Convert speech to text using OpenAI Whisper
        // 3. Send the transcribed text as a regular message
        
        let transcription = "Voice message transcription would go here"
        try await sendMessage(content: transcription, sessionId: sessionId)
    }
}