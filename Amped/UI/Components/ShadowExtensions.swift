import SwiftUI

// Rules: Prioritize performance - consolidated shadow effects for better rendering
extension View {
    /// Lightweight shadow for text elements
    func lightTextShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
    }
    
    /// Standard shadow for UI elements
    func standardShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
    }
    
    /// Subtle glow effect for highlighted elements
    func glowEffect(color: Color = .ampedGreen, opacity: Double = 0.6) -> some View {
        self.shadow(color: color.opacity(opacity), radius: 8, x: 0, y: 0)
    }
    
    /// Combined text highlight effect
    func textHighlight(color: Color = .ampedGreen) -> some View {
        self.shadow(color: color.opacity(0.8), radius: 1.2, x: 0, y: 0)
    }
}
