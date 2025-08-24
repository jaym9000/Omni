import SwiftUI
import RevenueCatUI

struct MoodBottomSheet: View {
    let selectedMood: MoodType?
    let onClose: () -> Void
    let onTalkToOmni: (String) -> Void
    let onJournal: (MoodType?) -> Void
    
    @State private var emojiScale: CGFloat = 0.5
    @State private var emojiOpacity: Double = 0
    @State private var emojiRotation: Double = -15
    @State private var buttonsOffset: CGFloat = 30
    @State private var buttonsOpacity: Double = 0
    @State private var showPaywall = false
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Safe area spacer for proper spacing
            Spacer()
                .frame(height: 16)
            // Header with close button
            HStack {
                Text("Let's explore this feeling")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.omniTextPrimary)
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.omniTextTertiary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            
            // Mood display with bounce animation
            if let mood = selectedMood {
                VStack(spacing: 12) {
                    Text(mood.emoji)
                        .font(.system(size: 60))
                        .scaleEffect(emojiScale)
                        .opacity(emojiOpacity)
                        .rotationEffect(.degrees(emojiRotation))
                    
                    Text(mood.label)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.omniTextPrimary)
                        .opacity(emojiOpacity)
                }
            }
            
            // Action buttons with slide-up animation
            VStack(spacing: 12) {
                // Talk to Omni Button
                Button(action: { 
                    onTalkToOmni(generateMoodPrompt())
                    onClose()
                }) {
                    HStack {
                        Image(systemName: "message")
                            .font(.system(size: 16))
                        Text("Talk to Omni")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.omniPrimary)
                    .cornerRadius(12)
                }
                .buttonStyle(TherapeuticPressStyle())
                .scaleEffect(buttonsOpacity > 0 ? 1.0 : 0.95)
                
                // Journal Button - Now Premium Only
                Button(action: { 
                    // All journaling is now premium
                    if authManager.currentUser?.isPremium == true {
                        onJournal(selectedMood)
                        onClose()
                    } else {
                        showPaywall = true
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 16))
                        Text("Journal about it")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.omniPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.omniPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(SoftPressStyle())
                .scaleEffect(buttonsOpacity > 0 ? 1.0 : 0.95)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .offset(y: buttonsOffset)
            .opacity(buttonsOpacity)
        }
        .background(
            Color(UIColor.systemBackground)
                .clipShape(
                    RoundedRectangle(cornerRadius: 16)
                )
        )
        .onAppear {
            animateEntrance()
        }
        .sheet(isPresented: $showPaywall) {
            Group {
                if let offering = RevenueCatManager.shared.currentOffering {
                    RevenueCatUI.PaywallView(offering: offering)
                } else {
                    RevenueCatUI.PaywallView()
                }
            }
            .onPurchaseCompleted { _ in
                showPaywall = false
                Task {
                    await RevenueCatManager.shared.checkSubscriptionStatus()
                }
            }
            .onRestoreCompleted { _ in
                if RevenueCatManager.shared.isPremium {
                    showPaywall = false
                }
            }
            .task {
                if RevenueCatManager.shared.offerings == nil {
                    await RevenueCatManager.shared.fetchOfferings()
                }
            }
        }
    }
    
    private func animateEntrance() {
        // Emoji bounce animation
        withAnimation(
            .spring(response: 0.4, dampingFraction: 0.6)
        ) {
            emojiScale = 1.0
            emojiOpacity = 1.0
            emojiRotation = 0
        }
        
        // Slight overshoot for extra bounce
        withAnimation(
            .spring(response: 0.3, dampingFraction: 0.5)
            .delay(0.1)
        ) {
            emojiScale = 1.05
        }
        
        withAnimation(
            .spring(response: 0.3, dampingFraction: 0.7)
            .delay(0.2)
        ) {
            emojiScale = 1.0
        }
        
        // Buttons slide up
        withAnimation(
            .spring(response: 0.5, dampingFraction: 0.8)
            .delay(0.2)
        ) {
            buttonsOffset = 0
            buttonsOpacity = 1.0
        }
    }
    
    private func generateMoodPrompt() -> String {
        guard let mood = selectedMood else { return "" }
        
        switch mood {
        case .happy:
            return "I see you're feeling happy today! That's wonderful. What's been the highlight of your day so far? I'd love to hear what's bringing you this joy."
        case .anxious:
            return "I notice you're feeling anxious right now. I'm here to support you through this. What's on your mind that's making you feel this way? We can work through it together."
        case .sad:
            return "I can see you're feeling sad today. I'm here to listen and support you. Would you like to share what's been weighing on your heart? Sometimes talking about it can help."
        case .overwhelmed:
            return "I see you're feeling overwhelmed right now. That can be really tough to handle. Let's take this one step at a time. What's making you feel like there's too much going on?"
        case .calm:
            return "I notice you're feeling calm and peaceful today. That's beautiful. What's been helping you feel this way? I'd love to hear about what's going well for you."
        }
    }
}

#Preview {
    MoodBottomSheet(
        selectedMood: .happy, 
        onClose: {},
        onTalkToOmni: { _ in },
        onJournal: { _ in }
    )
    .environmentObject(PremiumManager())
}