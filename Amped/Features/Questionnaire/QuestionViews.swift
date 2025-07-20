import SwiftUI
import HealthKit
import UIKit

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

                    // Custom Month/Year picker with native iOS wheel style
                    HStack(spacing: 0) {
                        // Month Picker
                        Picker("Month", selection: Binding(
                            get: { viewModel.selectedBirthMonth },
                            set: { viewModel.updateSelectedMonth($0) }
                        )) {
                            ForEach(viewModel.availableMonths, id: \.self) { month in
                                Text(viewModel.monthName(for: month))
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                    .tag(month)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)
                        
                        // Year Picker
                        Picker("Year", selection: Binding(
                            get: { viewModel.selectedBirthYear },
                            set: { viewModel.updateSelectedYear($0) }
                        )) {
                            ForEach(viewModel.availableYears, id: \.self) { year in
                                Text(String(year))
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.white)
                                    .tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .colorScheme(.dark)
                    }
                    .frame(height: 216) // Standard iOS picker height
                    .padding(.horizontal, 24)

                    Spacer()
                    Spacer() // Extra spacer for more spacing above Continue button

                    // Continue button with increased spacing
                    VStack(spacing: 12) {
                        Button(action: handleContinue) {
                            Text("Continue")
                        }
                        .questionnaireButtonStyle(isSelected: false)
                        .opacity(viewModel.canProceed ? 1.0 : 0.6)
                        .disabled(!viewModel.canProceed)
                        .hapticFeedback(.heavy)
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
                
                // Options at bottom for thumb access - matching other questions structure
                VStack(spacing: 12) {
                    TextField("Enter your name", text: $viewModel.userName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            if viewModel.canProceed {
                                proceedToNext()
                            }
                        }
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                    
                    Button(action: {
                        if viewModel.canProceed {
                            proceedToNext()
                        }
                    }) {
                        Text("Continue")
                    }
                    .questionnaireButtonStyle(isSelected: false)
                    .opacity(viewModel.canProceed ? 1.0 : 0.6)
                    .disabled(!viewModel.canProceed)
                    .hapticFeedback(.heavy)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
            .onAppear {
                // Simplified focus management - only focus when this specific question appears
                // Use async dispatch to focus after current main loop, ensuring transition is finished without long delay
                if viewModel.currentQuestion == .name {
                    DispatchQueue.main.async {
                        isTextFieldFocused = true
                    }
                }
            }
            .onDisappear {
                // Immediately dismiss keyboard when leaving
                isTextFieldFocused = false
            }
        }
        
        // Consolidated navigation function
        private func proceedToNext() {
            // Dismiss keyboard first
            isTextFieldFocused = false
            
            // Longer delay to ensure keyboard dismissal completes before navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
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
                Text("How would you describe your typical stress levels?")
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
                        .hapticFeedback(.heavy)
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
                        .hapticFeedback(.heavy)
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
                Text("How would you describe your typical diet?")
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
                        .hapticFeedback(.heavy)
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
                Text("Do you smoke tobacco products?")
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
                    ForEach(QuestionnaireViewModel.SmokingStatus.allCases, id: \.self) { status in
                        Button(action: {
                            viewModel.selectedSmokingStatus = status
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: status.displayName)
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedSmokingStatus == status)
                        .hapticFeedback(.heavy)
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
                Text("How often do you consume alcoholic beverages?")
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
                    ForEach(QuestionnaireViewModel.AlcoholFrequency.allCases, id: \.self) { frequency in
                        Button(action: {
                            viewModel.selectedAlcoholFrequency = frequency
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: frequency.displayName)
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedAlcoholFrequency == frequency)
                        .hapticFeedback(.heavy)
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
                Text("How would you describe your social connections?")
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
                        .hapticFeedback(.heavy)
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
                    .hapticFeedback(.heavy)
                    
                    // No option
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .no
                        skipToLifeMotivation()
                    }) {
                        Text("No, I don't use any device")
                    }
                    .questionnaireButtonStyle(isSelected: viewModel.selectedDeviceTrackingStatus == .no)
                    .hapticFeedback(.heavy)
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
                        .hapticFeedback(.heavy)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
} 