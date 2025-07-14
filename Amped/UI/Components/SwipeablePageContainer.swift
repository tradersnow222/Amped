import SwiftUI

/// A reusable container for swipeable pages with properly positioned page indicators
/// This solves the TabView page indicator overlap issue by implementing custom indicators
public struct SwipeablePageContainer<Content: View>: View {
    // MARK: - Properties
    
    /// Current page index
    @Binding var currentPage: Int
    
    /// Total number of pages
    let pageCount: Int
    
    /// The content pages to display
    let content: Content
    
    /// Spacing between page indicators - iOS standard
    private let indicatorSpacing: CGFloat = 12
    
    /// Size of page indicators - iOS standard (larger, more prominent)
    private let indicatorSize: CGFloat = 10
    
    /// Active indicator size - slightly larger for better visibility
    private let activeIndicatorSize: CGFloat = 12
    
    // MARK: - Initialization
    
    public init(currentPage: Binding<Int>, pageCount: Int, @ViewBuilder content: () -> Content) {
        self._currentPage = currentPage
        self.pageCount = pageCount
        self.content = content()
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            // Main content with swipeable pages
            TabView(selection: $currentPage) {
                content
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // Hide default indicators
            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: currentPage) // Smoother page transitions
            
            // Custom page indicators with iOS-standard styling
            HStack(spacing: indicatorSpacing) {
                ForEach(0..<pageCount, id: \.self) { index in
                    let isActive = index == currentPage
                    
                    Circle()
                        .fill(
                            isActive ? 
                                Color.ampedGreen :
                                Color.white.opacity(0.4)
                        )
                        .frame(
                            width: isActive ? activeIndicatorSize : indicatorSize,
                            height: isActive ? activeIndicatorSize : indicatorSize
                        )
                        // iOS-style glow effect for active indicator
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive ? Color.ampedGreen.opacity(0.6) : Color.clear,
                                    lineWidth: isActive ? 1.5 : 0
                                )
                                .blur(radius: isActive ? 0.5 : 0)
                        )
                        // Subtle shadow for depth
                        .shadow(
                            color: isActive ? Color.ampedGreen.opacity(0.3) : Color.black.opacity(0.1),
                            radius: isActive ? 3 : 1,
                            x: 0,
                            y: 1
                        )
                        // Smooth animations with spring physics
                        .animation(.interpolatingSpring(stiffness: 400, damping: 25), value: currentPage)
                        .scaleEffect(isActive ? 1.0 : 0.9) // Subtle scale difference
                        .animation(.easeInOut(duration: 0.15), value: currentPage)
                        .onTapGesture {
                            // Smooth page transition with haptic feedback
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                currentPage = index
                            }
                            
                            // Haptic feedback for better user experience
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                        }
                        .contentShape(Circle().inset(by: -8)) // Larger tap area for better UX
                }
            }
            .padding(.vertical, 20) // More generous padding
            .padding(.horizontal, 16) // Ensure dots don't touch edges
            .background(
                // Subtle background with glass effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .opacity(0.6)
                    .frame(height: 44) // iOS standard touch target height
            )
            .overlay(
                // Subtle border for definition
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                    .frame(height: 44)
            )
            .padding(.bottom, 12) // Extra bottom padding for safety
        }
    }
}

// MARK: - Convenience Extensions

extension View {
    /// Tag this view for use in SwipeablePageContainer
    func swipeablePage<T: Hashable>(_ tag: T) -> some View {
        self.tag(tag)
    }
}

// MARK: - Preview

struct SwipeablePageContainer_Previews: PreviewProvider {
    @State static var currentPage = 0
    
    static var previews: some View {
        SwipeablePageContainer(currentPage: $currentPage, pageCount: 3) {
            // Example pages
            Color.blue
                .overlay(Text("Page 1").foregroundColor(.white))
                .swipeablePage(0)
            
            Color.green
                .overlay(Text("Page 2").foregroundColor(.white))
                .swipeablePage(1)
            
            Color.orange
                .overlay(Text("Page 3").foregroundColor(.white))
                .swipeablePage(2)
        }
        .background(Color.black)
    }
} 