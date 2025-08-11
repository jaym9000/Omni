import Foundation

struct ChatSession: Codable, Identifiable {
    let id: String
    let userId: String
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date
    var isActive: Bool = true
    
    init(userId: String, title: String = "New Chat") {
        self.id = UUID().uuidString
        self.userId = userId
        self.title = title
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: String
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isTyping: Bool = false
    
    init(content: String, isUser: Bool) {
        self.id = UUID().uuidString
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}