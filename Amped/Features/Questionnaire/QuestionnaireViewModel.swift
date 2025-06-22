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
        case deviceTracking // New question about health tracking devices
        case lifeMotivation // Moved to last - will be shown after HealthKit
    }
    
    enum NutritionQuality: CaseIterable {
        case veryHealthy        // 9.0 - Most positive
        case mostlyHealthy      // 7.0
        case mixed              // 5.0
        case mostlyUnhealthy    // 3.0 - Most negative
        
        var displayName: String {
            switch self {
            case .veryHealthy: return "Very Healthy\n(whole foods, plant-based)"
            case .mostlyHealthy: return "Mostly Healthy\n(balanced diet)"
            case .mixed: return "Mixed\n(some healthy, some processed)"
            case .mostlyUnhealthy: return "Mostly Processed\n(convenience foods)"
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
        case never              // 9.0 - Most positive
        case former             // 6.0
        case occasionally       // 3.0
        case daily              // 1.0 - Most negative
        
        var displayName: String {
            switch self {
            case .never: return "Never"
            case .former: return "Former smoker\n(quit in the past)"
            case .occasionally: return "Occasionally"
            case .daily: return "Daily"
            }
        }
        
        var smokingValue: Double {
            switch self {
            case .never: return 9.0
            case .former: return 6.0
            case .occasionally: return 3.0
            case .daily: return 1.0
            }
        }
    }
    
    enum AlcoholFrequency: CaseIterable {
        case never              // 9.0 - Most positive
        case occasionally       // 7.0
        case severalTimesWeek   // 4.0
        case daily              // 3.0 - Most negative
        
        var displayName: String {
            switch self {
            case .never: return "Never"
            case .occasionally: return "Occasionally\n(weekly or less)"
            case .severalTimesWeek: return "Several Times\n(per week)"
            case .daily: return "Daily"
            }
        }
        
        var alcoholValue: Double {
            switch self {
            case .never: return 9.0
            case .occasionally: return 7.0
            case .severalTimesWeek: return 4.0
            case .daily: return 3.0
            }
        }
    }
    
    enum SocialConnectionsQuality: CaseIterable {
        case veryStrong         // 9.0 - Most positive
        case good               // 7.0
        case moderate           // 5.0
        case limited            // 2.0 - Most negative
        
        var displayName: String {
            switch self {
            case .veryStrong: return "Very Strong\n(daily interactions)"
            case .good: return "Good\n(regular engagement)"
            case .moderate: return "Moderate\n(occasional connections)"
            case .limited: return "Limited\n(rare interactions)"
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
    
    enum DeviceTrackingStatus: String, CaseIterable, Codable {
        case yesBoth = "yesBoth"          // Tracking both activity and sleep
        case yesActivityOnly = "yesActivityOnly"   // Only tracking activity
        case yesSleepOnly = "yesSleepOnly"      // Only tracking sleep
        case no = "no"                // Not using any device
        
        var displayName: String {
            switch self {
            case .yesBoth: return "Yes, tracking both"
            case .yesActivityOnly: return "Only tracking activity"
            case .yesSleepOnly: return "Only tracking sleep"
            case .no: return "No, not using any device"
            }
        }
        
        var requiresHealthKit: Bool {
            switch self {
            case .yesBoth, .yesActivityOnly, .yesSleepOnly:
                return true
            case .no:
                return false
            }
        }
    }
    
    enum LifeMotivation: String, CaseIterable, Codable {
        case family = "family"
        case dreams = "dreams"
        case experience = "experience"
        case contribution = "contribution"
        
        var displayName: String {
            switch self {
            case .family: return "Watch my family grow"
            case .dreams: return "Achieve my dreams"
            case .experience: return "Simply to experience life longer"
            case .contribution: return "Give more back to the world"
            }
        }
        
        var icon: String {
            switch self {
            case .family: return "figure.2.and.child.holdinghands"
            case .dreams: return "star.fill"
            case .experience: return "sun.max.fill"
            case .contribution: return "globe.americas.fill"
            }
        }
    }
    
    // Form data
    @Published var currentQuestion: Question {
        didSet {
            // Persist current question to UserDefaults to survive app background/foreground transitions
            UserDefaults.standard.set(currentQuestion.rawValue, forKey: "questionnaire_current_question")
        }
    }
    
    // Birthdate (replacing age)
    @Published var birthdate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date() // Default to 30 years ago
    
    // Separate month and year selection for improved UX
    @Published var selectedBirthMonth: Int = Calendar.current.component(.month, from: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date())
    @Published var selectedBirthYear: Int = Calendar.current.component(.year, from: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date())
    
    // Update birthdate when month or year changes
    private func updateBirthdateFromMonthYear() {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = selectedBirthYear
        components.month = selectedBirthMonth
        components.day = 1 // Always use 1st of the month for consistency
        
        if let newDate = calendar.date(from: components) {
            birthdate = newDate
        }
    }
    
    // Available months for picker - limit to current month if current year is selected
    var availableMonths: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let currentMonth = Calendar.current.component(.month, from: Date())
        
        if selectedBirthYear == currentYear {
            // If current year is selected, only show months up to current month
            return Array(1...currentMonth)
        } else {
            // For other years, show all months
            return Array(1...12)
        }
    }
    
    // Available years for picker (18-120 years ago from current year)
    var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let minYear = currentYear - 120
        let maxYear = currentYear // Allow up to current year
        return Array(minYear...maxYear) // Earliest first (removed .reversed())
    }
    
    // Month name for display
    func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.monthSymbols = formatter.monthSymbols
        return formatter.monthSymbols[month - 1]
    }
    
    // Update month selection
    func updateSelectedMonth(_ month: Int) {
        selectedBirthMonth = month
        updateBirthdateFromMonthYear()
    }
    
    // Update year selection
    func updateSelectedYear(_ year: Int) {
        selectedBirthYear = year
        updateBirthdateFromMonthYear()
    }
    
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
    @Published var selectedGender: UserProfile.Gender?
    
    // Nutrition
    @Published var selectedNutritionQuality: NutritionQuality?
    
    // Smoking
    @Published var selectedSmokingStatus: SmokingStatus?
    
    // Alcohol
    @Published var selectedAlcoholFrequency: AlcoholFrequency?
    
    // Social Connections
    @Published var selectedSocialConnectionsQuality: SocialConnectionsQuality?
    
    // Device Tracking
    @Published var selectedDeviceTrackingStatus: DeviceTrackingStatus?
    
    // Life Motivation
    @Published var selectedLifeMotivation: LifeMotivation?
    
    // Progress tracking for indicator
    var currentStep: Int {
        // Personalization Intro is step 1, so the first question starts at step 2
        currentQuestion.rawValue + 2 
    }
    var totalSteps: Int {
        10 // Total steps in the onboarding flow (excluding welcome and dashboard)
    }
    
    var isComplete: Bool {
        currentQuestion == Question.lifeMotivation && canProceed
    }
    
    // Check if it's possible to proceed to the next question
    var canProceed: Bool {
        switch currentQuestion {
        case .birthdate:
            return age >= 18 && age <= 120 // Validate age from birthdate
        case .gender:
            return selectedGender != nil // Require user to make a selection
        case .nutritionQuality:
            return selectedNutritionQuality != nil
        case .smokingStatus:
            return selectedSmokingStatus != nil
        case .alcoholConsumption:
            return selectedAlcoholFrequency != nil
        case .socialConnections:
            return selectedSocialConnectionsQuality != nil
        case .deviceTracking:
            return selectedDeviceTrackingStatus != nil
        case .lifeMotivation:
            return selectedLifeMotivation != nil
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
        // lifeMotivation is the actual last question
        return currentQuestion == .lifeMotivation
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
            // Remove animation here to consolidate animation control in the View
            currentQuestion = nextQuestion
        }
    }
    
    // Move back to previous question with animation
    func moveBackToPreviousQuestion() {
        if let prevQuestion = getPreviousQuestion() {
            currentQuestion = prevQuestion
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
    
    // MARK: - Helper Methods for View Transitions
    
    // Get the index of a question
    func questionIndex(for question: Question) -> Int {
        return question.rawValue
    }
    
    // Get the current question index
    var currentQuestionIndex: Int {
        return currentQuestion.rawValue
    }
    
    // MARK: - Initialization
    
    init() {
        // Restore current question from UserDefaults if available
        if let savedQuestionRawValue = UserDefaults.standard.object(forKey: "questionnaire_current_question") as? Int,
           let savedQuestion = Question(rawValue: savedQuestionRawValue) {
            self.currentQuestion = savedQuestion
        } else {
            self.currentQuestion = .birthdate
        }
        
        // Sync the separate month/year properties with the default birthdate
        let calendar = Calendar.current
        selectedBirthMonth = calendar.component(.month, from: birthdate)
        selectedBirthYear = calendar.component(.year, from: birthdate)
    }
    
    // Add a new initializer to start at a specific question - for returning from HealthKit
    init(startingAt question: Question) {
        // Set the starting question
        self.currentQuestion = question
        
        // Save to UserDefaults immediately
        UserDefaults.standard.set(question.rawValue, forKey: "questionnaire_current_question")
        
        // Sync the separate month/year properties with the default birthdate
        let calendar = Calendar.current
        selectedBirthMonth = calendar.component(.month, from: birthdate)
        selectedBirthYear = calendar.component(.year, from: birthdate)
    }
} 