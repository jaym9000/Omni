import SwiftUI

struct SimpleWelcomeView: View {
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    let onGetStarted: () -> Void
    
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
                        Text("Your AI therapist,\navailable 24/7")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.omniTextPrimary)
                            .multilineTextAlignment(.center)
                        
                        Text("Get personalized mental health support instantly. No appointments, no waiting.")
                            .font(.system(size: 17))
                            .foregroundColor(.omniTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                }
                
                // Trust signals
                VStack(spacing: 20) {
                    // Trust badges
                    HStack(spacing: 20) {
                        SimpleTrustBadge(icon: "lock.shield", text: "100% Private")
                        SimpleTrustBadge(icon: "checkmark.shield", text: "Evidence-Based")
                        SimpleTrustBadge(icon: "heart.circle", text: "Always Available")
                    }
                }
                .padding(.top, 30)
                
                Spacer()
                
                // Single CTA button
                Button(action: {
                    // Analytics will be tracked in ContentView
                    onGetStarted()
                }) {
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
                        .shadow(color: Color.omniPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                // Privacy Policy Notice
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextTertiary)
                    
                    HStack(spacing: 4) {
                        Button(action: {
                            // Open privacy policy
                            if let url = URL(string: "https://omniapp.com/privacy") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Privacy Policy")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.omniPrimary)
                                .underline()
                        }
                        
                        Text("and")
                            .font(.system(size: 12))
                            .foregroundColor(.omniTextTertiary)
                        
                        Button(action: {
                            // Open terms
                            if let url = URL(string: "https://omniapp.com/terms") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Text("Terms of Service")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.omniPrimary)
                                .underline()
                        }
                    }
                    
                    Text("Your data is encrypted and protected")
                        .font(.system(size: 11))
                        .foregroundColor(.omniTextTertiary.opacity(0.8))
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            isAnimating = true
            // Analytics will be tracked in ContentView
        }
    }
}

// MARK: - Trust Badge Component
private struct SimpleTrustBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.omniSecondary)
            
            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.omniTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SimpleWelcomeView(onGetStarted: {})
}