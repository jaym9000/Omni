import Foundation
import SwiftUI

enum PremiumFeature: String, CaseIterable {
    case chatWithOmni = "chat_with_omni"
    case moodTalkToOmni = "mood_talk_to_omni"
    case unlimitedJournalEntries = "unlimited_journal_entries"
    case advancedAnalytics = "advanced_analytics"
    case voiceMode = "voice_mode"
    case exportData = "export_data"
    case customThemes = "custom_themes"
    
    var displayName: String {
        switch self {
        case .chatWithOmni:
            return "Chat with Omni"
        case .moodTalkToOmni:
            return "Mood-based Conversations"
        case .unlimitedJournalEntries:
            return "Unlimited Journal Entries"
        case .advancedAnalytics:
            return "Advanced Analytics"
        case .voiceMode:
            return "Voice Mode"
        case .exportData:
            return "Export Your Data"
        case .customThemes:
            return "Custom Themes"
        }
    }
    
    var description: String {
        switch self {
        case .chatWithOmni:
            return "Have unlimited conversations with your AI companion"
        case .moodTalkToOmni:
            return "Get personalized support based on your current mood"
        case .unlimitedJournalEntries:
            return "Create unlimited journal entries without restrictions"
        case .advancedAnalytics:
            return "View detailed insights about your mental health journey"
        case .voiceMode:
            return "Talk to Omni using voice conversations"
        case .exportData:
            return "Export all your data in various formats"
        case .customThemes:
            return "Customize the app with unique themes"
        }
    }
    
    var icon: String {
        switch self {
        case .chatWithOmni:
            return "message.circle.fill"
        case .moodTalkToOmni:
            return "face.smiling.fill"
        case .unlimitedJournalEntries:
            return "book.fill"
        case .advancedAnalytics:
            return "chart.line.uptrend.xyaxis"
        case .voiceMode:
            return "mic.fill"
        case .exportData:
            return "square.and.arrow.up"
        case .customThemes:
            return "paintbrush.fill"
        }
    }
}

class PremiumManager: ObservableObject {
    @Published var isPremium = false
    @Published var isFreemium = true
    @Published var isLoading = false
    @AppStorage("premiumStatus") private var storedPremiumStatus = false
    
    // Free tier limits
    let freeJournalEntriesLimit = 5
    let freeMoodTracksPerDay = 3
    
    init() {
        self.isPremium = storedPremiumStatus
        self.isFreemium = !storedPremiumStatus
    }
    
    func checkFeatureAccess(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .chatWithOmni, .moodTalkToOmni, .voiceMode, .exportData, .customThemes:
            return isPremium
        case .unlimitedJournalEntries, .advancedAnalytics:
            return isPremium
        }
    }
    
    func upgradeToPremium() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate purchase
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            self.isPremium = true
            self.isFreemium = false
            self.storedPremiumStatus = true
        }
    }
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate restore
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Check if user has previous purchases
        // For demo, we'll just return current status
    }
}