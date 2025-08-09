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
        
        // OPTIMIZED: Early return for invalid conditions
        guard let viewModel = viewModel, viewModel.canMoveBack else {
            return 0
        }
        
        // OPTIMIZED: Cached calculation for better performance
        let horizontalDistance = abs(gesture.translation.width)
        let verticalDistance = abs(gesture.translation.height)
        
        // Only allow backward (right) swipes, not forward (left) swipes
        // OPTIMIZED: More efficient conditions
        if gesture.translation.width > 0 && horizontalDistance > verticalDistance * 1.2 {
            // Dragging right (backward)
            dragDirection = .trailing
            
            // OPTIMIZED: Simplified resistance calculation
            let screenWidth = geometry.size.width
            let progress = min(gesture.translation.width / screenWidth, 1.0)
            let resistance = 1.0 - (progress * 0.25) // Optimized resistance curve
            dragOffset = min(gesture.translation.width, screenWidth) * resistance
        }
        
        return dragOffset
    }
    
    /// Handle when drag gesture ends
    func handleDragEnded(_ gesture: DragGesture.Value, geometry: GeometryProxy, completion: @escaping () -> Void) {
        guard dragDirection != nil else { 
            completion()
            return 
        }
        
        // OPTIMIZED: Single threshold calculation
        let threshold: CGFloat = geometry.size.width * 0.12 // Even lower threshold for ultra-responsive feel
        
        // Only handle backward (trailing) swipes - forward swipes are disabled
        if dragDirection == .trailing && abs(dragOffset) > threshold {
            // OPTIMIZED: Immediate haptic feedback before navigation
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.prepare()
            impactFeedback.impactOccurred(intensity: 0.6)
            
            // Backward swipe - go to previous question or back to intro if at first question
            if viewModel?.isFirstQuestion == true {
                // If at first question, signal parent to navigate back to personalization intro
                // Set backward direction for proper iOS-standard transition
                viewModel?.navigationDirection = .backward
                withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
                    exitToPersonalizationIntro.wrappedValue = true
                }
            } else {
                // For any other question, navigate internally
                // Direction is set automatically in moveBackToPreviousQuestion()
                withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
                    viewModel?.moveBackToPreviousQuestion()
                }
            }
        }
        
        // Reset drag state using the unified luxury slow spring for consistency
        withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
            dragOffset = 0
        }
        
        dragDirection = nil
        completion()
    }
    
    /// Handle back button navigation
    func handleBackNavigation() {
        // OPTIMIZED: Immediate haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        if viewModel?.isFirstQuestion == true {
            // At first question, navigate back to personalization intro
            isBackButtonTapped = true
            print("🔍 QUESTIONNAIRE: Back to previous onboarding screen (personalization intro) - SCREEN SHOULD EXIT RIGHT")
            
            // Set backward direction for proper iOS-standard transition
            viewModel?.navigationDirection = .backward
            
            // Signal to parent to navigate back with unified spring
            withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
                exitToPersonalizationIntro.wrappedValue = true
            }
            
            // OPTIMIZED: Faster reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.isBackButtonTapped = false
                print("🔍 QUESTIONNAIRE: Back button flag reset")
            }
        } else {
            // For any other question, navigate internally within questionnaire
            isBackButtonTapped = true
            print("🔍 QUESTIONNAIRE: Back to previous question - CURRENT QUESTION SHOULD EXIT RIGHT")
            
            // Direction is set automatically in moveBackToPreviousQuestion(); use unified spring
            withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
                viewModel?.moveBackToPreviousQuestion()
            }
            
            // OPTIMIZED: Faster reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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