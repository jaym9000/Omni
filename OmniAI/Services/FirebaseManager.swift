import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseFunctions
import UIKit

/// Centralized Firebase manager for all Firebase services
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    // Firebase services
    let auth: Auth
    let firestore: Firestore
    let storage: Storage
    let functions: Functions
    
    // Firestore collections
    let usersCollection = "users"
    let chatSessionsCollection = "chat_sessions"
    let messagesCollection = "messages"
    let journalEntriesCollection = "journal_entries"
    let moodEntriesCollection = "mood_entries"
    
    private init() {
        // Initialize Firebase services
        self.auth = Auth.auth()
        self.firestore = Firestore.firestore()
        self.storage = Storage.storage()
        self.functions = Functions.functions()
        
        // Configure Firestore settings
        let settings = FirestoreSettings()
        // Persistence is enabled by default in Firebase 10+
        // Cache size is also set to unlimited by default
        firestore.settings = settings
        
        // Enable offline persistence
        firestore.enableNetwork { error in
            if let error = error {
                print("❌ Error enabling Firestore network: \(error)")
            } else {
                print("✅ Firestore network enabled")
            }
        }
        
        print("🔥 FirebaseManager initialized")
    }
    
    // MARK: - User Management
    
    /// Create or update user document in Firestore
    func saveUser(_ user: User) async throws {
        // Use the Firebase Auth UID as the document ID
        let documentId = user.authUserId ?? user.id.uuidString
        let userRef = firestore.collection(usersCollection).document(documentId)
        
        let userData: [String: Any] = [
            "id": user.id.uuidString,
            "authUserId": user.authUserId ?? "",
            "email": user.email,
            "displayName": user.displayName,
            "avatarImageName": user.avatarImageName ?? "",
            "isPremium": user.isPremium,
            "isGuest": user.isGuest,
            "createdAt": user.createdAt,
            "lastActiveAt": Date(),
            "biometricEnabled": user.biometricEnabled,
            "notificationsEnabled": user.notificationsEnabled,
            "dailyReminder": user.dailyReminder,
            "authProvider": user.authProvider.rawValue,
            "hasCompletedOnboarding": user.hasCompletedOnboarding,
            "companionName": user.companionName,
            "companionPersonality": user.companionPersonality
        ]
        
        try await userRef.setData(userData, merge: true)
    }
    
    /// Fetch user from Firestore
    func fetchUser(userId: String) async throws -> User? {
        let userRef = firestore.collection(usersCollection).document(userId)
        let document = try await userRef.getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        var user = User(
            id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
            authUserId: data["authUserId"] as? String,
            email: data["email"] as? String ?? "",
            displayName: data["displayName"] as? String ?? "",
            emailVerified: data["emailVerified"] as? Bool ?? false,
            authProvider: AuthProvider(rawValue: data["authProvider"] as? String ?? "email") ?? .email
        )
        user.avatarImageName = data["avatarImageName"] as? String
        user.isPremium = data["isPremium"] as? Bool ?? false
        user.isGuest = data["isGuest"] as? Bool ?? false
        user.biometricEnabled = data["biometricEnabled"] as? Bool ?? false
        user.notificationsEnabled = data["notificationsEnabled"] as? Bool ?? false
        user.dailyReminder = data["dailyReminder"] as? Bool ?? true
        user.hasCompletedOnboarding = data["hasCompletedOnboarding"] as? Bool ?? false
        user.companionName = data["companionName"] as? String ?? "Omni"
        user.companionPersonality = data["companionPersonality"] as? String ?? "supportive"
        return user
    }
    
    // MARK: - Chat Management
    
    /// Save chat session to Firestore
    func saveChatSession(_ session: ChatSession, authUserId: String) async throws {
        let sessionRef = firestore.collection(chatSessionsCollection).document(session.id.uuidString)
        
        let sessionData: [String: Any] = [
            "id": session.id.uuidString,
            "userId": session.userId.uuidString,  // Keep for backward compatibility
            "authUserId": authUserId,  // Add Firebase Auth UID for security rules
            "title": session.title,
            "createdAt": session.createdAt,
            "updatedAt": session.updatedAt,
            "messageCount": session.messageCount,
            "lastMessage": session.lastMessage ?? ""
        ]
        
        try await sessionRef.setData(sessionData, merge: true)
    }
    
    /// Delete a chat session and all its messages
    func deleteChatSession(sessionId: String) async throws {
        // Delete all messages in the session first
        let messagesRef = firestore.collection(chatSessionsCollection)
            .document(sessionId)
            .collection("messages")
        
        let messagesSnapshot = try await messagesRef.getDocuments()
        
        // Delete all messages
        for document in messagesSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete the session document
        let sessionRef = firestore.collection(chatSessionsCollection).document(sessionId)
        try await sessionRef.delete()
    }
    
    /// Fetch chat sessions for a user by Firebase Auth UID
    func fetchChatSessions(authUserId: String) async throws -> [ChatSession] {
        // Only query by authUserId field - must match security rules exactly
        let snapshot = try await firestore.collection(chatSessionsCollection)
            .whereField("authUserId", isEqualTo: authUserId)
            .order(by: "updatedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            return ChatSession(
                id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                userId: UUID(uuidString: data["userId"] as? String ?? "") ?? UUID(),
                title: data["title"] as? String ?? "Untitled Chat",
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date(),
                messageCount: data["messageCount"] as? Int ?? 0,
                lastMessage: data["lastMessage"] as? String
            )
        }
    }
    
    /// Save chat message to Firestore
    func saveChatMessage(_ message: FirebaseMessage, sessionId: String) async throws {
        let messageRef = firestore
            .collection(chatSessionsCollection)
            .document(sessionId)
            .collection(messagesCollection)
            .document(message.id.uuidString)
        
        let messageData: [String: Any] = [
            "id": message.id.uuidString,
            "content": message.content,
            "role": message.role.rawValue,
            "timestamp": message.timestamp,
            "mood": message.mood ?? ""
        ]
        
        try await messageRef.setData(messageData)
        
        // Update session's last message
        let sessionRef = firestore.collection(chatSessionsCollection).document(sessionId)
        try await sessionRef.updateData([
            "lastMessage": message.content,
            "updatedAt": Date(),
            "messageCount": FieldValue.increment(Int64(1))
        ])
    }
    
    /// Fetch messages for a chat session
    func fetchMessages(sessionId: String) async throws -> [FirebaseMessage] {
        let snapshot = try await firestore
            .collection(chatSessionsCollection)
            .document(sessionId)
            .collection(messagesCollection)
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            
            return FirebaseMessage(
                id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                content: data["content"] as? String ?? "",
                role: FirebaseMessage.Role(rawValue: data["role"] as? String ?? "user") ?? .user,
                timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                mood: data["mood"] as? String
            )
        }
    }
    
    // MARK: - Real-time Listeners
    
    /// Listen to chat messages in real-time
    func listenToMessages(sessionId: String, completion: @escaping ([FirebaseMessage]) -> Void) -> ListenerRegistration {
        return firestore
            .collection(chatSessionsCollection)
            .document(sessionId)
            .collection(messagesCollection)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching messages: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let messages = documents.compactMap { document -> FirebaseMessage? in
                    let data = document.data()
                    
                    return FirebaseMessage(
                        id: UUID(uuidString: data["id"] as? String ?? "") ?? UUID(),
                        content: data["content"] as? String ?? "",
                        role: FirebaseMessage.Role(rawValue: data["role"] as? String ?? "user") ?? .user,
                        timestamp: (data["timestamp"] as? Timestamp)?.dateValue() ?? Date(),
                        mood: data["mood"] as? String
                    )
                }
                
                completion(messages)
            }
    }
    
    // MARK: - Mood Management
    
    /// Save mood entry to Firestore
    func saveMoodEntry(_ entry: MoodEntry, authUserId: String) async throws {
        let entryRef = firestore.collection(moodEntriesCollection).document(entry.id.uuidString)
        
        let entryData: [String: Any] = [
            "id": entry.id.uuidString,
            "userId": entry.userId.uuidString,
            "authUserId": authUserId,
            "mood": entry.mood.rawValue,
            "note": entry.note ?? "",
            "timestamp": entry.timestamp
        ]
        
        try await entryRef.setData(entryData)
    }
    
    /// Fetch mood entries for a user
    func fetchMoodEntries(authUserId: String) async throws -> [MoodEntry] {
        let snapshot = try await firestore.collection(moodEntriesCollection)
            .whereField("authUserId", isEqualTo: authUserId)
            .order(by: "timestamp", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            var entry = MoodEntry(
                userId: UUID(uuidString: data["userId"] as? String ?? "") ?? UUID(),
                mood: MoodType(rawValue: data["mood"] as? String ?? "calm") ?? .calm,
                note: data["note"] as? String
            )
            entry.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            return entry
        }
    }
    
    /// Listen to mood entries in real-time
    func listenToMoodEntries(authUserId: String, completion: @escaping ([MoodEntry]) -> Void) -> ListenerRegistration {
        return firestore.collection(moodEntriesCollection)
            .whereField("authUserId", isEqualTo: authUserId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching mood entries: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let entries = documents.compactMap { document -> MoodEntry? in
                    let data = document.data()
                    var entry = MoodEntry(
                        userId: UUID(uuidString: data["userId"] as? String ?? "") ?? UUID(),
                        mood: MoodType(rawValue: data["mood"] as? String ?? "calm") ?? .calm,
                        note: data["note"] as? String
                    )
                    entry.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                    return entry
                }
                
                completion(entries)
            }
    }
    
    /// Update mood entry
    func updateMoodEntry(_ entry: MoodEntry, authUserId: String) async throws {
        let entryRef = firestore.collection(moodEntriesCollection).document(entry.id.uuidString)
        
        try await entryRef.updateData([
            "note": entry.note as Any,
            "updatedAt": Date()
        ])
    }
    
    /// Delete mood entry
    func deleteMoodEntry(entryId: String, authUserId: String) async throws {
        let entryRef = firestore.collection(moodEntriesCollection).document(entryId)
        try await entryRef.delete()
    }
    
    /// Get latest mood for context
    func getLatestMood(authUserId: String) async throws -> MoodEntry? {
        let snapshot = try await firestore.collection(moodEntriesCollection)
            .whereField("authUserId", isEqualTo: authUserId)
            .order(by: "timestamp", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        
        let data = document.data()
        var entry = MoodEntry(
            userId: UUID(uuidString: data["userId"] as? String ?? "") ?? UUID(),
            mood: MoodType(rawValue: data["mood"] as? String ?? "calm") ?? .calm,
            note: data["note"] as? String
        )
        entry.timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        return entry
    }
    
    // MARK: - Journal Management
    
    /// Save journal entry to Firestore
    func saveJournalEntry(_ entry: JournalEntry, authUserId: String) async throws {
        let entryRef = firestore.collection(journalEntriesCollection).document(entry.id.uuidString)
        
        let entryData: [String: Any] = [
            "id": entry.id.uuidString,
            "userId": entry.userId.uuidString,
            "authUserId": authUserId,
            "type": entry.type.rawValue,
            "title": entry.title,
            "content": entry.content,
            "mood": entry.mood?.rawValue ?? "",
            "tags": entry.tags,
            "isFavorite": entry.isFavorite,
            "createdAt": entry.createdAt,
            "updatedAt": entry.updatedAt,
            "prompt": entry.prompt ?? ""
        ]
        
        try await entryRef.setData(entryData, merge: true)
    }
    
    /// Fetch journal entries for a user
    func fetchJournalEntries(authUserId: String) async throws -> [JournalEntry] {
        let snapshot = try await firestore.collection(journalEntriesCollection)
            .whereField("authUserId", isEqualTo: authUserId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            var entry = JournalEntry(
                userId: UUID(uuidString: data["userId"] as? String ?? "") ?? UUID(),
                title: data["title"] as? String ?? "",
                content: data["content"] as? String ?? "",
                type: JournalType(rawValue: data["type"] as? String ?? "freeForm") ?? .freeForm
            )
            entry.mood = MoodType(rawValue: data["mood"] as? String ?? "")
            entry.tags = data["tags"] as? [String] ?? []
            entry.isFavorite = data["isFavorite"] as? Bool ?? false
            entry.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            entry.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
            entry.prompt = data["prompt"] as? String
            return entry
        }
    }
    
    /// Listen to journal entries in real-time
    func listenToJournalEntries(authUserId: String, completion: @escaping ([JournalEntry]) -> Void) -> ListenerRegistration {
        return firestore.collection(journalEntriesCollection)
            .whereField("authUserId", isEqualTo: authUserId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching journal entries: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let entries = documents.compactMap { document -> JournalEntry? in
                    let data = document.data()
                    var entry = JournalEntry(
                        userId: UUID(uuidString: data["userId"] as? String ?? "") ?? UUID(),
                        title: data["title"] as? String ?? "",
                        content: data["content"] as? String ?? "",
                        type: JournalType(rawValue: data["type"] as? String ?? "freeForm") ?? .freeForm
                    )
                    entry.mood = MoodType(rawValue: data["mood"] as? String ?? "")
                    entry.tags = data["tags"] as? [String] ?? []
                    entry.isFavorite = data["isFavorite"] as? Bool ?? false
                    entry.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    entry.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    entry.prompt = data["prompt"] as? String
                    return entry
                }
                
                completion(entries)
            }
    }
    
    /// Update journal entry
    func updateJournalEntry(_ entry: JournalEntry, authUserId: String) async throws {
        let entryRef = firestore.collection(journalEntriesCollection).document(entry.id.uuidString)
        
        let updateData: [String: Any] = [
            "title": entry.title,
            "content": entry.content,
            "tags": entry.tags,
            "isFavorite": entry.isFavorite,
            "updatedAt": Date()
        ]
        
        try await entryRef.updateData(updateData)
    }
    
    /// Delete journal entry
    func deleteJournalEntry(entryId: String, authUserId: String) async throws {
        let entryRef = firestore.collection(journalEntriesCollection).document(entryId)
        try await entryRef.delete()
    }
    
    /// Search journal entries
    func searchJournalEntries(authUserId: String, searchText: String) async throws -> [JournalEntry] {
        // Note: For full-text search, consider using Algolia or Cloud Functions
        // This is a basic implementation that searches titles
        let entries = try await fetchJournalEntries(authUserId: authUserId)
        
        let searchLower = searchText.lowercased()
        return entries.filter { entry in
            entry.title.lowercased().contains(searchLower) ||
            entry.content.lowercased().contains(searchLower) ||
            entry.tags.contains { $0.lowercased().contains(searchLower) }
        }
    }
    
    // MARK: - Error Handling
    
    enum FirebaseError: LocalizedError {
        case userNotFound
        case sessionNotFound
        case networkError
        case permissionDenied
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .userNotFound:
                return "User not found in database"
            case .sessionNotFound:
                return "Chat session not found"
            case .networkError:
                return "Network connection error. Please check your internet connection."
            case .permissionDenied:
                return "You don't have permission to access this data"
            case .unknown(let message):
                return message
            }
        }
    }
    
    // MARK: - Data Privacy & User Control
    
    /// Delete all user data (for PIPEDA compliance)
    func deleteAllUserData(userId: String) async throws {
        
        // Delete all chat sessions
        let sessionsSnapshot = try await firestore
            .collection(chatSessionsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for document in sessionsSnapshot.documents {
            // Delete all messages in the session
            let messagesSnapshot = try await firestore
                .collection(chatSessionsCollection)
                .document(document.documentID)
                .collection(messagesCollection)
                .getDocuments()
            
            for messageDoc in messagesSnapshot.documents {
                try await messageDoc.reference.delete()
            }
            
            // Delete the session itself
            try await document.reference.delete()
        }
        
        // Delete user document
        try await firestore.collection(usersCollection).document(userId).delete()
        
        // Delete mood entries
        let moodSnapshot = try await firestore
            .collection(moodEntriesCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for document in moodSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete journal entries
        let journalSnapshot = try await firestore
            .collection(journalEntriesCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        for document in journalSnapshot.documents {
            try await document.reference.delete()
        }
    }
    
    /// Delete a specific chat session
    func deleteChatSession(sessionId: String, userId: String) async throws {
        
        // Verify user owns this session
        let sessionDoc = try await firestore
            .collection(chatSessionsCollection)
            .document(sessionId)
            .getDocument()
        
        guard let data = sessionDoc.data(),
              data["userId"] as? String == userId else {
            throw NSError(domain: "FirebaseManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        
        // Delete all messages in the session
        let messagesSnapshot = try await firestore
            .collection(chatSessionsCollection)
            .document(sessionId)
            .collection(messagesCollection)
            .getDocuments()
        
        for document in messagesSnapshot.documents {
            try await document.reference.delete()
        }
        
        // Delete the session
        try await sessionDoc.reference.delete()
    }
    
    /// Export all user data (for PIPEDA compliance - data portability)
    func exportUserData(userId: String) async throws -> [String: Any] {
        var exportData: [String: Any] = [:]
        
        // Export user profile
        let userDoc = try await firestore.collection(usersCollection).document(userId).getDocument()
        if let userData = userDoc.data() {
            exportData["profile"] = userData
        }
        
        // Export chat sessions and messages
        let sessionsSnapshot = try await firestore
            .collection(chatSessionsCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        var sessions: [[String: Any]] = []
        for sessionDoc in sessionsSnapshot.documents {
            var sessionData = sessionDoc.data()
            
            // Get messages for this session
            let messagesSnapshot = try await firestore
                .collection(chatSessionsCollection)
                .document(sessionDoc.documentID)
                .collection(messagesCollection)
                .order(by: "timestamp", descending: false)
                .getDocuments()
            
            var messages: [[String: Any]] = []
            
            for messageDoc in messagesSnapshot.documents {
                let messageData = messageDoc.data()
                messages.append(messageData)
            }
            
            sessionData["messages"] = messages
            sessions.append(sessionData)
        }
        exportData["chatSessions"] = sessions
        
        // Export mood entries
        let moodSnapshot = try await firestore
            .collection(moodEntriesCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        exportData["moodEntries"] = moodSnapshot.documents.map { $0.data() }
        
        // Export journal entries
        let journalSnapshot = try await firestore
            .collection(journalEntriesCollection)
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        exportData["journalEntries"] = journalSnapshot.documents.map { $0.data() }
        
        // Add export metadata
        exportData["exportMetadata"] = [
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "dataFormat": "JSON",
            "encryptionNote": "All encrypted messages have been decrypted for this export"
        ]
        
        return exportData
    }
}

// MARK: - Firebase Message Model for Firestore
// Using a different name to avoid conflict with app's ChatMessage

struct FirebaseMessage: Identifiable, Codable {
    enum Role: String, Codable {
        case user
        case assistant
        case system
    }
    
    let id: UUID
    let content: String
    let role: Role
    let timestamp: Date
    let mood: String?
    
    init(id: UUID = UUID(), content: String, role: Role, timestamp: Date = Date(), mood: String? = nil) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
        self.mood = mood
    }
}