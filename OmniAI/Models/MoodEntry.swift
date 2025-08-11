import Foundation
import SwiftUI

enum MoodType: String, CaseIterable, Codable {
    case happy
    case anxious
    case sad
    case overwhelmed
    case calm
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .anxious: return "😰"
        case .sad: return "😢"
        case .overwhelmed: return "🤯"
        case .calm: return "😌"
        }
    }
    
    var color: Color {
        switch self {
        case .happy: return .moodHappy
        case .anxious: return .moodAnxious
        case .sad: return .moodSad
        case .overwhelmed: return .moodOverwhelmed
        case .calm: return .moodCalm
        }
    }
    
    var label: String {
        switch self {
        case .happy: return "Happy"
        case .anxious: return "Anxious"
        case .sad: return "Sad"
        case .overwhelmed: return "Overwhelmed"
        case .calm: return "Calm"
        }
    }
}

struct MoodEntry: Codable, Identifiable {
    let id: String
    let userId: String
    let mood: MoodType
    let timestamp: Date
    var note: String?
    
    init(userId: String, mood: MoodType, note: String? = nil) {
        self.id = UUID().uuidString
        self.userId = userId
        self.mood = mood
        self.timestamp = Date()
        self.note = note
    }
}