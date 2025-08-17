import Supabase
import Foundation

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://rchropdkyqpfyjwgdudv.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjaHJvcGRreXFwZnlqd2dkdWR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwNDQxNjcsImV4cCI6MjA3MDYyMDE2N30.ZfHFGnqY9XaPqV9oMnxScE4Wuj7dWBLe-NHHQ8GAzaw",
            options: SupabaseClientOptions(
                db: .init(schema: "public"),
                auth: .init(
                    flowType: .pkce,
                    autoRefreshToken: true
                ),
                global: .init(
                    headers: ["x-client-info": "omni-ai-ios/1.1"]
                )
            )
        )
    }
    
    // MARK: - Connection Status
    @MainActor @Published var isConnected = true
    @MainActor @Published var lastSyncTime: Date?
    
    func checkConnection() async {
        do {
            // Simple health check by querying auth state
            _ = try await client.auth.user()
            await MainActor.run {
                self.isConnected = true
                self.lastSyncTime = Date()
            }
        } catch {
            await MainActor.run {
                self.isConnected = false
            }
        }
    }
}