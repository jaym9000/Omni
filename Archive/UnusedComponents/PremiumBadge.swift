import SwiftUI

struct PremiumBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.yellow)
            
            Text("PRO")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.3),
                    Color.orange.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.5),
                            Color.orange.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .cornerRadius(4)
    }
}

// Larger variant for feature gates
struct PremiumFeatureBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.yellow)
            
            Text("PREMIUM")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: [
                    Color.yellow.opacity(0.25),
                    Color.orange.opacity(0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.yellow.opacity(0.6),
                            Color.orange.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .cornerRadius(6)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Small badge for inline use
        HStack {
            Text("Feature Name")
            PremiumBadge()
        }
        
        // Larger badge for feature gates
        PremiumFeatureBadge()
        
        // In a button
        Button(action: {}) {
            HStack {
                Image(systemName: "pencil")
                Text("Journal Entry")
                Spacer()
                PremiumBadge()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    .padding()
}