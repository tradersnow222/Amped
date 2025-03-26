import SwiftUI

/// View modifier that applies the DeepBackground image as a full-screen background
/// This modifier is meant to be applied to all screens except WelcomeView
struct DeepBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // Deep background image as full-screen background
            GeometryReader { geometry in
                Image("DeepBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .overlay(
                        // Overlay gradient to ensure text readability
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.black.opacity(0.5),
                                    Color.black.opacity(0.3)
                                ]
                            ),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .edgesIgnoringSafeArea(.all)
            }
            .edgesIgnoringSafeArea(.all)
            
            // The actual content
            content
        }
        // Force dark color scheme when using deep background to ensure proper text contrast
        .environment(\.colorScheme, .dark)
    }
}

extension View {
    /// Apply the deep background image to the view
    /// This should be applied to all views EXCEPT WelcomeView
    func withDeepBackground() -> some View {
        modifier(DeepBackgroundModifier())
    }
} 