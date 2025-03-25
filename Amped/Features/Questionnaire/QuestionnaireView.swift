import SwiftUI

/// Questionnaire view for collecting additional health metrics
struct QuestionnaireView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = QuestionnaireViewModel()
    @Environment(\.themeManager) private var themeManager
    
    // Drag gesture state
    @State private var dragOffset: CGFloat = 0
    @State private var dragDirection: Edge? = nil
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
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
                                viewModel.moveBackToPreviousQuestion()
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
                                    .transition(getTransition(for: dragDirection))
                                    .zIndex(viewModel.currentQuestion == question ? 1 : 0)
                            }
                        }
                    }
                    .animation(dragDirection == nil ? .interpolatingSpring(stiffness: 300, damping: 30) : nil, value: viewModel.currentQuestion)
                    
                    Spacer()
                    
                    // Action buttons
                    if viewModel.currentQuestion == .demographics {
                        Button(action: {
                            if viewModel.isComplete {
                                onContinue?()
                            }
                        }) {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.ampedGreen)
                                .foregroundColor(.white)
                                .cornerRadius(14)
                        }
                        .hapticFeedback()
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        .disabled(!viewModel.canProceed)
                        .opacity(viewModel.canProceed ? 1 : 0.6)
                    }
                    
                    // Progress indicator at bottom - consistent with other screens
                    ProgressIndicator(currentStep: viewModel.currentStep, totalSteps: viewModel.totalSteps)
                        .padding(.bottom, 40)
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if abs(gesture.translation.width) > abs(gesture.translation.height) {
                                // Determine drag direction
                                if gesture.translation.width < 0 && viewModel.canProceed {
                                    // Dragging to the left (forward)
                                    dragDirection = .leading
                                    
                                    // Create smoother drag with spring-like resistance
                                    let resistance = 1.0 - min(abs(gesture.translation.width) / geometry.size.width, 0.5) * 0.2
                                    dragOffset = max(gesture.translation.width, -geometry.size.width) * resistance
                                } else if gesture.translation.width > 0 && viewModel.canMoveBack {
                                    // Dragging to the right (backward)
                                    dragDirection = .trailing
                                    
                                    // Create smoother drag with spring-like resistance
                                    let resistance = 1.0 - min(abs(gesture.translation.width) / geometry.size.width, 0.5) * 0.2
                                    dragOffset = min(gesture.translation.width, geometry.size.width) * resistance
                                }
                            }
                        }
                        .onEnded { gesture in
                            guard dragDirection != nil else { return }
                            
                            // Calculate if the drag was significant enough to trigger navigation
                            let threshold: CGFloat = geometry.size.width * 0.2 // Reduced threshold for easier swiping
                            
                            if dragDirection == .leading && abs(dragOffset) > threshold && viewModel.canProceed {
                                // Dragged left past threshold - move forward
                                viewModel.proceedToNextQuestion()
                            } else if dragDirection == .trailing && abs(dragOffset) > threshold && viewModel.canMoveBack {
                                // Dragged right past threshold - move backward
                                viewModel.moveBackToPreviousQuestion()
                            }
                            
                            // Reset drag state with animation
                            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                                dragOffset = 0
                                dragDirection = nil
                            }
                        }
                )
            }
        }
    }
    
    // Get the appropriate transition based on the drag direction
    private func getTransition(for direction: Edge?) -> AnyTransition {
        guard let direction = direction else {
            // Default transition for programmatic navigation
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
        
        // Return the correct directional transition based on swipe
        switch direction {
        case .leading:
            // Forward navigation (left swipe)
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .trailing:
            // Backward navigation (right swipe)
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        default:
            // Fallback
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
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
                .foregroundColor(themeManager.currentTheme.textColor)
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
            
            // Continue button at very bottom
            Button(action: { viewModel.proceedToNextQuestion() }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ampedGreen)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .hapticFeedback()
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
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(UserProfile.Gender.allCases.filter { $0 != .preferNotToSay }, id: \.self) { gender in
                    Button(action: {
                        viewModel.selectedGender = gender
                        viewModel.proceedToNextQuestion()
                    }) {
                        HStack {
                            Text(gender.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedGender == gender {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedGender == gender ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                    .hapticFeedback(.selection)
                }
                
                Button(action: {
                    viewModel.selectedGender = .preferNotToSay
                    viewModel.proceedToNextQuestion()
                }) {
                    HStack {
                        Text("Prefer not to say")
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if viewModel.selectedGender == .preferNotToSay {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ampedGreen)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.selectedGender == .preferNotToSay ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
                .foregroundColor(themeManager.currentTheme.textColor)
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
                        HStack {
                            Text(diet.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedDiet == diet {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedDiet == diet ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
                .foregroundColor(themeManager.currentTheme.textColor)
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
                        HStack {
                            Text(frequency.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedExerciseFrequency == frequency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedExerciseFrequency == frequency ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
                .foregroundColor(themeManager.currentTheme.textColor)
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
                        HStack {
                            Text(duration.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedSleepDuration == duration {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedSleepDuration == duration ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
                .foregroundColor(themeManager.currentTheme.textColor)
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
                        HStack {
                            Text(level.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedStressLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedStressLevel == level ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
                .foregroundColor(themeManager.currentTheme.textColor)
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
                        HStack {
                            Text(frequency.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedSocializationFrequency == frequency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedSocializationFrequency == frequency ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
                .foregroundColor(themeManager.currentTheme.textColor)
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
                        HStack {
                            Text(status.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedSmokingStatus == status {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedSmokingStatus == status ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
                .foregroundColor(themeManager.currentTheme.textColor)
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
                        HStack {
                            Text(frequency.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedAlcoholFrequency == frequency {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedAlcoholFrequency == frequency ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
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
                .foregroundColor(themeManager.currentTheme.textColor)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
            
            Spacer()
            
            // Options at bottom for thumb access
            VStack(spacing: 12) {
                ForEach(QuestionnaireViewModel.WeightRange.allCases, id: \.self) { range in
                    Button(action: {
                        viewModel.selectedWeightRange = range
                        viewModel.proceedToNextQuestion()
                    }) {
                        HStack {
                            Text(range.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if viewModel.selectedWeightRange == range {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.ampedGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(viewModel.selectedWeightRange == range ? Color.ampedGreen : Color.gray.opacity(0.3), lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity)
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
            case .underFiftyFive: return "Under 55 kg (121 lbs)"
            case .fiftyFiveToSeventy: return "55-70 kg (121-154 lbs)"
            case .seventyToEightyFive: return "70-85 kg (154-187 lbs)"
            case .eightyFiveToHundred: return "85-100 kg (187-220 lbs)"
            case .overHundred: return "Over 100 kg (220 lbs)"
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
    
    var progressPercentage: Double {
        let questionIndex = Double(currentQuestion.rawValue)
        let totalQuestions = Double(Question.allCases.count)
        return min(1.0, (questionIndex + 0.5) / totalQuestions)
    }
    
    // Proceed to next question with animation
    func proceedToNextQuestion() {
        guard canProceed else { return }
        
        if let nextQuestion = getNextQuestion() {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
                currentQuestion = nextQuestion
            }
        }
    }
    
    // Move back to previous question with animation
    func moveBackToPreviousQuestion() {
        if let prevQuestion = getPreviousQuestion() {
            withAnimation(.interpolatingSpring(stiffness: 300, damping: 30)) {
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
        QuestionnaireView(onContinue: {})
    }
} 