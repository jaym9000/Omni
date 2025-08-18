import Supabase
import Foundation

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Read configuration from Info.plist
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              let url = URL(string: supabaseURL),
              let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SupabaseAnonKey") as? String else {
            fatalError("Supabase configuration missing from Info.plist. Please add SupabaseURL and SupabaseAnonKey keys.")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                db: .init(schema: "public"),
                auth: .init(
                    redirectToURL: URL(string: "com.jns.Omni://auth"),
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