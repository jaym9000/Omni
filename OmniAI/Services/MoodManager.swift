import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class MoodManager: ObservableObject {
    static let shared = MoodManager()
    
    @Published var moodEntries: [MoodEntry] = []
    @Published var todaysMood: MoodEntry?
    @Published var isLoading = false
    @Published var moodStats: MoodStatistics?
    
    private let firebaseManager = FirebaseManager.shared
    private var listener: ListenerRegistration?
    
    private init() {
        setupMoodListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - Mood Tracking
    
    func trackMood(_ mood: MoodType, note: String? = nil, userId: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Create mood entry
        let entry = MoodEntry(userId: userId, mood: mood, note: note)
        
        // Get Firebase Auth UID
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            throw FirebaseManager.FirebaseError.userNotFound
        }
        
        // Save to Firebase
        try await firebaseManager.saveMoodEntry(entry, authUserId: authUserId)
        
        // Update local state
        moodEntries.insert(entry, at: 0)
        
        // Update today's mood
        if Calendar.current.isDateInToday(entry.timestamp) {
            todaysMood = entry
        }
        
        // Update statistics
        await updateMoodStatistics()
    }
    
    func loadUserMoods(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        // Get Firebase Auth UID
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            print("⚠️ No authenticated user")
            return
        }
        
        do {
            let entries = try await firebaseManager.fetchMoodEntries(authUserId: authUserId)
            moodEntries = entries.sorted { $0.timestamp > $1.timestamp }
            
            // Find today's mood
            todaysMood = moodEntries.first { entry in
                Calendar.current.isDateInToday(entry.timestamp)
            }
            
            // Calculate statistics
            await updateMoodStatistics()
        } catch {
            print("❌ Failed to load mood entries: \(error)")
        }
    }
    
    // MARK: - Real-time Updates
    
    private func setupMoodListener() {
        guard let authUserId = firebaseManager.auth.currentUser?.uid else { return }
        
        listener = firebaseManager.listenToMoodEntries(authUserId: authUserId) { [weak self] entries in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.moodEntries = entries.sorted { $0.timestamp > $1.timestamp }
                
                // Update today's mood
                self.todaysMood = self.moodEntries.first { entry in
                    Calendar.current.isDateInToday(entry.timestamp)
                }
                
                // Update statistics
                await self.updateMoodStatistics()
            }
        }
    }
    
    // MARK: - Analytics
    
    func getMoodHistory(days: Int = 30) -> [MoodEntry] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return moodEntries.filter { $0.timestamp >= startDate }
    }
    
    func getMoodCounts() -> [MoodType: Int] {
        var counts: [MoodType: Int] = [:]
        for mood in MoodType.allCases {
            counts[mood] = moodEntries.filter { $0.mood == mood }.count
        }
        return counts
    }
    
    func getWeeklyMoodTrend() -> [(date: Date, moods: [MoodEntry])] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) ?? endDate
        
        var weekData: [(date: Date, moods: [MoodEntry])] = []
        
        for dayOffset in 0...6 {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate),
               date >= startDate {
                let dayMoods = moodEntries.filter { entry in
                    calendar.isDate(entry.timestamp, inSameDayAs: date)
                }
                weekData.append((date: date, moods: dayMoods))
            }
        }
        
        return weekData.reversed()
    }
    
    func getDominantMood(for date: Date? = nil) -> MoodType? {
        let relevantEntries: [MoodEntry]
        
        if let date = date {
            relevantEntries = moodEntries.filter { entry in
                Calendar.current.isDate(entry.timestamp, inSameDayAs: date)
            }
        } else {
            relevantEntries = moodEntries
        }
        
        guard !relevantEntries.isEmpty else { return nil }
        
        let moodCounts = Dictionary(grouping: relevantEntries, by: { $0.mood })
            .mapValues { $0.count }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    private func updateMoodStatistics() async {
        let last30Days = getMoodHistory(days: 30)
        let last7Days = getMoodHistory(days: 7)
        
        // Calculate averages
        let weeklyAverage = calculateMoodScore(for: last7Days)
        let monthlyAverage = calculateMoodScore(for: last30Days)
        
        // Find most common mood only if there are entries
        let moodCounts = getMoodCounts()
        let mostCommon = moodEntries.isEmpty ? nil : moodCounts.max(by: { $0.value < $1.value })?.key
        
        // Calculate streak
        let currentStreak = calculateMoodTrackingStreak()
        
        moodStats = MoodStatistics(
            weeklyAverage: weeklyAverage,
            monthlyAverage: monthlyAverage,
            mostCommonMood: mostCommon,
            totalEntries: moodEntries.count,
            currentStreak: currentStreak,
            last7DaysCount: last7Days.count,
            last30DaysCount: last30Days.count
        )
    }
    
    private func calculateMoodScore(for entries: [MoodEntry]) -> Double {
        guard !entries.isEmpty else { return 0 }
        
        let scores = entries.map { entry -> Double in
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
    
    private func calculateMoodTrackingStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let hasEntry = moodEntries.contains { entry in
                calendar.isDate(entry.timestamp, inSameDayAs: currentDate)
            }
            
            if hasEntry {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Mood Insights
    
    func getMoodInsights() -> [String] {
        var insights: [String] = []
        
        // Check for patterns
        let weeklyTrend = getWeeklyMoodTrend()
        let recentMoods = weeklyTrend.flatMap { $0.moods }
        
        // Anxiety pattern
        let anxiousCount = recentMoods.filter { $0.mood == .anxious }.count
        if anxiousCount >= 3 {
            insights.append("You've been feeling anxious frequently. Consider trying our anxiety relief exercises.")
        }
        
        // Positive trend
        let happyCount = recentMoods.filter { $0.mood == .happy || $0.mood == .calm }.count
        if happyCount >= 4 {
            insights.append("Great job maintaining positive moods! Keep up the good self-care.")
        }
        
        // Consistency
        if let stats = moodStats, stats.currentStreak >= 7 {
            insights.append("Amazing! You've tracked your mood for \(stats.currentStreak) days straight.")
        }
        
        // Time patterns
        let morningMoods = recentMoods.filter { entry in
            let hour = Calendar.current.component(.hour, from: entry.timestamp)
            return hour >= 6 && hour < 12
        }
        let eveningMoods = recentMoods.filter { entry in
            let hour = Calendar.current.component(.hour, from: entry.timestamp)
            return hour >= 18 && hour < 24
        }
        
        if !morningMoods.isEmpty && !eveningMoods.isEmpty {
            let morningScore = calculateMoodScore(for: morningMoods)
            let eveningScore = calculateMoodScore(for: eveningMoods)
            
            if morningScore > eveningScore + 1 {
                insights.append("Your mood tends to be better in the morning. Try to maintain that energy throughout the day.")
            } else if eveningScore > morningScore + 1 {
                insights.append("You feel better in the evenings. Consider adjusting your morning routine for a better start.")
            }
        }
        
        return insights
    }
    
    // MARK: - Data Management
    
    func deleteMoodEntry(_ entry: MoodEntry) async throws {
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            throw FirebaseManager.FirebaseError.userNotFound
        }
        
        try await firebaseManager.deleteMoodEntry(entryId: entry.id.uuidString, authUserId: authUserId)
        moodEntries.removeAll { $0.id == entry.id }
        
        // Update today's mood if needed
        if todaysMood?.id == entry.id {
            todaysMood = nil
        }
        
        await updateMoodStatistics()
    }
    
    func updateMoodNote(_ entry: MoodEntry, note: String) async throws {
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            throw FirebaseManager.FirebaseError.userNotFound
        }
        
        var updatedEntry = entry
        updatedEntry.note = note
        
        try await firebaseManager.updateMoodEntry(updatedEntry, authUserId: authUserId)
        
        if let index = moodEntries.firstIndex(where: { $0.id == entry.id }) {
            moodEntries[index] = updatedEntry
        }
    }
}

// MARK: - Mood Statistics Model

struct MoodStatistics {
    let weeklyAverage: Double
    let monthlyAverage: Double
    let mostCommonMood: MoodType?
    let totalEntries: Int
    let currentStreak: Int
    let last7DaysCount: Int
    let last30DaysCount: Int
    
    var weeklyAverageText: String {
        switch weeklyAverage {
        case 4...: return "Excellent"
        case 3..<4: return "Good"
        case 2..<3: return "Fair"
        default: return "Needs attention"
        }
    }
    
    var monthlyAverageText: String {
        switch monthlyAverage {
        case 4...: return "Excellent"
        case 3..<4: return "Good"
        case 2..<3: return "Fair"
        default: return "Needs attention"
        }
    }
}