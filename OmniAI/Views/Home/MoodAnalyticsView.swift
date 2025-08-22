import SwiftUI
import Charts

struct MoodAnalyticsView: View {
    @StateObject private var moodManager = MoodManager.shared
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTimeRange = TimeRange.week
    @State private var showInsights = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .all: return 365
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    if let stats = moodManager.moodStats {
                        StatsOverviewCard(stats: stats)
                    }
                    
                    // Time Range Picker
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Mood Distribution Chart
                    MoodDistributionChart(
                        moodEntries: moodManager.getMoodHistory(days: selectedTimeRange.days)
                    )
                    .id(selectedTimeRange)  // Force refresh when time range changes
                    
                    // Weekly Trend Chart
                    WeeklyTrendChart(weekData: moodManager.getWeeklyMoodTrend())
                    
                    // Mood Insights
                    if !moodManager.getMoodInsights().isEmpty {
                        InsightsCard(insights: moodManager.getMoodInsights())
                    }
                    
                    // Recent Mood Entries
                    RecentMoodsCard(entries: Array(moodManager.moodEntries.prefix(5)))
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Mood Analytics")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if let user = authManager.currentUser {
                    await moodManager.loadUserMoods(userId: user.id)
                }
            }
        }
    }
}

// MARK: - Stats Overview Card
struct StatsOverviewCard: View {
    let stats: MoodStatistics
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                StatItem(
                    title: "Current Streak",
                    value: "\(stats.currentStreak)",
                    subtitle: "days",
                    icon: "flame.fill",
                    color: .orange
                )
                
                StatItem(
                    title: "Total Entries",
                    value: "\(stats.totalEntries)",
                    subtitle: "moods tracked",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
            }
            
            HStack(spacing: 20) {
                StatItem(
                    title: "Weekly Mood",
                    value: stats.weeklyAverageText,
                    subtitle: "Last 7 days",
                    icon: "calendar",
                    color: .green
                )
                
                if let mostCommon = stats.mostCommonMood {
                    StatItem(
                        title: "Most Common",
                        value: mostCommon.emoji,
                        subtitle: mostCommon.label,
                        icon: "star.fill",
                        color: mostCommon.color
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.omniTextSecondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.omniTextPrimary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.omniTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Mood Distribution Chart
struct MoodDistributionChart: View {
    let moodEntries: [MoodEntry]
    
    var moodCounts: [(mood: MoodType, count: Int)] {
        let counts = Dictionary(grouping: moodEntries, by: { $0.mood })
            .mapValues { $0.count }
        
        return MoodType.allCases.map { mood in
            (mood: mood, count: counts[mood] ?? 0)
        }.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Distribution")
                .font(.headline)
                .foregroundColor(.omniTextPrimary)
                .padding(.horizontal)
            
            if !moodEntries.isEmpty {
                Chart(moodCounts, id: \.mood) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Mood", item.mood.label)
                    )
                    .foregroundStyle(item.mood.color.gradient)
                    .cornerRadius(8)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.omniTextSecondary)
                    }
                }
                .frame(height: 200)
                .padding(.horizontal)
                .chartXAxis {
                    AxisMarks(position: .bottom) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            } else {
                Text("No mood data available")
                    .font(.subheadline)
                    .foregroundColor(.omniTextSecondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Weekly Trend Chart
struct WeeklyTrendChart: View {
    let weekData: [(date: Date, moods: [MoodEntry])]
    
    var chartData: [(date: Date, score: Double, dominant: MoodType?)] {
        weekData.map { day in
            let score = calculateDayScore(moods: day.moods)
            let dominant = day.moods.first?.mood
            return (date: day.date, score: score, dominant: dominant)
        }
    }
    
    func calculateDayScore(moods: [MoodEntry]) -> Double {
        guard !moods.isEmpty else { return 0 }
        
        let scores = moods.map { entry -> Double in
            switch entry.mood {
            case .happy: return 5
            case .calm: return 4
            case .anxious: return 2
            case .sad: return 2
            case .overwhelmed: return 1
            }
        }
        
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Mood Trend")
                .font(.headline)
                .foregroundColor(.omniTextPrimary)
                .padding(.horizontal)
            
            if !chartData.isEmpty {
                Chart(chartData, id: \.date) { item in
                    LineMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(Color.omniPrimary.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    PointMark(
                        x: .value("Day", item.date, unit: .day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(item.dominant?.color ?? .omniPrimary)
                    .symbolSize(100)
                }
                .frame(height: 200)
                .padding(.horizontal)
                .chartYScale(domain: 0...5)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisTick()
                        if let intValue = value.as(Int.self) {
                            AxisValueLabel {
                                Text(moodLabel(for: intValue))
                                    .font(.caption2)
                            }
                        }
                    }
                }
            } else {
                Text("Track your mood daily to see trends")
                    .font(.subheadline)
                    .foregroundColor(.omniTextSecondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    func moodLabel(for score: Int) -> String {
        switch score {
        case 5: return "😊"
        case 4: return "😌"
        case 3: return "😐"
        case 2: return "😔"
        case 1: return "😰"
        default: return ""
        }
    }
}

// MARK: - Insights Card
struct InsightsCard: View {
    let insights: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                Text("Insights")
                    .font(.headline)
                    .foregroundColor(.omniTextPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Color.omniPrimary)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.omniTextSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Recent Moods Card
struct RecentMoodsCard: View {
    let entries: [MoodEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Moods")
                .font(.headline)
                .foregroundColor(.omniTextPrimary)
                .padding(.horizontal)
            
            if !entries.isEmpty {
                VStack(spacing: 8) {
                    ForEach(entries) { entry in
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
                                        .lineLimit(1)
                                }
                            }
                            
                            Spacer()
                            
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundColor(.omniTextSecondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(entry.mood.color.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            } else {
                Text("No recent moods")
                    .font(.subheadline)
                    .foregroundColor(.omniTextSecondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct MoodAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        MoodAnalyticsView()
            .environmentObject(AuthenticationManager())
    }
}