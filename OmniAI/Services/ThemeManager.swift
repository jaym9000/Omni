import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("useSystemTheme") var useSystemTheme = true
    
    var currentColorScheme: ColorScheme? {
        useSystemTheme ? nil : (isDarkMode ? .dark : .light)
    }
}

// MARK: - Color Palette
extension Color {
    // Primary Colors - Light Blue Theme
    static let omniprimary = Color(hex: "6BA6CD")
    static let omnisecondary = Color(hex: "8BC1D8")
    
    // Background Colors
    static let omniBackground = Color(UIColor.systemBackground)
    static let omniSecondaryBackground = Color(UIColor.secondarySystemBackground)
    static let omniTertiaryBackground = Color(UIColor.tertiarySystemBackground)
    
    // Text Colors
    static let omniTextPrimary = Color(UIColor.label)
    static let omniTextSecondary = Color(UIColor.secondaryLabel)
    static let omniTextTertiary = Color(UIColor.tertiaryLabel)
    
    // Card Colors
    static let omniCardBeige = Color(hex: "F5F1E8")
    static let omniCardBeigeDark = Color(hex: "2C2A26")
    
    // Mood Colors
    static let moodHappy = Color(hex: "FFD700")
    static let moodAnxious = Color(hex: "FF6B6B")
    static let moodSad = Color(hex: "6495ED")
    static let moodOverwhelmed = Color(hex: "FF8C00")
    static let moodCalm = Color(hex: "98D8C8")
    
    // Status Colors
    static let omniSuccess = Color(hex: "4CAF50")
    static let omniWarning = Color(hex: "FFC107")
    static let omniError = Color(hex: "F44336")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct Typography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - Spacing
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    
    static let minimumTouchSize: CGFloat = 44
}