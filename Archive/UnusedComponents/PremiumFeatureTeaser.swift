import SwiftUI
import RevenueCatUI

struct PremiumFeatureTeaser: View {
    let featureName: String
    let featureDescription: String
    let iconName: String
    @Binding var showPaywall: Bool
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Close button
            HStack {
                Spacer()
                Button(action: { showPaywall = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.omniTextTertiary)
                }
                .padding()
            }
            
            Spacer()
            
            // Locked Feature Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.omniPrimary.opacity(0.2), Color.omniSecondary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [Color.omniPrimary, Color.omniSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                VStack(spacing: 8) {
                    Image(systemName: iconName)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.omniPrimary, Color.omniSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextSecondary)
                }
            }
            
            // Feature Info
            VStack(spacing: 12) {
                Text("\(featureName) is Premium")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.omniTextPrimary)
                
                Text(featureDescription)
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            // Premium Benefits Preview
            VStack(alignment: .leading, spacing: 16) {
                Text("Unlock with Premium")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.omniTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                VStack(alignment: .leading, spacing: 12) {
                    FeatureBenefitRow(icon: "infinity", text: "Unlimited messages")
                    FeatureBenefitRow(icon: "clock.arrow.circlepath", text: "Full chat history access")
                    FeatureBenefitRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced analytics")
                    FeatureBenefitRow(icon: "calendar", text: "Journal & mood calendar")
                    FeatureBenefitRow(icon: "bolt.fill", text: "No delays, priority access")
                }
                .padding(.horizontal, 40)
            }
            .padding(.vertical, 20)
            .background(Color.omniSecondaryBackground)
            .cornerRadius(16)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // CTA Button
            Button(action: { showPaywall = true }) {
                HStack {
                    Text("Unlock Premium")
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: "crown.fill")
                        .font(.system(size: 16))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.omniPrimary, Color.omniSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
            }
            .padding(.horizontal, 20)
            .shadow(color: Color.omniPrimary.opacity(0.3), radius: 8, y: 4)
            
            // Restore button
            Button(action: {
                Task {
                    try? await RevenueCatManager.shared.restorePurchases()
                }
            }) {
                Text("Restore Purchases")
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextSecondary)
            }
            .padding(.bottom, 20)
        }
        .background(Color.omniBackground)
        .onAppear {
            isAnimating = true
        }
    }
}

struct FeatureBenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.omniPrimary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.omniTextPrimary)
            
            Spacer()
        }
    }
}

// Preview wrapper to show how it looks for different features
struct PremiumFeatureTeaserPreview: View {
    @State private var showPaywall = false
    
    var body: some View {
        PremiumFeatureTeaser(
            featureName: "Chat History",
            featureDescription: "Access all your past conversations and insights from your chat history",
            iconName: "clock.arrow.circlepath",
            showPaywall: $showPaywall
        )
    }
}

#Preview {
    PremiumFeatureTeaserPreview()
}