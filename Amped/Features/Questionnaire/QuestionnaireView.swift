import SwiftUI
import HealthKit

/// Questionnaire view for collecting additional health metrics
struct QuestionnaireView: View {
    // MARK: - Properties
    
    // CRITICAL PERFORMANCE FIX: Accept injected viewModel instead of creating new one
    @ObservedObject private var viewModel: QuestionnaireViewModel
    @StateObject private var questionnaireManager = QuestionnaireManager()
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    // Navigation bindings
    @Binding var exitToPersonalizationIntro: Bool
    @Binding var proceedToHealthPermissions: Bool
    
    // Gesture handler
    private var gestureHandler: QuestionnaireGestureHandler
    
    // Internal state
    @State private var animationCompleted = false
    
    // CRITICAL KEYBOARD FIX: Track keyboard visibility to disable gestures
    @State private var isKeyboardVisible = false
    
    // Background control
    private let includeBackground: Bool
    
    // MARK: - Initializers
    
    init(viewModel: QuestionnaireViewModel, exitToPersonalizationIntro: Binding<Bool>, proceedToHealthPermissions: Binding<Bool>, includeBackground: Bool = true) {
        // CRITICAL PERFORMANCE FIX: Use injected viewModel instead of creating new one
        let startTime = CFAbsoluteTimeGetCurrent()
        
        self.viewModel = viewModel
        self._exitToPersonalizationIntro = exitToPersonalizationIntro
        self._proceedToHealthPermissions = proceedToHealthPermissions
        self.includeBackground = includeBackground
        
        // Use the existing view model instance for the gesture handler
        self.gestureHandler = QuestionnaireGestureHandler(
            viewModel: viewModel,
            exitToPersonalizationIntro: exitToPersonalizationIntro
        )
        
        _ = CFAbsoluteTimeGetCurrent() - startTime  // Performance timing (unused in release)
        print("🔍 PERFORMANCE_DEBUG: QuestionnaireView.init() completed")
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // CRITICAL PERFORMANCE FIX: Use optimized background that doesn't recalculate on keyboard
                if includeBackground {
                    Color.clear.withOptimizedDeepBackground()
                }
                
                ZStack {
                    // ULTRA-STABLE: Completely static overlay layer - NEVER transitions, NEVER recreates
                    VStack(spacing: 0) {
                        // Back button - static overlay (needs hit testing enabled)
                        HStack {
                            if viewModel.canMoveBack {
                                BackButton(action: {
                                    gestureHandler.handleBackNavigation()
                                }, showText: false)
                                .allowsHitTesting(true) // Ensure back button is tappable
                            }
                            Spacer()
                                .allowsHitTesting(false) // Let spacer pass gestures through
                        }
                        .padding(.top, 16)
                        .padding(.leading, 8)
                        .frame(height: 42)
                        
                        // CategoryHeader - COMPLETELY STATIC OVERLAY (never recreated)
                        CategoryHeader(category: viewModel.currentQuestionCategory)
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity)
                            .fixedSize(horizontal: false, vertical: true)
                            .id("static_category_header") // Static ID - never changes
                            .allowsHitTesting(false) // Let gestures pass through header
                        
                        Spacer()
                            .allowsHitTesting(false) // Let gestures pass through spacer
                        
                        // Progress indicator - static overlay  
                        ProgressIndicator(currentStep: viewModel.currentStep, totalSteps: viewModel.totalSteps)
                            .padding(.bottom, 10)
                            .allowsHitTesting(false) // Let gestures pass through progress indicator
                    }
                    .zIndex(1000) // Always on top
                    // Removed global allowsHitTesting(false) and applied selectively instead
                    
                    // Content layer - this animates but overlay stays put
                    VStack(spacing: 0) {
                        // Top spacer for CategoryHeader
                        Spacer().frame(height: 100) // Fixed space for header
                        
                        // Animated content - NO ID to prevent view recreation
                        ZStack {
                            questionView(for: viewModel.currentQuestion)
                                .padding()
                                .transition(getAdaptiveTransition())
                        }
                        .clipped()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Bottom spacer for progress indicator
                        Spacer().frame(height: 60) // Fixed space for progress
                    }
                }
                .withDeepBackgroundTheme()
            }
            // CRITICAL KEYBOARD FIX: Only apply gestures when keyboard is NOT visible
            .contentShape(Rectangle()) // Ensure the entire area responds to gestures
            .gesture(
                isKeyboardVisible ? nil :
                DragGesture(minimumDistance: 10, coordinateSpace: .local) // iOS-STANDARD: Lower threshold for more responsive feel
                    .onChanged { gesture in
                        // CRITICAL: Don't process gestures if keyboard is visible
                        guard !isKeyboardVisible else { return }
                        
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
                        // CRITICAL: Don't process gestures if keyboard is visible
                        guard !isKeyboardVisible else { return }
                        
                        gestureHandler.handleDragEnded(gesture, geometry: geometry) {
                            animationCompleted = true
                        }
                    }
            )
        }
        // Applied rule: Simplicity is KING — let system avoid keyboard on the name screen only
        .modifier(ConditionalKeyboardIgnore(shouldIgnore: viewModel.currentQuestion != .name))
        .adaptiveSpacing() // Apply adaptive spacing environment
        // CRITICAL KEYBOARD FIX: Track keyboard visibility to disable gestures and prevent lag
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
            print("🔍 KEYBOARD_DEBUG: Keyboard will show - disabling gestures")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
            print("🔍 KEYBOARD_DEBUG: Keyboard will hide - enabling gestures")
        }
        .onAppear {
            // Rules: Simplicity is KING - removed background initialization
            // HealthKit will be initialized when actually needed
        }
    }
    
    // MARK: - Adaptive Transition
    private func getAdaptiveTransition() -> AnyTransition {
        // Applied rule: Simplicity is KING — use consistent transitions throughout
        // Use the same slide transitions for all questions, including birthdate picker
        
        // CRITICAL FIX: When exiting to parent (OnboardingFlow), let the parent handle the transition
        // to avoid conflicting animations that cause wrong exit direction
        if exitToPersonalizationIntro {
            return .identity // No internal transition - let OnboardingFlow handle it
        }
        
        // Use consistent transitions for all questions
        // The nested animation issue has been fixed, so we use the same transitions everywhere
        switch viewModel.navigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
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
            case .name:
                QuestionViews.NameQuestionView(
                    viewModel: viewModel
                )
            case .birthdate:
                QuestionViews.BirthdateQuestionView(
                    viewModel: viewModel, 
                    handleContinue: handleContinue
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
        
        // UX: Luxury slow spring to match onboarding transitions
        // Avoid nested animations during heavy view changes
        withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
            viewModel.currentQuestion = .lifeMotivation
        }
        
        print("🔍 QUESTIONNAIRE: HealthKit authorized, moving to life motivation question")
        print("🔍 QUESTIONNAIRE: Current question after navigation: \(viewModel.currentQuestion)")
    }
    
    private func skipToLifeMotivation() {
        // User doesn't track health, move directly to life motivation question
        // Set forward direction for proper iOS-standard transition
        viewModel.navigationDirection = .forward
        
        // UX: Luxury slow spring to match onboarding transitions
        // Avoid nested animations during heavy view changes
        withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
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
        
        // UX: Luxury slow spring to match onboarding transitions
        // Avoid double-wrapping the internal animation inside proceedToNextQuestion
        viewModel.proceedToNextQuestion()
    }
}

// MARK: - Keyboard Safe-Area Helper

/// Conditionally ignore the keyboard safe area. When `shouldIgnore` is true
/// the view behaves like `.ignoresSafeArea(.keyboard)`. When false, the system
/// will move content above the keyboard automatically.
private struct ConditionalKeyboardIgnore: ViewModifier {
    let shouldIgnore: Bool
    func body(content: Content) -> some View {
        Group {
            if shouldIgnore {
                content.ignoresSafeArea(.keyboard)
            } else {
                content
            }
        }
    }
}

// MARK: - Preview

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView(
            viewModel: QuestionnaireViewModel(startFresh: true),
            exitToPersonalizationIntro: .constant(false), 
            proceedToHealthPermissions: .constant(false)
        )
    }
}
