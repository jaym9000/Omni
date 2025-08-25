import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @Binding var showLogin: Bool
    @Binding var showSignUp: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAnimating = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
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
                
                // Logo and value proposition
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
                    
                    VStack(spacing: 16) {
                        Text("Your AI Wellness Companion")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.omniTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Get personalized mental health support anytime, anywhere. No appointments needed.")
                            .font(.system(size: 16))
                            .foregroundColor(.omniTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                
                // Trust signals and social proof
                VStack(spacing: 12) {
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.system(size: 12))
                            }
                        }
                        Text("4.8 • Trusted by 50,000+ users")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                    }
                    
                    // Trust badges
                    HStack(spacing: 16) {
                        TrustBadge(icon: "lock.shield", text: "100% Private")
                        TrustBadge(icon: "checkmark.shield", text: "Evidence-Based")
                        TrustBadge(icon: "heart.circle", text: "24/7 Support")
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Enhanced action buttons - REMOVED GUEST MODE
                VStack(spacing: 16) {
                    
                    // Apple Sign In - Using native button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task {
                                do {
                                    try await authManager.handleAppleSignInResult(result)
                                    print("✅ Apple Sign-In completed successfully")
                                } catch {
                                    print("❌ Apple Sign-In failed in WelcomeView: \(error)")
                                    await MainActor.run {
                                        errorMessage = "Apple Sign-In failed. Please try again."
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 56)
                    .cornerRadius(28)
                    
                    // Email sign in - changed to go to LoginView
                    Button(action: { showLogin = true }) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.system(size: 16))
                            Text("Continue with Email")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.omniPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.omniPrimary, lineWidth: 2)
                        )
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
        .alert("Authentication Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Trust Badge Component
struct TrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.omniSecondary)
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.omniTextSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.omniSecondary.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        WelcomeView(showLogin: .constant(false), showSignUp: .constant(false))
            .environmentObject(AuthenticationManager())
    }
}