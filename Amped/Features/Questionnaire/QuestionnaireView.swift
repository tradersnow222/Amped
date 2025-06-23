import SwiftUI
import HealthKit

/// Questionnaire view for collecting additional health metrics
struct QuestionnaireView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: QuestionnaireViewModel
    @StateObject private var questionnaireManager = QuestionnaireManager()
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    // Navigation bindings
    @Binding var exitToPersonalizationIntro: Bool
    @Binding var proceedToHealthPermissions: Bool
    
    // Gesture handler
    private var gestureHandler: QuestionnaireGestureHandler
    
    // Internal state
    @State private var animationCompleted = false
    
    // MARK: - Initializers
    
    init(exitToPersonalizationIntro: Binding<Bool>, proceedToHealthPermissions: Binding<Bool>) {
        self._exitToPersonalizationIntro = exitToPersonalizationIntro
        self._proceedToHealthPermissions = proceedToHealthPermissions
        
        // Create the StateObject before init completes
        let viewModel = QuestionnaireViewModel()
        self._viewModel = StateObject(wrappedValue: viewModel)
        
        // Use the same view model instance for the gesture handler
        self.gestureHandler = QuestionnaireGestureHandler(
            viewModel: viewModel,
            exitToPersonalizationIntro: exitToPersonalizationIntro
        )
        
        print("🔍 QUESTIONNAIRE: Initialized with starting question: \(viewModel.currentQuestion)")
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep background
                Color.clear.withDeepBackground()
                
                VStack(spacing: 12) {
                    // Navigation header with back button - Rules: Using consistent BackButton component
                    if viewModel.canMoveBack {
                        HStack {
                            BackButton(action: {
                                gestureHandler.handleBackNavigation()
                            }, showText: false)
                            
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
                            // Show current question and adjacent questions for smooth transitions
                            let questionIndex = viewModel.questionIndex(for: question)
                            let currentIndex = viewModel.currentQuestionIndex
                            let isVisible = abs(questionIndex - currentIndex) <= 1
                            
                            if isVisible {
                                questionView(for: question)
                                    .padding()
                                    .offset(x: gestureHandler.calculateOffset(for: question, geometry: geometry))
                                    .transition(gestureHandler.getTransition())
                                    .id("question_\(question.rawValue)") // Add stable ID to help SwiftUI track view identity
                                    .zIndex(viewModel.currentQuestion == question ? 1 : 0)
                                    .opacity(viewModel.currentQuestion == question ? 1 : 0)
                            }
                        }
                    }
                    .clipped() // Ensure off-screen views don't show
                    // Use a clear, direct animation for transitions with a slightly higher stiffness for snappier movement
                    .animation(
                        .interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5),
                        value: viewModel.currentQuestion
                    )
                    
                    Spacer()
                    
                    // Progress indicator at bottom - consistent with other screens
                    ProgressIndicator(currentStep: viewModel.currentStep, totalSteps: viewModel.totalSteps)
                        .padding(.top, -10) // Negative padding to bring it closer to the button
                        .padding(.bottom, 10) // Further reduced to allow button to sit closer
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
        .onAppear {
            // OPTIMIZATION: Pre-warm HealthKit when questionnaire appears
            // This ensures everything is ready by the time user reaches device tracking
            if HKHealthStore.isHealthDataAvailable() {
                Task { @MainActor in
                    // Access the shared instance to trigger initialization
                    _ = HealthKitManager.shared
                    
                    // Pre-compute health types if not already done
                    _ = HealthKitManager.precomputedHealthTypes
                }
            }
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
                viewModel: viewModel
            )
        case .deviceTracking:
            QuestionViews.DeviceTrackingQuestionView(
                viewModel: viewModel,
                proceedToHealthKit: proceedToHealthKit,
                skipToLifeMotivation: skipToLifeMotivation
            )
        case .lifeMotivation:
            QuestionViews.LifeMotivationQuestionView(
                viewModel: viewModel,
                completeQuestionnaire: completeQuestionnaire
            )
        }
    }
    
    // MARK: - Navigation Handling
    
    private func proceedToHealthKit() {
        print("🔍 QUESTIONNAIRE: proceedToHealthKit called")
        print("🔍 QUESTIONNAIRE: Current question before navigation: \(viewModel.currentQuestion)")
        
        // Save questionnaire data before proceeding
        questionnaireManager.saveQuestionnaireData(from: viewModel)
        
        // Move directly to life motivation question after successful HealthKit authorization
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5)) {
            viewModel.currentQuestion = .lifeMotivation
        }
        
        print("🔍 QUESTIONNAIRE: HealthKit authorized, moving to life motivation question")
        print("🔍 QUESTIONNAIRE: Current question after navigation: \(viewModel.currentQuestion)")
    }
    
    private func skipToLifeMotivation() {
        // User doesn't track health, move directly to life motivation question
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5)) {
            viewModel.currentQuestion = .lifeMotivation
        }
        
        print("🔍 QUESTIONNAIRE: User doesn't track, skipping to life motivation question")
    }
    
    private func completeQuestionnaire() {
        guard viewModel.canProceed else { return }
        
        // CRITICAL FIX: Save questionnaire data before proceeding
        questionnaireManager.saveQuestionnaireData(from: viewModel)
        
        // Clear persisted questionnaire state since we're done
        UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")
        
        // If the current question is life motivation and we're in the questionnaire flow,
        // we should trigger navigation to sign in with Apple
        if viewModel.currentQuestion == .lifeMotivation {
            // This means user completed life motivation within questionnaire (no device tracking)
            // We need to signal to move to Sign in with Apple
            // Since we can't directly navigate from here, we'll use the proceedToHealthPermissions
            // binding but the parent will need to check this condition
            proceedToHealthPermissions = true
        } else {
            // Normal flow - proceed to health permissions
            proceedToHealthPermissions = true
        }
        
        print("🔍 QUESTIONNAIRE: Completed questionnaire, moving to next step")
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
        withAnimation(.interpolatingSpring(stiffness: 180, damping: 20, initialVelocity: 0.5)) {
            viewModel.proceedToNextQuestion()
        }
        print("🔍 QUESTIONNAIRE: Continue to next question")
    }
}

// MARK: - Preview

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView(exitToPersonalizationIntro: .constant(false), proceedToHealthPermissions: .constant(false))
    }
} 