import Foundation
import SwiftUI
import RevenueCat
import Combine

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

@MainActor
class PremiumManager: ObservableObject {
    @Published var isPremium = false
    @Published var isFreemium = true
    @Published var isLoading = false
    @AppStorage("premiumStatus") private var storedPremiumStatus = false
    
    // Free tier limits
    let freeJournalEntriesLimit = 5
    let freeMoodTracksPerDay = 3
    
    // RevenueCat integration
    private let revenueCatManager = RevenueCatManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Sync with RevenueCat subscription status
        setupRevenueCatBinding()
        
        // Initial status from RevenueCat
        self.isPremium = revenueCatManager.isPremium
        self.isFreemium = !revenueCatManager.isPremium
        self.storedPremiumStatus = revenueCatManager.isPremium
    }
    
    private func setupRevenueCatBinding() {
        // Observe RevenueCat premium status changes
        revenueCatManager.$isPremium
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                guard let self = self else { return }
                self.isPremium = isPremium
                self.isFreemium = !isPremium
                self.storedPremiumStatus = isPremium
            }
            .store(in: &cancellables)
        
        // Observe loading state
        revenueCatManager.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }
    
    func checkFeatureAccess(_ feature: PremiumFeature) -> Bool {
        // Use RevenueCat to check feature access
        return revenueCatManager.hasAccessToFeature(feature)
    }
    
    func upgradeToPremium() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Get current offering from RevenueCat
        guard let offering = revenueCatManager.currentOffering,
              let package = offering.availablePackages.first else {
            throw NSError(domain: "PremiumManager", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No subscription packages available"
            ])
        }
        
        // Attempt purchase through RevenueCat
        let success = try await revenueCatManager.purchase(package: package)
        
        if success {
            await MainActor.run {
                self.isPremium = true
                self.isFreemium = false
                self.storedPremiumStatus = true
            }
        } else {
            throw NSError(domain: "PremiumManager", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Purchase was not successful"
            ])
        }
    }
    
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Restore through RevenueCat
        let restored = try await revenueCatManager.restorePurchases()
        
        if restored {
            await MainActor.run {
                self.isPremium = true
                self.isFreemium = false
                self.storedPremiumStatus = true
            }
        } else {
            // No purchases to restore is not an error, just inform the user
            print("No purchases to restore")
        }
    }
    
    // Convenience methods for checking specific limits
    var canCreateMoreJournalEntries: Bool {
        if isPremium { return true }
        // Check current journal count against limit
        // This would need to be tracked elsewhere
        return true // Placeholder
    }
    
    var canTrackMoreMoodsToday: Bool {
        if isPremium { return true }
        // Check today's mood tracking count against limit
        // This would need to be tracked elsewhere  
        return true // Placeholder
    }
    
    // Get subscription expiration date
    var subscriptionExpirationDate: Date? {
        return revenueCatManager.subscriptionExpirationDate
    }
    
    // Get formatted subscription status
    var subscriptionStatusText: String {
        return revenueCatManager.subscriptionStatusText
    }
}