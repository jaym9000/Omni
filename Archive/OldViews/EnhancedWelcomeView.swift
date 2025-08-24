import SwiftUI

struct EnhancedWelcomeView: View {
    @State private var currentPage = 0
    @State private var isAnimating = false
    @State private var showGuestPreview = false
    @State private var showAuthentication = false
    @Binding var showSignUp: Bool
    @Binding var showLogin: Bool
    
    let valuePropositions = [
        ValueProposition(
            title: "Your AI Wellness Companion",
            subtitle: "Get personalized support 24/7",
            description: "Talk to Omni anytime about your feelings, stress, or mental health concerns. No appointments needed.",
            imageName: "brain.head.profile",
            color: .omniPrimary,
            benefits: ["24/7 availability", "Evidence-based responses", "Complete privacy"]
        ),
        ValueProposition(
            title: "Track Your Journey",
            subtitle: "See your progress over time",
            description: "Monitor your mood patterns and celebrate your mental health wins with visual progress tracking.",
            imageName: "chart.line.uptrend.xyaxis",
            color: .moodHappy,
            benefits: ["Mood insights", "Progress visualization", "Pattern recognition"]
        ),
        ValueProposition(
            title: "Safe & Private",
            subtitle: "Your conversations stay secure",
            description: "All conversations are encrypted and private. We never share your personal information.",
            imageName: "lock.shield",
            color: .omniSecondary,
            benefits: ["End-to-end encryption", "No data sharing", "HIPAA compliant"]
        )
    ]
    
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
                // Value proposition carousel
                TabView(selection: $currentPage) {
                    ForEach(0..<valuePropositions.count, id: \.self) { index in
                        ValuePropositionView(proposition: valuePropositions[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<valuePropositions.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.omniPrimary : Color.omniPrimary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 20)
                
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
                        TrustBadge(icon: "lock.shield", text: "HIPAA Compliant")
                        TrustBadge(icon: "checkmark.shield", text: "Evidence-Based")
                        TrustBadge(icon: "heart.circle", text: "Therapist Approved")
                    }
                }
                .padding(.top, 16)
                
                // Action buttons
                VStack(spacing: 16) {
                    // Primary CTA - Try it free with animation
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.1)) {
                            // Micro-interaction feedback
                        }
                        showGuestPreview = true 
                    }) {
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
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: showGuestPreview)
                    
                    // Secondary CTA - Sign up for full access
                    Button(action: { showAuthentication = true }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 16))
                            Text("Create Account for Full Access")
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
                    
                    // Tertiary - Sign in link
                    Button(action: { showLogin = true }) {
                        Text("Already have an account? Sign in")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimating = true
            startAutoCarousel()
        }
        .fullScreenCover(isPresented: $showGuestPreview) {
            GuestPreviewView(showSignUp: $showSignUp)
        }
        .sheet(isPresented: $showAuthentication) {
            AuthenticationChoiceView(showSignUp: $showSignUp, showLogin: $showLogin)
        }
    }
    
    private func startAutoCarousel() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPage = (currentPage + 1) % valuePropositions.count
            }
        }
    }
}

// MARK: - Value Proposition Model
struct ValueProposition {
    let title: String
    let subtitle: String
    let description: String
    let imageName: String
    let color: Color
    let benefits: [String]
}

// MARK: - Value Proposition View
struct ValuePropositionView: View {
    let proposition: ValueProposition
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with animation
            Image(systemName: proposition.imageName)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [proposition.color, proposition.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isAnimating ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
            
            VStack(spacing: 16) {
                // Title and subtitle
                VStack(spacing: 8) {
                    Text(proposition.title)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.omniTextPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(proposition.subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(proposition.color)
                        .multilineTextAlignment(.center)
                }
                
                // Description
                Text(proposition.description)
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Benefits
                VStack(spacing: 8) {
                    ForEach(proposition.benefits, id: \.self) { benefit in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(proposition.color)
                                .font(.system(size: 14))
                            Text(benefit)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.omniTextSecondary)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
            }
            
            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Authentication Choice View
struct AuthenticationChoiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var showSignUp: Bool
    @Binding var showLogin: Bool
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("Join Omni")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("Create your account to save progress and sync across devices")
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                VStack(spacing: 16) {
                    // Apple Sign In
                    Button(action: { 
                        Task { 
                            try await authManager.signInWithApple()
                            dismiss()
                        }
                    }) {
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
                    
                    // Email Sign Up
                    Button(action: { 
                        showSignUp = true
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.system(size: 16))
                            Text("Sign up with Email")
                                .font(.system(size: 16, weight: .medium))
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
                    }
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.omniTextTertiary)
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                        Rectangle()
                            .fill(Color.omniTextTertiary)
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)
                    
                    // Sign In
                    Button(action: { 
                        showLogin = true
                        dismiss()
                    }) {
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
                }
                .padding(.horizontal, 24)
                
                // Privacy note
                Text("By continuing, you agree to our Terms of Service and Privacy Policy. Your mental health data is encrypted and private.")
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
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
    EnhancedWelcomeView(showSignUp: .constant(false), showLogin: .constant(false))
        .environmentObject(AuthenticationManager())
}