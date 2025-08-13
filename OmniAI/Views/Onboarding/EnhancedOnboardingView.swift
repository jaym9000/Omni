import SwiftUI

struct EnhancedOnboardingView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var selectedConcerns: Set<String> = []
    @State private var selectedCopingStyle = ""
    @State private var selectedPreferences: Set<String> = []
    @State private var shareAdditionalInfo = ""
    @State private var canSkipToEnd = false
    
    // Smart defaults based on research
    @State private var defaultConcerns: Set<String> = ["Feeling anxious or overwhelmed", "Stress from school/work"]
    @State private var defaultCopingStyle = "Talk to friends or family"
    @State private var defaultPreferences: Set<String> = ["Advice and ideas – give me tips or things to try"]
    
    let concerns = [
        "Feeling anxious or overwhelmed",
        "Feeling sad or depressed", 
        "Stress from school/work",
        "Problems in relationships",
        "Low self-esteem or confidence",
        "Trouble sleeping",
        "Grieving or loss",
        "Other/Not sure"
    ]
    
    let copingStyles = [
        "Talk to friends or family",
        "Do something to distract myself (games, music, etc.)",
        "Try to solve it on my own (research, self-help)",
        "Nothing specific, I just endure it",
        "Other"
    ]
    
    let preferences = [
        "Just someone to listen – I want to vent and feel heard",
        "Advice and ideas – give me tips or things to try",
        "Activities and exercises – help me practice skills", 
        "Check-ins and motivation – keep me on track",
        "Not sure yet"
    ]
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color.omniPrimary.opacity(0.1), Color.omniSecondary.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Progress indicator with skip option
                HStack {
                    HStack(spacing: 8) {
                        ForEach(0..<6) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(index <= currentPage ? Color.omniPrimary : Color.omniPrimary.opacity(0.3))
                                .frame(height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    if currentPage > 1 && currentPage < 5 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = 5
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.omniTextSecondary)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top)
                
                // Content
                TabView(selection: $currentPage) {
                    // Page 0: Welcome
                    WelcomeOnboardingPage()
                        .tag(0)
                    
                    // Page 1: Name input
                    NameInputPage(userName: $userName)
                        .tag(1)
                    
                    // Page 2: Concerns (with smart defaults)
                    ConcernsPage(
                        selectedConcerns: $selectedConcerns,
                        concerns: concerns,
                        defaultConcerns: defaultConcerns
                    )
                    .tag(2)
                    
                    // Page 3: Coping style
                    CopingStylePage(
                        selectedCopingStyle: $selectedCopingStyle,
                        copingStyles: copingStyles,
                        defaultStyle: defaultCopingStyle
                    )
                    .tag(3)
                    
                    // Page 4: Preferences
                    PreferencesPage(
                        selectedPreferences: $selectedPreferences,
                        preferences: preferences,
                        defaultPreferences: defaultPreferences
                    )
                    .tag(4)
                    
                    // Page 5: Additional info (optional)
                    AdditionalInfoPage(shareAdditionalInfo: $shareAdditionalInfo)
                        .tag(5)
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
                        .foregroundColor(.omniPrimary)
                    }
                    
                    Spacer()
                    
                    Button(action: nextAction) {
                        HStack {
                            Text(nextButtonText)
                                .font(.system(size: 16, weight: .semibold))
                            
                            if currentPage == 5 {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.omniPrimary, Color.omniSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color.omniPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(1.0)
                    .animation(.easeInOut(duration: 0.1), value: currentPage)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            applySmartDefaults()
        }
    }
    
    private var nextButtonText: String {
        switch currentPage {
        case 0: return "Let's Start"
        case 1: return "Continue"
        case 2: return "Next"
        case 3: return "Next" 
        case 4: return "Next"
        case 5: return "Start My Journey"
        default: return "Next"
        }
    }
    
    private func nextAction() {
        if currentPage < 5 {
            withAnimation {
                currentPage += 1
            }
        } else {
            completeOnboarding()
        }
    }
    
    private func applySmartDefaults() {
        // Apply research-based defaults to reduce cognitive load
        selectedConcerns = defaultConcerns
        selectedCopingStyle = defaultCopingStyle
        selectedPreferences = defaultPreferences
    }
    
    private func completeOnboarding() {
        // Add celebration animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            // Trigger any completion animations
        }
        
        // Save onboarding data with both selected and default values
        let finalConcerns = selectedConcerns.isEmpty ? defaultConcerns : selectedConcerns
        let finalCopingStyle = selectedCopingStyle.isEmpty ? defaultCopingStyle : selectedCopingStyle
        let finalPreferences = selectedPreferences.isEmpty ? defaultPreferences : selectedPreferences
        
        // Save to UserDefaults
        UserDefaults.standard.set(Array(finalConcerns), forKey: "userConcerns")
        UserDefaults.standard.set(finalCopingStyle, forKey: "userCopingStyle")
        UserDefaults.standard.set(Array(finalPreferences), forKey: "userPreferences")
        UserDefaults.standard.set(shareAdditionalInfo, forKey: "userAdditionalInfo")
        UserDefaults.standard.set(userName.isEmpty ? (authManager.currentUser?.displayName ?? "Friend") : userName, forKey: "preferredName")
        
        // Update user profile if authenticated
        if authManager.isAuthenticated {
            Task {
                await authManager.updateProfile(displayName: userName.isEmpty ? (authManager.currentUser?.displayName ?? "Friend") : userName)
            }
        }
        
        // Delayed completion for smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Onboarding Pages

struct WelcomeOnboardingPage: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.omniPrimary, Color.omniSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 20) {
                Text("Welcome")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                
                Text("Let's personalize your mental wellness journey")
                    .font(.system(size: 18))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.omniPrimary)
                    Text("100% Private")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.omniTextSecondary)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.omniPrimary)
                    Text("Takes less than 2 minutes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.omniTextSecondary)
                }
            }
            
            Spacer()
            Spacer()
        }
    }
}

struct NameInputPage: View {
    @Binding var userName: String
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("What should I call you?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("This helps me personalize our conversations")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                TextField("Your name or nickname", text: $userName)
                    .font(.system(size: 18))
                    .padding()
                    .background(Color.omniSecondaryBackground)
                    .cornerRadius(12)
                    .onAppear {
                        // Smart default from authenticated user
                        if userName.isEmpty, let displayName = authManager.currentUser?.displayName {
                            userName = displayName
                        }
                    }
                
                Text("You can always change this later")
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

struct ConcernsPage: View {
    @Binding var selectedConcerns: Set<String>
    let concerns: [String]
    let defaultConcerns: Set<String>
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Your Concerns")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("What's something you're struggling with lately that you'd like support on?")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("Select up to 3 options")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.omniPrimary)
            }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                    ForEach(concerns, id: \.self) { concern in
                        ConcernOption(
                            title: concern,
                            isSelected: selectedConcerns.contains(concern),
                            isDefault: defaultConcerns.contains(concern),
                            action: {
                                if selectedConcerns.contains(concern) {
                                    selectedConcerns.remove(concern)
                                } else if selectedConcerns.count < 3 {
                                    selectedConcerns.insert(concern)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

struct ConcernOption: View {
    let title: String
    let isSelected: Bool
    let isDefault: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .omniTextPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else if isDefault {
                    Text("Popular")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.omniPrimary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.omniPrimary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(isSelected ? Color.omniPrimary : Color.omniSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : (isDefault ? Color.omniPrimary.opacity(0.3) : Color.clear), lineWidth: 1)
            )
        }
    }
}

struct CopingStylePage: View {
    @Binding var selectedCopingStyle: String
    let copingStyles: [String]
    let defaultStyle: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Coping Style")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("When you feel stressed or down, what do you usually do to cope?")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 12) {
                ForEach(copingStyles, id: \.self) { style in
                    CopingStyleOption(
                        title: style,
                        isSelected: selectedCopingStyle == style,
                        isDefault: style == defaultStyle,
                        action: { selectedCopingStyle = style }
                    )
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

struct CopingStyleOption: View {
    let title: String
    let isSelected: Bool
    let isDefault: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .omniPrimary : .omniTextTertiary)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isDefault && !isSelected {
                    Text("Most common")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.omniSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.omniSecondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(isSelected ? Color.omniPrimary.opacity(0.1) : Color.omniSecondaryBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.omniPrimary : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct PreferencesPage: View {
    @Binding var selectedPreferences: Set<String>
    let preferences: [String]
    let defaultPreferences: Set<String>
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Preferences")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("How would you like Omni to support you?")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("You can always change these later")
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
            }
            
            VStack(spacing: 12) {
                ForEach(preferences, id: \.self) { preference in
                    PreferenceOption(
                        title: preference,
                        isSelected: selectedPreferences.contains(preference),
                        isDefault: defaultPreferences.contains(preference),
                        action: {
                            if selectedPreferences.contains(preference) {
                                selectedPreferences.remove(preference)
                            } else {
                                selectedPreferences.insert(preference)
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

struct PreferenceOption: View {
    let title: String
    let isSelected: Bool
    let isDefault: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .omniTextPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else if isDefault {
                    Text("Recommended")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.omniSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.omniSecondary.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(isSelected ? Color.omniPrimary : Color.omniSecondaryBackground)
            .cornerRadius(12)
        }
    }
}

struct AdditionalInfoPage: View {
    @Binding var shareAdditionalInfo: String
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Text("Anything Else?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.omniTextPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Finally, is there anything else you'd like to share about yourself or what you're going through?")
                    .font(.system(size: 16))
                    .foregroundColor(.omniTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("(Totally optional – you can always tell me more later!)")
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextTertiary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                TextField("I'd like to share...", text: $shareAdditionalInfo, axis: .vertical)
                    .font(.system(size: 16))
                    .padding()
                    .background(Color.omniSecondaryBackground)
                    .cornerRadius(12)
                    .lineLimit(3...6)
                
                Text("This helps me understand you better and provide more personalized support.")
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}

#Preview {
    EnhancedOnboardingView()
        .environmentObject(AuthenticationManager())
}