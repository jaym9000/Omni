import Foundation

enum JournalType: String, Codable {
    case freeForm = "free_form"
    case tagged = "tagged"
    case themed = "themed"
    case dailyPrompt = "daily_prompt"
}

struct JournalEntry: Codable, Identifiable {
    let id: String
    let userId: String
    var title: String
    var content: String
    let type: JournalType
    var tags: [String] = []
    var mood: MoodType?
    let createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool = false
    var prompt: String?
    
    init(userId: String, title: String, content: String, type: JournalType) {
        self.id = UUID().uuidString
        self.userId = userId
        self.title = title
        self.content = content
        self.type = type
        self.createdAt = Date()
        self.updatedAt = Date()
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