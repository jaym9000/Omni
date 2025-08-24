import Foundation
import RevenueCat
import FirebaseAuth
import FirebaseFirestore

@MainActor
class RevenueCatManager: NSObject, ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var isPremium = false
    @Published var isLoading = false
    @Published var customerInfo: CustomerInfo?
    @Published var offerings: Offerings?
    @Published var currentOffering: Offering?
    
    // Entitlement identifiers
    private let premiumEntitlement = "premium"
    
    // Product identifiers (should match App Store Connect)
    struct Products {
        static let monthlySubscription = "omni_premium_monthly"
        static let yearlySubscription = "omni_premium_yearly"
        // Removed weekly and lifetime to simplify offerings
    }
    
    private let firebaseManager = FirebaseManager.shared
    
    private override init() {
        super.init()
        // Initialize will be called from app startup
    }
    
    func configure(with apiKey: String) {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: apiKey)
        
        // Set delegate to listen for updates
        Purchases.shared.delegate = self
        
        // Check initial subscription status and fetch offerings
        Task {
            await checkSubscriptionStatus()
            await fetchOfferings()
            
            // Log available offerings for debugging
            if let offerings = self.offerings {
                print("📱 RevenueCat: Available offerings:")
                for (key, offering) in offerings.all {
                    print("  - \(key): \(offering.identifier)")
                }
                if let current = offerings.current {
                    print("📱 RevenueCat: Current offering: \(current.identifier)")
                }
            }
        }
    }
    
    func identifyUser(userId: String) async {
        do {
            // Identify the user to RevenueCat
            _ = try await Purchases.shared.logIn(userId)
            print("📱 RevenueCat: Identified user \(userId)")
            
            // Check subscription status after identifying
            await checkSubscriptionStatus()
        } catch {
            print("❌ RevenueCat: Failed to identify user: \(error)")
        }
    }
    
    func logOut() async {
        do {
            _ = try await Purchases.shared.logOut()
            print("📱 RevenueCat: User logged out")
            
            // Reset premium status
            self.isPremium = false
            self.customerInfo = nil
        } catch {
            print("❌ RevenueCat: Failed to log out: \(error)")
        }
    }
    
    func checkSubscriptionStatus() async {
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            self.customerInfo = customerInfo
            
            // Check if user has premium entitlement
            self.isPremium = customerInfo.entitlements[premiumEntitlement]?.isActive == true
            
            // Update Firebase user record with subscription status
            if let userId = Auth.auth().currentUser?.uid {
                await updateFirebaseSubscriptionStatus(userId: userId, isPremium: self.isPremium, customerInfo: customerInfo)
            }
            
            print("📱 RevenueCat: Premium status = \(self.isPremium)")
        } catch {
            print("❌ RevenueCat: Failed to get customer info: \(error)")
            self.isPremium = false
        }
    }
    
    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.offerings = offerings
            
            // Try to get "Omni New" offering first, fallback to current
            if let omniNewOffering = offerings.offering(identifier: "Omni New") {
                self.currentOffering = omniNewOffering
                print("📱 RevenueCat: Using 'Omni New' offering")
            } else {
                self.currentOffering = offerings.current
                print("📱 RevenueCat: 'Omni New' not found, using current: \(offerings.current?.identifier ?? "none")")
            }
            
            print("📱 RevenueCat: Fetched \(offerings.all.count) offerings")
            print("📱 RevenueCat: Available offerings: \(offerings.all.keys.joined(separator: ", "))")
        } catch {
            print("❌ RevenueCat: Failed to fetch offerings: \(error)")
        }
    }
    
    func purchase(package: Package) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            // Check if purchase was successful
            if result.customerInfo.entitlements[premiumEntitlement]?.isActive == true {
                self.customerInfo = result.customerInfo
                self.isPremium = true
                
                // Update Firebase
                if let userId = Auth.auth().currentUser?.uid {
                    await updateFirebaseSubscriptionStatus(userId: userId, isPremium: true, customerInfo: result.customerInfo)
                }
                
                print("✅ RevenueCat: Purchase successful")
                return true
            } else {
                print("❌ RevenueCat: Purchase completed but entitlement not active")
                return false
            }
        } catch let error as RevenueCat.ErrorCode {
            if error == .purchaseCancelledError {
                print("📱 RevenueCat: Purchase cancelled by user")
            } else {
                print("❌ RevenueCat: Purchase failed: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    func restorePurchases() async throws -> Bool {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = customerInfo
            
            // Check if restoration found premium entitlement
            let hadPremium = self.isPremium
            self.isPremium = customerInfo.entitlements[premiumEntitlement]?.isActive == true
            
            // Update Firebase
            if let userId = Auth.auth().currentUser?.uid {
                await updateFirebaseSubscriptionStatus(userId: userId, isPremium: self.isPremium, customerInfo: customerInfo)
            }
            
            if self.isPremium && !hadPremium {
                print("✅ RevenueCat: Purchases restored successfully")
                return true
            } else if self.isPremium {
                print("📱 RevenueCat: User already had premium")
                return true
            } else {
                print("📱 RevenueCat: No purchases to restore")
                return false
            }
        } catch {
            print("❌ RevenueCat: Failed to restore purchases: \(error)")
            throw error
        }
    }
    
    private func updateFirebaseSubscriptionStatus(userId: String, isPremium: Bool, customerInfo: CustomerInfo) async {
        let db = Firestore.firestore()
        
        var subscriptionData: [String: Any] = [
            "isPremium": isPremium,
            "revenueCatUserId": customerInfo.originalAppUserId,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Add subscription details if premium
        if isPremium, let entitlement = customerInfo.entitlements[premiumEntitlement] {
            subscriptionData["subscriptionExpirationDate"] = entitlement.expirationDate
            subscriptionData["subscriptionProductIdentifier"] = entitlement.productIdentifier
            subscriptionData["subscriptionIsActive"] = entitlement.isActive
            subscriptionData["subscriptionPeriodType"] = entitlement.periodType.rawValue
            subscriptionData["subscriptionStore"] = entitlement.store.rawValue
            subscriptionData["subscriptionIsSandbox"] = entitlement.isSandbox
        }
        
        do {
            try await db.collection("users").document(userId).setData(subscriptionData, merge: true)
            print("✅ Firebase: Updated subscription status for user \(userId)")
        } catch {
            print("❌ Firebase: Failed to update subscription status: \(error)")
        }
    }
    
    // Check if a specific feature is available
    func hasAccessToFeature(_ feature: PremiumFeature) -> Bool {
        // All premium features require subscription
        return isPremium
    }
    
    // Get the user's subscription expiration date
    var subscriptionExpirationDate: Date? {
        guard let entitlement = customerInfo?.entitlements[premiumEntitlement],
              entitlement.isActive else {
            return nil
        }
        return entitlement.expirationDate
    }
    
    // Get formatted subscription status text
    var subscriptionStatusText: String {
        if isPremium {
            if let expirationDate = subscriptionExpirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Premium until \(formatter.string(from: expirationDate))"
            } else {
                return "Premium (Lifetime)"
            }
        } else {
            return "Free Plan"
        }
    }
}

// MARK: - PurchasesDelegate
extension RevenueCatManager: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            print("📱 RevenueCat: Customer info updated")
            self.customerInfo = customerInfo
            self.isPremium = customerInfo.entitlements[premiumEntitlement]?.isActive == true
            
            // Update Firebase
            if let userId = Auth.auth().currentUser?.uid {
                await updateFirebaseSubscriptionStatus(userId: userId, isPremium: self.isPremium, customerInfo: customerInfo)
            }
        }
    }
}