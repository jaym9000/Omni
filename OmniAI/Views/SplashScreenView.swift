import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var imageScale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background matching launch screen
            Color(red: 250/255, green: 249/255, blue: 247/255)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo with circular background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.omniPrimary.opacity(0.1), Color.omniSecondary.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 380, height: 380)
                        .blur(radius: 20)
                        .scaleEffect(imageScale * 1.1)
                    
                    Image("LaunchScreenImage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 350, height: 350)
                        .clipShape(Circle())
                        .shadow(color: Color.omniPrimary.opacity(0.2), radius: 20, x: 0, y: 10)
                        .scaleEffect(imageScale)
                }
                .offset(y: -25)
                
                // Title
                Text("Omni")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Color.omniPrimary)
                    .scaleEffect(imageScale)
                
                // Tagline
                Text("Your AI Mental Health Companion")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.67))
                    .opacity(opacity * 0.8)
            }
            .scaleEffect(imageScale)
            .opacity(opacity)
        }
        .onAppear {
            // Start animation after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.8)) {
                    imageScale = 1.1
                    opacity = 0
                }
                
                // Complete after animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(onComplete: {})
}