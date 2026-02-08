import SwiftUI
import UIKit

/// PocketPaws Design System Tokens
/// Defined based on the brand's playful and organic visual identity.
enum DesignTokens {
    
    // MARK: - Colors
    struct Colors {
        static let backgroundGradient = [
            Color(hex: "#E0F7FA"),
            Color(hex: "#B2EBF2"),
            Color(hex: "#80DEEA"),
            Color(hex: "#4DD0E1"),
            Color(hex: "#26C6DA"),
            Color(hex: "#00BCD4")
        ]
        static let surface = Color(hex: "#FFFDF4")
        static let primary = Color(hex: "#4D8ECA")
        static let secondary = Color(hex: "#7FD2EE")
        static let textPrimary = Color(hex: "#2E3448")
        static let textSecondary = Color(hex: "#6D7488")
        static let border = Color(hex: "#E8DFC8")
        static let dock = Color(hex: "#C4E5EB")
        static let waveTop = Color(hex: "#95D6E4")
        static let waveBottom = Color(hex: "#73C7DE")
        static let cardMint = Color(hex: "#DDEBC1")
        static let cardPeach = Color(hex: "#F8D9BD")
        static let cardLilac = Color(hex: "#D9D4F5")
        static let accentSuccess = Color(hex: "#79B95B")
        static let accentWarning = Color(hex: "#F4B26D")
        static let accentDestructive = Color(hex: "#F07A86")
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
        static let title = Font.system(size: 42, weight: .black, design: .rounded)
        static let headline = Font.system(size: 22, weight: .heavy, design: .rounded)
        static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = Font.system(size: 12, weight: .semibold, design: .rounded)
        static let pixel = retro(size: 11, weight: .medium)
        static let pixelTitle = retro(size: 24, weight: .bold)
        static let pixelBody = retro(size: 14, weight: .regular)
        
        static let branding = Font.system(size: 28, weight: .heavy, design: .rounded)
        
        private static func retro(size: CGFloat, weight: Font.Weight) -> Font {
            // Uses custom pixel font when available in project, otherwise a built-in monospaced fallback.
            let candidates = ["PressStart2P-Regular", "Silkscreen-Regular", "Pixellari"]
            for fontName in candidates where UIFont(name: fontName, size: size) != nil {
                return .custom(fontName, size: size)
            }
            return .system(size: size, weight: weight, design: .monospaced)
        }
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
