import SwiftUI

struct QuickSetupView: View {
    @State private var currentStep = 0
    @State private var selectedGoal: String? = nil
    @State private var selectedMood: Int? = nil
    let onComplete: (String?, Int?) -> Void
    let onSkip: () -> Void
    
    let goals = [
        ("Anxiety", "😰"),
        ("Depression", "😔"),
        ("Stress", "😤"),
        ("Sleep", "😴"),
        ("Relationships", "💔"),
        ("Self-esteem", "🪞"),
        ("Grief", "😢"),
        ("Just exploring", "🔍")
    ]
    
    let moods = [
        ("Terrible", "😢"),
        ("Bad", "😟"),
        ("Okay", "😐"),
        ("Good", "🙂"),
        ("Great", "😊")
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.omniPrimary.opacity(0.05), Color.omniSecondary.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Skip button - respects safe area
                    HStack {
                        Spacer()
                        Button("Skip") {
                            onSkip()
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.omniTextSecondary)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .padding(.top, geometry.safeAreaInsets.top)
                    
                    // Scrollable content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 30) {
                        if currentStep == 0 {
                            // Step 1: What brings you here?
                            VStack(spacing: 30) {
                                VStack(spacing: 12) {
                                    Text("What brings you here?")
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(.omniTextPrimary)
                                    
                                    Text("Select what you'd like help with")
                                        .font(.system(size: 16))
                                        .foregroundColor(.omniTextSecondary)
                                }
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.top, 20)
                                
                                // Goals grid
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(goals, id: \.0) { goal in
                                        GoalButton(
                                            title: goal.0,
                                            emoji: goal.1,
                                            isSelected: selectedGoal == goal.0,
                                            action: {
                                                selectedGoal = goal.0
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    currentStep = 1
                                                }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal, 24)
                                .padding(.bottom, 40)
                            }
                        } else {
                            // Step 2: How are you feeling?
                            VStack(spacing: 30) {
                                VStack(spacing: 12) {
                                    Text("How are you feeling right now?")
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundColor(.omniTextPrimary)
                                    
                                    Text("This helps me provide better support")
                                        .font(.system(size: 16))
                                        .foregroundColor(.omniTextSecondary)
                                }
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.top, 40)
                                
                                // Mood selector - adaptive layout
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(Array(moods.enumerated()), id: \.offset) { index, mood in
                                            SetupMoodButton(
                                                emoji: mood.1,
                                                label: mood.0,
                                                isSelected: selectedMood == index,
                                                action: {
                                                    selectedMood = index
                                                    // Short delay then complete
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                        onComplete(selectedGoal, selectedMood)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                                .padding(.bottom, 50)
                            }
                        }
                    }
                    .frame(minHeight: geometry.size.height - 100)
                }
            }
        }
        }
    }
}

// MARK: - Goal Button
private struct GoalButton: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text(emoji)
                    .font(.system(size: 40))
                
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .white : .omniTextPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(isSelected ? Color.omniPrimary : Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.clear : Color.omniPrimary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Mood Button
private struct SetupMoodButton: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(emoji)
                    .font(.system(size: 38))
                
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .omniPrimary : .omniTextSecondary)
            }
            .frame(width: 60, height: 80)
            .background(isSelected ? Color.omniPrimary.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.omniPrimary : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    QuickSetupView(
        onComplete: { goal, mood in
            print("Goal: \(goal ?? "none"), Mood: \(mood ?? -1)")
        },
        onSkip: {
            print("Skipped")
        }
    )
}