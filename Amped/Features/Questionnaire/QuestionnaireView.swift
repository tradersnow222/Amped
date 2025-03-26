import SwiftUI

/// Questionnaire view for collecting additional health metrics
struct QuestionnaireView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = QuestionnaireViewModel()
    @Environment(\.themeManager) private var themeManager
    
    // Drag gesture state
    @State private var dragOffset: CGFloat = 0
    @State private var dragDirection: Edge? = nil
    @State private var isBackButtonTapped: Bool = false
    
    // Navigation bindings
    @Binding var exitToPersonalizationIntro: Bool
    @Binding var proceedToHealthPermissions: Bool
    
    // MARK: - Initializers
    
    init(exitToPersonalizationIntro: Binding<Bool>, proceedToHealthPermissions: Binding<Bool>) {
        self._exitToPersonalizationIntro = exitToPersonalizationIntro
        self._proceedToHealthPermissions = proceedToHealthPermissions
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
                                handleBackNavigation()
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
                                    .offset(x: calculateOffset(for: question, geometry: geometry))
                                    .transition(getTransition())
                                    .zIndex(viewModel.currentQuestion == question ? 1 : 0)
                            }
                        }
                    }
                    .animation(dragDirection == nil ? .interpolatingSpring(stiffness: 150, damping: 20, initialVelocity: 0.3) : nil, value: viewModel.currentQuestion)
                    
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
                        handleDragChanged(gesture, geometry: geometry)
                    }
                    .onEnded { gesture in
                        handleDragEnded(gesture, geometry: geometry)
                    }
            )
        }
    }
    
    // MARK: - Gesture Handling
    
    private func handleDragChanged(_ gesture: DragGesture.Value, geometry: GeometryProxy) {
        // Add debug log
        print("🔍 QUESTIONNAIRE: Drag detected, translation=\(gesture.translation)")
        
        // Reset back button flag when user starts dragging
        isBackButtonTapped = false
        
        // Only consider horizontal drags that are significantly more horizontal than vertical
        if abs(gesture.translation.width) > abs(gesture.translation.height) * 1.5 {
            // Only allow backward (right) swipes, not forward (left) swipes
            if gesture.translation.width > 0 && viewModel.canMoveBack {
                // Dragging right (backward)
                dragDirection = .trailing
                
                // Create smoother drag with spring-like resistance
                let resistance = 1.0 - min(abs(gesture.translation.width) / geometry.size.width, 0.5) * 0.2
                dragOffset = min(gesture.translation.width, geometry.size.width) * resistance
                print("🔍 QUESTIONNAIRE: Backward drag, offset=\(dragOffset), isFirstQuestion=\(viewModel.isFirstQuestion), canMoveBack=\(viewModel.canMoveBack)")
            }
        }
    }
    
    private func handleDragEnded(_ gesture: DragGesture.Value, geometry: GeometryProxy) {
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
            if viewModel.isFirstQuestion {
                // If at first question, signal parent to navigate back to personalization intro
                print("🔍 QUESTIONNAIRE: Backward swipe at first question - signaling parent")
                exitToPersonalizationIntro = true
            } else {
                // For any other question, navigate internally
                print("🔍 QUESTIONNAIRE: Backward swipe to previous question, currentQuestion=\(viewModel.currentQuestion)")
                viewModel.moveBackToPreviousQuestion()
            }
        } else {
            print("🔍 QUESTIONNAIRE: Drag threshold not met, canceling navigation")
        }
        
        // Reset drag state with animation - use consistent speed with app-wide animations but slower and more deliberate
        withAnimation(.interpolatingSpring(stiffness: 150, damping: 20, initialVelocity: 0.3)) {
            dragOffset = 0
            // Keep dragDirection set until animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                dragDirection = nil
            }
        }
    }
    
    // MARK: - Navigation Handling
    
    private func handleBackNavigation(isSwipe: Bool = false) {
        if viewModel.isFirstQuestion {
            // At first question, navigate back to personalization intro
            isBackButtonTapped = true
            print("🔍 QUESTIONNAIRE: Back to previous onboarding screen (personalization intro)")
            
            // Signal to parent to navigate back
            exitToPersonalizationIntro = true
        } else {
            // For any other question, navigate internally within questionnaire
            isBackButtonTapped = true
            viewModel.moveBackToPreviousQuestion()
            print("🔍 QUESTIONNAIRE: Back to previous question")
            
            // Reset flag after transition completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isBackButtonTapped = false
            }
        }
    }
    
    // Get the appropriate transition based on navigation context
    private func getTransition() -> AnyTransition {
        // For back button navigation
        if isBackButtonTapped {
            print("🔍 QUESTIONNAIRE: Back button transition (right to left appearance)")
            // For back button taps, the old view should move right (trailing) while the new view comes from left (leading)
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
        
        // For gesture-based navigation
        if let direction = dragDirection {
            switch direction {
            case .leading:
                // Forward navigation (left swipe)
                print("🔍 QUESTIONNAIRE: Forward swipe transition")
                // When swiping left (forward), old view moves left while new view comes from right
                return .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            case .trailing:
                // Backward navigation (right swipe)
                print("🔍 QUESTIONNAIRE: Backward swipe transition")
                // When swiping right (backward), old view moves right while new view comes from left
                return .asymmetric(
                    insertion: AnyTransition.move(edge: .leading)
                        .combined(with: .opacity)
                        .animation(.interpolatingSpring(stiffness: 150, damping: 20, initialVelocity: 0.3).delay(0.05)),
                    removal: AnyTransition.move(edge: .trailing)
                        .combined(with: .opacity)
                        .animation(.interpolatingSpring(stiffness: 150, damping: 20, initialVelocity: 0.3))
                )
            default:
                // Fallback
                print("🔍 QUESTIONNAIRE: Default transition (unknown direction)")
                return .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            }
        }
        
        // Default transition for other programmatic navigation (Continue button)
        print("🔍 QUESTIONNAIRE: Default continue button transition")
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    // Calculate the offset for the current question based on drag
    private func calculateOffset(for question: QuestionnaireViewModel.Question, geometry: GeometryProxy) -> CGFloat {
        guard question == viewModel.currentQuestion else { return 0 }
        
        if dragDirection == .leading || dragDirection == .trailing {
            return dragOffset
        }
        
        return 0
    }
    
    // MARK: - UI Components
    
    /// Get the view for a specific question
    @ViewBuilder
    private func questionView(for question: QuestionnaireViewModel.Question) -> some View {
        switch question {
        case .birthdate:
            birthdateQuestionView
        case .gender:
            genderQuestionView
        case .diet:
            dietQuestionView
        case .exercise:
            exerciseQuestionView
        case .sleep:
            sleepQuestionView
        case .stress:
            stressQuestionView
        case .socialization:
            socializationQuestionView
        case .smoking:
            smokingQuestionView
        case .alcohol:
            alcoholQuestionView
        case .demographics:
            demographicsQuestionView
        }
    }
    
    // Birthdate question
    private var birthdateQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question text placed higher
            Text("When were you born?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)

            Spacer()

            // DatePicker positioned at bottom for thumb access
            DatePicker("", selection: $viewModel.birthdate, in: viewModel.birthdateRange, displayedComponents: .date)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .colorScheme(.dark)
            
            // Continue button at very bottom
            Button(action: handleContinue) {
                Text("Continue")
                    .fontWeight(.bold)
                    .font(.system(.title3, design: .default))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ampedGreen)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .hapticFeedback()
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
            .opacity(viewModel.canProceed ? 1 : 0.6)
            .disabled(!viewModel.canProceed)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Gender question
    private var genderQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("What is your biological sex?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
                .onAppear {
                    print("Gender question appeared. Selected gender: \(viewModel.selectedGender)")
                    // Reset selected gender to ensure correct styling
                    viewModel.selectedGender = .preferNotToSay
                }
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(["Male", "Female"], id: \.self) { gender in
                    Button(action: {
                        viewModel.selectedGender = gender == "Male" ? .male : .female
                        print("Selected gender: \(viewModel.selectedGender)")
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text(gender)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((gender == "Male" && viewModel.selectedGender == .male) || 
                                         (gender == "Female" && viewModel.selectedGender == .female) ?
                                         Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                    .hapticFeedback(.selection)
                }
                
                Button(action: {
                    viewModel.selectedGender = .preferNotToSay
                    print("Selected 'Prefer not to say', gender: \(viewModel.selectedGender)")
                    viewModel.proceedToNextQuestion()
                }) {
                    Text("Prefer not to say")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Diet question
    private var dietQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("How would you describe your diet?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.DietType.allCases, id: \.self) { diet in
                    Button(action: {
                        viewModel.selectedDiet = diet
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text(diet.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedDiet == diet ? Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Exercise question
    private var exerciseQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("How often do you exercise?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.ExerciseFrequency.allCases, id: \.self) { frequency in
                    Button(action: {
                        viewModel.selectedExerciseFrequency = frequency
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text(frequency.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedExerciseFrequency == frequency ? Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Sleep question
    private var sleepQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("How much sleep do you typically get each night?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.SleepDuration.allCases, id: \.self) { duration in
                    Button(action: {
                        viewModel.selectedSleepDuration = duration
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text(duration.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedSleepDuration == duration ? Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Stress question
    private var stressQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("How would you rate your typical stress level?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.StressLevel.allCases, id: \.self) { level in
                    Button(action: {
                        viewModel.selectedStressLevel = level
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text(level.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedStressLevel == level ? Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Socialization question
    private var socializationQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("How often do you socialize with friends, family, or community?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.SocializationFrequency.allCases, id: \.self) { frequency in
                    Button(action: {
                        viewModel.selectedSocializationFrequency = frequency
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text(frequency.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedSocializationFrequency == frequency ? Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Smoking question
    private var smokingQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("Do you smoke tobacco products?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.SmokingStatus.allCases, id: \.self) { status in
                    Button(action: {
                        viewModel.selectedSmokingStatus = status
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text(status.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedSmokingStatus == status ? Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Alcohol question
    private var alcoholQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("How often do you consume alcoholic beverages?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.AlcoholFrequency.allCases, id: \.self) { frequency in
                    Button(action: {
                        viewModel.selectedAlcoholFrequency = frequency
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text(frequency.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedAlcoholFrequency == frequency ? Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // Demographics question
    private var demographicsQuestionView: some View {
        VStack(alignment: .center, spacing: 0) {
            // Question placed higher
            Text("Finally, what is your current weight range?")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
                .onAppear {
                    print("Demographics question appeared. Selected weight range: \(String(describing: viewModel.selectedWeightRange))")
                    print("canProceed: \(viewModel.canProceed)")
                }
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.WeightRange.allCases, id: \.self) { range in
                    Button(action: {
                        viewModel.selectedWeightRange = range
                        print("Selected weight range: \(range)")
                        
                        // This is the final question, so we need to move to the next onboarding step
                        completeQuestionnaire()
                    }) {
                        Text(range.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedWeightRange == range ? Color.ampedGreen : Color.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Completing the Questionnaire

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

// MARK: - ViewModel

final class QuestionnaireViewModel: ObservableObject {
    enum Question: Int, CaseIterable, Hashable {
        case birthdate
        case gender
        case diet
        case exercise
        case sleep
        case stress
        case socialization
        case smoking
        case alcohol
        case demographics
    }
    
    enum DietType: CaseIterable {
        case mostlyPlantBased
        case balanced
        case highProteinLowCarb
        case processedFoods
        
        var displayName: String {
            switch self {
            case .mostlyPlantBased: return "Mostly Plant Based"
            case .balanced: return "Balanced Mix"
            case .highProteinLowCarb: return "High Protein/Low Carb"
            case .processedFoods: return "Mostly Processed Foods"
            }
        }
        
        var nutritionValue: Double {
            switch self {
            case .mostlyPlantBased: return 9.0
            case .balanced: return 7.0
            case .highProteinLowCarb: return 5.5
            case .processedFoods: return 3.0
            }
        }
    }
    
    enum ExerciseFrequency: CaseIterable {
        case daily
        case severalTimesWeek
        case onceWeek
        case rarelyOrNever
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .severalTimesWeek: return "Several times a week"
            case .onceWeek: return "Once a week"
            case .rarelyOrNever: return "Rarely or never"
            }
        }
        
        var exerciseValue: Double {
            switch self {
            case .daily: return 9.0
            case .severalTimesWeek: return 7.0
            case .onceWeek: return 5.0
            case .rarelyOrNever: return 2.0
            }
        }
    }
    
    enum SleepDuration: CaseIterable {
        case lessThan6
        case between6And7
        case between7And8
        case moreThan8
        
        var displayName: String {
            switch self {
            case .lessThan6: return "Less than 6 hours"
            case .between6And7: return "6-7 hours"
            case .between7And8: return "7-8 hours"
            case .moreThan8: return "More than 8 hours"
            }
        }
        
        var sleepValue: Double {
            switch self {
            case .lessThan6: return 4.5
            case .between6And7: return 6.5
            case .between7And8: return 7.5
            case .moreThan8: return 8.5
            }
        }
    }
    
    enum StressLevel: CaseIterable {
        case high
        case moderate
        case low
        case veryLow
        
        var displayName: String {
            switch self {
            case .high: return "High"
            case .moderate: return "Moderate"
            case .low: return "Low"
            case .veryLow: return "Very Low"
            }
        }
        
        var stressValue: Double {
            switch self {
            case .high: return 2.0
            case .moderate: return 5.0
            case .low: return 7.0
            case .veryLow: return 9.0
            }
        }
    }
    
    enum SocializationFrequency: CaseIterable {
        case daily
        case severalTimesWeek
        case weeklyOrMonthly
        case rarely
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .severalTimesWeek: return "Several times a week"
            case .weeklyOrMonthly: return "Weekly or monthly"
            case .rarely: return "Rarely or never"
            }
        }
        
        var socializationValue: Double {
            switch self {
            case .daily: return 9.0
            case .severalTimesWeek: return 7.5
            case .weeklyOrMonthly: return 5.0
            case .rarely: return 2.0
            }
        }
    }
    
    enum SmokingStatus: CaseIterable {
        case daily
        case occasionally
        case former
        case never
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .occasionally: return "Occasionally"
            case .former: return "Former smoker"
            case .never: return "Never"
            }
        }
        
        var smokingValue: Double {
            switch self {
            case .daily: return 1.0
            case .occasionally: return 3.0
            case .former: return 6.0
            case .never: return 9.0
            }
        }
    }
    
    enum AlcoholFrequency: CaseIterable {
        case daily
        case severalTimesWeek
        case occasionally
        case never
        
        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .severalTimesWeek: return "Several times a week"
            case .occasionally: return "Occasionally (weekly or less)"
            case .never: return "Never"
            }
        }
        
        var alcoholValue: Double {
            switch self {
            case .daily: return 3.0
            case .severalTimesWeek: return 4.0
            case .occasionally: return 7.0
            case .never: return 9.0
            }
        }
    }
    
    enum WeightRange: CaseIterable {
        case underFiftyFive
        case fiftyFiveToSeventy
        case seventyToEightyFive
        case eightyFiveToHundred
        case overHundred
        
        var displayName: String {
            switch self {
            case .underFiftyFive: return "Under 121 lbs (55 kg)"
            case .fiftyFiveToSeventy: return "121-154 lbs (55-70 kg)"
            case .seventyToEightyFive: return "154-187 lbs (70-85 kg)"
            case .eightyFiveToHundred: return "187-220 lbs (85-100 kg)"
            case .overHundred: return "Over 220 lbs (100 kg)"
            }
        }
        
        var weightValue: Double {
            switch self {
            case .underFiftyFive: return 50.0
            case .fiftyFiveToSeventy: return 62.5
            case .seventyToEightyFive: return 77.5
            case .eightyFiveToHundred: return 92.5
            case .overHundred: return 110.0
            }
        }
    }
    
    enum WeightUnit {
        case kg
        case lbs
    }
    
    // Form data
    @Published var currentQuestion: Question = .birthdate
    
    // Birthdate (replacing age)
    @Published var birthdate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date() // Default to 30 years ago
    
    // Birthdate range calculation
    var birthdateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        
        let maxDate = Date() // Today (no future dates)
        let minDate = calendar.date(byAdding: .year, value: -120, to: Date()) ?? Date() // Max 120 years ago
        
        return minDate...maxDate
    }
    
    // Calculate age from birthdate
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year ?? 0
    }
    
    // Gender
    @Published var selectedGender: UserProfile.Gender = .preferNotToSay
    
    // Diet
    @Published var selectedDiet: DietType?
    
    // Exercise
    @Published var selectedExerciseFrequency: ExerciseFrequency?
    
    // Sleep
    @Published var selectedSleepDuration: SleepDuration?
    
    // Stress
    @Published var selectedStressLevel: StressLevel?
    
    // Socialization
    @Published var selectedSocializationFrequency: SocializationFrequency?
    
    // Smoking
    @Published var selectedSmokingStatus: SmokingStatus?
    
    // Alcohol
    @Published var selectedAlcoholFrequency: AlcoholFrequency?
    
    // Weight (replacing text field with range selection)
    @Published var selectedWeightRange: WeightRange?
    
    // Progress tracking for indicator
    var currentStep: Int {
        currentQuestion.rawValue + 3 // Offset by 3 to account for previous onboarding steps
    }
    var totalSteps: Int {
        7 // Match the total steps in the onboarding flow
    }
    
    var isComplete: Bool {
        currentQuestion == Question.demographics && canProceed
    }
    
    // Check if it's possible to proceed to the next question
    var canProceed: Bool {
        switch currentQuestion {
        case .birthdate:
            return age >= 18 && age <= 120 // Validate age from birthdate
        case .gender:
            return true // Always has a default
        case .diet:
            return selectedDiet != nil
        case .exercise:
            return selectedExerciseFrequency != nil
        case .sleep:
            return selectedSleepDuration != nil
        case .stress:
            return selectedStressLevel != nil
        case .socialization:
            return selectedSocializationFrequency != nil
        case .smoking:
            return selectedSmokingStatus != nil
        case .alcohol:
            return selectedAlcoholFrequency != nil
        case .demographics:
            return selectedWeightRange != nil
        }
    }
    
    // Check if it's possible to move back to previous question
    var canMoveBack: Bool {
        return currentQuestion != .birthdate
    }
    
    // Check if we're at the first question
    var isFirstQuestion: Bool {
        return currentQuestion == .birthdate
    }
    
    // Check if we're at the last question
    var isLastQuestion: Bool {
        return currentQuestion == .alcohol || currentQuestion == .demographics
    }
    
    var progressPercentage: Double {
        let questionIndex = Double(currentQuestion.rawValue)
        let totalQuestions = Double(Question.allCases.count)
        return min(1.0, (questionIndex + 0.5) / totalQuestions)
    }
    
    // Proceed to next question with animation
    func proceedToNextQuestion() {
        guard canProceed else { return }
        
        if let nextQuestion = getNextQuestion() {
            withAnimation(.interpolatingSpring(stiffness: 200, damping: 25, initialVelocity: 0.5)) {
                currentQuestion = nextQuestion
            }
        }
    }
    
    // Move back to previous question with animation
    func moveBackToPreviousQuestion() {
        if let prevQuestion = getPreviousQuestion() {
            withAnimation(.interpolatingSpring(stiffness: 150, damping: 20, initialVelocity: 0.3)) {
                currentQuestion = prevQuestion
            }
        }
    }
    
    // Get the next question in sequence
    private func getNextQuestion() -> Question? {
        let nextIndex = currentQuestion.rawValue + 1
        if nextIndex < Question.allCases.count {
            return Question(rawValue: nextIndex)
        }
        return nil
    }
    
    // Get the previous question in sequence
    private func getPreviousQuestion() -> Question? {
        let prevIndex = currentQuestion.rawValue - 1
        if prevIndex >= 0 {
            return Question(rawValue: prevIndex)
        }
        return nil
    }
    
    func saveAndProceed() {
        proceedToNextQuestion()
    }
}

// MARK: - Preview

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView(exitToPersonalizationIntro: .constant(false), proceedToHealthPermissions: .constant(false))
    }
} 