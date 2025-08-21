import SwiftUI
import UIKit

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
                    // Skeleton loading view for better UX
                    VStack(spacing: 0) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonChatRow()
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.top)
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
                        
                        Button(action: { 
                            dismiss()
                            // Post notification to open chat
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                NotificationCenter.default.post(
                                    name: NSNotification.Name("OpenChatFromHistory"),
                                    object: nil
                                )
                            }
                        }) {
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
            .sheet(isPresented: $showCalendarView) {
                ChatHistoryCalendarView(selectedDate: $selectedDate, chatSessions: chatSessions)
            }
        }
        .onAppear {
            loadChatSessions()
        }
        .refreshable {
            await loadChatSessionsAsync()
        }
    }
    
    private func loadChatSessions() {
        Task {
            await loadChatSessionsAsync()
        }
    }
    
    private func loadChatSessionsAsync() async {
        isLoading = true
        guard let userId = authManager.currentUser?.id else {
            isLoading = false
            return
        }
        
        print("🔄 Refreshing chat sessions for user: \(userId)")
        await chatService.loadUserSessions(userId: userId)
        
        await MainActor.run {
            chatSessions = chatService.chatSessions
            isLoading = false
            print("📱 UI Updated with \(chatSessions.count) sessions")
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
        // Haptic feedback for deletion
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Optimistically remove from UI first for smooth animation
        withAnimation(.easeOut(duration: 0.3)) {
            for index in offsets {
                if let sessionIndex = chatSessions.firstIndex(where: { $0.id == sessions[index].id }) {
                    chatSessions.remove(at: sessionIndex)
                }
            }
        }
        
        // Then delete from Firebase in background
        Task {
            for index in offsets {
                await chatService.deleteSession(sessions[index])
            }
            // Reload to ensure sync with Firebase
            await loadChatSessionsAsync()
        }
    }
}

struct ChatSessionRow: View {
    let session: ChatSession
    let action: () -> Void
    
    private func timeAgo(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "1d" : "\(days)d"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1h" : "\(hours)h"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1m" : "\(minutes)m"
        } else {
            return "now"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Avatar circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.omniPrimary.opacity(0.8), Color.omniSecondary.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(session.title.prefix(1).uppercased())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.omniTextPrimary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(timeAgo(session.updatedAt))
                            .font(.system(size: 13))
                            .foregroundColor(.omniTextTertiary)
                    }
                    
                    if let lastMessage = session.lastMessage {
                        Text(lastMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("No messages yet")
                            .font(.system(size: 14))
                            .foregroundColor(.omniTextTertiary)
                            .italic()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Skeleton Loading View
struct SkeletonChatRow: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 16)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.white.opacity(0.3), Color.clear]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: isAnimating ? 200 : -200)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                )
            
            // Content skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 280, height: 14)
            
            // Date skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.15))
                .frame(width: 100, height: 12)
        }
        .padding(.vertical, 8)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    RecentChatsView()
}