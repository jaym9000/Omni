import SwiftUI

struct AIPreviewView: View {
    let selectedGoal: String?
    let selectedMood: Int?
    let onShowPaywall: () -> Void
    
    @State private var messageOpacity: Double = 0
    @State private var planOpacity: Double = 0
    @State private var isTyping = true
    @State private var showContinueButton = false
    
    var personalizedMessage: String {
        let moodText = getMoodText()
        
        if let goal = selectedGoal, goal != "Just exploring" {
            return "I understand you're dealing with \(goal.lowercased())\(moodText). I'm here to support you through this. Together, we can work on evidence-based strategies that thousands of people have used to feel better."
        } else {
            return "I'm here to support your mental wellness journey\(moodText). Let me create a personalized plan to help you feel better, using proven techniques that have helped thousands of people."
        }
    }
    
    var weeklyPlan: [String] {
        if let goal = selectedGoal {
            switch goal {
            case "Anxiety":
                return [
                    "Day 1-2: Learn grounding techniques for immediate relief",
                    "Day 3-4: Practice cognitive reframing exercises",
                    "Day 5-6: Build your personalized anxiety toolkit",
                    "Day 7: Create your long-term anxiety management plan"
                ]
            case "Depression":
                return [
                    "Day 1-2: Establish mood-boosting morning routines",
                    "Day 3-4: Learn thought-challenging techniques",
                    "Day 5-6: Build behavioral activation strategies",
                    "Day 7: Design your personal wellness plan"
                ]
            case "Stress":
                return [
                    "Day 1-2: Master quick stress-relief techniques",
                    "Day 3-4: Develop healthy boundaries",
                    "Day 5-6: Create work-life balance strategies",
                    "Day 7: Build your stress-resilience toolkit"
                ]
            case "Sleep":
                return [
                    "Day 1-2: Optimize your sleep environment",
                    "Day 3-4: Establish calming bedtime routines",
                    "Day 5-6: Learn sleep anxiety management",
                    "Day 7: Create your personalized sleep protocol"
                ]
            default:
                return defaultPlan
            }
        }
        return defaultPlan
    }
    
    var defaultPlan: [String] {
        [
            "Day 1-2: Understand your emotional patterns",
            "Day 3-4: Build healthy coping strategies",
            "Day 5-6: Develop mindfulness practices",
            "Day 7: Create your personalized wellness plan"
        ]
    }
    
    private func getMoodText() -> String {
        guard let mood = selectedMood else { return "" }
        switch mood {
        case 0, 1: return " and that you're having a tough time"
        case 2: return " and that things feel challenging right now"
        case 3, 4: return ""
        default: return ""
        }
    }
    
    private func getGoalText() -> String {
        guard let goal = selectedGoal else { return "improve your mental health" }
        switch goal {
        case "Just exploring": return "explore mental wellness strategies"
        default: return "manage your \(goal.lowercased())"
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.omniPrimary.opacity(0.05), Color.omniSecondary.opacity(0.02)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    // AI Avatar and typing indicator
                    HStack(alignment: .top, spacing: 16) {
                        // AI Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.omniPrimary, Color.omniSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "heart.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Omni")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            
                            if isTyping {
                                PreviewTypingIndicator()
                                    .transition(.opacity)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    
                    // Personalized message
                    VStack(alignment: .leading, spacing: 20) {
                        Text(personalizedMessage)
                            .font(.system(size: 17))
                            .foregroundColor(.omniTextPrimary)
                            .lineSpacing(4)
                            .opacity(messageOpacity)
                        
                        // 7-day plan
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Your 7-Day Wellness Plan:")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(weeklyPlan, id: \.self) { item in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.omniSecondary)
                                            .font(.system(size: 16))
                                            .padding(.top, 2)
                                        
                                        Text(item)
                                            .font(.system(size: 15))
                                            .foregroundColor(.omniTextSecondary)
                                            .lineSpacing(2)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .opacity(planOpacity)
                    }
                    .padding(.horizontal, 24)
                    
                    // Continue button
                    if showContinueButton {
                        Button(action: onShowPaywall) {
                            Text("Start Your Free Trial")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
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
                                .shadow(color: Color.omniPrimary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .opacity(showContinueButton ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: showContinueButton)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .onAppear {
            // Simulate typing effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeIn(duration: 0.3)) {
                    isTyping = false
                }
                withAnimation(.easeIn(duration: 0.5)) {
                    messageOpacity = 1.0
                }
            }
            
            // Show plan
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    planOpacity = 1.0
                }
            }
            
            // Show continue button after plan is visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeIn(duration: 0.5)) {
                    showContinueButton = true
                }
            }
        }
    }
}

// MARK: - Typing Indicator
private struct PreviewTypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.omniTextSecondary.opacity(0.6))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount == Double(index) ? 1.3 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .onAppear {
            animationAmount = 2.0
        }
    }
}

#Preview {
    AIPreviewView(
        selectedGoal: "Anxiety",
        selectedMood: 1,
        onShowPaywall: {
            print("Show paywall")
        }
    )
}