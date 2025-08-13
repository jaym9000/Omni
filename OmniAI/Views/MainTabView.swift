import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var premiumManager: PremiumManager
    @State private var selectedTab = 0
    @State private var tabIconScales: [Int: CGFloat] = [0: 1.0, 1: 1.0, 2: 1.0]
    
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
        .accentColor(.omniPrimary)
        .onChange(of: selectedTab) { newTab in
            animateTabSelection(newTab)
        }
    }
    
    private func animateTabSelection(_ newTab: Int) {
        // Animate tab icon bounce
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            tabIconScales[newTab] = 1.2
        }
        
        // Return to normal size
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.1)) {
            tabIconScales[newTab] = 1.0
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(PremiumManager())
        .environmentObject(AuthenticationManager())
        .environmentObject(ThemeManager())
}