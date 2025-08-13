import SwiftUI
import HealthKit
import UIKit

/// Helper function to create category header for questions
func CategoryHeader(category: QuestionnaireViewModel.QuestionCategory) -> some View {
    // Applied rule: Simplicity is KING; match category style to scientific citation style
    VStack(spacing: 8) {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(height: 1)

            Text(category.displayName)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 12)
                .tracking(1.0)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)

            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}

// MARK: - Utilities
/// Removes the default dimming and background from SwiftUI .sheet for a clearer presentation
/// Simplicity is KING: small, focused modifier
struct ClearSheetBackground: ViewModifier {
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 16.4, *) {
                content
                    .background(.clear)
                    .presentationBackground(.clear)
                    .presentationCornerRadius(0) // we'll handle corner shape inside the popup
            } else {
                content
                    .background(.clear)
            }
        }
    }
}

/// Interactive scientific citation view with popup
struct ScientificCitation: View {
    let text: String
    let metricType: HealthMetricType?
    @State private var showPopup = false
    
    var body: some View {
        HStack {
            Button(action: {
                if metricType != nil {
                    showPopup = true
                }
            }) {
                Image(systemName: metricType != nil ? "info.circle.fill" : "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(metricType != nil ? 0.7 : 0.5))
            }
            .disabled(metricType == nil)
            
            Text(text)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(2)
                .onTapGesture {
                    if metricType != nil {
                        showPopup = true
                    }
                }
        }
        .padding(.top, 8)
        .padding(.bottom, 40) // CRITICAL FIX: Consistent spacing between citation and buttons for all questions
        .sheet(isPresented: $showPopup) {
            if let type = metricType,
               let popup = ScientificCredibilityPopupFactory.createPopup(for: type, isPresented: $showPopup) {
                popup
                    .presentationDetents([.fraction(0.54)])
                    .presentationDragIndicator(.hidden)
                    .modifier(ClearSheetBackground())
            }
        }
    }
}

/// Helper function to create formatted button content with primary and secondary text
/// Automatically detects and styles text in parentheses as smaller, greyed subtext
func FormattedButtonText(text: String, subtitle: String? = nil) -> some View {
    VStack(spacing: 4) {
        // Parse the main text to separate primary text from parentheses content
        let components = parseTextWithParentheses(text)
        
        Text(components.primary)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
        
        // Show parentheses content as smaller, greyed subtext
        if let parenthesesText = components.parentheses {
            Text(parenthesesText)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        
        // Show additional subtitle if provided
        if let subtitle = subtitle {
            Text(subtitle)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Helper function to parse text and extract content in parentheses
private func parseTextWithParentheses(_ text: String) -> (primary: String, parentheses: String?) {
    // Split by newline and look for parentheses in each line
    let lines = text.components(separatedBy: "\n")
    var primaryLines: [String] = []
    var parenthesesText: String?
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        
        // Check if line contains parentheses
        if trimmedLine.hasPrefix("(") && trimmedLine.hasSuffix(")") {
            // Extract content inside parentheses
            let startIndex = trimmedLine.index(trimmedLine.startIndex, offsetBy: 1)
            let endIndex = trimmedLine.index(trimmedLine.endIndex, offsetBy: -1)
            parenthesesText = String(trimmedLine[startIndex..<endIndex])
        } else {
            // This is primary text
            primaryLines.append(trimmedLine)
        }
    }
    
    let primaryText = primaryLines.joined(separator: "\n")
    return (primary: primaryText, parentheses: parenthesesText)
}

/// Contains all the individual question views for the questionnaire
struct QuestionViews {
    
    // MARK: - Birthdate Question
    
    struct BirthdateQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        var handleContinue: () -> Void
        
        // ULTRA-PERFORMANCE FIX: Local state to prevent excessive view updates during scrolling
        @State private var localBirthMonth: Int
        @State private var localBirthYear: Int
        
        // ULTRA-PERFORMANCE FIX: Truly static month names - zero system calls, zero lag
        private static let monthNames: [String] = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]
        
        // ULTRA-PERFORMANCE FIX: Pre-computed static year array - zero computation during scroll
        private static let yearRange: [Int] = {
            let currentYear = Calendar.current.component(.year, from: Date())
            let minYear = currentYear - 110  // 110 years old max
            let maxYear = currentYear - 5    // 5 years old min
            return Array(minYear...maxYear)
        }()
        
        // PERFORMANCE: Initialize local state to prevent picker lag
        init(viewModel: QuestionnaireViewModel, handleContinue: @escaping () -> Void) {
            self.viewModel = viewModel
            self.handleContinue = handleContinue
            self._localBirthMonth = State(initialValue: viewModel.selectedBirthMonth)
            self._localBirthYear = State(initialValue: viewModel.selectedBirthYear)
        }
        
        var body: some View {
            VStack(spacing: 0) {
                // Main content area with consistent padding
                VStack(alignment: .center, spacing: 0) {
                    // Question text placed higher - consistent with other questions
                    Text("When were you born?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    Spacer()
                    Spacer() // Additional spacer to push picker lower

                // ULTRA-FAST PERFORMANCE FIX: Zero-lag pickers with static data and no bindings during scroll
                HStack(spacing: 0) {
                        // Month Picker - ULTRA-FAST with local state to prevent view model updates during scroll
                        Picker("Month", selection: $localBirthMonth) {
                            // PERFORMANCE: Use static month names for instant rendering
                            ForEach(1...12, id: \.self) { month in
                                Text(Self.monthNames[month - 1])
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                    .tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)
                        .clipped() // PERFORMANCE: Prevent off-screen rendering
                        
                        // Year Picker - ULTRA-FAST with local state to prevent view model updates during scroll
                        Picker("Year", selection: $localBirthYear) {
                            // PERFORMANCE: Use static pre-computed array for zero-lag scrolling
                            ForEach(Self.yearRange, id: \.self) { year in
                                Text(String(year))
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)
                        .clipped() // PERFORMANCE: Prevent off-screen rendering
                }
                .frame(height: 216) // Standard iOS picker height
                .padding(.horizontal, 24)

                    Spacer()
                    Spacer() // Extra spacer for more spacing above Continue button

                // Continue button with increased spacing - CRITICAL PERFORMANCE FIX
                VStack(spacing: 12) {
                        // Compute eligibility locally to avoid binding VM during scroll
                        let currentYear = Calendar.current.component(.year, from: Date())
                        let approxAge = currentYear - localBirthYear
                        let canProceedLocal = approxAge >= 18 && approxAge <= 120
                        Button(action: {
                            // CRITICAL FIX: Sync local state to view model only on continue
                            viewModel.selectedBirthMonth = localBirthMonth
                            viewModel.selectedBirthYear = localBirthYear
                            viewModel.updateBirthdateFromMonthYear() // Now synchronous and fast
                            handleContinue()
                        }) {
                            Text("Continue")
                        }
                        .questionnaireButtonStyle(isSelected: false)
                        .opacity(canProceedLocal ? 1.0 : 0.6)
                        .disabled(!canProceedLocal)
                        .hapticFeedback(.light)
                    }
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 24)
                .frame(maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Name Question
    
    struct NameQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @FocusState private var isTextFieldFocused: Bool
        // Applied rule: Simplicity is KING — focus immediately on appear for zero perceived lag
        // PERFORMANCE: Use local text state to avoid rebinding the entire questionnaire on every keystroke
        @State private var localName: String = ""
         // PERFORMANCE: Gate keyboard focus until after transition to avoid concurrent heavy animations
         // (Rules referenced: Simplicity is KING; Security over performance; Readability over extreme optimization)
         @State private var isActive: Bool = false
         private let focusDelaySeconds: Double = 0.12
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                Text("What's your first name?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // ULTRA-FAST input container with zero animation overhead
                VStack(spacing: 12) {
                    // ULTRA-PERFORMANCE FIX: Blazingly fast TextField with minimal styling
                    TextField("Enter your name", text: $localName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(16)
                        .background(
                            // LIGHTNING-FAST: Single-layer static background for zero lag
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.12))
                        )
                        .focused($isTextFieldFocused)
                        .textInputAutocapitalization(.words)
                        .textContentType(.givenName)
                        .submitLabel(.done)
                        .disableAutocorrection(true)
                        .onSubmit {
                            let canProceedLocal = !localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            if canProceedLocal { proceedToNext() }
                        }
                    
                    // Continue button with iOS-standard timing
                    Button(action: {
                        let canProceedLocal = !localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        if canProceedLocal { proceedToNext() }
                    }) {
                        Text("Continue")
                    }
                    .questionnaireButtonStyle(isSelected: false)
                    .opacity(!localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1.0 : 0.6)
                    .disabled(localName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .hapticFeedback(.light)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
            .onAppear {
                // Sync local from view model once on appear
                localName = viewModel.userName
                // Mark active to allow delayed focus
                isActive = true
                // Defer keyboard presentation slightly so it does not overlap with the heavy wheel picker removal
                // This removes jank during the birthdate -> name transition on device
                // Also explicitly disable implicit animations for focus state to avoid extra layout work
                DispatchQueue.main.asyncAfter(deadline: .now() + focusDelaySeconds) {
                    if isActive {
                        UIView.setAnimationsEnabled(false)
                        isTextFieldFocused = true
                        UIView.setAnimationsEnabled(true)
                    }
                }
            }
            .onDisappear {
                // Cancel any pending focus if view is leaving; ensure keyboard is dismissed
                isActive = false
                isTextFieldFocused = false
            }
        }
        
        // ULTRA-FAST: Instant navigation with zero lag
        private func proceedToNext() {
            // Dismiss keyboard immediately
            isTextFieldFocused = false
            
            // PERFORMANCE: Immediate transition - no artificial delays
            DispatchQueue.main.async {
                // Sync local name to view model only once
                viewModel.userName = localName
                viewModel.proceedToNextQuestion()
            }
        }
    }
    
    // MARK: - Stress Level Question
    
    struct StressQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                VStack(spacing: 0) {
                    Text("How would you describe your typical stress levels?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                    
                    ScientificCitation(text: "Based on 68 studies, 2.3 million participants", metricType: .stressLevel)
                }
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    // Show all regular options first
                    ForEach(QuestionnaireViewModel.StressLevel.allCases, id: \.self) { stressLevel in
                        Button(action: {
                            viewModel.selectedStressLevel = stressLevel
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(
                                text: stressLevel.displayName,
                                subtitle: nil
                            )
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedStressLevel == stressLevel)
                        .hapticFeedback(.light)
                    }
                    
                    // "Not sure" button at the bottom
                    Button(action: {
                        viewModel.selectedStressLevel = nil
                        viewModel.proceedToNextQuestionAllowingNil()
                    }) {
                        Text("Not sure")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    // Applied rule: Simplicity is KING — do not pre-highlight Not sure
                    .questionnaireButtonStyle(isSelected: false)
                    .hapticFeedback(.light)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Anxiety Level Question
    
    struct AnxietyQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                VStack(spacing: 0) {
                    Text("How would you describe your anxiety levels?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                    
                    ScientificCitation(text: "Based on 42 studies, 890,000 participants", metricType: .stressLevel)
                }
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    // Limit to 4 base options to keep total <= 5 with Not sure
                    let baseOptions = Array(QuestionnaireViewModel.AnxietyLevel.allCases.prefix(4))
                    
                    // Show all regular options first
                    ForEach(baseOptions, id: \.self) { anxietyLevel in
                        Button(action: {
                            viewModel.selectedAnxietyLevel = anxietyLevel
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(
                                text: anxietyLevel.displayName,
                                subtitle: nil
                            )
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedAnxietyLevel == anxietyLevel)
                        .hapticFeedback(.light)
                    }
                    
                    // "Not sure" button at the bottom
                    Button(action: {
                        viewModel.selectedAnxietyLevel = nil
                        viewModel.proceedToNextQuestionAllowingNil()
                    }) {
                        Text("Not sure")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    // Applied rule: Simplicity is KING — do not pre-highlight Not sure
                    .questionnaireButtonStyle(isSelected: false)
                    .hapticFeedback(.light)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Gender Question
    
    struct GenderQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                Text("What is your biological sex?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    ForEach(["Female", "Male"], id: \.self) { gender in
                        Button(action: {
                            viewModel.selectedGender = gender == "Male" ? .male : .female
                            viewModel.proceedToNextQuestion()
                        }) {
                            Text(gender)
                        }
                        .questionnaireButtonStyle(
                            isSelected: (gender == "Male" && viewModel.selectedGender == .male) || 
                                       (gender == "Female" && viewModel.selectedGender == .female)
                        )
                        .hapticFeedback(.light)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Nutrition Question
    
    struct NutritionQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                VStack(spacing: 0) {
                    Text("How would you describe your typical diet?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                    
                    ScientificCitation(text: "Based on 195 studies, 4.9 million participants", metricType: .nutritionQuality)
                }
                

                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.NutritionQuality.allCases, id: \.self) { nutrition in
                        Button(action: {
                            viewModel.selectedNutritionQuality = nutrition
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(
                                text: nutrition.displayName,
                                subtitle: nil
                            )
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedNutritionQuality == nutrition)
                        .hapticFeedback(.light)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Smoking Question
    
    struct SmokingQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                VStack(spacing: 0) {
                    Text("Do you smoke tobacco products?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                    
                    ScientificCitation(text: "Based on 81 studies, 3.9 million participants", metricType: .smokingStatus)
                }
                

                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.SmokingStatus.allCases, id: \.self) { status in
                        Button(action: {
                            viewModel.selectedSmokingStatus = status
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: status.displayName)
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedSmokingStatus == status)
                        .hapticFeedback(.light)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Alcohol Question
    
    struct AlcoholQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                VStack(spacing: 0) {
                    Text("How often do you consume alcoholic beverages?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                    
                    ScientificCitation(text: "Based on 107 studies, 4.8 million participants", metricType: .alcoholConsumption)
                }
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.AlcoholFrequency.allCases, id: \.self) { frequency in
                        Button(action: {
                            viewModel.selectedAlcoholFrequency = frequency
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: frequency.displayName)
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedAlcoholFrequency == frequency)
                        .hapticFeedback(.light)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Social Connections Question
    
    struct SocialConnectionsQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                VStack(spacing: 0) {
                    Text("How would you describe your social connections?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)
                    
                    ScientificCitation(text: "Based on 39 studies, 1.8 million participants", metricType: .socialConnectionsQuality)
                }
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    // Show all regular options first
                    ForEach(QuestionnaireViewModel.SocialConnectionsQuality.allCases, id: \.self) { quality in
                        Button(action: {
                            viewModel.selectedSocialConnectionsQuality = quality
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(
                                text: quality.displayName,
                                subtitle: nil
                            )
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedSocialConnectionsQuality == quality)
                        .hapticFeedback(.light)
                    }
                    
                    // "Not sure" button at the bottom
                    Button(action: {
                        viewModel.selectedSocialConnectionsQuality = nil
                        viewModel.proceedToNextQuestionAllowingNil()
                    }) {
                        Text("Not sure")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    // Applied rule: Simplicity is KING — do not pre-highlight Not sure
                    .questionnaireButtonStyle(isSelected: false)
                    .hapticFeedback(.light)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
    
    // MARK: - Desired Daily Lifespan Gain Question (replaces sleep duration dial)
    struct SleepQualityQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        @State private var desiredMinutes: Int = 5 // 5..120

        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Prompt and guidance
                VStack(spacing: 12) {
                    Text("How much time do you want to gain each day?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)

                    Text("Daily wins add up. Set your goal up to 120 minutes as you use Amped to build better habits.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .padding(.top, 10)

                Spacer()

                // Luxury interactive dial
                LifespanGainDial(minutesPerDay: $desiredMinutes)
                    .padding(.bottom, 8)

                // Continue
                Button(action: {
                    viewModel.desiredDailyLifespanGainMinutes = desiredMinutes
                    // Map the user's aspiration to sleep quality preference proxy for compatibility
                    // Keep existing model usage minimal (Simplicity is KING)
                    viewModel.selectedSleepQuality = mapDesiredGainToSleepQuality(desiredMinutes)
                    viewModel.proceedToNextQuestion()
                }) {
                    Text("Continue")
                }
                .questionnaireButtonStyle(isSelected: false)
                .hapticFeedback(.light)
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }

        private func mapDesiredGainToSleepQuality(_ minutes: Int) -> QuestionnaireViewModel.SleepQuality {
            // Coarse mapping only to satisfy existing validation logic without changing downstream types
            switch minutes {
            case ..<20: return .average
            case 20..<40: return .good
            case 40...: return .excellent
            default: return .average
            }
        }
    }
    
    // MARK: - Blood Pressure Awareness Question
    struct BloodPressureAwarenessQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel

        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question title + research citation to mirror other questions
                VStack(spacing: 0) {
                    Text("What is your typical blood pressure reading?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    ScientificCitation(text: "ACC/AHA 2017 guideline + SPRINT (NEJM 2015): risk rises from ≥120 systolic; lowest near 110–119/70–79", metricType: .bloodPressure)
                }

                Spacer()

                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    let nonUnknown: [QuestionnaireViewModel.BloodPressureCategory] = [.normal, .elevatedToStage1, .high]
                    
                    // Show all regular options first
                    ForEach(nonUnknown, id: \.self) { category in
                        Button(action: {
                            viewModel.selectedBloodPressureCategory = category
                            viewModel.proceedToNextQuestion()
                        }) {
                            switch category {
                            case .normal:
                                FormattedButtonText(text: "Below 120/80 (Normal/Optimal)")
                            case .elevatedToStage1:
                                FormattedButtonText(text: "120–129 systolic and <80 diastolic (Elevated)")
                            case .high:
                                FormattedButtonText(text: "130/80 or higher (High/Hypertension)")
                            default:
                                EmptyView()
                            }
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedBloodPressureCategory == category)
                        .hapticFeedback(.light)
                    }
                    
                    // "Not sure" button at the bottom
                    Button(action: {
                        viewModel.selectedBloodPressureCategory = .unknown
                        viewModel.proceedToNextQuestionAllowingNil()
                    }) {
                        Text("Not sure")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    // Applied rule: Simplicity is KING — do not pre-highlight Not sure
                    .questionnaireButtonStyle(isSelected: false)
                    .hapticFeedback(.light)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Device Tracking Question
    
    struct DeviceTrackingQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        var proceedToHealthKit: () -> Void
        var skipToLifeMotivation: () -> Void
        
        @State private var isWaitingForHealthKitAuth = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Fitness tracker image (similar to screenshot)
                Image(systemName: "applewatch")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.bottom, 40)
                
                // Question text - shorter and more scannable
                Text("Do you track your health\nwith a device?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Options at bottom for thumb access - simplified to 2 options
                VStack(spacing: 12) {
                    // Yes option
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .yesBoth
                        // Trigger HealthKit authorization directly and instantly
                        requestHealthKitAuthorization()
                    }) {
                        Text("Yes, I track with a device")
                    }
                    .questionnaireButtonStyle(isSelected: viewModel.selectedDeviceTrackingStatus == .yesBoth || 
                                                       viewModel.selectedDeviceTrackingStatus == .yesActivityOnly ||
                                                       viewModel.selectedDeviceTrackingStatus == .yesSleepOnly)
                    .hapticFeedback(.light)
                    
                    // No option
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .no
                        skipToLifeMotivation()
                    }) {
                        Text("No, I don't use any device")
                    }
                    .questionnaireButtonStyle(isSelected: viewModel.selectedDeviceTrackingStatus == .no)
                    .hapticFeedback(.light)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
            .onChange(of: viewModel.selectedDeviceTrackingStatus) { newValue in
                print("🔍 DEVICE TRACKING: Device tracking status changed to: \(String(describing: newValue))")
            }
        }
        
        private func requestHealthKitAuthorization() {
            print("🔍 DEVICE TRACKING: Requesting HealthKit authorization")
            print("🔍 DEVICE TRACKING: Current question before auth: \(viewModel.currentQuestion)")
            
            // Set flag to track that we're waiting for authorization
            isWaitingForHealthKitAuth = true
            
            // ULTRA-FAST: Fire the authorization immediately with completion handler
            HealthKitManager.shared.requestAuthorizationUltraFast {
                print("🔍 DEVICE TRACKING: HealthKit authorization completed")
                
                // Navigate to life motivation question when authorization completes
                DispatchQueue.main.async {
                    if self.isWaitingForHealthKitAuth {
                        print("🔍 DEVICE TRACKING: Navigating to life motivation question")
                        self.isWaitingForHealthKitAuth = false
                        self.proceedToHealthKit()
                    }
                }
            }
            
            // DO NOT navigate yet - stay on current screen while dialog is shown
            // Navigation will happen when authorization completes
        }
    }
    
    // MARK: - Framing Comfort (tactful; no UI preference phrasing)
    struct FramingComfortQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel

        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("What helps you stay consistent?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    ScientificCitation(text: "Helps us tailor motivation style — calculations are unchanged", metricType: nil)
                }

                Spacer()

                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.FramingComfort.allCases, id: \.self) { option in
                        Button(action: {
                            viewModel.selectedFramingComfort = option
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: option.displayName)
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedFramingComfort == option)
                        .hapticFeedback(.light)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Urgency Response (tactful; no countdown phrasing)
    struct UrgencyResponseQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel

        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                VStack(spacing: 0) {
                    Text("When timelines tighten…")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    ScientificCitation(text: "Helps us choose a motivating tone", metricType: nil)
                }

                Spacer()

                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.UrgencyResponse.allCases, id: \.self) { option in
                        Button(action: {
                            viewModel.selectedUrgencyResponse = option
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: option.displayName)
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedUrgencyResponse == option)
                        .hapticFeedback(.light)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Life Motivation Question
    
    struct LifeMotivationQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        var completeQuestionnaire: () -> Void
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher - consistent with other questions
                Text("What is the main reason you might want to live longer?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Options at bottom for thumb access - using consistent questionnaire styling
                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.LifeMotivation.allCases, id: \.self) { motivation in
                        Button(action: {
                            viewModel.selectedLifeMotivation = motivation
                            
                            // This is the final question, so we need to move to the next onboarding step
                            completeQuestionnaire()
                        }) {
                            FormattedButtonText(
                                text: motivation.displayName,
                                subtitle: nil
                            )
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedLifeMotivation == motivation)
                        .hapticFeedback(.light)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
}
