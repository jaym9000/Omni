import SwiftUI

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var logoOffset: CGFloat = 20
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Therapeutic gradient background
            LinearGradient(
                colors: [
                    Color.omniBackground,
                    Color.omniCardLavender,
                    Color.omniPrimary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // Therapeutic illustration-inspired design
                ZStack {
                    // Background elements (leaves/nature)
                    ForEach(0..<6, id: \.self) { index in
                        Image(systemName: "leaf.fill")
                            .font(.system(size: CGFloat(20 + index * 4)))
                            .foregroundColor(.omniPrimary.opacity(0.2))
                            .rotationEffect(.degrees(Double(index * 60)))
                            .offset(
                                x: CGFloat(cos(Double(index) * .pi / 3) * 60),
                                y: CGFloat(sin(Double(index) * .pi / 3) * 60)
                            )
                            .scaleEffect(scale * 0.8)
                    }
                    
                    // Central peaceful figure representation
                    ZStack {
                        // Head/body silhouette
                        Circle()
                            .fill(Color.omniPrimary.opacity(0.8))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                        
                        // Peaceful expression
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 8, height: 8)
                            }
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .frame(width: 16, height: 3)
                        }
                    }
                    .scaleEffect(scale)
                    .offset(y: logoOffset)
                }
                .opacity(opacity)
                
                VStack(spacing: 16) {
                    Text("Omni AI")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.omniTextPrimary)
                        .opacity(textOpacity)
                    
                    VStack(spacing: 4) {
                        Text("Therapeutic Support")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.omniPrimary)
                        
                        Text("Your safe space for mental wellness")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                    }
                    .opacity(textOpacity)
                    .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                scale = 1.0
                opacity = 1.0
                logoOffset = 0
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.8)) {
                textOpacity = 1.0
            }
        }
    }
}

#Preview {
    SplashView()
}