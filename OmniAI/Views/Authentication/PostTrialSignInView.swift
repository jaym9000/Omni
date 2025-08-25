import SwiftUI
import AuthenticationServices

struct PostTrialSignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var showEmailLogin = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.omniPrimary.opacity(0.05), Color.omniSecondary.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Success message
                    VStack(spacing: 24) {
                        // Checkmark animation
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Welcome to Premium!")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.omniTextPrimary)
                            
                            Text("Your 7-day free trial has started")
                                .font(.system(size: 17))
                                .foregroundColor(.omniTextSecondary)
                        }
                    }
                    
                    // Why create account section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Create your account to:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            AccountBenefit(icon: "icloud", text: "Save your progress across devices")
                            AccountBenefit(icon: "clock.arrow.circlepath", text: "Access your chat history anytime")
                            AccountBenefit(icon: "person.crop.circle.badge.checkmark", text: "Personalized AI that learns from you")
                            AccountBenefit(icon: "lock.shield", text: "Secure backup of your data")
                        }
                    }
                    .padding(24)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    // Sign in options
                    VStack(spacing: 16) {
                        // Apple Sign In
                        SignInWithAppleButton(
                            onRequest: { request in
                                request.requestedScopes = [.fullName, .email]
                            },
                            onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                        )
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 56)
                        .cornerRadius(28)
                        .disabled(isLoading)
                        
                        // Email sign in - changed to go to LoginView
                        Button(action: {
                            showEmailLogin = true
                        }) {
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
                        .disabled(isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
                
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationDestination(isPresented: $showEmailLogin) {
                LoginView()
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        
        Task {
            do {
                try await authManager.handleAppleSignInResult(result)
                
                // Save setup preferences if they exist
                if let goal = UserDefaults.standard.string(forKey: "tempSelectedGoal") {
                    await authManager.updateUserPreferences(goal: goal)
                }
                
                await MainActor.run {
                    isLoading = false
                    // Navigation will be handled by ContentView
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Sign in failed. Please try again."
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Account Benefit Row
private struct AccountBenefit: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.omniSecondary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.omniTextPrimary)
            
            Spacer()
        }
    }
}

#Preview {
    PostTrialSignInView()
        .environmentObject(AuthenticationManager())
        .environmentObject(PremiumManager())
}