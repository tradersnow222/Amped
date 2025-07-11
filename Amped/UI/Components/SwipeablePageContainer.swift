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
    
    /// Spacing between page indicators
    private let indicatorSpacing: CGFloat = 8
    
    /// Size of page indicators
    private let indicatorSize: CGFloat = 7
    
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
            
            // Custom page indicators with proper positioning
            HStack(spacing: indicatorSpacing) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.ampedGreen : Color.white.opacity(0.3))
                        .frame(width: indicatorSize, height: indicatorSize)
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                        .onTapGesture {
                            withAnimation {
                                currentPage = index
                            }
                        }
                }
            }
            .padding(.vertical, 16)
            .padding(.bottom, 8) // Extra bottom padding for safety
            .background(Color.black.opacity(0.01)) // Invisible background to ensure tap area
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