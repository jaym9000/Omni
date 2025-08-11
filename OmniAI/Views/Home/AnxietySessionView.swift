import SwiftUI

struct AnxietySessionView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedTechnique: AnxietyTechnique?
    
    enum AnxietyTechnique: String, CaseIterable, Identifiable {
        case breathing = "Box Breathing"
        case grounding = "5-4-3-2-1 Grounding"
        case bodyScan = "Body Scan Meditation"
        case positiveAffirmations = "Positive Affirmations"
        case journalPrompt = "Anxiety Journal"
        case quickCalm = "Quick Calm Technique"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .breathing: return "lungs.fill"
            case .grounding: return "eye.fill"
            case .bodyScan: return "figure.stand.line.dotted.figure.stand"
            case .positiveAffirmations: return "heart.fill"
            case .journalPrompt: return "pencil.and.outline"
            case .quickCalm: return "bolt.fill"
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .breathing: return [Color.blue.opacity(0.7), Color.cyan.opacity(0.5)]
            case .grounding: return [Color.green.opacity(0.7), Color.mint.opacity(0.5)]
            case .bodyScan: return [Color.purple.opacity(0.7), Color.pink.opacity(0.5)]
            case .positiveAffirmations: return [Color.orange.opacity(0.7), Color.yellow.opacity(0.5)]
            case .journalPrompt: return [Color.indigo.opacity(0.7), Color.blue.opacity(0.5)]
            case .quickCalm: return [Color.red.opacity(0.7), Color.orange.opacity(0.5)]
            }
        }
        
        var description: String {
            switch self {
            case .breathing: return "4-4-4-4 breathing pattern to regulate your nervous system"
            case .grounding: return "Use your 5 senses to anchor yourself in the present"
            case .bodyScan: return "Release tension by focusing on each part of your body"
            case .positiveAffirmations: return "Rewire negative thoughts with empowering statements"
            case .journalPrompt: return "Write through your anxiety with guided prompts"
            case .quickCalm: return "Immediate relief techniques for acute anxiety"
            }
        }
        
        var duration: String {
            switch self {
            case .breathing: return "5 min"
            case .grounding: return "3 min"
            case .bodyScan: return "10 min"
            case .positiveAffirmations: return "7 min"
            case .journalPrompt: return "15 min"
            case .quickCalm: return "2 min"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header with calming illustration
                    VStack(spacing: 20) {
                        Image("anxiety-management")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        VStack(spacing: 8) {
                            Text("Anxiety Relief Toolkit")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.omniTextPrimary)
                            
                            Text("Take a moment to care for yourself.\nChoose what feels right for you now.")
                                .font(.system(size: 16))
                                .foregroundColor(.omniTextSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Quick stats
                    HStack(spacing: 20) {
                        StatCard(title: "Techniques", value: "6", icon: "sparkles")
                        StatCard(title: "Duration", value: "2-15m", icon: "clock")
                        StatCard(title: "Success Rate", value: "94%", icon: "chart.line.uptrend.xyaxis")
                    }
                    .padding(.horizontal)
                    
                    // Techniques Grid
                    VStack(spacing: 16) {
                        HStack {
                            Text("Choose Your Technique")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 16) {
                            ForEach(AnxietyTechnique.allCases) { technique in
                                TechniqueCard(
                                    technique: technique,
                                    action: { selectedTechnique = technique }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Emergency section
                    VStack(spacing: 12) {
                        HStack {
                            Text("Need Immediate Help?")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            Spacer()
                        }
                        
                        EmergencyCard()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniprimary)
                }
            }
            .sheet(item: $selectedTechnique) { technique in
                TechniqueDetailView(technique: technique)
            }
        }
    }
}

struct TechniqueCard: View {
    let technique: AnxietySessionView.AnxietyTechnique
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: technique.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            LinearGradient(
                                colors: technique.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(technique.duration)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.omniTextSecondary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(technique.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                        .lineLimit(2)
                    
                    Text(technique.description)
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.omniprimary)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.omniTextPrimary)
            
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.omniTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Emergency Card
struct EmergencyCard: View {
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.red.gradient)
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Crisis Support")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Text("24/7 professional help available")
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextTertiary)
            }
            .padding()
            .background(Color.red.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TechniqueDetailView: View {
    let technique: AnxietySessionView.AnxietyTechnique
    @Environment(\.dismiss) var dismiss
    @State private var isStarted = false
    @State private var currentStep = 0
    
    var content: [String] {
        switch technique {
        case .breathing:
            return [
                "Find a comfortable position, sitting or lying down.",
                "Close your eyes and take a natural breath.",
                "Inhale slowly for 4 counts: 1... 2... 3... 4...",
                "Hold your breath for 4 counts: 1... 2... 3... 4...",
                "Exhale slowly for 4 counts: 1... 2... 3... 4...",
                "Hold empty for 4 counts: 1... 2... 3... 4...",
                "Repeat this cycle 5-10 times."
            ]
        case .grounding:
            return [
                "Look around and identify 5 things you can see.",
                "Notice 4 things you can touch or feel.",
                "Listen for 3 things you can hear.",
                "Identify 2 things you can smell.",
                "Think of 1 thing you can taste.",
                "Take a deep breath and notice how you feel now."
            ]
        case .bodyScan:
            return [
                "Lie down comfortably and close your eyes.",
                "Start by noticing your toes. How do they feel?",
                "Move up to your feet, then your ankles.",
                "Continue up your legs, noticing any tension.",
                "Focus on your torso, arms, and shoulders.",
                "Finally, relax your neck, face, and head.",
                "Take a moment to feel your whole body relaxed."
            ]
        case .positiveAffirmations:
            return [
                "\"I am capable of handling whatever comes my way.\"",
                "\"This feeling is temporary and will pass.\"",
                "\"I am safe and grounded in this moment.\"",
                "\"I have overcome challenges before, I can do it again.\"",
                "\"I choose peace and calm over worry and fear.\"",
                "\"I trust in my ability to find solutions.\"",
                "\"I am worthy of love, peace, and happiness.\""
            ]
        case .journalPrompt:
            return [
                "What am I feeling anxious about right now?",
                "What evidence do I have that supports this worry?",
                "What evidence contradicts this worry?",
                "What would I tell a friend in this situation?",
                "What's the worst that could realistically happen?",
                "How could I cope if that happened?",
                "What's one small step I can take today?"
            ]
        case .quickCalm:
            return [
                "Take 5 deep breaths, making your exhale longer than your inhale.",
                "Tense all your muscles for 5 seconds, then release.",
                "Name 3 things you're grateful for right now.",
                "Drink a glass of cold water slowly.",
                "Splash cool water on your wrists or face.",
                "Call or text someone you trust.",
                "Remember: This moment will pass."
            ]
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: technique.icon)
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .frame(width: 80, height: 80)
                            .background(
                                LinearGradient(
                                    colors: technique.gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(20)
                        
                        Text(technique.rawValue)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text("Duration: \(technique.duration)")
                            .font(.system(size: 16))
                            .foregroundColor(.omniTextSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.omniSecondaryBackground)
                            .cornerRadius(16)
                    }
                    .padding(.top)
                    
                    // Content Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Follow these steps:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                        
                        ForEach(Array(content.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.omniprimary)
                                    .cornerRadius(12)
                                
                                Text(step)
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniTextPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Button
                    Button(action: {
                        isStarted = true
                        // Here you could add timer logic, audio guidance, etc.
                    }) {
                        Text(isStarted ? "Session Started ✓" : "Start Session")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: isStarted ? [Color.green, Color.green.opacity(0.8)] : technique.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                    .disabled(isStarted)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationTitle(technique.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.omniprimary)
                }
            }
        }
    }
}

#Preview {
    AnxietySessionView()
}