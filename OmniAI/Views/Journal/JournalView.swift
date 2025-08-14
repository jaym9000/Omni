import SwiftUI

struct JournalView: View {
    @EnvironmentObject var journalManager: JournalManager
    @State private var showNewEntry = false
    @State private var selectedEntryType: JournalType = .freeForm
    @State private var showCalendar = false
    @State private var headerOpacity: Double = 0
    @State private var optionsVisible = false
    @State private var entriesVisible = false
    
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
                            // Free-form text entry with staggered animation
                            JournalOptionRow(
                                icon: "pencil",
                                title: "Free-form text entry",
                                action: {
                                    selectedEntryType = .freeForm
                                    showNewEntry = true
                                }
                            )
                            .opacity(optionsVisible ? 1 : 0)
                            .offset(x: optionsVisible ? 0 : -30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(0.1),
                                value: optionsVisible
                            )
                            
                            // Tag entries with mood or topics
                            JournalOptionRow(
                                icon: "tag",
                                title: "Tag entries with mood or topics",
                                action: {
                                    selectedEntryType = .tagged
                                    showNewEntry = true
                                }
                            )
                            .opacity(optionsVisible ? 1 : 0)
                            .offset(x: optionsVisible ? 0 : -30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(0.2),
                                value: optionsVisible
                            )
                            
                            // Referenced journal themes
                            JournalOptionRow(
                                icon: "book.closed",
                                title: "Referenced journal themes",
                                action: {
                                    selectedEntryType = .themed
                                    showNewEntry = true
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
                            
                            Button(action: { showCalendar = true }) {
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
                                JournalEntryCard(entry: entry)
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
            }
            .sheet(isPresented: $showNewEntry) {
                if selectedEntryType == .themed {
                    ThemedJournalEntryView()
                } else {
                    JournalEntryView(type: selectedEntryType)
                }
            }
            .sheet(isPresented: $showCalendar) {
                JournalCalendarView()
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
                    Label(mood.label, systemImage: "face.smiling")
                        .font(.system(size: 12))
                        .foregroundColor(mood.color)
                }
                
                Spacer()
                
                Text(formatDate(entry.createdAt))
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
            }
        }
        .padding()
        .background(Color.omniCardLavender)
        .cornerRadius(12)
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
                    
                    // Mood selector for non-tagged entries
                    if type != .tagged {
                        VStack(alignment: .leading, spacing: 16) {
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
                        }
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
        journalManager.saveEntry(entry)
        
        dismiss()
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
    @State private var currentPrompt = "What's one small win you had today, no matter how minor?"
    @State private var responseText = ""
    @State private var isCompleted = false
    
    let prompts = [
        "What's one small win you had today, no matter how minor?",
        "How are you feeling this morning, and what's contributing to that mood?",
        "What's something you're grateful for right now?",
        "What challenge are you facing, and how might you approach it?",
        "Describe a moment when you felt truly peaceful today."
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Themed Journal")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.omniTextPrimary)
                    }
                    .padding(.top, 16)
                    
                    // Guided Journal Prompt Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Guided Journal Prompt")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.omniTextSecondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                currentPrompt = prompts.randomElement() ?? prompts[0]
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 14))
                                    Text("New Prompt")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.omniPrimary)
                            }
                        }
                        
                        // Prompt Display
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniPrimary)
                                
                                Text("GRATITUDE & WINS")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.omniPrimary)
                                    .textCase(.uppercase)
                            }
                            
                            Text(currentPrompt)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.omniTextPrimary)
                                .lineSpacing(4)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.omniPrimary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.omniPrimary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    
                    // Text Input Area
                    VStack(spacing: 16) {
                        ZStack(alignment: .topLeading) {
                            if responseText.isEmpty {
                                Text("Write your thoughts here...")
                                    .font(.system(size: 16))
                                    .foregroundColor(.omniTextTertiary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 16)
                            }
                            
                            TextEditor(text: $responseText)
                                .font(.system(size: 16))
                                .foregroundColor(.omniTextPrimary)
                                .padding(8)
                                .frame(minHeight: 200)
                                .background(Color.clear)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(responseText.isEmpty ? Color.clear : Color.omniPrimary.opacity(0.3), lineWidth: 1)
                        )
                        
                        // Character counter and save button
                        HStack {
                            Text("\(responseText.count) characters")
                                .font(.system(size: 12))
                                .foregroundColor(.omniTextTertiary)
                            
                            Spacer()
                            
                            Button(action: saveEntry) {
                                Text("Save Entry")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .disabled(responseText.isEmpty)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(responseText.isEmpty ? Color.gray.opacity(0.3) : Color.omniPrimary)
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
    
    private func saveEntry() {
        guard !responseText.isEmpty else { return }
        
        let _ = JournalEntry(
            userId: UUID(),
            title: "Themed Entry",
            content: responseText,
            type: .themed
        )
        
        // Note: In a real app, we would inject JournalManager here
        // For now, this creates the entry structure
        dismiss()
    }
}

#Preview {
    JournalView()
        .environmentObject(AuthenticationManager())
}