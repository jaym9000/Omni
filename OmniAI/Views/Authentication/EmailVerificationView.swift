import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isChecking = false
    @State private var showResendSuccess = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: "envelope.badge.shield.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.omniPrimary, Color.omniSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Title
            Text("Verify Your Email")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.omniTextPrimary)
            
            // Description
            VStack(spacing: 12) {
                Text("We've sent a verification email to:")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.omniTextPrimary)
                
                Text("Please check your inbox and click the verification link to continue.")
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Actions
            VStack(spacing: 16) {
                Button(action: checkVerification) {
                    if isChecking {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("I've Verified My Email")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
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
                .disabled(isChecking)
                .padding(.horizontal, 24)
                
                Button(action: resendEmail) {
                    Text("Resend Verification Email")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.omniPrimary)
                }
                .padding(.horizontal, 24)
                
                Button(action: signOut) {
                    Text("Sign Out")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.omniTextTertiary)
                }
                .padding(.horizontal, 24)
            }
            
            Spacer()
            Spacer()
        }
        .alert("Email Sent", isPresented: $showResendSuccess) {
            Button("OK") { }
        } message: {
            Text("A new verification email has been sent to your inbox.")
        }
    }
    
    private func checkVerification() {
        isChecking = true
        Task {
            do {
                try await authManager.checkEmailVerification()
            } catch {
                // Handle error
            }
            isChecking = false
        }
    }
    
    private func resendEmail() {
        Task {
            do {
                try await authManager.sendVerificationEmail()
                showResendSuccess = true
            } catch {
                // Handle error
            }
        }
    }
    
    private func signOut() {
        authManager.signOut()
    }
}

#Preview {
    EmailVerificationView()
        .environmentObject(AuthenticationManager())
}