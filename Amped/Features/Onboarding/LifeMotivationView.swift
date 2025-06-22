import SwiftUI

/// Standalone Life Motivation view that appears after HealthKit permissions
struct LifeMotivationView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = QuestionnaireViewModel(startingAt: .lifeMotivation)
    @StateObject private var questionnaireManager = QuestionnaireManager()
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    /// Callbacks for navigation
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep background
                Color.clear.withDeepBackground()
                
                VStack(spacing: 12) {
                    // Navigation header with back button
                    HStack {
                        BackButton(action: {
                            onBack?()
                        }, showText: false)
                        
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.leading, 8)
                    
                    // Add spacer to push question down approximately 1/3 from top
                    Spacer().frame(height: geometry.size.height * 0.15)
                    
                    // Life Motivation Question View
                    QuestionViews.LifeMotivationQuestionView(
                        viewModel: viewModel,
                        completeQuestionnaire: completeLifeMotivation
                    )
                    .padding()
                    
                    Spacer()
                    
                    // Progress indicator at bottom - step 9 of 10
                    ProgressIndicator(currentStep: 9, totalSteps: 10)
                        .padding(.bottom, 40)
                }
                .withDeepBackgroundTheme()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func completeLifeMotivation() {
        // Save the life motivation selection
        questionnaireManager.saveQuestionnaireData(from: viewModel)
        
        // Continue to next step
        onContinue?()
        
        print("🔍 LIFE_MOTIVATION: Completed life motivation question, proceeding to next step")
    }
}

// MARK: - Preview

#if DEBUG
struct LifeMotivationView_Previews: PreviewProvider {
    static var previews: some View {
        LifeMotivationView(
            onContinue: {
                print("Continue tapped in preview")
            },
            onBack: {
                print("Back tapped in preview")
            }
        )
    }
}
#endif 