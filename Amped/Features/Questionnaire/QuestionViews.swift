import SwiftUI

/// Helper function to create formatted button content with primary and secondary text
func FormattedButtonText(text: String, subtitle: String? = nil) -> some View {
    VStack(spacing: 4) {
        Text(text)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
        
        if let subtitle = subtitle {
            Text(subtitle)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
    }
}

/// Contains all the individual question views for the questionnaire
struct QuestionViews {
    
    // MARK: - Birthdate Question
    
    struct BirthdateQuestionView: View {
        @ObservedObject var viewModel: QuestionnaireViewModel
        var handleContinue: () -> Void
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question text placed higher
                Text("When were you born?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)

                Spacer()

                // Custom Month/Year Picker positioned at bottom for thumb access
                HStack(spacing: 0) {
                    // Month Picker
                    Picker("Month", selection: Binding(
                        get: { viewModel.selectedBirthMonth },
                        set: { viewModel.updateSelectedMonth($0) }
                    )) {
                        ForEach(viewModel.availableMonths, id: \.self) { month in
                            Text(viewModel.monthName(for: month))
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .tag(month)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
                    
                    // Year Picker
                    Picker("Year", selection: Binding(
                        get: { viewModel.selectedBirthYear },
                        set: { viewModel.updateSelectedYear($0) }
                    )) {
                        ForEach(viewModel.availableYears, id: \.self) { year in
                            Text(String(year))
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                                .tag(year)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                
                // Continue button at very bottom
                Button(action: handleContinue) {
                    Text("Continue")
                }
                .continueButtonStyle(isEnabled: viewModel.canProceed)
                .hapticFeedback(.selection)
                .padding(.horizontal, 40)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .disabled(!viewModel.canProceed)
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
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    ForEach(["Male", "Female"], id: \.self) { gender in
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
                        .hapticFeedback(.selection)
                    }
                    
                    Button(action: {
                        viewModel.selectedGender = .preferNotToSay
                        viewModel.proceedToNextQuestion()
                    }) {
                        Text("Prefer not to say")
                    }
                    .questionnaireButtonStyle(isSelected: viewModel.selectedGender == .preferNotToSay)
                    .hapticFeedback(.selection)
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
                        .hapticFeedback(.selection)
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
                        .hapticFeedback(.selection)
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
                        .hapticFeedback(.selection)
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
        var completeQuestionnaire: () -> Void
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                Text("How would you describe your social connections?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.SocialConnectionsQuality.allCases, id: \.self) { quality in
                        Button(action: {
                            viewModel.selectedSocialConnectionsQuality = quality
                            
                            // This is the final question, so we need to move to the next onboarding step
                            completeQuestionnaire()
                        }) {
                            FormattedButtonText(
                                text: quality.displayName,
                                subtitle: nil
                            )
                        }
                        .questionnaireButtonStyle(isSelected: viewModel.selectedSocialConnectionsQuality == quality)
                        .hapticFeedback(.selection)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: .infinity)
        }
    }
} 