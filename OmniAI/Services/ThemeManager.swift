import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode = false
    @AppStorage("useSystemTheme") var useSystemTheme = true
    
    var currentColorScheme: ColorScheme? {
        useSystemTheme ? nil : (isDarkMode ? .dark : .light)
    }
}

// MARK: - Therapeutic Color Palette (Research-Based)
extension Color {
    // Primary Colors - Calming Sage Green (scientifically proven to reduce anxiety)
    static let omniprimary = Color(hex: "7FB069")      // Soft sage green - therapeutic & calming
    static let omnisecondary = Color(hex: "A8C686")    // Lighter sage for accents
    
    // Background Colors - Warm & Nurturing (avoiding clinical white)
    static let omniBackground = Color(hex: "F9F7F4")         // Warm cream instead of stark white
    static let omniSecondaryBackground = Color(hex: "F0EDE8") // Soft beige
    static let omniTertiaryBackground = Color(hex: "E8F4F8")  // Barely-there blue tint
    
    // Text Colors - Softer, warmer grays (less harsh than pure black)
    static let omniTextPrimary = Color(hex: "3A3D42")        // Warm dark gray
    static let omniTextSecondary = Color(hex: "6B7280")      // Medium warm gray  
    static let omniTextTertiary = Color(hex: "9CA3AF")       // Light warm gray
    
    // Card Colors - Therapeutic tones
    static let omniCardBeige = Color(hex: "F0EDE8")          // Soft warm beige
    static let omniCardBeigeDark = Color(hex: "2C2A26")      // Keep for dark mode
    static let omniCardSoftBlue = Color(hex: "E8F4F8")       // Calming blue tint
    static let omniCardLavender = Color(hex: "F0EEFF")       // Stress-reducing lavender
    
    // Therapeutic Mood Colors (muted, non-stimulating)
    static let moodHappy = Color(hex: "F4E5A3")        // Soft warm yellow (less intense)
    static let moodAnxious = Color(hex: "D4A5A5")      // Muted coral (less alarming)
    static let moodSad = Color(hex: "B8D4E3")          // Soft periwinkle blue
    static let moodOverwhelmed = Color(hex: "E5C4A3")  // Muted peach (less intense than orange)
    static let moodCalm = Color(hex: "C4E4C4")         // Gentle sage green
    
    // Status Colors - Softer, less alarming versions
    static let omniSuccess = Color(hex: "7FB069")      // Matches primary green
    static let omniWarning = Color(hex: "E5C4A3")      // Soft amber
    static let omniError = Color(hex: "D4A5A5")        // Muted coral (less harsh)
    
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