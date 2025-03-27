import Foundation
import SwiftUI

/// ViewModel for the Questionnaire functionality
final class QuestionnaireViewModel: ObservableObject {
    enum Question: Int, CaseIterable, Hashable {
        case birthdate
        case gender
        case nutritionQuality
        case smokingStatus
        case alcoholConsumption
        case socialConnections
    }
    
    enum NutritionQuality: CaseIterable {
        case veryHealthy
        case mostlyHealthy
        case mixed
        case mostlyUnhealthy
        
        var displayName: String {
            switch self {
            case .veryHealthy: return "Very Healthy (whole foods, plant-based)"
            case .mostlyHealthy: return "Mostly Healthy (balanced diet)"
            case .mixed: return "Mixed (some healthy, some processed)"
            case .mostlyUnhealthy: return "Mostly Processed Foods"
            }
        }
        
        var nutritionValue: Double {
            switch self {
            case .veryHealthy: return 9.0
            case .mostlyHealthy: return 7.0
            case .mixed: return 5.0
            case .mostlyUnhealthy: return 3.0
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
    
    enum SocialConnectionsQuality: CaseIterable {
        case veryStrong
        case good
        case moderate
        case limited
        
        var displayName: String {
            switch self {
            case .veryStrong: return "Very Strong (daily meaningful interactions)"
            case .good: return "Good (regular social engagement)"
            case .moderate: return "Moderate (occasional social connections)"
            case .limited: return "Limited (rare meaningful interactions)"
            }
        }
        
        var socialValue: Double {
            switch self {
            case .veryStrong: return 9.0
            case .good: return 7.0
            case .moderate: return 5.0
            case .limited: return 2.0
            }
        }
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
    
    // Nutrition
    @Published var selectedNutritionQuality: NutritionQuality?
    
    // Smoking
    @Published var selectedSmokingStatus: SmokingStatus?
    
    // Alcohol
    @Published var selectedAlcoholFrequency: AlcoholFrequency?
    
    // Social Connections
    @Published var selectedSocialConnectionsQuality: SocialConnectionsQuality?
    
    // Progress tracking for indicator
    var currentStep: Int {
        currentQuestion.rawValue + 3 // Offset by 3 to account for previous onboarding steps
    }
    var totalSteps: Int {
        7 // Match the total steps in the onboarding flow
    }
    
    var isComplete: Bool {
        currentQuestion == Question.socialConnections && canProceed
    }
    
    // Check if it's possible to proceed to the next question
    var canProceed: Bool {
        switch currentQuestion {
        case .birthdate:
            return age >= 18 && age <= 120 // Validate age from birthdate
        case .gender:
            return true // Always has a default
        case .nutritionQuality:
            return selectedNutritionQuality != nil
        case .smokingStatus:
            return selectedSmokingStatus != nil
        case .alcoholConsumption:
            return selectedAlcoholFrequency != nil
        case .socialConnections:
            return selectedSocialConnectionsQuality != nil
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
        return currentQuestion == .socialConnections
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