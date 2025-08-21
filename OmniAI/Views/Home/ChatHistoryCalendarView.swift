import SwiftUI

struct ChatHistoryCalendarView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    let chatSessions: [ChatSession]
    @State private var selectedMonth = Date()
    
    private let calendar = Calendar.current
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Month Navigator
                HStack {
                    Button(action: previousMonth) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.omniPrimary)
                    }
                    
                    Spacer()
                    
                    Text(dateFormatter.string(from: selectedMonth))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.omniTextPrimary)
                    
                    Spacer()
                    
                    Button(action: nextMonth) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(.omniPrimary)
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                CalendarGrid(
                    selectedMonth: selectedMonth,
                    selectedDate: $selectedDate,
                    chatSessions: chatSessions,
                    onDaySelected: { date in
                        selectedDate = date
                        dismiss()
                    }
                )
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
        }
    }
    
    private func previousMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
    }
    
    private func nextMonth() {
        selectedMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
    }
}

struct CalendarGrid: View {
    let selectedMonth: Date
    @Binding var selectedDate: Date
    let chatSessions: [ChatSession]
    let onDaySelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        VStack(spacing: 10) {
            // Weekday Headers
            HStack {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.omniTextSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Days Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(getDaysInMonth(), id: \.self) { day in
                    if let day = day {
                        ChatDayCell(
                            date: day,
                            isSelected: calendar.isDate(day, inSameDayAs: selectedDate),
                            hasChats: hasChatsOnDate(day),
                            chatCount: getChatsCountOnDate(day),
                            onTap: { onDaySelected(day) }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func getDaysInMonth() -> [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: selectedMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }
        
        // Fill remaining days to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func hasChatsOnDate(_ date: Date) -> Bool {
        chatSessions.contains { session in
            calendar.isDate(session.updatedAt, inSameDayAs: date)
        }
    }
    
    private func getChatsCountOnDate(_ date: Date) -> Int {
        chatSessions.filter { session in
            calendar.isDate(session.updatedAt, inSameDayAs: date)
        }.count
    }
}

struct ChatDayCell: View {
    let date: Date
    let isSelected: Bool
    let hasChats: Bool
    let chatCount: Int
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
                    )
                
                VStack(spacing: 2) {
                    Text("\(calendar.component(.day, from: date))")
                        .font(.system(size: 16, weight: isSelected ? .bold : .medium))
                        .foregroundColor(textColor)
                    
                    if hasChats {
                        HStack(spacing: 2) {
                            ForEach(0..<min(chatCount, 3), id: \.self) { _ in
                                Circle()
                                    .fill(Color.omniPrimary)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                }
            }
            .frame(height: 40)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return Color.omniPrimary.opacity(0.15)
        } else if hasChats {
            return Color.omniSecondaryBackground
        } else if calendar.isDateInToday(date) {
            return Color.omniPrimary.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        if isSelected {
            return Color.omniPrimary
        } else if calendar.isDateInToday(date) {
            return Color.omniPrimary.opacity(0.3)
        } else {
            return Color.clear
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return Color.omniPrimary
        } else if !calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
            return Color.omniTextTertiary
        } else {
            return Color.omniTextPrimary
        }
    }
}

#Preview {
    ChatHistoryCalendarView(
        selectedDate: .constant(Date()),
        chatSessions: []
    )
}