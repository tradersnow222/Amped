import SwiftUI

/// Handles gesture interactions for the Questionnaire flow
class QuestionnaireGestureHandler {
    // Drag state
    var dragOffset: CGFloat = 0
    var dragDirection: Edge? = nil
    var isBackButtonTapped: Bool = false
    
    // References
    private weak var viewModel: QuestionnaireViewModel?
    private var exitToPersonalizationIntro: Binding<Bool>
    
    init(viewModel: QuestionnaireViewModel, exitToPersonalizationIntro: Binding<Bool>) {
        self.viewModel = viewModel
        self.exitToPersonalizationIntro = exitToPersonalizationIntro
    }
    
    /// Handle when drag gesture changes
    func handleDragChanged(_ gesture: DragGesture.Value, geometry: GeometryProxy) -> CGFloat {
        // Add debug log
        print("🔍 QUESTIONNAIRE: Drag detected, translation=\(gesture.translation)")
        
        // Reset back button flag when user starts dragging
        isBackButtonTapped = false
        
        // Only consider horizontal drags that are significantly more horizontal than vertical
        if abs(gesture.translation.width) > abs(gesture.translation.height) * 1.5 {
            // Only allow backward (right) swipes, not forward (left) swipes
            if gesture.translation.width > 0 && viewModel?.canMoveBack == true {
                // Dragging right (backward)
                dragDirection = .trailing
                
                // Create smoother drag with spring-like resistance
                let resistance = 1.0 - min(abs(gesture.translation.width) / geometry.size.width, 0.5) * 0.2
                dragOffset = min(gesture.translation.width, geometry.size.width) * resistance
                print("🔍 QUESTIONNAIRE: Backward drag, offset=\(dragOffset), isFirstQuestion=\(viewModel?.isFirstQuestion ?? false), canMoveBack=\(viewModel?.canMoveBack ?? false)")
            }
        }
        
        return dragOffset
    }
    
    /// Handle when drag gesture ends
    func handleDragEnded(_ gesture: DragGesture.Value, geometry: GeometryProxy, completion: @escaping () -> Void) {
        guard dragDirection != nil else { 
            print("🔍 QUESTIONNAIRE: Drag ended but dragDirection is nil")
            return 
        }
        
        // Calculate if the drag was significant enough to trigger navigation
        let threshold: CGFloat = geometry.size.width * 0.2 // 20% threshold for easier swiping
        print("🔍 QUESTIONNAIRE: Drag ended, dragOffset=\(dragOffset), threshold=\(threshold), dragDirection=\(String(describing: dragDirection))")
        
        // Only handle backward (trailing) swipes - forward swipes are disabled
        if dragDirection == .trailing && abs(dragOffset) > threshold {
            // Backward swipe - go to previous question or back to intro if at first question
            if viewModel?.isFirstQuestion == true {
                // If at first question, signal parent to navigate back to personalization intro
                print("🔍 QUESTIONNAIRE: Backward swipe at first question - signaling parent")
                withAnimation(.interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5)) {
                    exitToPersonalizationIntro.wrappedValue = true
                }
            } else {
                // For any other question, navigate internally
                print("🔍 QUESTIONNAIRE: Backward swipe to previous question, currentQuestion=\(viewModel?.currentQuestion.rawValue ?? -1)")
                withAnimation(.interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5)) {
                    viewModel?.moveBackToPreviousQuestion()
                }
            }
        } else {
            print("🔍 QUESTIONNAIRE: Drag threshold not met, canceling navigation")
        }
        
        // Reset drag state with animation - use consistent animation parameters
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5)) {
            dragOffset = 0
            // Keep dragDirection set until animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.dragDirection = nil
                completion()
            }
        }
    }
    
    /// Handle back button navigation
    func handleBackNavigation() {
        if viewModel?.isFirstQuestion == true {
            // At first question, navigate back to personalization intro
            isBackButtonTapped = true
            print("🔍 QUESTIONNAIRE: Back to previous onboarding screen (personalization intro) - SCREEN SHOULD EXIT RIGHT")
            
            // Signal to parent to navigate back
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5)) {
                exitToPersonalizationIntro.wrappedValue = true
            }
            
            // Reset flag after transition completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.isBackButtonTapped = false
                print("🔍 QUESTIONNAIRE: Back button flag reset")
            }
        } else {
            // For any other question, navigate internally within questionnaire
            isBackButtonTapped = true
            print("🔍 QUESTIONNAIRE: Back to previous question - CURRENT QUESTION SHOULD EXIT RIGHT")
            
            // Use view model with animation
            withAnimation(.interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5)) {
                viewModel?.moveBackToPreviousQuestion()
            }
            
            // Reset flag after transition completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.isBackButtonTapped = false
                print("🔍 QUESTIONNAIRE: Back button flag reset")
            }
        }
    }
    
    /// Get the appropriate transition based on navigation context
    func getTransition() -> AnyTransition {
        // For back button navigation
        if isBackButtonTapped {
            print("🔍 QUESTIONNAIRE: Back button transition (current view exits right, previous view enters from left)")
            // For back button taps, the current view should move right while the previous view comes from left
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
        
        // For gesture-based navigation
        if let direction = dragDirection {
            switch direction {
            case .leading:
                // Forward navigation (left swipe)
                print("🔍 QUESTIONNAIRE: Forward swipe transition")
                // When swiping left (forward), current view moves left while new view comes from right
                return .asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                )
            case .trailing:
                // Backward navigation (right swipe)
                print("🔍 QUESTIONNAIRE: Backward swipe transition")
                // When swiping right (backward), current view moves right while previous view comes from left
                return .asymmetric(
                    insertion: .move(edge: .leading),
                    removal: .move(edge: .trailing)
                )
            default:
                // Fallback
                print("🔍 QUESTIONNAIRE: Default transition (unknown direction)")
                return .asymmetric(
                    insertion: .move(edge: .trailing),
                    removal: .move(edge: .leading)
                )
            }
        }
        
        // Default transition for other programmatic navigation (Continue button)
        print("🔍 QUESTIONNAIRE: Default continue button transition")
        return .asymmetric(
            insertion: .move(edge: .trailing),
            removal: .move(edge: .leading)
        )
    }
    
    /// Calculate the offset for the current question based on drag
    func calculateOffset(for question: QuestionnaireViewModel.Question, geometry: GeometryProxy) -> CGFloat {
        guard question == viewModel?.currentQuestion else { return 0 }
        
        if dragDirection == .leading || dragDirection == .trailing {
            return dragOffset
        }
        
        return 0
    }
} 