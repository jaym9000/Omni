import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var companionName = "Omni"
    @State private var selectedGoals: Set<String> = []
    @State private var selectedPersonality = "supportive"
    
    let pages = [
        OnboardingPage(
            title: "Welcome to Your Safe Space",
            description: "Omni is here to support you on your mental health journey with compassion and understanding.",
            imageName: "heart.circle.fill",
            color: .omniprimary
        ),
        OnboardingPage(
            title: "Track Your Mood",
            description: "Log your emotions daily and discover patterns in your mental health journey.",
            imageName: "face.smiling.fill",
            color: .moodHappy
        ),
        OnboardingPage(
            title: "Journal Your Thoughts",
            description: "Express yourself freely through guided prompts or free-form journaling.",
            imageName: "book.fill",
            color: .omnisecondary
        )
    ]
    
    let goals = [
        "Manage Anxiety",
        "Improve Mood",
        "Better Sleep",
        "Stress Relief",
        "Self-Discovery",
        "Build Resilience"
    ]
    
    let personalities = [
        ("supportive", "Supportive", "Warm and encouraging"),
        ("analytical", "Analytical", "Logical and structured"),
        ("motivational", "Motivational", "Energetic and inspiring"),
        ("gentle", "Gentle", "Soft and nurturing")
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.omniprimary.opacity(0.1), Color.omnisecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(0..<5) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index <= currentPage ? Color.omniprimary : Color.omniprimary.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top)
                
                // Content
                TabView(selection: $currentPage) {
                    // Page 0-2: Introduction pages
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                    
                    // Page 3: Customize companion
                    CustomizeCompanionView(
                        companionName: $companionName,
                        selectedPersonality: $selectedPersonality,
                        personalities: personalities
                    )
                    .tag(3)
                    
                    // Page 4: Select goals
                    SelectGoalsView(
                        selectedGoals: $selectedGoals,
                        goals: goals
                    )
                    .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button("Back") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.omniprimary)
                    }
                    
                    Spacer()
                    
                    Button(action: nextAction) {
                        Text(currentPage == 4 ? "Get Started" : "Next")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color.omniprimary, Color.omnisecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func nextAction() {
        if currentPage < 4 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func completeOnboarding() {
        // Save onboarding data
        if var user = authManager.currentUser {
            user.companionName = companionName
            user.companionPersonality = selectedPersonality
            authManager.currentUser = user
            
            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }
        
        // Save selected goals
        UserDefaults.standard.set(Array(selectedGoals), forKey: "userGoals")
        
        // Mark onboarding as completed
        hasCompletedOnboarding = true
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let color: Color
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [page.color, page.color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 20) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 18))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Customize Companion View
struct CustomizeCompanionView: View {
    @Binding var companionName: String
    @Binding var selectedPersonality: String
    let personalities: [(String, String, String)]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Customize Your Companion")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.omniTextPrimary)
                .multilineTextAlignment(.center)
            
            // Name input
            VStack(alignment: .leading, spacing: 12) {
                Text("Companion Name")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.omniTextSecondary)
                
                TextField("Enter a name", text: $companionName)
                    .font(.system(size: 18))
                    .padding()
                    .background(Color.omniSecondaryBackground)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            // Personality selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Choose Personality")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.omniTextSecondary)
                    .padding(.horizontal, 40)
                
                VStack(spacing: 12) {
                    ForEach(personalities, id: \.0) { personality in
                        PersonalityOption(
                            id: personality.0,
                            title: personality.1,
                            description: personality.2,
                            isSelected: selectedPersonality == personality.0,
                            action: { selectedPersonality = personality.0 }
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Personality Option
struct PersonalityOption: View {
    let id: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .omniprimary : .omniTextTertiary)
            }
            .padding()
            .background(isSelected ? Color.omniprimary.opacity(0.1) : Color.omniSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.omniprimary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Select Goals View
struct SelectGoalsView: View {
    @Binding var selectedGoals: Set<String>
    let goals: [String]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("What brings you here?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Select all that apply")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
            }
            
            // Goals grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(goals, id: \.self) { goal in
                    GoalOption(
                        title: goal,
                        isSelected: selectedGoals.contains(goal),
                        action: {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Goal Option
struct GoalOption: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .omniTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.omniprimary : Color.omniSecondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.clear : Color.omniprimary.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthenticationManager())
}