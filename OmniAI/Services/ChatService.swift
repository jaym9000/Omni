import Foundation
import Supabase
import SwiftUI

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
                .eq("is_active", value: true)
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
                .order("timestamp", ascending: true)
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
        
        // Simulate AI processing time
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))
        
        let aiResponses = [
            "I understand how you're feeling. It's completely normal to have these emotions, and I'm here to support you through this.",
            "Thank you for sharing that with me. Your feelings are valid, and it's important to acknowledge them. How can we work through this together?",
            "I hear you. It sounds like you're going through something challenging. Remember that you're not alone in this journey.",
            "That's a lot to process. Take your time with these feelings. What do you think might help you feel more grounded right now?",
            "I appreciate you opening up to me. Your mental health matters, and taking time to reflect like this is a positive step."
        ]
        
        let response = aiResponses.randomElement() ?? "I'm here to listen and support you."
        let aiMessage = ChatMessage(content: response, isUser: false, sessionId: sessionId)
        
        do {
            // Insert AI message into Supabase
            try await supabase
                .from("chat_messages")
                .insert(aiMessage)
                .execute()
            
            // Add to local messages
            messages.append(aiMessage)
        } catch {
            // Fallback to local message for development
            messages.append(aiMessage)
        }
    }
    
    // MARK: - Real-time Subscriptions
    
    func subscribeToMessages(sessionId: UUID) {
        messagesSubscription?.cancel()
        
        messagesSubscription = Task {
            do {
                let channel = await supabase.channel("chat_messages")
                
                let subscription = await channel.onPostgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: "chat_messages",
                    filter: "session_id=eq.\(sessionId)"
                ) { [weak self] payload in
                    Task { @MainActor in
                        await self?.handleMessageUpdate(payload)
                    }
                }
                
                await channel.subscribe()
            } catch {
                print("Failed to subscribe to messages: \(error)")
            }
        }
    }
    
    private func handleMessageUpdate(_ payload: AnyAction) async {
        // Handle real-time message updates
        switch payload.eventType {
        case .insert:
            if let newMessage = try? JSONDecoder().decode(ChatMessage.self, from: payload.record) {
                if !messages.contains(where: { $0.id == newMessage.id }) {
                    messages.append(newMessage)
                }
            }
        case .update:
            if let updatedMessage = try? JSONDecoder().decode(ChatMessage.self, from: payload.record) {
                if let index = messages.firstIndex(where: { $0.id == updatedMessage.id }) {
                    messages[index] = updatedMessage
                }
            }
        case .delete:
            if let deletedId = payload.old?["id"] as? String,
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
            // Soft delete in Supabase
            var deletedSession = session
            deletedSession.isActive = false
            
            try await supabase
                .from("chat_sessions")
                .update(deletedSession)
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