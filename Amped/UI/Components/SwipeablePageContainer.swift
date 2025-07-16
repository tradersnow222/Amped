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
    
    /// Internal selection state for infinite scrolling
    @State private var selection: Int = 1000 // Start at a high number to allow scrolling in both directions
    
    /// Timer for detecting when to reset position
    @State private var resetTimer: Timer?
    
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
            TabView(selection: $selection) {
                // For a 2-page setup, we need to handle it specially
                if pageCount == 2 {
                    // Create many virtual pages that map to our 2 real pages
                    ForEach(0..<2000, id: \.self) { virtualIndex in
                        let realIndex = virtualIndex % pageCount
                        
                        // Show the appropriate content based on real index
                        Group {
                            if realIndex == 0 {
                                AnyView(content)
                                    .tag(virtualIndex)
                            } else {
                                AnyView(content)
                                    .tag(virtualIndex)
                            }
                        }
                    }
                } else {
                    // For other page counts, just show the content normally
                    content
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onAppear {
                // Initialize to show the current page
                selection = 1000 + currentPage
            }
            .onChange(of: selection) { newSelection in
                // Update the current page based on selection
                let actualPage = newSelection % pageCount
                if actualPage != currentPage {
                    currentPage = actualPage
                    
                    // Schedule a reset to center position to maintain infinite scroll
                    resetTimer?.invalidate()
                    resetTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                        // Only reset if we're getting too far from center
                        if abs(selection - 1000) > 100 {
                            selection = 1000 + currentPage
                        }
                    }
                }
            }
            .onChange(of: currentPage) { newPage in
                // When currentPage changes externally, update selection
                if selection % pageCount != newPage {
                    selection = 1000 + newPage
                }
            }
            
            // Custom page indicators without background
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
                        // Smooth animations with relaxed spring physics
                        .animation(.interpolatingSpring(
                            mass: 1.5,
                            stiffness: 200,
                            damping: 30,
                            initialVelocity: 0
                        ), value: currentPage)
                        .scaleEffect(isActive ? 1.0 : 0.9) // Subtle scale difference
                        .animation(.easeInOut(duration: 0.35), value: currentPage)
                        .onTapGesture {
                            // Smooth page transition with relaxed haptic feedback
                            withAnimation(.interpolatingSpring(
                                mass: 2.0,
                                stiffness: 60,
                                damping: 22,
                                initialVelocity: 0
                            )) {
                                currentPage = index
                            }
                            
                            // Haptic feedback for better user experience
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.prepare()
                            impactFeedback.impactOccurred(intensity: 0.6)
                        }
                        .contentShape(Circle().inset(by: -8)) // Larger tap area for better UX
                }
            }
            .padding(.vertical, 20) // Generous padding for touch targets
            .padding(.horizontal, 16) // Ensure dots don't touch edges
            .padding(.bottom, 12) // Extra bottom padding for safety
        }
        .onDisappear {
            resetTimer?.invalidate()
        }
    }
}

// MARK: - Infinite Scrolling Container for Dashboard

/// Special container for the dashboard's 2-page infinite scrolling
public struct InfiniteDashboardContainer: View {
    @Binding var currentPage: Int
    let healthFactorsPage: AnyView
    let lifespanBatteryPage: AnyView
    
    /// Internal selection for virtual pages
    @State private var selection: Int = 1000
    
    /// Track if we're currently animating to prevent rapid changes
    @State private var isAnimating = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // TabView with many virtual pages
            TabView(selection: $selection) {
                ForEach(0..<2000, id: \.self) { index in
                    Group {
                        if index % 2 == 0 {
                            healthFactorsPage
                        } else {
                            lifespanBatteryPage
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            // Add custom transition animation for much smoother, slower feel
            .animation(.interpolatingSpring(
                mass: 2.5,        // Much heavier mass for slower, more deliberate movement
                stiffness: 50,    // Much lower stiffness for very gentle acceleration
                damping: 25,      // Higher damping for smooth deceleration
                initialVelocity: 0
            ), value: selection)
            .onChange(of: selection) { newSelection in
                // CRITICAL FIX: Always update currentPage for user swipes to prevent period selector persistence bug
                let newPage = newSelection % 2
                if currentPage != newPage {
                    currentPage = newPage
                }
                
                // Only use isAnimating to prevent rapid programmatic changes, not user swipes
                if !isAnimating {
                    isAnimating = true
                    
                    // Add haptic feedback with longer delay for more natural feel
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.prepare()
                        impactFeedback.impactOccurred(intensity: 0.5) // Even gentler feedback
                    }
                    
                    // Reset animation flag after animation completes (longer duration)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isAnimating = false
                    }
                }
            }
            .onChange(of: currentPage) { newPage in
                if selection % 2 != newPage && !isAnimating {
                    // Use even smoother animation when programmatically changing pages
                    withAnimation(.interpolatingSpring(
                        mass: 2.0,
                        stiffness: 60,
                        damping: 22,
                        initialVelocity: 0
                    )) {
                        selection = 1000 + newPage
                    }
                }
            }
            .onAppear {
                selection = 1000 + currentPage
            }
            
            // Custom page indicators
            HStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { index in
                    let isActive = index == currentPage
                    
                    Circle()
                        .fill(
                            isActive ? 
                                Color.ampedGreen :
                                Color.white.opacity(0.4)
                        )
                        .frame(
                            width: isActive ? 12 : 10,
                            height: isActive ? 12 : 10
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
                        // Even smoother animation for dots
                        .animation(.interpolatingSpring(
                            mass: 1.5,
                            stiffness: 200,
                            damping: 30,
                            initialVelocity: 0
                        ), value: currentPage)
                        .scaleEffect(isActive ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 0.35), value: currentPage) // Longer duration
                        .onTapGesture {
                            if !isAnimating {
                                withAnimation(.interpolatingSpring(
                                    mass: 2.0,
                                    stiffness: 60,
                                    damping: 22,
                                    initialVelocity: 0
                                )) {
                                    currentPage = index
                                }
                                
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred(intensity: 0.6)
                            }
                        }
                        .contentShape(Circle().inset(by: -8))
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
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