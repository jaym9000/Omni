import SwiftUI

struct PremiumFeatureGate<Content: View>: View {
    @EnvironmentObject var premiumManager: PremiumManager
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
            PremiumUpgradeView()
        }
    }
}

struct PremiumUpgradeView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.omniPrimary, Color.omniSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Unlock Premium")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("Get unlimited access to all features")
                            .font(.system(size: 18))
                            .foregroundColor(.omniTextSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Features list
                    VStack(spacing: 16) {
                        ForEach(PremiumFeature.allCases, id: \.self) { feature in
                            HStack(spacing: 16) {
                                Image(systemName: feature.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(.omniPrimary)
                                    .frame(width: 40)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feature.displayName)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.omniTextPrimary)
                                    
                                    Text(feature.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.omniTextSecondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.omniSecondaryBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Pricing
                    VStack(spacing: 16) {
                        Text("$9.99/month")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("Cancel anytime")
                            .font(.system(size: 16))
                            .foregroundColor(.omniTextSecondary)
                    }
                    
                    // Subscribe button
                    Button(action: subscribe) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Start Free Trial")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.omniPrimary, Color.omniSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .disabled(isProcessing)
                    .padding(.horizontal)
                    
                    // Restore purchases
                    Button("Restore Purchases") {
                        Task {
                            try await premiumManager.restorePurchases()
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.omniPrimary)
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
        }
    }
    
    private func subscribe() {
        isProcessing = true
        Task {
            do {
                try await premiumManager.upgradeToPremium()
                dismiss()
            } catch {
                // Handle error
            }
            isProcessing = false
        }
    }
}

#Preview {
    PremiumUpgradeView()
        .environmentObject(PremiumManager())
}