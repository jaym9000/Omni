import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSplash = true
    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                if authManager.isAuthenticated {
                    if !authManager.isEmailVerified && !authManager.isAppleUser && !(authManager.currentUser?.isGuest ?? false) {
                        EmailVerificationView()
                    } else if !(authManager.currentUser?.hasCompletedOnboarding ?? false) {
                        OnboardingView()
                    } else {
                        MainTabView()
                    }
                } else {
                    // Enhanced welcome flow with value-first approach
                    NavigationStack {
                        WelcomeView(showLogin: $showLogin, showSignUp: $showSignUp)
                            .navigationDestination(isPresented: $showLogin) {
                                LoginView()
                            }
                            .navigationDestination(isPresented: $showSignUp) {
                                SignUpView()
                            }
                    }
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