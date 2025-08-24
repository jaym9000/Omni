import SwiftUI
import RevenueCatUI

struct TrialCountdownBanner: View {
    let trialEndDate: Date
    @State private var showPaywall = false
    
    var body: some View {
        let hoursRemaining = trialEndDate.timeIntervalSinceNow / 3600
        
        // Only show when less than 48 hours remaining
        if hoursRemaining <= 48 && hoursRemaining > 0 {
            HStack {
                Image(systemName: hoursRemaining <= 24 ? "exclamationmark.triangle.fill" : "clock.fill")
                    .foregroundColor(hoursRemaining <= 24 ? .red : .orange)
                    .font(.system(size: 14, weight: .medium))
                
                if hoursRemaining <= 1 {
                    Text("Trial ends in less than 1 hour!")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                } else if hoursRemaining <= 24 {
                    Text("Trial ends TODAY")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                } else {
                    Text("Trial ends TOMORROW")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Button(action: { showPaywall = true }) {
                    Text("Keep Premium")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            hoursRemaining <= 24 ?
                            Color.red : Color.orange
                        )
                        .cornerRadius(14)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                hoursRemaining <= 24 ?
                Color.red.opacity(0.1) :
                Color.orange.opacity(0.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        hoursRemaining <= 24 ?
                        Color.red.opacity(0.3) :
                        Color.orange.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .cornerRadius(12)
            .padding(.horizontal)
            .sheet(isPresented: $showPaywall) {
                Group {
                    if let offering = RevenueCatManager.shared.currentOffering {
                        RevenueCatUI.PaywallView(offering: offering)
                    } else {
                        RevenueCatUI.PaywallView()
                    }
                }
                .onPurchaseCompleted { _ in
                    showPaywall = false
                    Task {
                        await RevenueCatManager.shared.checkSubscriptionStatus()
                    }
                }
                .onRestoreCompleted { _ in
                    if RevenueCatManager.shared.isPremium {
                        showPaywall = false
                    }
                }
                .task {
                    if RevenueCatManager.shared.offerings == nil {
                        await RevenueCatManager.shared.fetchOfferings()
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Less than 1 hour
        TrialCountdownBanner(trialEndDate: Date().addingTimeInterval(1800))
        
        // Less than 24 hours
        TrialCountdownBanner(trialEndDate: Date().addingTimeInterval(14400))
        
        // Less than 48 hours
        TrialCountdownBanner(trialEndDate: Date().addingTimeInterval(129600))
        
        // More than 48 hours (won't show)
        TrialCountdownBanner(trialEndDate: Date().addingTimeInterval(259200))
    }
    .padding()
}