import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @Binding var showLogin: Bool
    @Binding var showSignUp: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAnimating = false
    @State private var showGuestPreview = false
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

// MARK: - Enhanced Guest Mode View
struct GuestModeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var showSignUp: Bool
    @State private var isStartingGuestSession = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Header
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.omniPrimary, Color.omniSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Try Omni Free!")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("Experience AI-powered mental health support with no commitment required.")
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Benefits
                VStack(spacing: 16) {
                    GuestBenefit(icon: "bubble.left.and.bubble.right", title: "3 Free AI Conversations", description: "Try our therapeutic AI companion")
                    GuestBenefit(icon: "heart.circle", title: "Evidence-Based Support", description: "Get personalized mental health guidance")
                    GuestBenefit(icon: "lock.shield", title: "100% Private & Secure", description: "Your conversations are confidential")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button(action: startGuestSession) {
                        HStack {
                            if isStartingGuestSession {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 18))
                                Text("Start Free Trial")
                                    .font(.system(size: 18, weight: .semibold))
                            }
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
                    .disabled(isStartingGuestSession)
                    
                    Button("Create Full Account") {
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
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func startGuestSession() {
        isStartingGuestSession = true
        
        Task {
            do {
                try await authManager.startGuestSession()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Error starting guest session: \(error)")
                await MainActor.run {
                    isStartingGuestSession = false
                    errorMessage = "Unable to start guest session. Please check your internet connection and try again."
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Guest Benefit Component
struct GuestBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.omniPrimary)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.omniTextPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.omniSecondaryBackground)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        WelcomeView(showLogin: .constant(false), showSignUp: .constant(false))
            .environmentObject(AuthenticationManager())
    }
}