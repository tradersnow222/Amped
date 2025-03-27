import SwiftUI

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
                .hapticFeedback(.selection)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .opacity(viewModel.canProceed ? 1 : 0.6)
                .disabled(!viewModel.canProceed)
            }
            .padding(.horizontal, 20)
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
                    .hapticFeedback(.selection)
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
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
                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.NutritionQuality.allCases, id: \.self) { nutrition in
                        Button(action: {
                            viewModel.selectedNutritionQuality = nutrition
                            viewModel.proceedToNextQuestion()
                        }) {
                            Text(nutrition.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.selectedNutritionQuality == nutrition ? Color.ampedGreen : Color.black.opacity(0.7))
                                )
                        }
                        .hapticFeedback(.selection)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
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
                        .hapticFeedback(.selection)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
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
                        .hapticFeedback(.selection)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
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
                VStack(spacing: 12) {
                    ForEach(QuestionnaireViewModel.SocialConnectionsQuality.allCases, id: \.self) { quality in
                        Button(action: {
                            viewModel.selectedSocialConnectionsQuality = quality
                            
                            // This is the final question, so we need to move to the next onboarding step
                            completeQuestionnaire()
                        }) {
                            Text(quality.displayName)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(viewModel.selectedSocialConnectionsQuality == quality ? Color.ampedGreen : Color.black.opacity(0.7))
                                )
                        }
                        .hapticFeedback(.selection)
                    }
                }
                .padding(.bottom, 30)
            }
            .padding(.horizontal, 20)
            .frame(maxHeight: .infinity)
        }
    }
} 