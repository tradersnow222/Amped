import SwiftUI

/// Custom Button Style for Questionnaire
struct QuestionButtonStyle: ViewModifier {
    let isSelected: Bool
    @Environment(\.themeManager) private var themeManager
    
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.ampedGreen : Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isSelected ? Color.ampedGreen.opacity(0.9) : Color.ampedGreen.opacity(0.4),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Extension for applying the custom button style
extension View {
    func questionButtonStyle(isSelected: Bool) -> some View {
        self.modifier(QuestionButtonStyle(isSelected: isSelected))
    }
}

/// Helper function to create formatted button content with primary and secondary text
func FormattedButtonText(text: String) -> some View {
    if text.contains("\n") {
        let components = text.components(separatedBy: "\n")
        return VStack(spacing: 4) {
            Text(components[0])
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if components.count > 1 {
                Text(components[1])
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    } else {
        return VStack {
            Text(text)
                .fontWeight(.semibold)
                .foregroundColor(.white)
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
                    .font(.title)
                    .fontWeight(.bold)
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
                        .fontWeight(.bold)
                        .font(.system(.title3, design: .default))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ampedGreen)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
                .hapticFeedback(.selection)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .opacity(viewModel.canProceed ? 1 : 0.6)
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
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        print("Gender question appeared. Selected gender: \(viewModel.selectedGender)")
                    }
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 14) {
                    ForEach(["Male", "Female"], id: \.self) { gender in
                        Button(action: {
                            viewModel.selectedGender = gender == "Male" ? .male : .female
                            print("Selected gender: \(viewModel.selectedGender)")
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: gender)
                                .questionButtonStyle(isSelected: (gender == "Male" && viewModel.selectedGender == .male) || 
                                                             (gender == "Female" && viewModel.selectedGender == .female))
                        }
                        .hapticFeedback(.selection)
                    }
                    
                    Button(action: {
                        viewModel.selectedGender = .preferNotToSay
                        print("Selected 'Prefer not to say', gender: \(viewModel.selectedGender)")
                        viewModel.proceedToNextQuestion()
                    }) {
                        FormattedButtonText(text: "Prefer not to say")
                            .questionButtonStyle(isSelected: viewModel.selectedGender == .preferNotToSay)
                    }
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
        @Environment(\.themeManager) private var themeManager
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                Text("How would you describe your typical diet?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 14) {
                    ForEach(QuestionnaireViewModel.NutritionQuality.allCases, id: \.self) { nutrition in
                        Button(action: {
                            viewModel.selectedNutritionQuality = nutrition
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: nutrition.displayName)
                                .questionButtonStyle(isSelected: viewModel.selectedNutritionQuality == nutrition)
                        }
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
        @Environment(\.themeManager) private var themeManager
        
        var body: some View {
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
                VStack(spacing: 14) {
                    ForEach(QuestionnaireViewModel.SmokingStatus.allCases, id: \.self) { status in
                        Button(action: {
                            viewModel.selectedSmokingStatus = status
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: status.displayName)
                                .questionButtonStyle(isSelected: viewModel.selectedSmokingStatus == status)
                        }
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
        @Environment(\.themeManager) private var themeManager
        
        var body: some View {
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
                VStack(spacing: 14) {
                    ForEach(QuestionnaireViewModel.AlcoholFrequency.allCases, id: \.self) { frequency in
                        Button(action: {
                            viewModel.selectedAlcoholFrequency = frequency
                            viewModel.proceedToNextQuestion()
                        }) {
                            FormattedButtonText(text: frequency.displayName)
                                .questionButtonStyle(isSelected: viewModel.selectedAlcoholFrequency == frequency)
                        }
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
        @Environment(\.themeManager) private var themeManager
        var completeQuestionnaire: () -> Void
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                // Question placed higher
                Text("How would you describe your social connections?")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 10)
                    .frame(maxWidth: .infinity)
                
                Spacer()
                
                // Options at bottom for thumb access
                VStack(spacing: 14) {
                    ForEach(QuestionnaireViewModel.SocialConnectionsQuality.allCases, id: \.self) { quality in
                        Button(action: {
                            viewModel.selectedSocialConnectionsQuality = quality
                            
                            // This is the final question, so we need to move to the next onboarding step
                            completeQuestionnaire()
                        }) {
                            FormattedButtonText(text: quality.displayName)
                                .questionButtonStyle(isSelected: viewModel.selectedSocialConnectionsQuality == quality)
                        }
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