import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var imageScale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @Environment(\.colorScheme) var colorScheme
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background that adapts to light/dark mode
            Color.omniBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo with circular background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.omniPrimary.opacity(colorScheme == .dark ? 0.15 : 0.1),
                                    Color.omniSecondary.opacity(colorScheme == .dark ? 0.08 : 0.05)
                                ],
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
                        .shadow(
                            color: Color.omniPrimary.opacity(colorScheme == .dark ? 0.3 : 0.2),
                            radius: 20,
                            x: 0,
                            y: 10
                        )
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
                    .foregroundColor(Color.omniTextSecondary)
                    .opacity(opacity * 0.9)
            }
            .scaleEffect(imageScale)
            .opacity(opacity)
        }
        .onAppear {
            // Let users take in the splash screen for longer (1.5 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                // Slower, smoother fade out animation (1.2 seconds)
                withAnimation(.easeInOut(duration: 1.2)) {
                    imageScale = 1.05  // Subtle scale instead of 1.1
                    opacity = 0
                }
                
                // Complete after animation finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    SplashScreenView(onComplete: {})
}