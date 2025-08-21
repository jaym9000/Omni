import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class JournalManager: ObservableObject {
    static let shared = JournalManager()
    
    @Published var journalEntries: [JournalEntry] = []
    @Published var isLoading = false
    @Published var searchText = ""
    
    private let firebaseManager = FirebaseManager.shared
    private var listener: ListenerRegistration?
    
    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty {
            return journalEntries
        }
        
        let searchLower = searchText.lowercased()
        return journalEntries.filter { entry in
            entry.title.lowercased().contains(searchLower) ||
            entry.content.lowercased().contains(searchLower) ||
            entry.tags.contains { $0.lowercased().contains(searchLower) }
        }
    }
    
    private init() {
        setupJournalListener()
    }
    
    deinit {
        listener?.remove()
    }
    
    // MARK: - CRUD Operations
    
    func saveEntry(_ entry: JournalEntry) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Get Firebase Auth UID
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            throw FirebaseManager.FirebaseError.userNotFound
        }
        
        // Save to Firebase - the listener will update local state
        try await firebaseManager.saveJournalEntry(entry, authUserId: authUserId)
        
        // Don't update local state here - let the listener handle it to avoid duplicates
    }
    
    func updateEntry(_ entry: JournalEntry) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            throw FirebaseManager.FirebaseError.userNotFound
        }
        
        var updatedEntry = entry
        updatedEntry.updatedAt = Date()
        
        try await firebaseManager.updateJournalEntry(updatedEntry, authUserId: authUserId)
        
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = updatedEntry
        }
    }
    
    func deleteEntry(_ id: UUID) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            throw FirebaseManager.FirebaseError.userNotFound
        }
        
        try await firebaseManager.deleteJournalEntry(entryId: id.uuidString, authUserId: authUserId)
        journalEntries.removeAll { $0.id == id }
    }
    
    func toggleFavorite(_ id: UUID) async throws {
        if let index = journalEntries.firstIndex(where: { $0.id == id }) {
            journalEntries[index].isFavorite.toggle()
            try await updateEntry(journalEntries[index])
        }
    }
    
    // MARK: - Query Methods
    
    func getEntriesForDate(_ date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        return journalEntries.filter { entry in
            calendar.isDate(entry.createdAt, inSameDayAs: date)
        }
    }
    
    func getEntriesForMonth(_ date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        return journalEntries.filter { entry in
            let entryComponents = calendar.dateComponents([.year, .month], from: entry.createdAt)
            return entryComponents.year == components.year && entryComponents.month == components.month
        }
    }
    
    func getDatesWithEntries(for month: Date) -> Set<DateComponents> {
        let calendar = Calendar.current
        let monthEntries = getEntriesForMonth(month)
        
        return Set(monthEntries.map { entry in
            calendar.dateComponents([.year, .month, .day], from: entry.createdAt)
        })
    }
    
    func getEntriesWithTag(_ tag: String) -> [JournalEntry] {
        return journalEntries.filter { $0.tags.contains(tag) }
    }
    
    func getRecentPrompts() -> [JournalPrompt] {
        // Return sample prompts for now
        return JournalPrompt.samplePrompts
    }
    
    func getEntriesByMood(_ mood: MoodType) -> [JournalEntry] {
        return journalEntries.filter { $0.mood == mood }
    }
    
    func getFavoriteEntries() -> [JournalEntry] {
        return journalEntries.filter { $0.isFavorite }
    }
    
    // MARK: - Statistics
    
    func getMoodStatistics() -> [(mood: MoodType, count: Int)] {
        var stats: [MoodType: Int] = [:]
        
        for entry in journalEntries {
            if let mood = entry.mood {
                stats[mood, default: 0] += 1
            }
        }
        
        return MoodType.allCases.compactMap { mood in
            if let count = stats[mood], count > 0 {
                return (mood: mood, count: count)
            }
            return nil
        }
    }
    
    func getTotalEntryCount() -> Int {
        return journalEntries.count
    }
    
    func getCurrentStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let hasEntry = journalEntries.contains { entry in
                calendar.isDate(entry.createdAt, inSameDayAs: currentDate)
            }
            
            if hasEntry {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if streak == 0 {
                // Check yesterday if today has no entry yet
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                let hasYesterdayEntry = journalEntries.contains { entry in
                    calendar.isDate(entry.createdAt, inSameDayAs: currentDate)
                }
                if hasYesterdayEntry {
                    streak = 1
                    currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Firebase Integration
    
    func loadUserJournals(userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            print("⚠️ No authenticated user")
            return
        }
        
        do {
            let entries = try await firebaseManager.fetchJournalEntries(authUserId: authUserId)
            journalEntries = entries.sorted { $0.createdAt > $1.createdAt }
            print("✅ Loaded \(entries.count) journal entries from Firebase")
        } catch {
            print("❌ Failed to load journal entries: \(error)")
        }
    }
    
    private func setupJournalListener() {
        guard let authUserId = firebaseManager.auth.currentUser?.uid else { return }
        
        listener = firebaseManager.listenToJournalEntries(authUserId: authUserId) { [weak self] entries in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.journalEntries = entries.sorted { $0.createdAt > $1.createdAt }
            }
        }
    }
    
    // MARK: - Search & Tags
    
    func searchJournalEntries(_ searchText: String) async throws -> [JournalEntry] {
        guard let authUserId = firebaseManager.auth.currentUser?.uid else {
            throw FirebaseManager.FirebaseError.userNotFound
        }
        
        return try await firebaseManager.searchJournalEntries(authUserId: authUserId, searchText: searchText)
    }
    
    func getAllTags() -> [String] {
        var allTags = Set<String>()
        for entry in journalEntries {
            allTags.formUnion(entry.tags)
        }
        return Array(allTags).sorted()
    }
    
    func getPopularTags(limit: Int = 10) -> [(tag: String, count: Int)] {
        var tagCounts: [String: Int] = [:]
        
        for entry in journalEntries {
            for tag in entry.tags {
                tagCounts[tag, default: 0] += 1
            }
        }
        
        return tagCounts
            .sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (tag: $0.key, count: $0.value) }
    }
    
    // MARK: - Export Functions
    
    func exportAsText() -> String {
        var exportText = "My Journal Entries\n"
        exportText += "Exported on: \(Date().formatted())\n"
        exportText += "Total Entries: \(journalEntries.count)\n\n"
        exportText += String(repeating: "=", count: 50) + "\n\n"
        
        for entry in journalEntries {
            exportText += "📅 \(entry.createdAt.formatted(date: .long, time: .shortened))\n"
            exportText += "📝 \(entry.title)\n"
            
            if let mood = entry.mood {
                exportText += "\(mood.emoji) Mood: \(mood.label)\n"
            }
            
            if !entry.tags.isEmpty {
                exportText += "🏷️ Tags: \(entry.tags.joined(separator: ", "))\n"
            }
            
            if entry.isFavorite {
                exportText += "⭐ Favorited\n"
            }
            
            exportText += "\n\(entry.content)\n\n"
            exportText += String(repeating: "-", count: 50) + "\n\n"
        }
        
        return exportText
    }
}