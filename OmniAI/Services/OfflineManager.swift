import Foundation
import SwiftUI
import Network

@MainActor
class OfflineManager: ObservableObject {
    @Published var isOnline = true
    @Published var hasPendingSync = false
    @Published var lastSyncTime: Date?
    
    private let userDefaults = UserDefaults.standard
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    // MARK: - Connection Monitoring
    
    func startMonitoring() {
        // Monitor network connectivity using Network framework
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isOnline = path.status == .satisfied
                
                if self?.isOnline == true && self?.hasPendingSync == true {
                    await self?.syncPendingData()
                }
            }
        }
        
        monitor.start(queue: queue)
        
        // Set up periodic sync check
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.checkConnectionStatus()
            }
        }
    }
    
    func checkConnectionStatus() async {
        // Check network status
        // isOnline is already updated by the monitor
        
        if isOnline && hasPendingSync {
            await syncPendingData()
        }
    }
    
    // MARK: - Offline Data Storage
    
    func saveOfflineData<T: Codable>(_ data: T, key: String) {
        do {
            let encoded = try JSONEncoder().encode(data)
            userDefaults.set(encoded, forKey: "offline_\(key)")
            hasPendingSync = true
        } catch {
            print("Failed to save offline data: \(error)")
        }
    }
    
    func loadOfflineData<T: Codable>(_ type: T.Type, key: String) -> T? {
        guard let data = userDefaults.data(forKey: "offline_\(key)") else { return nil }
        
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("Failed to load offline data: \(error)")
            return nil
        }
    }
    
    func removeOfflineData(key: String) {
        userDefaults.removeObject(forKey: "offline_\(key)")
    }
    
    // MARK: - Pending Operations Queue
    
    struct PendingOperation: Codable {
        let id: UUID
        let type: OperationType
        let data: Data
        let timestamp: Date
        
        enum OperationType: String, Codable {
            case createUser
            case updateUser
            case createChatSession
            case createChatMessage
            case updateChatSession
            case createMoodEntry
            case createJournalEntry
            case updateJournalEntry
        }
    }
    
    func queueOperation<T: Codable>(_ data: T, type: PendingOperation.OperationType) {
        do {
            let encoded = try JSONEncoder().encode(data)
            let operation = PendingOperation(
                id: UUID(),
                type: type,
                data: encoded,
                timestamp: Date()
            )
            
            var pendingOps = loadPendingOperations()
            pendingOps.append(operation)
            savePendingOperations(pendingOps)
            hasPendingSync = true
        } catch {
            print("Failed to queue operation: \(error)")
        }
    }
    
    private func loadPendingOperations() -> [PendingOperation] {
        guard let data = userDefaults.data(forKey: "pending_operations") else { return [] }
        
        do {
            return try JSONDecoder().decode([PendingOperation].self, from: data)
        } catch {
            print("Failed to load pending operations: \(error)")
            return []
        }
    }
    
    private func savePendingOperations(_ operations: [PendingOperation]) {
        do {
            let encoded = try JSONEncoder().encode(operations)
            userDefaults.set(encoded, forKey: "pending_operations")
        } catch {
            print("Failed to save pending operations: \(error)")
        }
    }
    
    // MARK: - Data Synchronization
    
    func syncPendingData() async {
        guard isOnline else { return }
        
        let pendingOps = loadPendingOperations()
        var completedOps: [UUID] = []
        
        for operation in pendingOps {
            do {
                try await processPendingOperation(operation)
                completedOps.append(operation.id)
            } catch {
                print("Failed to process operation \(operation.id): \(error)")
                // Keep failed operations for retry
            }
        }
        
        // Remove completed operations
        let remainingOps = pendingOps.filter { !completedOps.contains($0.id) }
        savePendingOperations(remainingOps)
        
        hasPendingSync = !remainingOps.isEmpty
        if !hasPendingSync {
            lastSyncTime = Date()
        }
    }
    
    private func processPendingOperation(_ operation: PendingOperation) async throws {
        let supabase = supabaseManager.client
        
        switch operation.type {
        case .createUser:
            let user = try JSONDecoder().decode(User.self, from: operation.data)
            try await supabase
                .from("users")
                .insert(user)
                .execute()
            
        case .updateUser:
            let user = try JSONDecoder().decode(User.self, from: operation.data)
            try await supabase
                .from("users")
                .update(user)
                .eq("id", value: user.id)
                .execute()
            
        case .createChatSession:
            let session = try JSONDecoder().decode(ChatSession.self, from: operation.data)
            try await supabase
                .from("chat_sessions")
                .insert(session)
                .execute()
            
        case .createChatMessage:
            let message = try JSONDecoder().decode(ChatMessage.self, from: operation.data)
            try await supabase
                .from("chat_messages")
                .insert(message)
                .execute()
            
        case .updateChatSession:
            let session = try JSONDecoder().decode(ChatSession.self, from: operation.data)
            try await supabase
                .from("chat_sessions")
                .update(session)
                .eq("id", value: session.id)
                .execute()
            
        case .createMoodEntry:
            let mood = try JSONDecoder().decode(MoodEntry.self, from: operation.data)
            try await supabase
                .from("mood_entries")
                .insert(mood)
                .execute()
            
        case .createJournalEntry:
            let journal = try JSONDecoder().decode(JournalEntry.self, from: operation.data)
            try await supabase
                .from("journal_entries")
                .insert(journal)
                .execute()
            
        case .updateJournalEntry:
            let journal = try JSONDecoder().decode(JournalEntry.self, from: operation.data)
            try await supabase
                .from("journal_entries")
                .update(journal)
                .eq("id", value: journal.id)
                .execute()
        }
    }
    
    // MARK: - Offline Data Management
    
    func saveOfflineMoodEntry(_ mood: MoodEntry) {
        var offlineMoods = loadOfflineMoodEntries()
        offlineMoods.append(mood)
        saveOfflineData(offlineMoods, key: "mood_entries")
        
        if !isOnline {
            queueOperation(mood, type: .createMoodEntry)
        }
    }
    
    func loadOfflineMoodEntries() -> [MoodEntry] {
        return loadOfflineData([MoodEntry].self, key: "mood_entries") ?? []
    }
    
    func saveOfflineJournalEntry(_ journal: JournalEntry) {
        var offlineJournals = loadOfflineJournalEntries()
        if let index = offlineJournals.firstIndex(where: { $0.id == journal.id }) {
            offlineJournals[index] = journal
            queueOperation(journal, type: .updateJournalEntry)
        } else {
            offlineJournals.append(journal)
            queueOperation(journal, type: .createJournalEntry)
        }
        saveOfflineData(offlineJournals, key: "journal_entries")
    }
    
    func loadOfflineJournalEntries() -> [JournalEntry] {
        return loadOfflineData([JournalEntry].self, key: "journal_entries") ?? []
    }
    
    func saveOfflineChatSession(_ session: ChatSession) {
        var offlineSessions = loadOfflineChatSessions()
        if let index = offlineSessions.firstIndex(where: { $0.id == session.id }) {
            offlineSessions[index] = session
            queueOperation(session, type: .updateChatSession)
        } else {
            offlineSessions.append(session)
            queueOperation(session, type: .createChatSession)
        }
        saveOfflineData(offlineSessions, key: "chat_sessions")
    }
    
    func loadOfflineChatSessions() -> [ChatSession] {
        return loadOfflineData([ChatSession].self, key: "chat_sessions") ?? []
    }
    
    func saveOfflineChatMessage(_ message: ChatMessage) {
        var offlineMessages = loadOfflineChatMessages()
        offlineMessages.append(message)
        saveOfflineData(offlineMessages, key: "chat_messages")
        queueOperation(message, type: .createChatMessage)
    }
    
    func loadOfflineChatMessages() -> [ChatMessage] {
        return loadOfflineData([ChatMessage].self, key: "chat_messages") ?? []
    }
    
    // MARK: - Cache Management
    
    func clearOfflineData() {
        let keys = [
            "offline_mood_entries",
            "offline_journal_entries", 
            "offline_chat_sessions",
            "offline_chat_messages",
            "pending_operations"
        ]
        
        for key in keys {
            userDefaults.removeObject(forKey: key)
        }
        
        hasPendingSync = false
        lastSyncTime = nil
    }
    
    func getCacheSize() -> String {
        let keys = [
            "offline_mood_entries",
            "offline_journal_entries",
            "offline_chat_sessions", 
            "offline_chat_messages",
            "pending_operations"
        ]
        
        var totalSize = 0
        for key in keys {
            if let data = userDefaults.data(forKey: key) {
                totalSize += data.count
            }
        }
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(totalSize))
    }
}