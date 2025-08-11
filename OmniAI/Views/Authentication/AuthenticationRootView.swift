import SwiftUI

struct AuthenticationRootView: View {
    @State private var showLogin = false
    @State private var showSignUp = false
    
    var body: some View {
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

#Preview {
    AuthenticationRootView()
        .environmentObject(AuthenticationManager())
}