import SwiftUI

/// PocketPaws Design System Tokens
/// Defined based on the brand's playful and organic visual identity.
enum DesignTokens {
    
    // MARK: - Colors
    struct Colors {
        static let backgroundGradient = [Color(hex: "#FDFCF0"), Color(hex: "#E2F2D5")]
        static let surface = Color(hex: "#FFFFFF")
        static let primary = Color(hex: "#97B476")
        static let secondary = Color(hex: "#B199F9")
        static let textPrimary = Color(hex: "#1D2939")
        static let textSecondary = Color(hex: "#667085")
        static let border = Color(hex: "#F2F4F7")
        static let accentSuccess = Color(hex: "#97B476")
        static let accentWarning = Color(hex: "#FFD666")
        static let accentDestructive = Color(hex: "#FF99C8")
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // MARK: - Radius
    struct Radius {
        static let s: CGFloat = 8
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let pill: CGFloat = 999
        static let circle: CGFloat = 500
    }
    
    // MARK: - Typography
    struct Typography {
        static let title = Font.system(size: 34, weight: .bold, design: .rounded)
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .medium, design: .rounded)
        
        // Custom branding font (Optional implementation)
        static let branding = Font.system(size: 24, weight: .bold, design: .monospaced)
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let softRadius: CGFloat = 4
        static let softOpacity: Double = 0.06
        static let softOffset = CGPoint(x: 0, y: 2)
        
        static let mediumRadius: CGFloat = 12
        static let mediumOpacity: Double = 0.12
        static let mediumOffset = CGPoint(x: 0, y: 6)
    }
}

// MARK: - Color Hex Extension
extension Color {
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
