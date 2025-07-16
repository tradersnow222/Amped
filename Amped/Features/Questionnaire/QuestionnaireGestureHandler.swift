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
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    exitToPersonalizationIntro.wrappedValue = true
                }
            } else {
                // For any other question, navigate internally
                print("🔍 QUESTIONNAIRE: Backward swipe to previous question, currentQuestion=\(viewModel?.currentQuestion.rawValue ?? -1)")
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
                    viewModel?.moveBackToPreviousQuestion()
                }
            }
        } else {
            print("🔍 QUESTIONNAIRE: Drag threshold not met, canceling navigation")
        }
        
        // Reset drag state with animation - use consistent animation parameters
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
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
        // With single-question rendering, we use a simple slide transition
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