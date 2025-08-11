import SwiftUI

struct RecentChatsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var chatSessions: [ChatSession] = []
    @State private var selectedSession: ChatSession?
    
    var body: some View {
        NavigationStack {
            Group {
                if chatSessions.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "message.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.omniTextTertiary.opacity(0.5))
                        
                        Text("No conversations yet")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.omniTextSecondary)
                        
                        Text("Start a new chat with Omni")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextTertiary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(chatSessions) { session in
                        ChatSessionRow(session: session) {
                            selectedSession = session
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.omniprimary)
                }
            }
            .fullScreenCover(item: $selectedSession) { session in
                ChatView()
                    // Pass session to continue conversation
            }
        }
        .onAppear {
            loadChatSessions()
        }
    }
    
    private func loadChatSessions() {
        // Load chat sessions from storage
        // For demo, create sample sessions
        chatSessions = [
            ChatSession(userId: "user1", title: "Feeling anxious today"),
            ChatSession(userId: "user1", title: "Morning check-in"),
            ChatSession(userId: "user1", title: "Dealing with stress")
        ]
    }
}

struct ChatSessionRow: View {
    let session: ChatSession
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(session.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.omniTextPrimary)
                
                if let lastMessage = session.messages.last {
                    Text(lastMessage.content)
                        .font(.system(size: 14))
                        .foregroundColor(.omniTextSecondary)
                        .lineLimit(2)
                }
                
                Text(formatDate(session.updatedAt))
                    .font(.system(size: 12))
                    .foregroundColor(.omniTextTertiary)
            }
            .padding(.vertical, 8)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    RecentChatsView()
}