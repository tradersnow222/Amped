import SwiftUI

/// ThemeModifier to ensure that dark backgrounds have proper text coloring
struct DeepBackgroundThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Force proper foreground colors for dark backgrounds
            .foregroundColor(.white)
            // Apply dark mode styling to all components
            .colorScheme(.dark)
    }
}

extension View {
    /// Apply the deep background theme modifications
    /// Use this on containers that have the deep background applied
    func withDeepBackgroundTheme() -> some View {
        modifier(DeepBackgroundThemeModifier())
    }
} 

extension LinearGradient {
    static var ampBlueGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#3FA9F5").opacity(0.3),
                Color.black.opacity(0.3)
            ]),
            startPoint: .topLeading,
            endPoint: .bottom
        )
    }
    
    static var ampButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#18EF47"),  // Bright green start
                Color(hex: "#0E8929")   // Brand blue end
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

