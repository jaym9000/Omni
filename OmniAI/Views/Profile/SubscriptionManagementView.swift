import SwiftUI
import RevenueCatUI
import RevenueCat
import StoreKit

struct SubscriptionManagementView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var showingPaywall = false
    @State private var isLoading = false
    @State private var showingRestoreAlert = false
    @State private var restoreMessage = ""
    
    var body: some View {
        NavigationStack {
            SwiftUI.ScrollView {
                VStack(spacing: 24) {
                    // Subscription Status Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Plan")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.omniTextSecondary)
                                
                                Text(revenueCatManager.isPremium ? "Premium" : "Free")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.omniTextPrimary)
                                
                                if let expirationDate = revenueCatManager.subscriptionExpirationDate {
                                    Text("Renews: \(expirationDate, style: .date)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.omniTextSecondary)
                                } else if revenueCatManager.isPremium {
                                    Text("Lifetime Access")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: revenueCatManager.isPremium ? "crown.fill" : "lock.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: revenueCatManager.isPremium ? 
                                            [Color.omniPrimary, Color.omniSecondary] : 
                                            [Color.gray, Color.gray.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding()
                        .background(Color.omniCardLavender)
                        .cornerRadius(16)
                        
                        // Upgrade/Manage Button
                        if !revenueCatManager.isPremium {
                            Button(action: {
                                showingPaywall = true
                            }) {
                                HStack {
                                    Text("Upgrade to Premium")
                                        .font(.system(size: 16, weight: .semibold))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    LinearGradient(
                                        colors: [Color.omniPrimary, Color.omniPrimary.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(24)
                            }
                        } else {
                            // Manage Subscription Button (opens App Store subscriptions)
                            Button(action: {
                                Task {
                                    await openSubscriptionManagement()
                                }
                            }) {
                                HStack {
                                    Text("Manage Subscription")
                                        .font(.system(size: 16, weight: .medium))
                                    Image(systemName: "arrow.up.forward.square")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(.omniPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.omniPrimary.opacity(0.1))
                                .cornerRadius(24)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Premium Features List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PREMIUM FEATURES")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.omniTextTertiary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(PremiumFeature.allCases, id: \.self) { feature in
                                HStack(spacing: 16) {
                                    Image(systemName: feature.icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(premiumManager.checkFeatureAccess(feature) ? .omniPrimary : .gray)
                                        .frame(width: 32)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(feature.displayName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.omniTextPrimary)
                                        
                                        Text(feature.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.omniTextSecondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    if premiumManager.checkFeatureAccess(feature) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color.omniSecondaryBackground)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Restore Purchases Button
                    Button(action: {
                        restorePurchases()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .omniPrimary))
                        } else {
                            Text("Restore Purchases")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.omniPrimary)
                        }
                    }
                    .disabled(isLoading)
                    .padding(.top)
                    
                    // Footer Information
                    VStack(spacing: 8) {
                        Text("Subscriptions auto-renew until cancelled")
                            .font(.system(size: 11))
                            .foregroundColor(.omniTextTertiary)
                        
                        Text("Manage or cancel anytime in Settings")
                            .font(.system(size: 11))
                            .foregroundColor(.omniTextTertiary)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Subscription")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
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
                showingPaywall = false
                // Refresh subscription status
                Task {
                    await revenueCatManager.checkSubscriptionStatus()
                }
            }
            .onRestoreCompleted { _ in
                // Check if restoration granted access
                if revenueCatManager.isPremium {
                    showingPaywall = false
                }
            }
            .task {
                // Ensure offerings are loaded
                if RevenueCatManager.shared.offerings == nil {
                    await RevenueCatManager.shared.fetchOfferings()
                }
            }
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage)
        }
    }
    
    private func restorePurchases() {
        isLoading = true
        Task {
            do {
                let restored = try await revenueCatManager.restorePurchases()
                
                await MainActor.run {
                    isLoading = false
                    if restored {
                        restoreMessage = "Your purchases have been restored successfully!"
                    } else {
                        restoreMessage = "No previous purchases found to restore."
                    }
                    showingRestoreAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    restoreMessage = "Failed to restore purchases. Please try again."
                    showingRestoreAlert = true
                }
            }
        }
    }
    
    @MainActor
    private func openSubscriptionManagement() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Failed to open subscription management: \(error)")
            }
        }
    }
}

#Preview {
    SubscriptionManagementView()
        .environmentObject(RevenueCatManager.shared)
        .environmentObject(PremiumManager())
}