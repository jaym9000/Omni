import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var agreedToTerms = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showLogin = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var isFormValid: Bool {
        !displayName.isEmpty && 
        !email.isEmpty && 
        !password.isEmpty && 
        password == confirmPassword && 
        password.count >= 6 &&
        agreedToTerms
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.omniPrimary, Color.omniSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("Start your mental wellness journey")
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextSecondary)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 16) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                        
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.omniTextTertiary)
                            
                            TextField("Enter your name", text: $displayName)
                                .textContentType(.name)
                                .focused($focusedField, equals: .name)
                        }
                        .padding()
                        .background(Color.omniSecondaryBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .name ? Color.omniPrimary : Color.clear, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .name
                        }
                    }
                    
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                        
                        HStack {
                            Image(systemName: "envelope")
                                .foregroundColor(.omniTextTertiary)
                            
                            TextField("Enter your email", text: $email)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .focused($focusedField, equals: .email)
                        }
                        .padding()
                        .background(Color.omniSecondaryBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .email ? Color.omniPrimary : Color.clear, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .email
                        }
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.omniTextTertiary)
                            
                            if showPassword {
                                TextField("Min 6 characters", text: $password)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .password)
                            } else {
                                SecureField("Min 6 characters", text: $password)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(.omniTextTertiary)
                            }
                        }
                        .padding()
                        .background(Color.omniSecondaryBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .password ? Color.omniPrimary : Color.clear, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .password
                        }
                    }
                    
                    // Confirm Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confirm Password")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                        
                        HStack {
                            Image(systemName: "lock")
                                .foregroundColor(.omniTextTertiary)
                            
                            if showPassword {
                                TextField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .confirmPassword)
                            } else {
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .confirmPassword)
                            }
                            
                            if !confirmPassword.isEmpty {
                                Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(password == confirmPassword ? .omniSuccess : .omniError)
                            }
                        }
                        .padding()
                        .background(Color.omniSecondaryBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedField == .confirmPassword ? Color.omniPrimary : Color.clear, lineWidth: 2)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            focusedField = .confirmPassword
                        }
                    }
                    
                    // Terms and conditions
                    HStack {
                        Button(action: { agreedToTerms.toggle() }) {
                            Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                .foregroundColor(agreedToTerms ? .omniPrimary : .omniTextTertiary)
                                .font(.system(size: 20))
                        }
                        
                        HStack(spacing: 4) {
                            Text("I agree to the")
                                .font(.system(size: 14))
                                .foregroundColor(.omniTextSecondary)
                            
                            Button(action: { showTermsOfService = true }) {
                                Text("Terms & Conditions")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.omniPrimary)
                                    .underline()
                            }
                            
                            Text("and")
                                .font(.system(size: 14))
                                .foregroundColor(.omniTextSecondary)
                            
                            Button(action: { showPrivacyPolicy = true }) {
                                Text("Privacy Policy")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.omniPrimary)
                                    .underline()
                            }
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 24)
                
                // Sign up button
                Button(action: signUp) {
                    if authManager.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
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
                .disabled(!isFormValid || authManager.isLoading)
                .opacity(!isFormValid ? 0.6 : 1.0)
                .padding(.horizontal, 24)
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color.omniTextTertiary.opacity(0.3))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.omniTextTertiary)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color.omniTextTertiary.opacity(0.3))
                        .frame(height: 1)
                }
                .padding(.horizontal, 24)
                
                // Apple Sign In
                Button(action: signUpWithApple) {
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
                .padding(.horizontal, 24)
                
                // Sign in link for existing users
                Button(action: { showLogin = true }) {
                    Text("Already have an account? Sign in")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.omniTextSecondary)
                }
                .padding(.top, 16)
                
                Spacer(minLength: 50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.omniTextPrimary)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .navigationDestination(isPresented: $showLogin) {
            LoginView()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariView(url: URL(string: "http://omnitherapy.co/privacy.html")!)
        }
        .sheet(isPresented: $showTermsOfService) {
            SafariView(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        }
    }
    
    private func signUp() {
        Task {
            do {
                try await authManager.signUp(email: email, password: password, displayName: displayName)
            } catch {
                // Provide more user-friendly error messages
                if let authError = error as? AuthError {
                    errorMessage = authError.errorDescription ?? "Sign up failed"
                } else {
                    errorMessage = "Unable to create account. Please check your internet connection and try again."
                }
                showError = true
            }
        }
    }
    
    private func signUpWithApple() {
        Task {
            do {
                try await authManager.signInWithApple()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
            .environmentObject(AuthenticationManager())
    }
}