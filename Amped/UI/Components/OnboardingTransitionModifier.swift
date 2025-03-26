import SwiftUI

/// A modifier that applies standardized transitions for the onboarding flow
struct OnboardingTransitionModifier: ViewModifier {
    // Transition types for the onboarding flow
    enum TransitionType {
        case welcome       // Fade in for welcome screen
        case onboarding    // Horizontal slide for onboarding screens
        case dashboard     // Fade to dashboard
        case buttonInitiated // Special case for button-initiated transitions (forward)
        case backButtonInitiated // Special case for back button transitions
    }
    
    let type: TransitionType
    let isPresented: Bool
    
    func body(content: Content) -> some View {
        switch type {
        case .welcome:
            // Initial fade in for welcome screen
            content
                .opacity(isPresented ? 1 : 0)
                .animation(.easeIn(duration: 2.5), value: isPresented)
                
        case .onboarding:
            // Horizontal slide for transitions between onboarding screens
            // No animation here - will be controlled by gesture in OnboardingFlow
            content
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                
        case .dashboard:
            // Fade transition to dashboard
            content
                .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                
        case .buttonInitiated:
            // Slightly slower transition for button-initiated navigation with spring animation
            // Forward direction (right to left)
            content
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: isPresented)
                
        case .backButtonInitiated:
            // Back button transition (left to right)
            content
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
                .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: isPresented)
        }
    }
}

// Extension to make the modifier easier to use
extension View {
    /// Apply welcome screen fade-in transition
    func withWelcomeTransition(isPresented: Bool = true) -> some View {
        modifier(OnboardingTransitionModifier(type: .welcome, isPresented: isPresented))
    }
    
    /// Apply horizontal slide transition for onboarding screens
    func withOnboardingTransition() -> some View {
        modifier(OnboardingTransitionModifier(type: .onboarding, isPresented: true))
    }
    
    /// Apply fade transition to dashboard
    func withDashboardTransition() -> some View {
        modifier(OnboardingTransitionModifier(type: .dashboard, isPresented: true))
    }
    
    /// Apply button-initiated transition (slightly slower) - forward direction
    func withButtonInitiatedTransition(isPresented: Bool = true) -> some View {
        modifier(OnboardingTransitionModifier(type: .buttonInitiated, isPresented: isPresented))
    }
    
    /// Apply back button transition - backward direction
    func withBackButtonTransition(isPresented: Bool = true) -> some View {
        modifier(OnboardingTransitionModifier(type: .backButtonInitiated, isPresented: isPresented))
    }
} 