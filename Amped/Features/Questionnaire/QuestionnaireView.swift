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
    
    init(exitToPersonalizationIntro: Binding<Bool>, proceedToHealthPermissions: Binding<Bool>, startFresh: Bool = false) {
        self._exitToPersonalizationIntro = exitToPersonalizationIntro
        self._proceedToHealthPermissions = proceedToHealthPermissions
        
        // Create the StateObject before init completes
        // CRITICAL FIX: Pass startFresh parameter to ensure fresh start when needed
        let viewModel = QuestionnaireViewModel(startFresh: startFresh)
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
                
                VStack(spacing: 0) {
                    // Category header at the very top - CRITICAL FIX: Prevent wrapping with fixed positioning
                    if viewModel.shouldShowCategoryHeader {
                        CategoryHeader(category: viewModel.currentQuestionCategory)
                            .padding(.top, 16)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true) // Prevent wrapping
                    }
                    
                    // Navigation header with back button - Rules: Using consistent BackButton component
                    if viewModel.canMoveBack {
                        HStack {
                            BackButton(action: {
                                gestureHandler.handleBackNavigation()
                            }, showText: false)
                            
                            Spacer()
                        }
                        .padding(.top, viewModel.shouldShowCategoryHeader ? 12 : 16)
                        .padding(.leading, 8)
                    } else {
                        // Empty space for consistent layout
                        HStack {
                            Spacer()
                        }
                        .frame(height: viewModel.shouldShowCategoryHeader ? 54 : 42)
                    }
                    
                    // Add spacer to push question down - adjusted for category header
                    Spacer().frame(height: geometry.size.height * (viewModel.shouldShowCategoryHeader ? 0.08 : 0.15))
                    
                    // Current question view - CRITICAL PERFORMANCE FIX: Ultra-smooth transitions
                    ZStack {
                        questionView(for: viewModel.currentQuestion)
                            .padding()
                            .id("question_\(viewModel.currentQuestion.rawValue)")
                            .transition(getDirectionalTransition())
                    }
                    .clipped() // Ensure off-screen content doesn't show
                    .animation(
                        .easeInOut(duration: 0.15), // ULTRA-PERFORMANCE: Even shorter duration for zero-lag feel
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
            // OPTIMIZED: Simplified gesture handling with better performance
            .contentShape(Rectangle()) // Ensure the entire area responds to gestures
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local) // iOS-STANDARD: Lower threshold for more responsive feel
                    .onChanged { gesture in
                        // iOS-STANDARD: Process horizontal movements with standard iOS sensitivity
                        let horizontalDistance = abs(gesture.translation.width)
                        let verticalDistance = abs(gesture.translation.height)
                        
                        // iOS-STANDARD: Use standard 1.3x ratio for horizontal gesture recognition
                        guard horizontalDistance > verticalDistance * 1.3 && horizontalDistance > 8 else {
                            return
                        }
                        
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
            // CRITICAL PERFORMANCE FIX: Zero main thread blocking on appear
            // Move ALL initialization to background with lowest priority
            DispatchQueue.global(qos: .background).async {
                // Only pre-warm if HealthKit is available
                guard HKHealthStore.isHealthDataAvailable() else { return }
                
                // Pre-compute health types in background
                _ = HealthKitManager.precomputedHealthTypes
                
                // Initialize HealthKit manager in background
                _ = HealthKitManager.shared
            }
        }
    }
    
    // MARK: - Direction-Aware Transitions
    
    /// Get the appropriate transition based on navigation direction (iOS standard)
    private func getDirectionalTransition() -> AnyTransition {
        switch viewModel.navigationDirection {
        case .forward:
            // Forward navigation: new content slides in from right, old content exits to left
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            // Backward navigation: new content slides in from left, old content exits to right
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
    
    // MARK: - Question Views
    
    /// Get the view for a specific question
    @ViewBuilder
    private func questionView(for question: QuestionnaireViewModel.Question) -> some View {
        VStack(spacing: 0) {
            // Question content (category header moved to top level)
            switch question {
            case .birthdate:
                QuestionViews.BirthdateQuestionView(
                    viewModel: viewModel, 
                    handleContinue: handleContinue
                )
            case .name:
                QuestionViews.NameQuestionView(
                    viewModel: viewModel
                )
            case .stressLevel:
                QuestionViews.StressQuestionView(
                    viewModel: viewModel
                )
            case .anxietyLevel:
                QuestionViews.AnxietyQuestionView(
                    viewModel: viewModel
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
            case .sleepQuality:
                QuestionViews.SleepQualityQuestionView(
                    viewModel: viewModel
                )
            case .bloodPressureAwareness:
                QuestionViews.BloodPressureAwarenessQuestionView(
                    viewModel: viewModel
                )
            case .deviceTracking:
                QuestionViews.DeviceTrackingQuestionView(
                    viewModel: viewModel,
                    proceedToHealthKit: proceedToHealthKit,
                    skipToLifeMotivation: skipToLifeMotivation
                )
            case .framingComfort:
                QuestionViews.FramingComfortQuestionView(
                    viewModel: viewModel
                )
            case .urgencyResponse:
                QuestionViews.UrgencyResponseQuestionView(
                    viewModel: viewModel
                )
            case .lifeMotivation:
                QuestionViews.LifeMotivationQuestionView(
                    viewModel: viewModel,
                    completeQuestionnaire: completeQuestionnaire
                )
            }
        }
    }
    
    // MARK: - Navigation Handling
    
    private func proceedToHealthKit() {
        print("🔍 QUESTIONNAIRE: proceedToHealthKit called")
        print("🔍 QUESTIONNAIRE: Current question before navigation: \(viewModel.currentQuestion)")
        
        // Save questionnaire data before proceeding
        questionnaireManager.saveQuestionnaireData(from: viewModel)
        
        // Set forward direction for proper iOS-standard transition
        viewModel.navigationDirection = .forward
        
        // iOS-STANDARD: Move to life motivation with proper timing
        withAnimation(.easeInOut(duration: 0.35)) {
            viewModel.currentQuestion = .lifeMotivation
        }
        
        print("🔍 QUESTIONNAIRE: HealthKit authorized, moving to life motivation question")
        print("🔍 QUESTIONNAIRE: Current question after navigation: \(viewModel.currentQuestion)")
    }
    
    private func skipToLifeMotivation() {
        // User doesn't track health, move directly to life motivation question
        // Set forward direction for proper iOS-standard transition
        viewModel.navigationDirection = .forward
        
        // iOS-STANDARD: Use proper timing for smooth transitions
        withAnimation(.easeInOut(duration: 0.35)) {
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
            completeQuestionnaire()
            return
        }
        
        // Set forward direction for proper iOS-standard transition
        viewModel.navigationDirection = .forward
        
        // iOS-STANDARD: Proper timing for smooth, natural feeling transitions
        withAnimation(.easeInOut(duration: 0.35)) {
            viewModel.proceedToNextQuestion()
        }
    }
}

// MARK: - Preview

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView(exitToPersonalizationIntro: .constant(false), proceedToHealthPermissions: .constant(false))
    }
}
