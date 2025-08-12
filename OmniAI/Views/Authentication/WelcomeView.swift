import SwiftUI

struct WelcomeView: View {
    @Binding var showLogin: Bool
    @Binding var showSignUp: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.omniPrimary.opacity(0.1), Color.omniSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo and illustration
                VStack(spacing: 30) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.omniPrimary, Color.omniSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    VStack(spacing: 12) {
                        Text("Welcome to Omni")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("Your safe space for mental wellness")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: { showSignUp = true }) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
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
                    }
                    
                    Button(action: { showLogin = true }) {
                        Text("I already have an account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.omniPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(Color.omniPrimary, lineWidth: 2)
                            )
                    }
                    
                    // Apple Sign In
                    Button(action: { Task { try await authManager.signInWithApple() } }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.omniTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.omniTertiaryBackground)
                        .cornerRadius(28)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView(showLogin: .constant(false), showSignUp: .constant(false))
            .environmentObject(AuthenticationManager())
    }
}