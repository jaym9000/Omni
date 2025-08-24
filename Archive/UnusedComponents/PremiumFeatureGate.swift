import SwiftUI
import RevenueCatUI

struct PremiumFeatureGate<Content: View>: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    let feature: PremiumFeature
    let content: () -> Content
    
    var body: some View {
        if premiumManager.checkFeatureAccess(feature) {
            content()
        } else {
            PremiumUpgradePrompt(feature: feature)
        }
    }
}

struct PremiumUpgradePrompt: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    let feature: PremiumFeature
    @State private var showUpgradeSheet = false
    
    var body: some View {
        Button(action: { showUpgradeSheet = true }) {
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.omniPrimary)
                
                Text(feature.displayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.omniTextPrimary)
                
                Text(feature.description)
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                
                Text("Upgrade to Premium")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.omniPrimary, Color.omniSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(20)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.omniSecondaryBackground)
            .cornerRadius(16)
        }
        .sheet(isPresented: $showUpgradeSheet) {
            RevenueCatPaywallView()
        }
    }
}

// RevenueCat Paywall View Wrapper
struct RevenueCatPaywallView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    @State private var purchaseCompleted = false
    
    var body: some View {
        Group {
            if let offering = RevenueCatManager.shared.currentOffering {
                // Use the specific offering (should be "Omni New")
                RevenueCatUI.PaywallView(offering: offering)
            } else {
                // Fallback: let RevenueCat find the paywall
                RevenueCatUI.PaywallView()
            }
        }
        .onPurchaseCompleted { _ in
            purchaseCompleted = true
            // Refresh subscription status
            Task {
                await revenueCatManager.checkSubscriptionStatus()
            }
            dismiss()
        }
        .onRestoreCompleted { _ in
            // Check if restoration granted access
            if revenueCatManager.isPremium {
                purchaseCompleted = true
                dismiss()
            }
        }
        .task {
            // Ensure offerings are loaded
            if RevenueCatManager.shared.offerings == nil {
                await RevenueCatManager.shared.fetchOfferings()
            }
        }
    }
}

// Legacy PremiumUpgradeView for backward compatibility
// This now just shows the RevenueCat paywall
struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    @State private var isProcessing = false
    
    var body: some View {
        Group {
            if let offering = RevenueCatManager.shared.currentOffering {
                // Use the specific offering (should be "Omni New")
                RevenueCatUI.PaywallView(offering: offering)
            } else {
                // Fallback: let RevenueCat find the paywall
                RevenueCatUI.PaywallView()
            }
        }
        .onPurchaseCompleted { _ in
            // Refresh subscription status
            Task {
                await revenueCatManager.checkSubscriptionStatus()
            }
            dismiss()
        }
        .onRestoreCompleted { _ in
            // Check if restoration granted access
            if revenueCatManager.isPremium {
                dismiss()
            }
        }
        .task {
            // Ensure offerings are loaded
            if RevenueCatManager.shared.offerings == nil {
                await RevenueCatManager.shared.fetchOfferings()
            }
        }
    }
}

#Preview {
    PremiumUpgradeView()
        .environmentObject(PremiumManager())
        .environmentObject(RevenueCatManager.shared)
}