import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            JournalView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .environment(\.horizontalSizeClass, .compact)
        .environment(\.verticalSizeClass, .regular)
        .accentColor(.omniprimary)
    }
}

#Preview {
    MainTabView()
        .environmentObject(PremiumManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
}