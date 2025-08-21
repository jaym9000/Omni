import Foundation

struct ChatSession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var messageCount: Int = 0
    var lastMessage: String?
    
    // Direct Date properties for Firestore
    var createdAt: Date
    var updatedAt: Date
    
    // Messages will be loaded separately for performance
    var messages: [ChatMessage] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case messageCount = "message_count"
        case lastMessage = "last_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), userId: UUID, title: String = "New Chat", createdAt: Date = Date(), updatedAt: Date = Date(), messageCount: Int = 0, lastMessage: String? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageCount = messageCount
        self.lastMessage = lastMessage
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    let content: String
    let isUser: Bool
    var mood: String?
    
    // Direct Date property for Firestore
    var timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case content
        case isUser = "is_user"
        case mood
        case timestamp = "created_at"
    }
    
    init(content: String, isUser: Bool, sessionId: UUID, timestamp: Date = Date(), mood: String? = nil) {
        self.id = UUID()
        self.sessionId = sessionId
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.mood = mood
    }
    
    // Init with existing ID (for messages loaded from Firebase)
    init(id: UUID, content: String, isUser: Bool, sessionId: UUID, timestamp: Date = Date(), mood: String? = nil) {
        self.id = id
        self.sessionId = sessionId
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
        self.mood = mood
    }
}