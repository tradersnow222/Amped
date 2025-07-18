import SwiftUI

/// Main enum to track the onboarding state - Rules: Removed signInWithApple from flow
enum OnboardingStep: Equatable {
    case welcome
    case valueProposition
    case personalizationIntro
    case questionnaire
    case payment
    case dashboard
}

/// Main container view for the entire onboarding flow
struct OnboardingFlow: View {
    @State private var currentStep: OnboardingStep = .welcome
    @EnvironmentObject var appState: AppState
    @State private var dragOffset: CGFloat = 0
    @State private var dragDirection: Edge? = nil
    @State private var isButtonNavigating: Bool = false
    @State private var isProgrammaticNavigation: Bool = false
    
    // Add binding for questionnaire navigation
    @State private var shouldExitQuestionnaire: Bool = false
    @State private var shouldCompleteQuestionnaire: Bool = false
    

    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Using conditional rendering with proper transitions
                if currentStep == .welcome {
                    WelcomeView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.valueProposition) 
                    })
                    .transition(.opacity)
                    .zIndex(currentStep == .welcome ? 1 : 0)
                }
                
                if currentStep == .valueProposition {
                    ValuePropositionView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.personalizationIntro) 
                    })
                    .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                    .transition(getTransition(forNavigatingTo: .valueProposition))
                    .zIndex(currentStep == .valueProposition ? 1 : 0)
                }
                
                if currentStep == .personalizationIntro {
                    PersonalizationIntroView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.questionnaire) 
                    })
                    .offset(x: dragDirection == .leading ? dragOffset : 0)
                    .transition(getTransition(forNavigatingTo: .personalizationIntro))
                    .zIndex(currentStep == .personalizationIntro ? 1 : 0)
                }
                
                if currentStep == .questionnaire {
                    QuestionnaireView(
                        exitToPersonalizationIntro: $shouldExitQuestionnaire,
                        proceedToHealthPermissions: $shouldCompleteQuestionnaire
                    )
                    .onChange(of: shouldExitQuestionnaire) { newValue in
                        if newValue {
                            // Reset flag first
                            shouldExitQuestionnaire = false
                            
                            // Important: First set drag direction, then navigate
                            isButtonNavigating = false
                            dragDirection = .trailing
                            
                            // Navigate back with trailing edge animation
                            // Use a slight delay to ensure the direction is set properly
                            DispatchQueue.main.async {
                                navigateTo(.personalizationIntro)
                                
                                // Reset drag direction after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    dragDirection = nil
                                }
                            }
                        }
                    }
                    .onChange(of: shouldCompleteQuestionnaire) { newValue in
                        if newValue {
                            // Reset flag first
                            shouldCompleteQuestionnaire = false
                            
                            // Navigate forward with leading edge animation
                            isButtonNavigating = false
                            dragDirection = .leading
                            
                            // Questionnaire completed - go directly to Payment (skipping sign-in) - Rules: Skip sign-in until after payment
                            DispatchQueue.main.async {
                                navigateTo(.payment)
                                
                                // Reset drag direction after animation
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    dragDirection = nil
                                }
                            }
                        }
                    }
                    .transition(getTransition(forNavigatingTo: .questionnaire))
                    .zIndex(currentStep == .questionnaire ? 1 : 0)
                }
                
                if currentStep == .payment {
                    PaymentView(onContinue: { 
                        isButtonNavigating = true
                        dragDirection = nil
                        navigateTo(.dashboard) 
                    })
                    .offset(x: dragDirection == .leading ? dragOffset : (dragDirection == .trailing ? dragOffset : 0))
                    .transition(getTransition(forNavigatingTo: .payment))
                    .zIndex(currentStep == .payment ? 1 : 0)
                }
                
                if currentStep == .dashboard {
                    NavigationView {
                        DashboardView()
                    }
                    .transition(.opacity)
                    .zIndex(currentStep == .dashboard ? 1 : 0)
                    .onAppear {
                        // Mark onboarding as complete once dashboard is shown
                        appState.completeOnboarding()
                    }
                }
            }
            .animation((isProgrammaticNavigation || dragDirection == nil ? .interpolatingSpring(
                mass: 1.0,
                stiffness: 200,
                damping: 25,
                initialVelocity: 0
            ) : nil), value: currentStep)
            .gesture(
                // iOS-STANDARD: Improved gesture handling with proper thresholds and physics
                DragGesture(minimumDistance: 8, coordinateSpace: .local) // iOS-standard minimum distance
                    .onChanged { gesture in
                        // Skip gesture handling entirely when in questionnaire
                        if currentStep == .questionnaire {
                            return
                        }
                        
                        // Reset button navigation flag when user starts dragging
                        isButtonNavigating = false
                        isProgrammaticNavigation = false
                        
                        // Skip gesture handling for welcome screen and when transitioning to dashboard
                        guard currentStep != .welcome && currentStep != .dashboard else { return }
                        
                        // iOS-STANDARD: Only respond to primarily horizontal gestures
                        let horizontalDistance = abs(gesture.translation.width)
                        let verticalDistance = abs(gesture.translation.height)
                        
                        if horizontalDistance > verticalDistance * 1.5 { // Must be 1.5x more horizontal
                            // Determine drag direction
                            if gesture.translation.width < 0 {
                                // Dragging to the left (forward)
                                if currentStep == .questionnaire {
                                    return
                                }
                                
                                dragDirection = .leading
                                let nextStep = getNextStep(after: currentStep)
                                if nextStep != nil {
                                    // iOS-STANDARD: Natural resistance curve
                                    let progress = min(abs(gesture.translation.width) / geometry.size.width, 1.0)
                                    let resistance = 1.0 - (progress * 0.3) // Less resistance for natural feel
                                    dragOffset = max(gesture.translation.width, -geometry.size.width) * resistance
                                }
                            } else if gesture.translation.width > 0 {
                                // Dragging to the right (backward)
                                // Don't allow swiping back to welcome view
                                if currentStep == .valueProposition {
                                    return
                                }
                                
                                if currentStep == .questionnaire {
                                    return
                                }
                                
                                dragDirection = .trailing
                                let previousStep = getPreviousStep(before: currentStep)
                                if previousStep != nil && previousStep != .welcome {
                                    // iOS-STANDARD: Natural resistance curve
                                    let progress = min(abs(gesture.translation.width) / geometry.size.width, 1.0)
                                    let resistance = 1.0 - (progress * 0.3) // Less resistance for natural feel
                                    dragOffset = min(gesture.translation.width, geometry.size.width) * resistance
                                }
                            }
                        }
                    }
                    .onEnded { gesture in
                        // Skip gesture handling entirely when in questionnaire
                        if currentStep == .questionnaire {
                            return
                        }
                        
                        guard dragDirection != nil else { return }
                        
                        // iOS-STANDARD: Reduced threshold for more responsive swiping
                        let threshold: CGFloat = geometry.size.width * 0.15 // 15% threshold instead of 20%
                        
                        if dragDirection == .leading && abs(dragOffset) > threshold {
                            // Dragged left past threshold - move forward
                            if let nextStep = getNextStep(after: currentStep) {
                                withAnimation(.interpolatingSpring(
                                    mass: 1.0,
                                    stiffness: 200,
                                    damping: 25,
                                    initialVelocity: 0
                                )) {
                                    dragOffset = 0
                                }
                                
                                // iOS-STANDARD: Immediate haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred(intensity: 0.6)
                                
                                navigateTo(nextStep)
                                // Reset dragDirection after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    dragDirection = nil
                                }
                            }
                        } else if dragDirection == .trailing && abs(dragOffset) > threshold {
                            // Dragged right past threshold - move backward
                            if let previousStep = getPreviousStep(before: currentStep), previousStep != .welcome {
                                withAnimation(.interpolatingSpring(
                                    mass: 1.0,
                                    stiffness: 200,
                                    damping: 25,
                                    initialVelocity: 0
                                )) {
                                    dragOffset = 0
                                }
                                
                                // iOS-STANDARD: Immediate haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred(intensity: 0.6)
                                
                                navigateTo(previousStep)
                                // Reset dragDirection after animation completes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    dragDirection = nil
                                }
                            }
                        } else {
                            // iOS-STANDARD: Spring back if threshold not met
                            withAnimation(.interpolatingSpring(
                                mass: 1.0,
                                stiffness: 200,
                                damping: 25,
                                initialVelocity: 0
                            )) {
                                dragOffset = 0
                            }
                            dragDirection = nil
                        }
                    }
            )
        }
    }
    
    // Helper method to determine the correct transition based on navigation direction
    private func getTransition(forNavigatingTo step: OnboardingStep) -> AnyTransition {
        print("🔍 DEBUG: Getting transition for navigating to \(step), isButtonNavigating=\(isButtonNavigating), dragDirection=\(String(describing: dragDirection))")
        
        // Special case: When transitioning FROM welcome screen, use fade transition
        if step == .valueProposition {
            print("🔍 DEBUG: Using fade transition from welcome to value proposition")
            return .asymmetric(
                insertion: .opacity,
                removal: .opacity
            )
        }
        
        // For button-initiated navigation
        if isButtonNavigating {
            print("🔍 DEBUG: Using button-initiated transition (forward)")
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
        
        // For gesture-based navigation
        if let dragDir = dragDirection {
            switch dragDir {
            case .leading:
                // Forward swipe (left to right on screen)
                print("🔍 DEBUG: Using leading edge transition (forward swipe)")
                return .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            case .trailing:
                // Backward swipe (right to left on screen)
                print("🔍 DEBUG: Using trailing edge transition (backward swipe)")
                return .asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                )
            default:
                // Default forward transition
                print("🔍 DEBUG: Using default transition (unknown drag direction)")
                return .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            }
        }
        
        // Default transition for programmatic navigation
        print("🔍 DEBUG: Using default transition (no drag direction)")
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    private func navigateTo(_ step: OnboardingStep) {
        print("🔍 DEBUG: Navigating from \(currentStep) to \(step), isButtonNavigating=\(isButtonNavigating), dragDirection=\(String(describing: dragDirection))")
        
        // Use spring animation for smoother transitions
        isProgrammaticNavigation = true
        
        // Log the transition being used
        if dragDirection == .trailing {
            print("🔍 DEBUG: Using BACKWARD transition (trailing edge) - current screen should exit RIGHT")
        } else if dragDirection == .leading {
            print("🔍 DEBUG: Using FORWARD transition (leading edge) - current screen should exit LEFT")
        } else if isButtonNavigating {
            print("🔍 DEBUG: Using BUTTON-INITIATED transition - current screen should exit LEFT")
        } else {
            print("🔍 DEBUG: Using DEFAULT transition - current screen should exit LEFT")
        }
        
        withAnimation(.interpolatingSpring(stiffness: 250, damping: 35)) {
            currentStep = step
        }
    }
    
    /// Get the next step in the onboarding flow - Rules: Updated to skip sign-in
    private func getNextStep(after step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome: return .valueProposition
        case .valueProposition: return .personalizationIntro
        case .personalizationIntro: return .questionnaire
        case .questionnaire: return .payment // Skip sign-in, go directly to payment
        case .payment: return .dashboard
        case .dashboard: return nil
        }
    }
    
    /// Get the previous step in the onboarding flow - Rules: Updated to skip sign-in
    private func getPreviousStep(before step: OnboardingStep) -> OnboardingStep? {
        switch step {
        case .welcome: return nil
        case .valueProposition: return .welcome
        case .personalizationIntro: return .valueProposition
        case .questionnaire: return .personalizationIntro
        case .payment: return .questionnaire // Skip sign-in when going back
        case .dashboard: return .payment
        }
    }
    

}

// Preview
struct OnboardingFlow_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingFlow()
            .environmentObject(AppState())
    }
} 