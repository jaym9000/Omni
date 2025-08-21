import SwiftUI

struct JournalCalendarView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var journalManager: JournalManager
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showingEntryDetail = false
    @State private var selectedEntry: JournalEntry?
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Calendar Header
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.omniPrimary)
                        }
                        
                        Spacer()
                        
                        Text(dateFormatter.string(from: currentMonth))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.omniTextPrimary)
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.omniPrimary)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar Grid
                    JournalCalendarGridView(
                        month: currentMonth,
                        selectedDate: $selectedDate,
                        journalManager: journalManager
                    )
                    .padding(.horizontal)
                    
                    // Selected Date Entries
                    if !getEntriesForSelectedDate().isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Entries for \(formatSelectedDate())")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                                .padding(.horizontal)
                            
                            LazyVStack(spacing: 12) {
                                ForEach(getEntriesForSelectedDate()) { entry in
                                    CalendarEntryCard(entry: entry) {
                                        selectedEntry = entry
                                        showingEntryDetail = true
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 32))
                                .foregroundColor(.omniTextTertiary.opacity(0.6))
                            
                            Text("No entries for this date")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.omniTextSecondary)
                            
                            Text("Select a different date or start journaling!")
                                .font(.system(size: 14))
                                .foregroundColor(.omniTextTertiary)
                        }
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Journal Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedDate = Date()
                            currentMonth = Date()
                        }
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
        }
        .background(Color.omniBackground)
        .sheet(item: $selectedEntry) { entry in
            JournalEntryDetailView(entry: entry)
        }
    }
    
    private func previousMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func nextMonth() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
        }
    }
    
    private func getEntriesForSelectedDate() -> [JournalEntry] {
        return journalManager.getEntriesForDate(selectedDate)
    }
    
    private func formatSelectedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: selectedDate)
    }
}

// MARK: - Calendar Grid View
struct JournalCalendarGridView: View {
    let month: Date
    @Binding var selectedDate: Date
    let journalManager: JournalManager
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(spacing: 0) {
            // Weekday Headers
            HStack {
                ForEach(getWeekdayHeaders(), id: \.self) { weekday in
                    Text(weekday)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.omniTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.bottom, 8)
            
            // Calendar Days Grid
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(getDaysInMonth(), id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: month, toGranularity: .month),
                        hasEntries: journalManager.getEntriesForDate(date).count > 0,
                        entryCount: journalManager.getEntriesForDate(date).count,
                        dominantMood: getDominantMood(for: date)
                    ) {
                        selectedDate = date
                    }
                }
            }
        }
        .padding()
        .background(Color.omniSecondaryBackground)
        .cornerRadius(16)
    }
    
    private func getWeekdayHeaders() -> [String] {
        let formatter = DateFormatter()
        return formatter.shortWeekdaySymbols
    }
    
    private func getDaysInMonth() -> [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start),
              let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1) else {
            return []
        }
        
        var days: [Date] = []
        var currentDate = monthFirstWeek.start
        
        while currentDate < monthLastWeek.end {
            days.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return days
    }
    
    private func getDominantMood(for date: Date) -> MoodType? {
        let entries = journalManager.getEntriesForDate(date)
        let moods = entries.compactMap { $0.mood }
        
        guard !moods.isEmpty else { return nil }
        
        let moodCounts = Dictionary(grouping: moods) { $0 }
            .mapValues { $0.count }
        
        return moodCounts.max { $0.value < $1.value }?.key
    }
}

// MARK: - Calendar Day View
struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasEntries: Bool
    let entryCount: Int
    let dominantMood: MoodType?
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                    .foregroundColor(textColor)
                
                // Mood indicator or entry count
                if hasEntries {
                    if let mood = dominantMood {
                        Text(mood.emoji)
                            .font(.system(size: 12))
                    } else {
                        Circle()
                            .fill(Color.omniPrimary)
                            .frame(width: 6, height: 6)
                    }
                } else {
                    Spacer()
                        .frame(height: 12)
                }
            }
            .frame(width: 40, height: 50)
            .background(backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .omniTextTertiary.opacity(0.5)
        }
        
        if isSelected {
            return hasEntries ? .white : .omniPrimary
        }
        
        if calendar.isDateInToday(date) {
            return .omniPrimary
        }
        
        return .omniTextPrimary
    }
    
    private var backgroundColor: Color {
        if isSelected && hasEntries {
            return dominantMood?.color ?? .omniPrimary
        }
        
        if isSelected {
            return .omniPrimary.opacity(0.1)
        }
        
        if calendar.isDateInToday(date) && hasEntries {
            return dominantMood?.color.opacity(0.2) ?? .omniPrimary.opacity(0.2)
        }
        
        if hasEntries {
            return dominantMood?.color.opacity(0.1) ?? .omniCardLavender
        }
        
        return .clear
    }
    
    private var borderColor: Color {
        if isSelected {
            return hasEntries ? (dominantMood?.color ?? .omniPrimary) : .omniPrimary
        }
        return .clear
    }
}

// MARK: - Calendar Entry Card
struct CalendarEntryCard: View {
    let entry: JournalEntry
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time indicator
                VStack(spacing: 4) {
                    Text(formatTime(entry.createdAt))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.omniTextTertiary)
                    
                    if let mood = entry.mood {
                        Text(mood.emoji)
                            .font(.system(size: 16))
                    }
                }
                .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(entry.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if entry.isFavorite {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.moodHappy)
                        }
                    }
                    
                    Text(entry.content)
                        .font(.system(size: 13))
                        .foregroundColor(.omniTextSecondary)
                        .lineLimit(2)
                    
                    if !entry.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(entry.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.omniPrimary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.omniPrimary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                            
                            if entry.tags.count > 3 {
                                Text("+\(entry.tags.count - 3)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.omniTextTertiary)
                            }
                        }
                    }
                }
                
                Spacer(minLength: 0)
            }
            .padding()
            .background(Color.omniCardBeige)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Journal Entry Detail View
struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with title and metadata
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(entry.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.omniTextPrimary)
                            
                            Spacer()
                            
                            if entry.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.moodHappy)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Text(formatDate(entry.createdAt))
                                .font(.system(size: 14))
                                .foregroundColor(.omniTextSecondary)
                            
                            if let mood = entry.mood {
                                HStack(spacing: 4) {
                                    Text(mood.emoji)
                                    Text(mood.label)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(mood.color)
                                }
                            }
                        }
                    }
                    
                    // Tags
                    if !entry.tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(entry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.omniPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.omniPrimary.opacity(0.1))
                                    .cornerRadius(16)
                            }
                        }
                    }
                    
                    // Prompt (for themed entries)
                    if let prompt = entry.prompt {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Prompt")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            
                            Text(prompt)
                                .font(.system(size: 14))
                                .foregroundColor(.omniTextSecondary)
                                .padding()
                                .background(Color.omniPrimary.opacity(0.05))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entry")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                        
                        Text(entry.content)
                            .font(.system(size: 16))
                            .foregroundColor(.omniTextPrimary)
                            .lineSpacing(2)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
        }
        .background(Color.omniBackground)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    JournalCalendarView()
        .environmentObject(JournalManager.shared)
}