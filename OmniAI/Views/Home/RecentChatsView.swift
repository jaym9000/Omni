import SwiftUI

struct RecentChatsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var chatService: ChatService
    @State private var chatSessions: [ChatSession] = []
    @State private var selectedSession: ChatSession?
    @State private var showCalendarView = false
    @State private var isLoading = true
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if chatSessions.isEmpty {
                    // Empty state
                    VStack(spacing: 24) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.omniPrimary.opacity(0.6), Color.omniSecondary.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(spacing: 8) {
                            Text("No chat history yet")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.omniTextPrimary)
                            
                            Text("Start a conversation with Omni")
                                .font(.system(size: 15))
                                .foregroundColor(.omniTextSecondary)
                            
                            Text("Your chats will appear here")
                                .font(.system(size: 13))
                                .foregroundColor(.omniTextTertiary)
                        }
                        
                        Button(action: { dismiss() }) {
                            Text("Start Your First Chat")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.omniPrimary, Color.omniSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(groupedSessions(), id: \.key) { group in
                            Section(header: Text(group.key)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.omniTextSecondary)) {
                                ForEach(group.sessions) { session in
                                    ChatSessionRow(session: session) {
                                        selectedSession = session
                                    }
                                }
                                .onDelete { indexSet in
                                    deleteSession(from: group.sessions, at: indexSet)
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showCalendarView = true }) {
                        Image(systemName: "calendar")
                            .foregroundColor(.omniPrimary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.omniPrimary)
                }
            }
            .fullScreenCover(item: $selectedSession) { session in
                ChatView(existingSessionId: session.id)
                    .environmentObject(authManager)
                    .environmentObject(chatService)
            }
            // Calendar view will be added after adding file to Xcode project
            // .sheet(isPresented: $showCalendarView) {
            //     ChatHistoryCalendarView(selectedDate: $selectedDate, chatSessions: chatSessions)
            // }
        }
        .onAppear {
            loadChatSessions()
        }
    }
    
    private func loadChatSessions() {
        Task {
            isLoading = true
            guard let userId = authManager.currentUser?.id else {
                isLoading = false
                return
            }
            
            await chatService.loadUserSessions(userId: userId)
            
            await MainActor.run {
                chatSessions = chatService.chatSessions
                isLoading = false
            }
        }
    }
    
    private func groupedSessions() -> [(key: String, sessions: [ChatSession])] {
        let calendar = Calendar.current
        let now = Date()
        
        var groups: [(String, [ChatSession])] = []
        
        // Today
        let todaySessions = chatSessions.filter { calendar.isDateInToday($0.updatedAt) }
        if !todaySessions.isEmpty {
            groups.append(("Today", todaySessions))
        }
        
        // Yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let yesterdaySessions = chatSessions.filter { calendar.isDate($0.updatedAt, inSameDayAs: yesterday) }
        if !yesterdaySessions.isEmpty {
            groups.append(("Yesterday", yesterdaySessions))
        }
        
        // This Week
        let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        let thisWeekSessions = chatSessions.filter {
            $0.updatedAt > weekAgo &&
            !calendar.isDateInToday($0.updatedAt) &&
            !calendar.isDate($0.updatedAt, inSameDayAs: yesterday)
        }
        if !thisWeekSessions.isEmpty {
            groups.append(("This Week", thisWeekSessions))
        }
        
        // Older
        let olderSessions = chatSessions.filter { $0.updatedAt <= weekAgo }
        if !olderSessions.isEmpty {
            groups.append(("Older", olderSessions))
        }
        
        return groups
    }
    
    private func deleteSession(from sessions: [ChatSession], at offsets: IndexSet) {
        Task {
            for index in offsets {
                await chatService.deleteSession(sessions[index])
            }
            loadChatSessions()
        }
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