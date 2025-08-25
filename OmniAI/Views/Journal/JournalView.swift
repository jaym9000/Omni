import SwiftUI
import RevenueCatUI

struct JournalView: View {
    @EnvironmentObject var journalManager: JournalManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var presentedJournalType: JournalType?
    @State private var showCalendar = false
    @State private var headerOpacity: Double = 0
    @State private var optionsVisible = false
    @State private var entriesVisible = false
    @State private var selectedEntry: JournalEntry?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with fade-in animation
                    Text("Journal")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.omniTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.top)
                        .opacity(headerOpacity)
                    
                    // Journal Options Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Journal Options")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                        
                        VStack(spacing: 12) {
                            // Free-form text entry - NOW PREMIUM
                            JournalOptionRow(
                                icon: "pencil",
                                title: "Free-form text entry",
                                action: {
                                    presentedJournalType = .freeForm
                                }
                            )
                            .opacity(optionsVisible ? 1 : 0)
                            .offset(x: optionsVisible ? 0 : -30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(0.1),
                                value: optionsVisible
                            )
                            
                            // Tag entries with mood or topics (Premium)
                            JournalOptionRow(
                                icon: "tag",
                                title: "Tag entries with mood or topics",
                                action: {
                                    presentedJournalType = .tagged
                                }
                            )
                            .opacity(optionsVisible ? 1 : 0)
                            .offset(x: optionsVisible ? 0 : -30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(0.2),
                                value: optionsVisible
                            )
                            
                            // Referenced journal themes (Premium)
                            JournalOptionRow(
                                icon: "book.closed",
                                title: "Referenced journal themes",
                                action: {
                                    presentedJournalType = .themed
                                }
                            )
                            .opacity(optionsVisible ? 1 : 0)
                            .offset(x: optionsVisible ? 0 : -30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(0.3),
                                value: optionsVisible
                            )
                        }
                    }
                    
                    // My Journal Log Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("My Journal Log")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            
                            Spacer()
                            
                            Button(action: { 
                                showCalendar = true
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                    Text("Calendar")
                                        .font(.system(size: 14, weight: .medium))
                                    
                                }
                                .foregroundColor(.omniPrimary)
                            }
                        }
                        
                        if !journalManager.journalEntries.isEmpty {
                            ForEach(Array(journalManager.journalEntries.prefix(5).enumerated()), id: \.element.id) { index, entry in
                                Button(action: { selectedEntry = entry }) {
                                    JournalEntryCard(entry: entry)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .opacity(entriesVisible ? 1 : 0)
                                .offset(y: entriesVisible ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.1 + 0.4),
                                    value: entriesVisible
                                )
                            }
                        } else {
                            // Empty state - properly centered
                            GeometryReader { geometry in
                                VStack(spacing: 20) {
                                    Spacer()
                                    
                                    VStack(spacing: 16) {
                                        Image(systemName: "book.closed")
                                            .font(.system(size: 56))
                                            .foregroundColor(.omniTextTertiary.opacity(0.6))
                                        
                                        VStack(spacing: 8) {
                                            Text("No journal entries yet")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.omniTextPrimary)
                                            
                                            Text("Start writing to see your entries here.")
                                                .font(.system(size: 14))
                                                .foregroundColor(.omniTextSecondary)
                                        }
                                        .multilineTextAlignment(.center)
                                    }
                                    
                                    Spacer()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: max(200, geometry.size.height * 0.4))
                            }
                            .frame(minHeight: 200)
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
            .background(Color.omniBackground)
            .onAppear {
                animateViewEntrance()
                // Load journal entries when view appears
                Task {
                    if let user = authManager.currentUser {
                        await journalManager.loadUserJournals(userId: user.id)
                    }
                }
            }
            .sheet(item: $presentedJournalType) { journalType in
                switch journalType {
                case .themed:
                    ThemedJournalEntryView()
                        .environmentObject(journalManager)
                        .environmentObject(authManager)
                case .dailyPrompt:
                    ReferencedPromptsView()
                        .environmentObject(journalManager)
                        .environmentObject(authManager)
                case .freeForm, .tagged:
                    JournalEntryView(type: journalType)
                        .environmentObject(journalManager)
                        .environmentObject(authManager)
                }
            }
            .sheet(isPresented: $showCalendar) {
                JournalCalendarView()
            }
            .sheet(item: $selectedEntry) { entry in
                JournalDetailView(entry: entry)
                    .environmentObject(journalManager)
            }
        }
    }
    
    private func animateViewEntrance() {
        withAnimation(.easeOut(duration: 0.5)) {
            headerOpacity = 1.0
        }
        
        withAnimation(.spring().delay(0.1)) {
            optionsVisible = true
        }
        
        withAnimation(.spring().delay(0.3)) {
            entriesVisible = true
        }
    }
}

// MARK: - Journal Option Row
struct JournalOptionRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.omniTextSecondary)
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.omniTextPrimary)
                
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextTertiary)
            }
            .padding()
            .background(Color.omniCardBeige)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sample Journal Entry
struct SampleJournalEntry: View {
    let type: JournalType
    let title: String
    let timeAgo: String
    let content: String
    var tags: String?
    var prompt: String?
    
    var body: some View {
        HStack {
            Image(systemName: iconForType(type))
                .font(.system(size: 18))
                .foregroundColor(.omniTextSecondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.omniTextPrimary)
                    
                    Spacer()
                    
                    Text(timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextTertiary)
                }
                
                Text(content)
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextSecondary)
                    .lineLimit(1)
                
                if let tags = tags {
                    Text("Tags: \(tags)")
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextTertiary)
                }
                
                if let prompt = prompt {
                    Text("Prompt: \(prompt)")
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextTertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding()
        .background(Color.omniSecondaryBackground)
        .cornerRadius(12)
    }
    
    private func iconForType(_ type: JournalType) -> String {
        switch type {
        case .freeForm:
            return "pencil"
        case .tagged:
            return "tag"
        case .themed:
            return "book.closed"
        case .dailyPrompt:
            return "calendar"
        }
    }
}

// MARK: - Journal Entry Card
struct JournalEntryCard: View {
    let entry: JournalEntry
    
    var body: some View {
        HStack(spacing: 0) {
            // Mood color accent bar
            if let mood = entry.mood {
                RoundedRectangle(cornerRadius: 4)
                    .fill(mood.color.opacity(0.8))
                    .frame(width: 4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.omniPrimary.opacity(0.3))
                    .frame(width: 4)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(entry.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.omniTextPrimary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.moodHappy)
                    }
                }
                
                Text(entry.content)
                    .font(.system(size: 14))
                    .foregroundColor(.omniTextSecondary)
                    .lineLimit(2)
                
                HStack {
                    if let mood = entry.mood {
                        HStack(spacing: 4) {
                            Text(mood.emoji)
                                .font(.system(size: 14))
                            Text(mood.label)
                                .font(.system(size: 12))
                                .foregroundColor(mood.color)
                        }
                    }
                    
                    Spacer()
                    
                    Text(formatDate(entry.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.omniTextTertiary)
                }
            }
            .padding()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Journal Entry View
struct JournalEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var journalManager: JournalManager
    @State private var title = ""
    @State private var content = ""
    @State private var selectedMood: MoodType?
    @State private var selectedTags: Set<String> = []
    let type: JournalType
    let mood: MoodType?
    
    init(type: JournalType = .freeForm, mood: MoodType? = nil) {
        self.type = type
        self.mood = mood
    }
    
    let availableTags = ["Gratitude", "Reflection", "Goals", "Challenges", "Achievements", "Relationships", "Work", "Health"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                        
                        TextField("Give your entry a title", text: $title)
                            .font(.system(size: 18))
                            .padding()
                            .background(Color.omniSecondaryBackground)
                            .cornerRadius(12)
                    }
                    
                    
                    // Tags (for tagged entries)
                    if type == .tagged {
                        VStack(alignment: .leading, spacing: 16) {
                            // How are you feeling section
                            Text("How are you feeling?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(MoodType.allCases, id: \.self) { mood in
                                        VStack(spacing: 8) {
                                            Button(action: { selectedMood = mood }) {
                                                Text(mood.emoji)
                                                    .font(.system(size: 24))
                                                    .frame(width: 50, height: 50)
                                                    .background(
                                                        Circle()
                                                            .fill(selectedMood == mood ? mood.color.opacity(0.2) : Color.clear)
                                                    )
                                                    .overlay(
                                                        Circle()
                                                            .stroke(selectedMood == mood ? mood.color : Color.clear, lineWidth: 2)
                                                    )
                                                    .padding(4) // Add padding to prevent clipping
                                            }
                                            .scaleEffect(selectedMood == mood ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.3), value: selectedMood)
                                            
                                            Text(mood.label)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(selectedMood == mood ? mood.color : .omniTextSecondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // What are you writing about section
                            Text("What are you writing about?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            
                            let topicTags = [
                                ("💝", "Relationships"),
                                ("💼", "Work"),
                                ("🏥", "Health"),
                                ("🌱", "Personal"),
                                ("💰", "Finance"),
                                ("👨‍👩‍👧‍👦", "Family")
                            ]
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(topicTags, id: \.1) { emoji, tag in
                                    TopicTagChip(
                                        emoji: emoji,
                                        text: tag,
                                        isSelected: selectedTags.contains(tag),
                                        action: {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your thoughts")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                        
                        TextEditor(text: $content)
                            .font(.system(size: 16))
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color.omniSecondaryBackground)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .foregroundColor(.omniPrimary)
                    .fontWeight(.semibold)
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
        .onAppear {
            if let mood = mood {
                selectedMood = mood
            }
        }
    }
    
    private func saveEntry() {
        // Create journal entry with all data
        var entry = JournalEntry(
            userId: authManager.currentUser?.id ?? UUID(),
            title: title,
            content: content,
            type: type
        )
        
        // Set mood if selected
        entry.mood = selectedMood
        
        // Set tags for tagged entries
        if type == .tagged {
            entry.tags = Array(selectedTags)
        }
        
        // Save through JournalManager
        Task {
            do {
                try await journalManager.saveEntry(entry)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to save entry: \(error)")
            }
        }
    }
}

// MARK: - Topic Tag Chip
struct TopicTagChip: View {
    let emoji: String
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 24))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.omniPrimary.opacity(0.1) : Color.omniSecondaryBackground)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.omniPrimary : Color.clear, lineWidth: 2)
                    )
                    .padding(2) // Add padding to prevent circle clipping
                
                Text(text)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .omniPrimary : .omniTextSecondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .omniTextPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.omniPrimary : Color.omniSecondaryBackground)
                .cornerRadius(20)
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.frames[index].origin.x + bounds.minX,
                                      y: result.frames[index].origin.y + bounds.minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Themed Journal Entry View
struct ThemedJournalEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var journalManager: JournalManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTheme: JournalTheme = .gratitude
    @State private var currentQuestionIndex = 0
    @State private var responses: [String] = ["", "", "", "", ""]
    @State private var showThemeSelection = true
    
    enum JournalTheme: String, CaseIterable {
        case gratitude = "Gratitude & Wins"
        case reflection = "Self-Reflection"
        case goals = "Goal Setting"
        case mindfulness = "Mindfulness"
        case emotional = "Emotional Check-in"
        
        var icon: String {
            switch self {
            case .gratitude: return "star.fill"
            case .reflection: return "brain.head.profile"
            case .goals: return "target"
            case .mindfulness: return "leaf.fill"
            case .emotional: return "heart.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .gratitude: return .moodHappy
            case .reflection: return .omniPrimary
            case .goals: return .moodCalm
            case .mindfulness: return .green
            case .emotional: return .moodAnxious
            }
        }
        
        var questions: [String] {
            switch self {
            case .gratitude:
                return [
                    "What's one small win you had today?",
                    "Who or what are you grateful for right now?",
                    "What made you smile today?",
                    "What strength did you show today?",
                    "What are you looking forward to tomorrow?"
                ]
            case .reflection:
                return [
                    "How are you feeling right now, in this moment?",
                    "What's been on your mind the most today?",
                    "What did you learn about yourself recently?",
                    "What would you like to let go of?",
                    "How have you grown this week?"
                ]
            case .goals:
                return [
                    "What's one goal you want to focus on?",
                    "What small step can you take today?",
                    "What might get in your way?",
                    "Who or what can support you?",
                    "How will you celebrate progress?"
                ]
            case .mindfulness:
                return [
                    "What do you notice in your body right now?",
                    "What sounds can you hear around you?",
                    "Describe something beautiful you saw today.",
                    "What are you feeling without judgment?",
                    "What simple pleasure did you enjoy?"
                ]
            case .emotional:
                return [
                    "Name the emotions you're experiencing.",
                    "What triggered these feelings?",
                    "Where do you feel this in your body?",
                    "What do you need right now?",
                    "What would self-compassion look like?"
                ]
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if showThemeSelection {
                // Theme Selection View
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Choose Your Journal Theme")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.omniTextPrimary)
                            Text("Select a guided journaling theme to get started")
                                .font(.system(size: 16))
                                .foregroundColor(.omniTextSecondary)
                        }
                        .padding(.top, 16)
                        
                        // Theme Cards
                        VStack(spacing: 12) {
                            ForEach(JournalTheme.allCases, id: \.self) { theme in
                                Button(action: {
                                    selectedTheme = theme
                                    showThemeSelection = false
                                    responses = Array(repeating: "", count: theme.questions.count)
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: theme.icon)
                                            .font(.system(size: 24))
                                            .foregroundColor(theme.color)
                                            .frame(width: 50, height: 50)
                                            .background(
                                                Circle()
                                                    .fill(theme.color.opacity(0.1))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(theme.rawValue)
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.omniTextPrimary)
                                            Text("\(theme.questions.count) guided prompts")
                                                .font(.system(size: 14))
                                                .foregroundColor(.omniTextSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.omniTextTertiary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(UIColor.secondarySystemBackground))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.omniPrimary)
                    }
                }
            } else {
                // Guided Questions View
                ScrollView {
                    VStack(spacing: 24) {
                        // Progress Header
                        VStack(spacing: 12) {
                            HStack {
                                Button(action: {
                                    if currentQuestionIndex > 0 {
                                        currentQuestionIndex -= 1
                                    } else {
                                        showThemeSelection = true
                                    }
                                }) {
                                    Image(systemName: "chevron.left")
                                        .foregroundColor(.omniPrimary)
                                }
                                
                                Spacer()
                                
                                Text("\(currentQuestionIndex + 1) of \(selectedTheme.questions.count)")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.omniTextSecondary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showThemeSelection = true
                                }) {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.omniTextSecondary)
                                }
                            }
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.omniSecondaryBackground)
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    Rectangle()
                                        .fill(selectedTheme.color)
                                        .frame(width: geometry.size.width * CGFloat(currentQuestionIndex + 1) / CGFloat(selectedTheme.questions.count), height: 4)
                                        .cornerRadius(2)
                                        .animation(.spring(), value: currentQuestionIndex)
                                }
                            }
                            .frame(height: 4)
                        }
                        .padding(.top, 16)
                        
                        // Theme Badge
                        HStack(spacing: 8) {
                            Image(systemName: selectedTheme.icon)
                                .font(.system(size: 16))
                                .foregroundColor(selectedTheme.color)
                            
                            Text(selectedTheme.rawValue.uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(selectedTheme.color)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(selectedTheme.color.opacity(0.1))
                        )
                        
                        // Current Question
                        VStack(alignment: .leading, spacing: 20) {
                            Text(selectedTheme.questions[currentQuestionIndex])
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            // Text Input
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack(alignment: .topLeading) {
                                    if responses[currentQuestionIndex].isEmpty {
                                        Text("Write your thoughts here...")
                                            .font(.system(size: 16))
                                            .foregroundColor(.omniTextTertiary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 16)
                                    }
                                    
                                    TextEditor(text: $responses[currentQuestionIndex])
                                        .font(.system(size: 16))
                                        .foregroundColor(.omniTextPrimary)
                                        .padding(8)
                                        .frame(minHeight: 150)
                                        .background(Color.clear)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(UIColor.systemBackground))
                                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(responses[currentQuestionIndex].isEmpty ? Color.clear : selectedTheme.color.opacity(0.3), lineWidth: 1)
                                )
                                
                                Text("\(responses[currentQuestionIndex].count) characters")
                                    .font(.system(size: 12))
                                    .foregroundColor(.omniTextTertiary)
                            }
                        }
                        
                        // Navigation Buttons
                        HStack(spacing: 12) {
                            if currentQuestionIndex < selectedTheme.questions.count - 1 {
                                Button(action: {
                                    currentQuestionIndex += 1
                                }) {
                                    Text("Skip")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.omniTextSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.omniTextTertiary, lineWidth: 1)
                                )
                                
                                Button(action: {
                                    currentQuestionIndex += 1
                                }) {
                                    Text("Next")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTheme.color)
                                )
                            } else {
                                Button(action: saveEntry) {
                                    Text("Save Journal Entry")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .disabled(responses.allSatisfy { $0.isEmpty })
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(responses.allSatisfy { $0.isEmpty } ? Color.gray.opacity(0.3) : selectedTheme.color)
                                )
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.omniPrimary)
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        // Filter out empty responses and create Q&A pairs
        var content = "Theme: \(selectedTheme.rawValue)\n\n"
        var hasContent = false
        
        for (index, question) in selectedTheme.questions.enumerated() {
            if !responses[index].isEmpty {
                content += "Q: \(question)\n"
                content += "A: \(responses[index])\n\n"
                hasContent = true
            }
        }
        
        guard hasContent else { return }
        
        // Create journal entry with all Q&A pairs
        var entry = JournalEntry(
            userId: authManager.currentUser?.id ?? UUID(),
            title: "Themed: \(selectedTheme.rawValue)",
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            type: .themed
        )
        
        // Set the theme as the prompt
        entry.prompt = selectedTheme.rawValue
        
        // Save through JournalManager
        Task {
            do {
                try await journalManager.saveEntry(entry)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to save themed entry: \(error)")
            }
        }
    }
}

// MARK: - Journal Detail View
struct JournalDetailView: View {
    let entry: JournalEntry
    @EnvironmentObject var journalManager: JournalManager
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Mood and Date Header
                    HStack {
                        if let mood = entry.mood {
                            HStack(spacing: 8) {
                                Text(mood.emoji)
                                    .font(.system(size: 32))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mood.label)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(mood.color)
                                    
                                    Text(formatDate(entry.createdAt))
                                        .font(.system(size: 14))
                                        .foregroundColor(.omniTextSecondary)
                                }
                            }
                        } else {
                            Text(formatDate(entry.createdAt))
                                .font(.system(size: 14))
                                .foregroundColor(.omniTextSecondary)
                        }
                        
                        Spacer()
                        
                        if entry.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.moodHappy)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Tags if any
                    if !entry.tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.omniPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.omniPrimary.opacity(0.1))
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                    
                    // Content
                    Text(entry.content)
                        .font(.system(size: 16))
                        .foregroundColor(.omniTextPrimary)
                        .lineSpacing(4)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    
                    // Journal Type
                    HStack {
                        Image(systemName: iconForType(entry.type))
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                        
                        Text(entry.type.rawValue.capitalized + " Entry")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                    }
                    
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle(entry.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showEditSheet = true }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: toggleFavorite) {
                            Label(entry.isFavorite ? "Remove from Favorites" : "Add to Favorites", 
                                  systemImage: entry.isFavorite ? "star.slash" : "star")
                        }
                        
                        Button(role: .destructive, action: { showDeleteAlert = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.omniPrimary)
                    }
                }
            }
            .alert("Delete Entry?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteEntry()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func iconForType(_ type: JournalType) -> String {
        switch type {
        case .freeForm:
            return "pencil"
        case .tagged:
            return "tag"
        case .themed:
            return "book.closed"
        case .dailyPrompt:
            return "calendar"
        }
    }
    
    private func toggleFavorite() {
        Task {
            do {
                try await journalManager.toggleFavorite(entry.id)
            } catch {
                print("Failed to toggle favorite: \(error)")
            }
        }
    }
    
    private func deleteEntry() {
        Task {
            do {
                try await journalManager.deleteEntry(entry.id)
                dismiss()
            } catch {
                print("Failed to delete entry: \(error)")
            }
        }
    }
}

// MARK: - Referenced Prompts View
struct ReferencedPromptsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var journalManager: JournalManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedPrompt: JournalPrompt?
    @State private var showWritingView = false
    @State private var title = ""
    @State private var content = ""
    
    // Group prompts by category
    private var groupedPrompts: [String: [JournalPrompt]] {
        Dictionary(grouping: JournalPrompt.dailyPrompts, by: { $0.category })
    }
    
    var body: some View {
        NavigationStack {
            if let selectedPrompt = selectedPrompt, showWritingView {
                // Writing view for selected prompt
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Selected Prompt Display
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Writing Prompt")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.omniTextSecondary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(selectedPrompt.category.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.omniPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.omniPrimary.opacity(0.1))
                                        .cornerRadius(8)
                                    
                                    Spacer()
                                }
                                
                                Text(selectedPrompt.text)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.omniTextPrimary)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .background(Color.omniCardBeige)
                            .cornerRadius(12)
                        }
                        
                        // Title Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Entry Title")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.omniTextSecondary)
                            
                            TextField("Give your entry a title", text: $title)
                                .font(.system(size: 18))
                                .padding()
                                .background(Color.omniSecondaryBackground)
                                .cornerRadius(12)
                        }
                        
                        // Content Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Response")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.omniTextSecondary)
                            
                            ZStack(alignment: .topLeading) {
                                if content.isEmpty {
                                    Text("Write your thoughts about this prompt...")
                                        .font(.system(size: 16))
                                        .foregroundColor(.omniTextTertiary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                }
                                
                                TextEditor(text: $content)
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniTextPrimary)
                                    .padding(8)
                                    .frame(minHeight: 200)
                                    .background(Color.clear)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.omniSecondaryBackground)
                            )
                            
                            Text("\(content.count) characters")
                                .font(.system(size: 12))
                                .foregroundColor(.omniTextTertiary)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .navigationTitle("Write Entry")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Back") {
                            showWritingView = false
                        }
                        .foregroundColor(.omniPrimary)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveEntry()
                        }
                        .foregroundColor(.omniPrimary)
                        .fontWeight(.semibold)
                        .disabled(title.isEmpty || content.isEmpty)
                    }
                }
            } else {
                // Prompt Selection View
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Referenced Journal Prompts")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.omniTextPrimary)
                            Text("Choose a prompt to guide your journaling")
                                .font(.system(size: 16))
                                .foregroundColor(.omniTextSecondary)
                        }
                        .padding(.top, 16)
                        
                        // Prompts grouped by category
                        ForEach(groupedPrompts.keys.sorted(), id: \.self) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                // Category Header
                                HStack {
                                    Text(category)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.omniTextPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(groupedPrompts[category]?.count ?? 0) prompts")
                                        .font(.system(size: 14))
                                        .foregroundColor(.omniTextSecondary)
                                }
                                
                                // Category Prompts
                                VStack(spacing: 8) {
                                    ForEach(groupedPrompts[category] ?? [], id: \.id) { prompt in
                                        Button(action: {
                                            selectedPrompt = prompt
                                            title = ""
                                            content = ""
                                            showWritingView = true
                                        }) {
                                            HStack(alignment: .top, spacing: 12) {
                                                Image(systemName: "quote.bubble")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.omniPrimary)
                                                    .frame(width: 24)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(prompt.text)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(.omniTextPrimary)
                                                        .multilineTextAlignment(.leading)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                    
                                                    Text("Tap to write about this")
                                                        .font(.system(size: 14))
                                                        .foregroundColor(.omniTextSecondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.omniTextTertiary)
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color(UIColor.secondarySystemBackground))
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.omniPrimary)
                    }
                }
            }
        }
    }
    
    private func saveEntry() {
        guard let selectedPrompt = selectedPrompt else { return }
        
        // Create journal entry with selected prompt
        var entry = JournalEntry(
            userId: authManager.currentUser?.id ?? UUID(),
            title: title,
            content: content,
            type: .dailyPrompt
        )
        
        // Set the prompt text for reference
        entry.prompt = selectedPrompt.text
        
        // Save through JournalManager
        Task {
            do {
                try await journalManager.saveEntry(entry)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to save prompt-based entry: \(error)")
            }
        }
    }
}

#Preview {
    JournalView()
        .environmentObject(AuthenticationManager())
}