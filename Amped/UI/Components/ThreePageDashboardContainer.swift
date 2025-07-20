import SwiftUI

/// Uses iOS 17+ ScrollView with proper paging behavior, with iOS 16 fallback
public struct ThreePageDashboardContainer: View {
    @Binding var currentPage: Int
    let impactPage: AnyView
    let lifespanFactorsPage: AnyView 
    let batteryPage: AnyView
    @Binding var isRefreshing: Bool
    @Binding var pullDistance: CGFloat
    
    /// Track scroll position for iOS-standard paging
    @State private var scrollPosition: Int? = 0
    
    public var body: some View {
        VStack(spacing: 0) {
            if #available(iOS 17.0, *) {
                // iOS 17+ native paging with proper UX standards
                modernScrollImplementation
            } else {
                // iOS 16 fallback with optimized TabView
                fallbackTabViewImplementation
            }
            
            // Custom page indicators with iOS-standard behavior
            pageIndicators
        }
    }
    
    /// iOS 17+ implementation using proper ScrollView paging
    @available(iOS 17.0, *)
    private var modernScrollImplementation: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                // Page 0: Impact Page
                impactPage
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                    .id(0)
                
                // Page 1: Lifespan Factors Page  
                lifespanFactorsPage
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                    .id(1)
                
                // Page 2: Battery Page
                batteryPage
                    .containerRelativeFrame(.horizontal, count: 1, spacing: 0)
                    .id(2)
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
    
    /// iOS 16 fallback implementation with optimized TabView
    private var fallbackTabViewImplementation: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Page 0: Impact Page
                    impactPage
                        .frame(maxWidth: .infinity)
                        .id(0)
                    
                    // Page 1: Lifespan Factors Page  
                    lifespanFactorsPage
                        .frame(maxWidth: .infinity)
                        .id(1)
                    
                    // Page 2: Battery Page
                    batteryPage
                        .frame(maxWidth: .infinity)
                        .id(2)
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
                        } else if horizontalDrag < -threshold && currentPage < 2 {
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
        HStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { index in
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
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
} 