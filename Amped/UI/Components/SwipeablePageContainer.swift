import SwiftUI

/// A reusable container for swipeable pages following Apple UX standards
/// Uses iOS 17+ ScrollView with proper paging, with iOS 16 fallback
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
    
    /// Track scroll position for iOS-standard paging
    @State private var scrollPosition: Int? = 0
    
    // MARK: - Initialization
    
    public init(currentPage: Binding<Int>, pageCount: Int, @ViewBuilder content: () -> Content) {
        self._currentPage = currentPage
        self.pageCount = pageCount
        self.content = content()
    }
    
    // MARK: - Body
    
    public var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 17.0, *) {
                // iOS 17+ native paging with proper UX standards
                modernScrollImplementation
            } else {
                // iOS 16 fallback implementation
                fallbackScrollViewImplementation
            }
            
            // Page indicators consistent across iOS versions
            pageIndicators
        }
    }
    
    /// iOS 17+ implementation using proper ScrollView paging
    @available(iOS 17.0, *)
    private var modernScrollImplementation: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                content
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrollPosition)
        .scrollIndicators(.hidden)
        .onChange(of: scrollPosition) { newPosition in
            // Update currentPage when scroll position changes
            if let newPage = newPosition, newPage != currentPage {
                currentPage = newPage
                
                // iOS-standard haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.prepare()
                impactFeedback.impactOccurred(intensity: 0.6)
            }
        }
        .onChange(of: currentPage) { newPage in
            // Update scroll position when currentPage changes programmatically
            if scrollPosition != newPage {
                withAnimation(.interpolatingSpring(
                    mass: 1.0,
                    stiffness: 200,
                    damping: 25,
                    initialVelocity: 0
                )) {
                    scrollPosition = newPage
                }
            }
        }
        .onAppear {
            scrollPosition = currentPage
        }
    }
    
    /// iOS 16 fallback implementation
    private var fallbackScrollViewImplementation: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    content
                        .frame(maxWidth: .infinity)
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        let threshold: CGFloat = 80 // iOS-standard threshold
                        let horizontalDrag = value.translation.width
                        
                        let newPage: Int
                        if horizontalDrag > threshold && currentPage > 0 {
                            // Swipe right - go to previous page
                            newPage = currentPage - 1
                        } else if horizontalDrag < -threshold && currentPage < pageCount - 1 {
                            // Swipe left - go to next page
                            newPage = currentPage + 1
                        } else {
                            newPage = currentPage
                        }
                        
                        if newPage != currentPage {
                            withAnimation(.interpolatingSpring(
                                mass: 1.0,
                                stiffness: 200,
                                damping: 25,
                                initialVelocity: 0
                            )) {
                                currentPage = newPage
                                proxy.scrollTo(newPage, anchor: .leading)
                            }
                            
                            // iOS-standard haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.prepare()
                            impactFeedback.impactOccurred(intensity: 0.6)
                        }
                    }
            )
            .onChange(of: currentPage) { newPage in
                withAnimation(.interpolatingSpring(
                    mass: 1.0,
                    stiffness: 200,
                    damping: 25,
                    initialVelocity: 0
                )) {
                    proxy.scrollTo(newPage, anchor: .leading)
                }
            }
            .onAppear {
                proxy.scrollTo(currentPage, anchor: .leading)
            }
        }
    }
    
    /// Page indicators consistent across iOS versions
    private var pageIndicators: some View {
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
                    .overlay(
                        Circle()
                            .stroke(
                                isActive ? Color.ampedGreen.opacity(0.6) : Color.clear,
                                lineWidth: isActive ? 1.5 : 0
                            )
                            .blur(radius: isActive ? 0.5 : 0)
                    )
                    .shadow(
                        color: isActive ? Color.ampedGreen.opacity(0.3) : Color.black.opacity(0.1),
                        radius: isActive ? 3 : 1,
                        x: 0,
                        y: 1
                    )
                    .animation(.interpolatingSpring(
                        mass: 1.0,
                        stiffness: 200,
                        damping: 25,
                        initialVelocity: 0
                    ), value: currentPage)
                    .scaleEffect(isActive ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
                    .onTapGesture {
                        withAnimation(.interpolatingSpring(
                            mass: 1.0,
                            stiffness: 200,
                            damping: 25,
                            initialVelocity: 0
                        )) {
                            currentPage = index
                        }
                        
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.prepare()
                        impactFeedback.impactOccurred(intensity: 0.6)
                    }
                    .contentShape(Circle().inset(by: -8))
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
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