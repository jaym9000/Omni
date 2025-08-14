import Foundation
import SwiftUI

class JournalManager: ObservableObject {
    static let shared = JournalManager()
    
    @Published var journalEntries: [JournalEntry] = []
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private let journalFile: URL
    
    private init() {
        journalFile = documentsDirectory.appendingPathComponent("journal_entries.json")
        loadEntries()
    }
    
    // MARK: - CRUD Operations
    
    func saveEntry(_ entry: JournalEntry) {
        // Check if entry already exists (for updates)
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            journalEntries[index] = entry
        } else {
            // New entry - add to beginning for most recent first
            journalEntries.insert(entry, at: 0)
        }
        persistEntries()
    }
    
    func updateEntry(_ entry: JournalEntry) {
        if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
            var updatedEntry = entry
            updatedEntry.updatedAt = Date()
            journalEntries[index] = updatedEntry
            persistEntries()
        }
    }
    
    func deleteEntry(_ id: UUID) {
        journalEntries.removeAll { $0.id == id }
        persistEntries()
    }
    
    func toggleFavorite(_ id: UUID) {
        if let index = journalEntries.firstIndex(where: { $0.id == id }) {
            journalEntries[index].isFavorite.toggle()
            persistEntries()
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
    
    func searchEntries(query: String) -> [JournalEntry] {
        let lowercasedQuery = query.lowercased()
        
        if lowercasedQuery.isEmpty {
            return journalEntries
        }
        
        return journalEntries.filter { entry in
            entry.title.lowercased().contains(lowercasedQuery) ||
            entry.content.lowercased().contains(lowercasedQuery) ||
            entry.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }
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
    
    // MARK: - Persistence
    
    private func loadEntries() {
        guard FileManager.default.fileExists(atPath: journalFile.path) else {
            // Load sample data for demo
            loadSampleEntries()
            return
        }
        
        do {
            let data = try Data(contentsOf: journalFile)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            journalEntries = try decoder.decode([JournalEntry].self, from: data)
        } catch {
            print("Error loading journal entries: \(error)")
            journalEntries = []
        }
    }
    
    private func persistEntries() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(journalEntries)
            try data.write(to: journalFile)
        } catch {
            print("Error saving journal entries: \(error)")
        }
    }
    
    private func loadSampleEntries() {
        // Create some sample entries for demo purposes
        let sampleEntries = [
            createSampleEntry(
                daysAgo: 0,
                title: "A Peaceful Morning",
                content: "Started my day with meditation and felt really centered. The breathing exercises from Omni really helped me manage my morning anxiety.",
                mood: .calm,
                tags: ["meditation", "morning", "breathing"]
            ),
            createSampleEntry(
                daysAgo: 1,
                title: "Challenging but Growth",
                content: "Work was overwhelming today, but I used the grounding techniques to stay focused. Proud of how I handled the pressure without panic.",
                mood: .overwhelmed,
                tags: ["work", "growth", "coping"]
            ),
            createSampleEntry(
                daysAgo: 2,
                title: "Gratitude Practice",
                content: "Three things I'm grateful for today: 1) My supportive family, 2) This app helping me track my moods, 3) The progress I'm making in therapy.",
                mood: .happy,
                tags: ["gratitude", "family", "progress"],
                isFavorite: true
            ),
            createSampleEntry(
                daysAgo: 3,
                title: "Anxiety Episode",
                content: "Had a panic attack at the grocery store. Used the 5-4-3-2-1 technique and it helped ground me. Still shaky but proud I got through it.",
                mood: .anxious,
                tags: ["anxiety", "panic", "coping"]
            ),
            createSampleEntry(
                daysAgo: 5,
                title: "Therapy Insights",
                content: "My therapist helped me recognize patterns in my anxiety triggers. Journaling here has made it easier to identify these patterns.",
                mood: .calm,
                tags: ["therapy", "insights", "patterns"]
            )
        ]
        
        journalEntries = sampleEntries
        persistEntries()
    }
    
    private func createSampleEntry(daysAgo: Int, title: String, content: String, mood: MoodType, tags: [String], isFavorite: Bool = false) -> JournalEntry {
        var entry = JournalEntry(
            userId: UUID(),
            title: title,
            content: content,
            type: .tagged
        )
        entry.mood = mood
        entry.tags = tags
        entry.isFavorite = isFavorite
        
        // Adjust creation date
        if daysAgo > 0 {
            let calendar = Calendar.current
            if let _ = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) {
                // Use mirror to set read-only property for demo data
                let mirror = Mirror(reflecting: entry)
                for child in mirror.children {
                    if child.label == "createdAt" {
                        // This is a workaround for demo data - in production, dates are set at creation
                    }
                }
            }
        }
        
        return entry
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