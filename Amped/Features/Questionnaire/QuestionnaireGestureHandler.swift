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
        // Reset back button flag when user starts dragging
        isBackButtonTapped = false
        
        // iOS-STANDARD: Only consider horizontal drags that are significantly more horizontal than vertical
        let horizontalDistance = abs(gesture.translation.width)
        let verticalDistance = abs(gesture.translation.height)
        
        if horizontalDistance > verticalDistance * 1.5 { // iOS-standard ratio
            // Only allow backward (right) swipes, not forward (left) swipes
            if gesture.translation.width > 0 && viewModel?.canMoveBack == true {
                // Dragging right (backward)
                dragDirection = .trailing
                
                // iOS-STANDARD: Natural resistance curve
                let progress = min(abs(gesture.translation.width) / geometry.size.width, 1.0)
                let resistance = 1.0 - (progress * 0.3) // Less resistance for natural feel
                dragOffset = min(gesture.translation.width, geometry.size.width) * resistance
            }
        }
        
        return dragOffset
    }
    
    /// Handle when drag gesture ends
    func handleDragEnded(_ gesture: DragGesture.Value, geometry: GeometryProxy, completion: @escaping () -> Void) {
        guard dragDirection != nil else { 
            return 
        }
        
        // iOS-STANDARD: Reduced threshold for more responsive swiping
        let threshold: CGFloat = geometry.size.width * 0.15 // 15% threshold for easier swiping
        
        // Only handle backward (trailing) swipes - forward swipes are disabled
        if dragDirection == .trailing && abs(dragOffset) > threshold {
            // Backward swipe - go to previous question or back to intro if at first question
            if viewModel?.isFirstQuestion == true {
                // If at first question, signal parent to navigate back to personalization intro
                // Set backward direction for proper iOS-standard transition
                viewModel?.navigationDirection = .backward
                withAnimation(.easeInOut(duration: 0.3)) { // OPTIMIZED: Faster animation
                    exitToPersonalizationIntro.wrappedValue = true
                }
            } else {
                // For any other question, navigate internally
                // Direction is set automatically in moveBackToPreviousQuestion()
                withAnimation(.easeInOut(duration: 0.3)) { // OPTIMIZED: Faster animation
                    viewModel?.moveBackToPreviousQuestion()
                }
            }
            
            // iOS-STANDARD: Immediate haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred(intensity: 0.6)
        }
        
        // OPTIMIZED: Reset drag state with faster animation
        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = 0
        }
        
        dragDirection = nil
        completion()
    }
    
    /// Handle back button navigation
    func handleBackNavigation() {
        if viewModel?.isFirstQuestion == true {
            // At first question, navigate back to personalization intro
            isBackButtonTapped = true
            print("🔍 QUESTIONNAIRE: Back to previous onboarding screen (personalization intro) - SCREEN SHOULD EXIT RIGHT")
            
            // Set backward direction for proper iOS-standard transition
            viewModel?.navigationDirection = .backward
            
            // Signal to parent to navigate back
            withAnimation(.easeInOut(duration: 0.3)) { // OPTIMIZED: Faster animation
                exitToPersonalizationIntro.wrappedValue = true
            }
            
            // OPTIMIZED: Faster reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isBackButtonTapped = false
                print("🔍 QUESTIONNAIRE: Back button flag reset")
            }
        } else {
            // For any other question, navigate internally within questionnaire
            isBackButtonTapped = true
            print("🔍 QUESTIONNAIRE: Back to previous question - CURRENT QUESTION SHOULD EXIT RIGHT")
            
            // Direction is set automatically in moveBackToPreviousQuestion()
            // Use view model with animation
            withAnimation(.easeInOut(duration: 0.3)) { // OPTIMIZED: Faster animation
                viewModel?.moveBackToPreviousQuestion()
            }
            
            // OPTIMIZED: Faster reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isBackButtonTapped = false
                print("🔍 QUESTIONNAIRE: Back button flag reset")
            }
        }
    }
    
    /// Get the appropriate transition based on navigation context
    func getTransition() -> AnyTransition {
        // NOTE: Transitions are now handled direction-aware in QuestionnaireView
        // This method is kept for compatibility but transitions are managed by getDirectionalTransition()
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    /// Calculate the offset for the current question based on drag
    func calculateOffset(for question: QuestionnaireViewModel.Question, geometry: GeometryProxy) -> CGFloat {
        // With single-question rendering, we don't need offset calculations
        return 0
    }
} 