import SwiftUI

/// PERFORMANCE-OPTIMIZED: Static background that doesn't recalculate on keyboard appearance
/// This prevents the expensive GeometryReader recalculations that cause keyboard lag
struct OptimizedDeepBackgroundModifier: ViewModifier {
    // CRITICAL: Use @State to cache the background view and prevent recreation
    @State private var hasInitialized = false
    @State private var cachedBackgroundSize: CGSize = .zero
    
    func body(content: Content) -> some View {
        ZStack {
            // PERFORMANCE FIX: Use a static background that doesn't depend on GeometryReader
            // This prevents recalculation when keyboard appears
            backgroundView
                .edgesIgnoringSafeArea(.all)
            
            // The actual content
            content
        }
        // Force dark color scheme for proper text contrast
        .environment(\.colorScheme, .dark)
        .onAppear {
            // Cache the initial size to prevent recalculation
            if !hasInitialized {
                hasInitialized = true
                // Get screen size once and cache it
                cachedBackgroundSize = UIScreen.main.bounds.size
            }
        }
    }
    
    // PERFORMANCE: Create a static background view that doesn't use GeometryReader
    @ViewBuilder
    private var backgroundView: some View {
        // Use screen bounds instead of GeometryReader for truly static sizing
        Image("DeepBackground")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: UIScreen.main.bounds.width, 
                   height: UIScreen.main.bounds.height)
            .overlay(
                // Static gradient overlay
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
            // CRITICAL: Ignore keyboard safe area to prevent recalculation
            .ignoresSafeArea(.keyboard)
    }
}

/// PERFORMANCE-OPTIMIZED: Lightweight theme modifier without heavy background
struct OptimizedDeepBackgroundThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            // Just apply the color scheme without heavy background processing
            .environment(\.colorScheme, .dark)
    }
}

// MARK: - View Extensions

extension View {
    /// PERFORMANCE: Apply optimized deep background that doesn't cause keyboard lag
    func withOptimizedDeepBackground() -> some View {
        modifier(OptimizedDeepBackgroundModifier())
    }
    
    /// PERFORMANCE: Apply lightweight theme without background for keyboard-sensitive views
    func withLightweightDeepTheme() -> some View {
        modifier(OptimizedDeepBackgroundThemeModifier())
    }
}
