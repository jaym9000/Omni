import Foundation
import FirebaseAnalytics
import RevenueCat

@MainActor
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Onboarding Events
    
    func trackWelcomeViewed() {
        Analytics.logEvent("welcome_viewed", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSetupStarted() {
        Analytics.logEvent("setup_started", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSetupCompleted(goal: String?, mood: Int?) {
        var parameters: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let goal = goal {
            parameters["selected_goal"] = goal
        }
        
        if let mood = mood {
            parameters["selected_mood"] = mood
        }
        
        Analytics.logEvent("setup_completed", parameters: parameters)
    }
    
    func trackSetupSkipped() {
        Analytics.logEvent("setup_skipped", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - AI Preview Events
    
    func trackAIPreviewShown(goal: String?, mood: Int?) {
        var parameters: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let goal = goal {
            parameters["goal"] = goal
        }
        
        if let mood = mood {
            parameters["mood"] = mood
        }
        
        Analytics.logEvent("ai_preview_shown", parameters: parameters)
    }
    
    // MARK: - Paywall Events
    
    func trackPaywallShown(source: String = "ai_preview") {
        Analytics.logEvent("paywall_shown", parameters: [
            "source": source,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackPaywallDismissed() {
        Analytics.logEvent("paywall_dismissed", parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackTrialStarted(product: String) {
        Analytics.logEvent("trial_started", parameters: [
            "product": product,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        // Also track in RevenueCat
        Purchases.shared.attribution.collectDeviceIdentifiers()
    }
    
    func trackPurchaseCompleted(product: String, revenue: Double) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            "product": product,
            "value": revenue,
            "currency": "USD",
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Authentication Events
    
    func trackSignInStarted(method: String) {
        Analytics.logEvent("sign_in_started", parameters: [
            "method": method,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSignInCompleted(method: String) {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            "method": method,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSignUpStarted(method: String) {
        Analytics.logEvent("sign_up_started", parameters: [
            "method": method,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSignUpCompleted(method: String) {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            "method": method,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Session Events
    
    func trackSessionStart() {
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackSessionEnd(duration: TimeInterval) {
        Analytics.logEvent("session_end", parameters: [
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - Chat Events
    
    func trackChatStarted(isFirstChat: Bool) {
        Analytics.logEvent("chat_started", parameters: [
            "is_first_chat": isFirstChat,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    func trackMessageSent(messageCount: Int) {
        Analytics.logEvent("message_sent", parameters: [
            "message_count": messageCount,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    // MARK: - User Properties
    
    func setUserProperties(isPremium: Bool, authMethod: String?) {
        Analytics.setUserProperty(isPremium ? "premium" : "free", forName: "subscription_status")
        
        if let authMethod = authMethod {
            Analytics.setUserProperty(authMethod, forName: "auth_method")
        }
    }
    
    // MARK: - Conversion Funnel
    
    func trackFunnelStep(_ step: FunnelStep) {
        Analytics.logEvent("funnel_step", parameters: [
            "step_name": step.rawValue,
            "step_number": step.stepNumber,
            "timestamp": Date().timeIntervalSince1970
        ])
    }
    
    enum FunnelStep: String {
        case appOpen = "app_open"
        case welcomeViewed = "welcome_viewed"
        case setupStarted = "setup_started"
        case setupCompleted = "setup_completed"
        case aiPreviewShown = "ai_preview_shown"
        case paywallShown = "paywall_shown"
        case trialStarted = "trial_started"
        case signInCompleted = "sign_in_completed"
        case firstChatStarted = "first_chat_started"
        
        var stepNumber: Int {
            switch self {
            case .appOpen: return 1
            case .welcomeViewed: return 2
            case .setupStarted: return 3
            case .setupCompleted: return 4
            case .aiPreviewShown: return 5
            case .paywallShown: return 6
            case .trialStarted: return 7
            case .signInCompleted: return 8
            case .firstChatStarted: return 9
            }
        }
    }
}