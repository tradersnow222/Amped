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