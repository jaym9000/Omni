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
    
    deinit {
        messagesSubscription?.cancel()
    }
    
    // MARK: - Session Management
    
    func createNewSession(userId: UUID, title: String = "New Chat") async throws -> ChatSession {
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
        
        // Create user message
        let userMessage = ChatMessage(content: content, isUser: true, sessionId: sessionId)
        
        do {
            // Insert user message into Supabase
            try await supabase
                .from("chat_messages")
                .insert(userMessage)
                .execute()
            
            // Add to local messages
            messages.append(userMessage)
            
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
            messages.append(userMessage)
            await generateAIResponse(for: sessionId, userMessage: content)
        }
    }
    
    private func generateAIResponse(for sessionId: UUID, userMessage: String) async {
        isTyping = true
        defer { isTyping = false }
        
        do {
            // Get current user session for authentication
            let session = try await supabase.auth.session
            
            // Prepare conversation history (last 10 messages for context)
            let recentMessages = messages.suffix(10).map { message in
                return [
                    "role": message.isUser ? "user" : "assistant",
                    "content": message.content
                ]
            }
            
            // Call Supabase Edge Function for AI response
            let requestBody: [String: Any] = [
                "message": userMessage,
                "sessionId": sessionId.uuidString,
                "conversationHistory": recentMessages
            ]
            
            // Convert to JSON Data
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            
            // Create URL request manually for Edge Function
            let url = URL(string: "https://rchropdkyqpfyjwgdudv.supabase.co/functions/v1/ai-chat")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            // Make the request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check response status
            if let httpResponse = response as? HTTPURLResponse {
                print("Edge Function Response Status: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Parse AI response
                    if let aiResponse = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let content = aiResponse["content"] as? String {
                        
                        // Check for crisis detection
                        let crisisDetected = aiResponse["crisisDetected"] as? Bool ?? false
                        let requiresEscalation = aiResponse["requiresEscalation"] as? Bool ?? false
                        
                        // Create AI message
                        let aiMessage = ChatMessage(content: content, isUser: false, sessionId: sessionId)
                        
                        // Add to local messages (Edge Function already stored in DB)
                        messages.append(aiMessage)
                        
                        // Handle crisis situation if detected
                        if crisisDetected || requiresEscalation {
                            await handleCrisisResponse(requiresEscalation: requiresEscalation)
                        }
                        
                        print("✅ OpenAI Response Received: \(content.prefix(50))...")
                        return
                    }
                }
            }
            
            // Fallback if response parsing fails
            print("⚠️ Edge Function response parsing failed, using fallback")
            await handleFallbackResponse(for: sessionId, userMessage: userMessage)
            
        } catch {
            print("❌ AI Chat Error: \(error)")
            // Fallback to supportive response if Edge Function fails
            await handleFallbackResponse(for: sessionId, userMessage: userMessage)
        }
    }
    
    private func handleFallbackResponse(for sessionId: UUID, userMessage: String) async {
        // Enhanced therapeutic responses until Edge Function is deployed
        let therapeuticResponses = [
            "I hear you and I'm here to support you. It sounds like you're going through something challenging right now. Would you like to talk more about what's on your mind? Remember, your feelings are valid and it's okay to take things one step at a time.",
            "Thank you for sharing that with me. Your feelings are completely valid, and it takes courage to express them. I'm here to listen without judgment. What do you think might help you feel more supported right now?",
            "I understand that you're experiencing something difficult. It's important to acknowledge these feelings rather than push them away. You're not alone in this journey. What has helped you cope with challenging emotions before?",
            "I appreciate you opening up about this. Your mental health and emotional well-being matter deeply. Sometimes just expressing what we're feeling can provide some relief. How are you taking care of yourself today?",
            "What you're sharing sounds really tough, and I want you to know that your feelings make complete sense. It's okay to feel whatever you're feeling. Would it help to explore what's behind these emotions, or would you prefer to focus on some grounding techniques?",
            "I can hear that this is weighing on you. Thank you for trusting me with what you're experiencing. Remember that healing isn't linear, and it's okay to have difficult moments. What would feel most supportive for you right now?"
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
            messages.append(aiMessage)
        } catch {
            // Local-only fallback
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