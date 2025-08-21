import SwiftUI

struct MoodReflectionSheet: View {
    let mood: MoodType
    let onTalkToOmni: () -> Void
    let onJournal: () -> Void
    let onDismiss: () -> Void
    
    @State private var animationScale: CGFloat = 0.8
    @State private var animationOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // Success Animation
            ZStack {
                Circle()
                    .fill(mood.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animationScale * 1.2)
                
                Circle()
                    .fill(mood.color.opacity(0.25))
                    .frame(width: 90, height: 90)
                    .scaleEffect(animationScale * 1.1)
                
                Text(mood.emoji)
                    .font(.system(size: 50))
                    .scaleEffect(animationScale)
            }
            .opacity(animationOpacity)
            .padding(.top, 20)
            
            // Success Message
            VStack(spacing: 8) {
                Text("Mood Tracked!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.omniTextPrimary)
                
                Text("You're feeling \(mood.label.lowercased())")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
            }
            .opacity(animationOpacity)
            
            // Reflection Prompt
            VStack(spacing: 4) {
                Text("Would you like to explore this feeling?")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.omniTextPrimary)
                
                Text("Talking or journaling can help you understand your emotions better")
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .opacity(animationOpacity)
            .padding(.top, 8)
            
            // Action Buttons
            VStack(spacing: 12) {
                // Primary CTA - Talk to Omni
                Button(action: onTalkToOmni) {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 18))
                        Text("Talk to Omni About It")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        LinearGradient(
                            colors: [mood.color, mood.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(26)
                }
                .scaleEffect(animationOpacity > 0 ? 1.0 : 0.95)
                
                // Secondary CTA - Journal
                Button(action: onJournal) {
                    HStack {
                        Image(systemName: "book.fill")
                            .font(.system(size: 16))
                        Text("Write in Journal")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(mood.color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 26)
                            .stroke(mood.color.opacity(0.3), lineWidth: 2)
                            .background(
                                mood.color.opacity(0.05)
                                    .cornerRadius(26)
                            )
                    )
                }
                .scaleEffect(animationOpacity > 0 ? 1.0 : 0.95)
                
                // Skip Button
                Button(action: onDismiss) {
                    Text("Maybe Later")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.omniTextTertiary)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
            .opacity(animationOpacity)
        }
        .padding(.vertical, 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                animationScale = 1.0
                animationOpacity = 1.0
            }
        }
    }
}

#Preview {
    MoodReflectionSheet(
        mood: .happy,
        onTalkToOmni: {},
        onJournal: {},
        onDismiss: {}
    )
}