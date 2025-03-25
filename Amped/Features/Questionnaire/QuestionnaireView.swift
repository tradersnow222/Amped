import SwiftUI

/// Questionnaire view for collecting additional health metrics
struct QuestionnaireView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = QuestionnaireViewModel()
    
    // Callback to proceed to next step
    var onContinue: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        // For MVP we're just showing a placeholder
        // In a real implementation, this would be a multi-step questionnaire
        VStack(spacing: 24) {
            Text("Quick Health Questions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("This information helps us provide accurate insights about your health habits")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Demographics form
            demographicsForm
                .padding()
            
            Spacer()
            
            // Nutrition question
            nutritionQuestion
                .padding()
            
            Spacer()
            
            // Stress question
            stressQuestion
                .padding()
            
            Spacer()
            
            // Continue button
            Button(action: {
                saveQuestionnaireData()
                onContinue?()
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ampedGreen)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
            
            // Progress indicator
            ProgressIndicator(currentStep: 3, totalSteps: 7)
                .padding(.bottom, 40)
        }
        .withDeepBackground()
    }
    
    // MARK: - Helper Methods
    
    private func saveQuestionnaireData() {
        // Save questionnaire data
        // In a real implementation, this would save to UserDefaults, CoreData, or another storage
    }
    
    // MARK: - UI Components
    
    /// Demographics form
    private var demographicsForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About You")
                .font(.headline)
            
            HStack {
                Text("Birth Year:")
                Spacer()
                Picker("Birth Year", selection: $viewModel.birthYear) {
                    ForEach((1940...2005).reversed(), id: \.self) { year in
                        Text("\(year)").tag(year)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 100)
            }
            
            HStack {
                Text("Gender:")
                Spacer()
                Picker("Gender", selection: $viewModel.gender) {
                    ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 180)
            }
        }
    }
    
    /// Nutrition question
    private var nutritionQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How would you rate your overall nutrition quality?")
                .font(.headline)
            
            VStack(spacing: 10) {
                Text("Rating: \(Int(viewModel.nutritionQuality))/10")
                    .font(.subheadline)
                
                Slider(value: $viewModel.nutritionQuality, in: 1...10, step: 1)
                    .accentColor(.ampedGreen)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Poor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Excellent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    /// Stress question
    private var stressQuestion: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("How would you rate your typical stress level?")
                .font(.headline)
            
            VStack(spacing: 10) {
                Text("Rating: \(Int(viewModel.stressLevel))/10")
                    .font(.subheadline)
                
                Slider(value: $viewModel.stressLevel, in: 1...10, step: 1)
                    .accentColor(.ampedGreen)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Very Low")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Very High")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - ViewModel

final class QuestionnaireViewModel: ObservableObject {
    // Form data
    @Published var birthYear: Int = 1990
    @Published var gender: UserProfile.Gender = .preferNotToSay
    @Published var nutritionQuality: Double = 5
    @Published var stressLevel: Double = 5
}

// MARK: - Preview

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView(onContinue: {})
    }
} 