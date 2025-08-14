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
        case .happy: return "🙂"       // Gentler smile instead of bright grin
        case .anxious: return "😔"     // Thoughtful instead of alarming sweaty face
        case .sad: return "🙁"         // Subtle frown instead of crying
        case .overwhelmed: return "🫨"     // Shaking face - gentle but expressive
        case .calm: return "😌"        // Keep the peaceful relieved face
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
    let id: UUID
    let userId: UUID
    let mood: MoodType
    var note: String?
    
    // Supabase timestamp handling
    private var _timestamp: String
    
    var timestamp: Date {
        get { 
            let formatter = ISO8601DateFormatter()
            return formatter.date(from: _timestamp) ?? Date()
        }
        set { 
            let formatter = ISO8601DateFormatter()
            _timestamp = formatter.string(from: newValue)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mood
        case note
        case _timestamp = "timestamp"
    }
    
    init(userId: UUID, mood: MoodType, note: String? = nil) {
        self.id = UUID()
        self.userId = userId
        self.mood = mood
        self.note = note
        self._timestamp = ISO8601DateFormatter().string(from: Date())
    }
}