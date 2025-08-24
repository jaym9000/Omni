import SwiftUI
import RevenueCatUI
import RevenueCat

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var revenueCatManager: RevenueCatManager
    @State private var showSplash = true
    @State private var currentFlow = OnboardingFlow.welcome
    @State private var selectedGoal: String? = nil
    @State private var selectedMood: Int? = nil
    @State private var showPaywall = false
    @State private var showPostTrialSignIn = false
    @State private var purchaseCompleted = false
    
    enum OnboardingFlow {
        case welcome
        case quickSetup
        case aiPreview
        case paywall
        case postTrialSignIn
        case complete
    }
    
    var body: some View {
        if showSplash {
            SplashScreenView(onComplete: {
                withAnimation {
                    showSplash = false
                }
            })
        } else if authManager.isAuthenticated {
            // Authenticated users flow
            if !authManager.isEmailVerified && !authManager.isAppleUser {
                EmailVerificationView()
            } else {
                MainTabView()
            }
        } else if (premiumManager.isPremium || purchaseCompleted) && !authManager.isAuthenticated {
            // User has premium but not signed in yet
            PostTrialSignInView()
        } else {
            // New user onboarding flow
            ZStack {
                switch currentFlow {
                case .welcome:
                    SimpleWelcomeView(onGetStarted: {
                        withAnimation {
                            currentFlow = .quickSetup
                        }
                    })
                    
                case .quickSetup:
                    QuickSetupView(
                        onComplete: { goal, mood in
                            selectedGoal = goal
                            selectedMood = mood
                            withAnimation {
                                currentFlow = .aiPreview
                            }
                        },
                        onSkip: {
                            withAnimation {
                                currentFlow = .aiPreview
                            }
                        }
                    )
                    
                case .aiPreview:
                    AIPreviewView(
                        selectedGoal: selectedGoal,
                        selectedMood: selectedMood,
                        onShowPaywall: {
                            showPaywall = true
                        }
                    )
                    
                case .paywall:
                    // This state is handled by the sheet
                    EmptyView()
                    
                case .postTrialSignIn:
                    PostTrialSignInView()
                    
                case .complete:
                    MainTabView()
                }
            }
            .sheet(isPresented: $showPaywall) {
                Group {
                    // Use the pre-fetched offering from RevenueCatManager
                    if let offering = revenueCatManager.currentOffering {
                        PaywallView(offering: offering, displayCloseButton: true)
                    } else if let offering = revenueCatManager.offerings?.current {
                        // Fallback to current offering if specific one not found
                        PaywallView(offering: offering, displayCloseButton: true)
                    } else {
                        // Last resort - this should rarely happen if offerings are pre-fetched
                        PaywallView(displayCloseButton: true)
                    }
                }
                .interactiveDismissDisabled(false) // Allow dismissal since we have close button
                .onPurchaseStarted { _ in
                    print("🛒 Purchase started...")
                }
                .onPurchaseCompleted { customerInfo in
                    print("✅ Purchase completed callback fired")
                    Task {
                        await MainActor.run {
                            // Purchase was successful
                            premiumManager.isPremium = true
                            purchaseCompleted = true
                            revenueCatManager.isPremium = true
                            revenueCatManager.customerInfo = customerInfo
                            showPaywall = false
                            print("✅ Navigation should trigger to sign-in view")
                        }
                    }
                }
                .onPurchaseCancelled {
                    print("❌ Purchase cancelled by user")
                    // User cancelled - just dismiss the paywall
                    showPaywall = false
                }
                .onPurchaseFailure { error in
                    print("❌ Purchase failed with error: \(error)")
                    
                    // Check error type for smart handling
                    let errorCode = (error as NSError).code
                    let errorDomain = (error as NSError).domain
                    
                    // Handle specific error scenarios
                    if errorDomain == "ASDErrorDomain" && errorCode == 825 {
                        // Code 825: "No transactions in response" - likely duplicate purchase
                        print("🔄 Detected possible duplicate purchase, triggering restore...")
                        
                        // Auto-trigger restore for this specific error
                        Task {
                            do {
                                let customerInfo = try await Purchases.shared.restorePurchases()
                                let hasPremium = !customerInfo.entitlements.active.isEmpty
                                
                                await MainActor.run {
                                    if hasPremium {
                                        print("✅ Restore successful - user has premium")
                                        premiumManager.isPremium = true
                                        purchaseCompleted = true
                                        revenueCatManager.isPremium = true
                                        revenueCatManager.customerInfo = customerInfo
                                        showPaywall = false
                                    } else {
                                        // No premium found after restore - dismiss paywall
                                        print("⚠️ No premium found after restore")
                                        showPaywall = false
                                    }
                                }
                            } catch {
                                print("❌ Auto-restore failed: \(error)")
                                // Don't dismiss - let user try manual restore
                            }
                        }
                    } else if errorCode == 1 {
                        // User cancelled - dismiss paywall
                        print("👤 User cancelled purchase")
                        showPaywall = false
                    } else if errorCode == 2 {
                        // Store problem - don't dismiss, user can retry or restore
                        print("🏪 Store problem detected - keeping paywall open for retry")
                        // In production, you might want to show an alert here
                        // For now, keep paywall open so user can retry or use restore button
                    } else {
                        // For other errors in production, check if user has premium
                        Task {
                            do {
                                let customerInfo = try await Purchases.shared.customerInfo()
                                let hasPremium = !customerInfo.entitlements.active.isEmpty
                                
                                await MainActor.run {
                                    if hasPremium {
                                        // User has premium - navigate forward
                                        premiumManager.isPremium = true
                                        purchaseCompleted = true
                                        revenueCatManager.isPremium = true
                                        revenueCatManager.customerInfo = customerInfo
                                        print("✅ User already has premium")
                                        showPaywall = false
                                    } else {
                                        // No premium and unknown error - keep paywall open
                                        print("⚠️ Purchase failed, keeping paywall open for retry")
                                    }
                                }
                            } catch {
                                // Can't check status - keep paywall open for safety
                                print("⚠️ Can't verify status, keeping paywall open")
                            }
                        }
                    }
                }
                .onRestoreStarted {
                    print("🔄 Restore started...")
                }
                .onRestoreCompleted { customerInfo in
                    print("✅ Restore completed")
                    Task {
                        await MainActor.run {
                            let hasPremium = !customerInfo.entitlements.active.isEmpty
                            if hasPremium {
                                premiumManager.isPremium = true
                                purchaseCompleted = true
                                revenueCatManager.isPremium = true
                                revenueCatManager.customerInfo = customerInfo
                            }
                            showPaywall = false
                        }
                    }
                }
                .onRestoreFailure { error in
                    print("❌ Restore failed: \(error)")
                    // Still dismiss on restore failure
                    showPaywall = false
                }
                .onRequestedDismissal {
                    print("👋 Paywall dismissal requested")
                    // Fallback - check purchase status one more time
                    Task {
                        do {
                            let customerInfo = try await Purchases.shared.customerInfo()
                            let hasPremium = !customerInfo.entitlements.active.isEmpty
                            
                            await MainActor.run {
                                if hasPremium {
                                    premiumManager.isPremium = true
                                    purchaseCompleted = true
                                    revenueCatManager.isPremium = true
                                    revenueCatManager.customerInfo = customerInfo
                                    print("✅ Premium detected on dismissal")
                                }
                                showPaywall = false
                            }
                        } catch {
                            await MainActor.run {
                                showPaywall = false
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
        .environmentObject(PremiumManager())
}