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

/// ULTRA-OPTIMIZED formatted button content - eliminates expensive string parsing
/// Pre-computes text components to prevent render-time performance issues
struct FormattedButtonText: View {
    private let primaryText: String
    private let parenthesesText: String?
    private let subtitle: String?
    
    // PERFORMANCE: Cache parsed components to avoid repeated string operations
    private static var textCache: [String: (primary: String, parentheses: String?)] = [:]
    
    init(text: String, subtitle: String? = nil) {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // PERFORMANCE: Use cached parsing results if available
        if let cached = Self.textCache[text] {
            self.primaryText = cached.primary
            self.parenthesesText = cached.parentheses
        } else {
            // PERFORMANCE: Optimized string parsing with minimal allocations
            let components = Self.optimizedParseText(text)
            Self.textCache[text] = components // Cache for future use
            self.primaryText = components.primary
            self.parenthesesText = components.parentheses
        }
        
        self.subtitle = subtitle
        
        let parseTime = CFAbsoluteTimeGetCurrent() - startTime
        if parseTime > 0.001 { // Only log if > 1ms
            print("🔍 PERFORMANCE_DEBUG: FormattedButtonText parsing took \(parseTime)s for '\(text.prefix(20))...'")
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(primaryText)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Show parentheses content as smaller, greyed subtext
            if let parenthesesText = parenthesesText {
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
    
    /// PERFORMANCE: Optimized text parsing with minimal string operations
    private static func optimizedParseText(_ text: String) -> (primary: String, parentheses: String?) {
        // PERFORMANCE: Single pass through string to find parentheses
        if let openParen = text.firstIndex(of: "("),
           let closeParen = text.lastIndex(of: ")"),
           openParen < closeParen {
            
            // Extract parentheses content efficiently
            let parenthesesRange = text.index(after: openParen)..<closeParen
            let parenthesesContent = String(text[parenthesesRange])
            
            // Extract primary text by removing parentheses line
            let primaryText = text.replacingOccurrences(
                of: text[openParen...closeParen],
                with: ""
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            
            return (primary: primaryText, parentheses: parenthesesContent)
        }
        
        // No parentheses found - return as-is
        return (primary: text, parentheses: nil)
    }
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
        
        var body: some View {
            VStack(spacing: 0) {
                VStack(alignment: .center, spacing: 0) {
                    // Question text - consistent with other questions
                    Text("What should we call you?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity)

                    Spacer()
                    
                    // Clean input design matching iOS standards
                    VStack(spacing: 16) {
                        TextField("First name", text: $viewModel.userName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                                    )
                            )
                            .focused($isTextFieldFocused)
                            .textInputAutocapitalization(.words)
                            .textContentType(.givenName)
                            .submitLabel(.continue)
                            .disableAutocorrection(true)
                            .onSubmit {
                                if viewModel.canProceed {
                                    proceedToNext()
                                }
                            }
                        
                        // Continue button - consistent with other questions
                        Button(action: {
                            proceedToNext()
                        }) {
                            Text("Continue")
                        }
                        .questionnaireButtonStyle(isSelected: false)
                        .opacity(viewModel.canProceed ? 1.0 : 0.6)
                        .disabled(!viewModel.canProceed)
                        .hapticFeedback(.light)
                    }
                    .padding(.bottom, 30) // CONSISTENCY FIX: Match spacing of other questions
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .frame(maxHeight: .infinity)
            }
            .onAppear {
                // ULTRA-PERFORMANCE FIX: No automatic keyboard focus - let user tap when ready
                let startTime = CFAbsoluteTimeGetCurrent()
                print("🔍 PERFORMANCE_DEBUG: NameQuestionView.onAppear() started at \(startTime)")
                
                // NO automatic focus - keyboard only appears when user taps the text field
                // This completely eliminates animation conflicts and follows iOS design patterns
                
                let onAppearTime = CFAbsoluteTimeGetCurrent() - startTime
                print("🔍 PERFORMANCE_DEBUG: NameQuestionView.onAppear() completed in \(onAppearTime)s (no keyboard conflict)")
            }
        }
        
        private func proceedToNext() {
            guard viewModel.canProceed else { return }
            
            // KEYBOARD TRANSITION FIX: Dismiss keyboard immediately to prevent animation conflicts
            isTextFieldFocused = false
            
            // Use standard questionnaire transition timing to match other questions
            viewModel.proceedToNextQuestion()
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
                    // Show all 4 stress level options (following 4-option maximum rule)
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
                    // Show all 4 anxiety level options (following 4-option maximum rule)
                    ForEach(QuestionnaireViewModel.AnxietyLevel.allCases, id: \.self) { anxietyLevel in
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
                    // Show all 4 social connections options (following 4-option maximum rule)
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
                    Text("How much longer do you want to live each day?")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)

                    Text("Add up to two hours daily")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .padding(.top, 10)

                Spacer()

                // Luxury interactive dial
                LifespanGainDial(minutesPerDay: $desiredMinutes)
                    .padding(.bottom, 20)

                // Scientific credibility info
                ScientificCitation(text: "Backed by 500+ studies, 15+ million participants", metricType: nil)

                // Continue
                Button(action: {
                    viewModel.desiredDailyLifespanGainMinutes = desiredMinutes
                    // Map the user's aspiration to sleep quality preference proxy for compatibility
                    // Keep existing model usage minimal (Simplicity is KING)
                    viewModel.selectedSleepQuality = mapDesiredGainToSleepQuality(desiredMinutes)
                    
                    // Setup smart goal-based notifications for this user's target
                    NotificationManager.shared.scheduleGoalBasedNotifications(targetMinutes: desiredMinutes)
                    
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

                    ScientificCitation(text: "Based on 61 studies, 1 million participants", metricType: .bloodPressure)
                }

                Spacer()

                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    // Show all 4 blood pressure options (following 4-option maximum rule)
                    ForEach(QuestionnaireViewModel.BloodPressureCategory.allCases, id: \.self) { category in
                        Button(action: {
                            viewModel.selectedBloodPressureCategory = category
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(
                                text: category.displayName,
                                subtitle: nil
                            )
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedBloodPressureCategory == category)
                        .hapticFeedback(.light)
                    }
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
