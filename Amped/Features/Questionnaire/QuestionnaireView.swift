import SwiftUI

/// Questionnaire view for collecting additional health metrics
struct QuestionnaireView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = QuestionnaireViewModel()
    @Environment(\.themeManager) private var themeManager
    
    // Navigation bindings
    @Binding var exitToPersonalizationIntro: Bool
    @Binding var proceedToHealthPermissions: Bool
    
    // Gesture handler
    private let gestureHandler: QuestionnaireGestureHandler
    
    // Internal state
    @State private var animationCompleted = false
    
    // MARK: - Initializers
    
    init(exitToPersonalizationIntro: Binding<Bool>, proceedToHealthPermissions: Binding<Bool>) {
        self._exitToPersonalizationIntro = exitToPersonalizationIntro
        self._proceedToHealthPermissions = proceedToHealthPermissions
        self.gestureHandler = QuestionnaireGestureHandler(
            viewModel: QuestionnaireViewModel(),
            exitToPersonalizationIntro: exitToPersonalizationIntro
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep background
                Color.clear.withDeepBackground()
                
                VStack(spacing: 12) {
                    // Navigation header with back button
                    if viewModel.canMoveBack {
                        HStack {
                            Button(action: {
                                gestureHandler.handleBackNavigation()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Back")
                                        .font(.system(size: 16, weight: .regular))
                                }
                                .foregroundColor(.ampedGreen)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                            }
                            .accessibilityLabel("Go back to previous question")
                            
                            Spacer()
                        }
                        .padding(.top, 16)
                        .padding(.leading, 8)
                    } else {
                        // Empty space for consistent layout
                        HStack {
                            Spacer()
                        }
                        .frame(height: 42)
                    }
                    
                    // Add spacer to push question down approximately 1/3 from top
                    Spacer().frame(height: geometry.size.height * 0.15)
                    
                    // Current question view with proper bidirectional transitions
                    ZStack {
                        ForEach(QuestionnaireViewModel.Question.allCases, id: \.self) { question in
                            if viewModel.currentQuestion == question {
                                questionView(for: question)
                                    .padding()
                                    .offset(x: gestureHandler.calculateOffset(for: question, geometry: geometry))
                                    .transition(gestureHandler.getTransition())
                                    .zIndex(viewModel.currentQuestion == question ? 1 : 0)
                            }
                        }
                    }
                    .animation(gestureHandler.dragDirection == nil ? .interpolatingSpring(stiffness: 150, damping: 20, initialVelocity: 0.3) : nil, value: viewModel.currentQuestion)
                    
                    Spacer()
                    
                    // Progress indicator at bottom - consistent with other screens
                    ProgressIndicator(currentStep: viewModel.currentStep, totalSteps: viewModel.totalSteps)
                        .padding(.bottom, 40)
                }
                .withDeepBackgroundTheme()
            }
            // Move the gesture to the ZStack level for better gesture recognition
            .contentShape(Rectangle()) // Ensure the entire area responds to gestures
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        let _ = gestureHandler.handleDragChanged(gesture, geometry: geometry)
                    }
                    .onEnded { gesture in
                        gestureHandler.handleDragEnded(gesture, geometry: geometry) {
                            animationCompleted = true
                        }
                    }
            )
        }
    }
    
    // MARK: - Question Views
    
    /// Get the view for a specific question
    @ViewBuilder
    private func questionView(for question: QuestionnaireViewModel.Question) -> some View {
        switch question {
        case .birthdate:
            QuestionViews.BirthdateQuestionView(
                viewModel: viewModel, 
                handleContinue: handleContinue
            )
        case .gender:
            QuestionViews.GenderQuestionView(
                viewModel: viewModel
            )
        case .nutritionQuality:
            QuestionViews.NutritionQuestionView(
                viewModel: viewModel
            )
        case .smokingStatus:
            QuestionViews.SmokingQuestionView(
                viewModel: viewModel
            )
        case .alcoholConsumption:
            QuestionViews.AlcoholQuestionView(
                viewModel: viewModel
            )
        case .socialConnections:
            QuestionViews.SocialConnectionsQuestionView(
                viewModel: viewModel,
                completeQuestionnaire: completeQuestionnaire
            )
        }
    }
    
    // MARK: - Navigation Handling
    
    private func completeQuestionnaire() {
        guard viewModel.canProceed else { return }
        
        // Activate binding to trigger the transition to health permissions
        proceedToHealthPermissions = true
        
        print("🔍 QUESTIONNAIRE: Completed questionnaire, moving to health permissions")
    }
    
    private func handleContinue() {
        guard viewModel.canProceed else { return }
        
        // If this is the last question, proceed to the next onboarding step
        if viewModel.isLastQuestion {
            print("🔍 QUESTIONNAIRE: Continue from last question - completing questionnaire")
            
            // Call the binding to move to the next onboarding step
            completeQuestionnaire()
            return
        }
        
        // For all other questions, proceed to next question within questionnaire
        viewModel.proceedToNextQuestion()
        print("🔍 QUESTIONNAIRE: Continue to next question")
    }
}

// MARK: - Preview

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView(exitToPersonalizationIntro: .constant(false), proceedToHealthPermissions: .constant(false))
    }
} 