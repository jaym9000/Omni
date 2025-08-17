import Foundation

struct ChatSession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    
    // Supabase timestamp handling
    private var _createdAt: String
    private var _updatedAt: String
    
    var createdAt: Date {
        get { 
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: _createdAt) ?? Date()
        }
        set { 
            let formatter = ISO8601DateFormatter()
            _createdAt = formatter.string(from: newValue)
        }
    }
    
    var updatedAt: Date {
        get { 
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: _updatedAt) ?? Date()
        }
        set { 
            let formatter = ISO8601DateFormatter()
            _updatedAt = formatter.string(from: newValue)
        }
    }
    
    // Messages will be loaded separately for performance
    var messages: [ChatMessage] = []
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case _createdAt = "created_at"
        case _updatedAt = "updated_at"
    }
    
    init(userId: UUID, title: String = "New Chat") {
        self.id = UUID()
        self.userId = userId
        self.title = title
        
        let now = ISO8601DateFormatter().string(from: Date())
        self._createdAt = now
        self._updatedAt = now
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    let content: String
    let isUser: Bool
    
    // Supabase timestamp handling
    private var _createdAt: String
    
    var timestamp: Date {
        get { 
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: _createdAt) ?? Date()
        }
        set { 
            let formatter = ISO8601DateFormatter()
            _createdAt = formatter.string(from: newValue)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case content
        case isUser = "is_user"
        case _createdAt = "created_at"
    }
    
    init(content: String, isUser: Bool, sessionId: UUID) {
        self.id = UUID()
        self.sessionId = sessionId
        self.content = content
        self.isUser = isUser
        self._createdAt = ISO8601DateFormatter().string(from: Date())
    }
}