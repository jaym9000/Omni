import Foundation

enum JournalType: String, Codable {
    case freeForm = "free_form"
    case tagged = "tagged"
    case themed = "themed"
    case dailyPrompt = "daily_prompt"
}

struct JournalEntry: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var content: String
    let type: JournalType
    var tags: [String] = []
    var mood: MoodType?
    var isFavorite: Bool = false
    var prompt: String?
    
    // Timestamp properties
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
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case content
        case type
        case tags
        case mood
        case isFavorite = "is_favorite"
        case prompt
        case _createdAt = "created_at"
        case _updatedAt = "updated_at"
    }
    
    init(userId: UUID, title: String, content: String, type: JournalType) {
        self.id = UUID()
        self.userId = userId
        self.title = title
        self.content = content
        self.type = type
        
        let now = ISO8601DateFormatter().string(from: Date())
        self._createdAt = now
        self._updatedAt = now
    }
}

struct JournalPrompt: Identifiable {
    let id = UUID()
    let text: String
    let category: String
    
    static let dailyPrompts = [
        JournalPrompt(text: "What's one thing you're grateful for today?", category: "Gratitude"),
        JournalPrompt(text: "What challenged you today and how did you handle it?", category: "Reflection"),
        JournalPrompt(text: "Describe a moment that made you smile today.", category: "Positivity"),
        JournalPrompt(text: "What's one thing you learned about yourself today?", category: "Self-Discovery"),
        JournalPrompt(text: "How did you practice self-care today?", category: "Self-Care")
    ]
}