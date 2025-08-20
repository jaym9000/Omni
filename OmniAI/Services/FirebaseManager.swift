import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
import FirebaseFunctions

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
            "createdAt": user.createdAt ?? Date(),
            "lastActiveAt": Date(),
            "biometricEnabled": user.biometricEnabled,
            "notificationsEnabled": user.notificationsEnabled,
            "dailyReminder": user.dailyReminder,
            "authProvider": user.authProvider.rawValue
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
        return user
    }
    
    // MARK: - Chat Management
    
    /// Save chat session to Firestore
    func saveChatSession(_ session: ChatSession) async throws {
        let sessionRef = firestore.collection(chatSessionsCollection).document(session.id.uuidString)
        
        let sessionData: [String: Any] = [
            "id": session.id.uuidString,
            "userId": session.userId.uuidString,
            "title": session.title,
            "createdAt": session.createdAt,
            "updatedAt": session.updatedAt,
            "messageCount": session.messageCount,
            "lastMessage": session.lastMessage ?? ""
        ]
        
        try await sessionRef.setData(sessionData, merge: true)
    }
    
    /// Fetch chat sessions for a user
    func fetchChatSessions(userId: String) async throws -> [ChatSession] {
        let snapshot = try await firestore.collection(chatSessionsCollection)
            .whereField("userId", isEqualTo: userId)
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
        
        // Update session's last message and timestamp
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