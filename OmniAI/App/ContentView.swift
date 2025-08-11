import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                if authManager.isAuthenticated {
                    if !authManager.isEmailVerified && !authManager.isAppleUser {
                        EmailVerificationView()
                    } else if !hasCompletedOnboarding {
                        OnboardingView()
                    } else {
                        MainTabView()
                    }
                } else {
                    AuthenticationRootView()
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSplash = false
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