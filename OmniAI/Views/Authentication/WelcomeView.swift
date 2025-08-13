import SwiftUI

struct WelcomeView: View {
    @Binding var showLogin: Bool
    @Binding var showSignUp: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAnimating = false
    @State private var showGuestPreview = false
    
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
                
                // Enhanced action buttons
                VStack(spacing: 16) {
                    // Primary CTA - Try it free
                    Button(action: { showGuestPreview = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16))
                            Text("Try Omni Free")
                                .font(.system(size: 18, weight: .semibold))
                        }
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
                        .shadow(color: Color.omniPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    // Apple Sign In - Promoted for faster onboarding
                    Button(action: { Task { try await authManager.signInWithApple() } }) {
                        HStack {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 20))
                            Text("Continue with Apple")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                    }
                    
                    // Email sign up
                    Button(action: { showSignUp = true }) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.system(size: 16))
                            Text("Sign up with Email")
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
                    
                    // Sign in link
                    Button(action: { showLogin = true }) {
                        Text("Already have an account? Sign in")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            isAnimating = true
        }
        .fullScreenCover(isPresented: $showGuestPreview) {
            GuestModeView(showSignUp: $showSignUp)
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

// MARK: - Simple Guest Mode View
struct GuestModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showSignUp: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundColor(.omniPrimary)
                    
                    Text("Welcome to Guest Mode!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("You can try Omni's core features without creating an account. Create one later to save your progress and sync across devices.")
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button("Continue as Guest") {
                        // This would set a guest mode flag and dismiss
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.omniPrimary)
                    .cornerRadius(28)
                    
                    Button("Create Account Instead") {
                        showSignUp = true
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.omniPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.omniPrimary, lineWidth: 2)
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
            .background(Color.omniBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniTextSecondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView(showLogin: .constant(false), showSignUp: .constant(false))
            .environmentObject(AuthenticationManager())
    }
}