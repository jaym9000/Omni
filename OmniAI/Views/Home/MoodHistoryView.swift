import SwiftUI

struct MoodHistoryView: View {
    @StateObject private var moodManager = MoodManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedDate = Date()
    @State private var selectedEntry: MoodEntry?
    @State private var showingAddMood = false
    @State private var showingEditNote = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar View
                    MoodCalendarView(
                        selectedDate: $selectedDate,
                        moodEntries: moodManager.moodEntries,
                        onDateSelected: { date in
                            selectedDate = date
                            // Find entry for selected date
                            selectedEntry = moodManager.moodEntries.first { entry in
                                Calendar.current.isDate(entry.timestamp, inSameDayAs: date)
                            }
                        }
                    )
                    
                    // Selected Date Details
                    if let entry = selectedEntry {
                        SelectedMoodCard(
                            entry: entry,
                            onEdit: {
                                showingEditNote = true
                            },
                            onDelete: {
                                Task {
                                    try await moodManager.deleteMoodEntry(entry)
                                    selectedEntry = nil
                                }
                            }
                        )
                    } else if Calendar.current.isDateInToday(selectedDate) {
                        EmptyDateCard(
                            date: selectedDate,
                            onAddMood: {
                                showingAddMood = true
                            }
                        )
                    }
                    
                    // Mood History List
                    MoodHistoryList(entries: moodManager.moodEntries)
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddMood = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.omniPrimary)
                    }
                }
            }
            .sheet(isPresented: $showingAddMood) {
                AddMoodSheet(initialMood: nil)
            }
            .sheet(isPresented: $showingEditNote) {
                if let entry = selectedEntry {
                    EditMoodNoteSheet(entry: entry)
                }
            }
            .task {
                if let user = authManager.currentUser {
                    await moodManager.loadUserMoods(userId: user.id)
                }
            }
        }
    }
}

// MARK: - Mood Calendar View
struct MoodCalendarView: View {
    @Binding var selectedDate: Date
    let moodEntries: [MoodEntry]
    let onDateSelected: (Date) -> Void
    
    @State private var displayedMonth = Date()
    
    var body: some View {
        VStack(spacing: 16) {
            // Month Navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.omniPrimary)
                }
                
                Spacer()
                
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                    .foregroundColor(.omniTextPrimary)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.omniPrimary)
                }
            }
            .padding(.horizontal)
            
            // Calendar Grid
            CalendarGridView(
                displayedMonth: displayedMonth,
                selectedDate: $selectedDate,
                moodEntries: moodEntries,
                onDateSelected: onDateSelected
            )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    func previousMonth() {
        withAnimation {
            displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
        }
    }
    
    func nextMonth() {
        withAnimation {
            displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        }
    }
}

struct CalendarGridView: View {
    let displayedMonth: Date
    @Binding var selectedDate: Date
    let moodEntries: [MoodEntry]
    let onDateSelected: (Date) -> Void
    
    let calendar = Calendar.current
    let weekdays = ["S", "M", "T", "W", "T", "F", "S"]
    
    var monthDays: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: displayedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.omniTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(Array(monthDays.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date),
                            mood: moodForDate(date),
                            onTap: {
                                selectedDate = date
                                onDateSelected(date)
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
    
    func moodForDate(_ date: Date) -> MoodType? {
        moodEntries.first { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: date)
        }?.mood
    }
}

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let mood: MoodType?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
                
                VStack(spacing: 2) {
                    // Date number
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 14, weight: isToday ? .bold : .regular))
                        .foregroundColor(textColor)
                    
                    // Mood indicator
                    if let mood = mood {
                        Text(mood.emoji)
                            .font(.system(size: 10))
                    }
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var backgroundColor: Color {
        if isSelected {
            return Color.omniPrimary.opacity(0.2)
        } else if mood != nil {
            return mood!.color.opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    var borderColor: Color {
        if isSelected {
            return Color.omniPrimary
        } else if isToday {
            return Color.omniPrimary.opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    var textColor: Color {
        if isToday {
            return Color.omniPrimary
        } else {
            return Color.omniTextPrimary
        }
    }
}

// MARK: - Selected Mood Card
struct SelectedMoodCard: View {
    let entry: MoodEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(entry.mood.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.mood.label)
                        .font(.headline)
                        .foregroundColor(.omniTextPrimary)
                    
                    Text(entry.timestamp.formatted(date: .complete, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.omniTextSecondary)
                }
                
                Spacer()
                
                Menu {
                    Button(action: onEdit) {
                        Label("Edit Note", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.omniTextSecondary)
                }
            }
            
            if let note = entry.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.omniTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(entry.mood.color.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Empty Date Card
struct EmptyDateCard: View {
    let date: Date
    let onAddMood: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "plus.circle")
                .font(.largeTitle)
                .foregroundColor(.omniPrimary)
            
            Text("No mood tracked for today")
                .font(.subheadline)
                .foregroundColor(.omniTextSecondary)
            
            Button(action: onAddMood) {
                Text("Track Your Mood")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.omniPrimary)
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Mood History List
struct MoodHistoryList: View {
    let entries: [MoodEntry]
    
    var groupedEntries: [(month: String, entries: [MoodEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            entry.timestamp.formatted(.dateTime.month(.wide).year())
        }
        
        return grouped
            .sorted { $0.value.first?.timestamp ?? Date() > $1.value.first?.timestamp ?? Date() }
            .map { (month: $0.key, entries: $0.value.sorted { $0.timestamp > $1.timestamp }) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("All Moods")
                .font(.headline)
                .foregroundColor(.omniTextPrimary)
                .padding(.horizontal)
            
            if !entries.isEmpty {
                ForEach(groupedEntries, id: \.month) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.month)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.omniTextSecondary)
                            .padding(.horizontal)
                        
                        ForEach(group.entries) { entry in
                            MoodHistoryRow(entry: entry)
                        }
                    }
                }
            } else {
                Text("No mood history yet")
                    .font(.subheadline)
                    .foregroundColor(.omniTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
    }
}

struct MoodHistoryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        HStack {
            Text(entry.mood.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.mood.label)
                    .font(.subheadline)
                    .foregroundColor(.omniTextPrimary)
                
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.omniTextSecondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.omniTextSecondary)
                
                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.omniTextSecondary.opacity(0.7))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Add Mood Sheet
struct AddMoodSheet: View {
    @StateObject private var moodManager = MoodManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    let initialMood: MoodType?
    
    @State private var selectedMood: MoodType?
    @State private var moodNote = ""
    @State private var isSaving = false
    @State private var showReflection = false
    @State private var savedMood: MoodType?
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(initialMood: MoodType? = nil) {
        self.initialMood = initialMood
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("How are you feeling?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.omniTextPrimary)
                    .padding(.top)
                
                // Mood Selection
                HStack(spacing: 16) {
                    ForEach(MoodType.allCases, id: \.self) { mood in
                        MoodSelectionButton(
                            mood: mood,
                            isSelected: selectedMood == mood,
                            onTap: {
                                withAnimation(.spring()) {
                                    selectedMood = mood
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                // Note Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a note (optional)")
                        .font(.subheadline)
                        .foregroundColor(.omniTextSecondary)
                    
                    TextEditor(text: $moodNote)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(height: 100)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Save Button
                Button(action: saveMood) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Mood")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedMood != nil ? Color.omniPrimary : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .disabled(selectedMood == nil || isSaving)
            }
            .navigationTitle("Track Mood")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Set the initial mood if provided
                if let initial = initialMood {
                    selectedMood = initial
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showReflection) {
            if let mood = savedMood {
                MoodReflectionSheet(
                    mood: mood,
                    onTalkToOmni: {
                        dismiss()
                        // Navigate to chat with mood context
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OpenChatWithMood"),
                                object: nil,
                                userInfo: ["mood": mood]
                            )
                        }
                    },
                    onJournal: {
                        dismiss()
                        // Navigate to journal with mood context
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OpenJournalWithMood"),
                                object: nil,
                                userInfo: ["mood": mood]
                            )
                        }
                    },
                    onDismiss: {
                        dismiss()
                    }
                )
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    func saveMood() {
        guard let mood = selectedMood,
              let user = authManager.currentUser else { return }
        
        isSaving = true
        
        Task {
            do {
                try await moodManager.trackMood(
                    mood,
                    note: moodNote.isEmpty ? nil : moodNote,
                    userId: user.id
                )
                
                await MainActor.run {
                    savedMood = mood
                    showReflection = true
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save mood. Please try again."
                    showError = true
                    isSaving = false
                }
                print("Failed to save mood: \(error)")
            }
        }
    }
}

struct MoodSelectionButton: View {
    let mood: MoodType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: 32))
                
                Text(mood.label)
                    .font(.caption)
                    .foregroundColor(isSelected ? mood.color : .omniTextSecondary)
            }
            .frame(width: 60, height: 80)
            .background(isSelected ? mood.color.opacity(0.2) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mood.color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Mood Note Sheet
struct EditMoodNoteSheet: View {
    let entry: MoodEntry
    @StateObject private var moodManager = MoodManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var noteText: String = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Mood Display
                HStack {
                    Text(entry.mood.emoji)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text(entry.mood.label)
                            .font(.headline)
                            .foregroundColor(.omniTextPrimary)
                        
                        Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.omniTextSecondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(entry.mood.color.opacity(0.1))
                .cornerRadius(12)
                
                // Note Editor
                VStack(alignment: .leading, spacing: 8) {
                    Text("Note")
                        .font(.subheadline)
                        .foregroundColor(.omniTextSecondary)
                    
                    TextEditor(text: $noteText)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .frame(minHeight: 150)
                }
                
                Spacer()
                
                // Save Button
                Button(action: saveNote) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Save Changes")
                            .fontWeight(.medium)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.omniPrimary)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(isSaving)
            }
            .padding()
            .navigationTitle("Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            noteText = entry.note ?? ""
        }
    }
    
    func saveNote() {
        isSaving = true
        
        Task {
            do {
                try await moodManager.updateMoodNote(entry, note: noteText)
                dismiss()
            } catch {
                print("Failed to update note: \(error)")
                isSaving = false
            }
        }
    }
}

struct MoodHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        MoodHistoryView()
            .environmentObject(AuthenticationManager())
    }
}