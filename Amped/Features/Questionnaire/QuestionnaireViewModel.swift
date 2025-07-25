import Foundation
import SwiftUI

/// ViewModel for the Questionnaire functionality
final class QuestionnaireViewModel: ObservableObject {
    enum Question: Int, CaseIterable, Hashable {
        case birthdate
        case name
        case stressLevel        // NEW: Question #3 for stress level
        case gender
        case nutritionQuality
        case smokingStatus
        case alcoholConsumption
        case socialConnections
        case deviceTracking // New question about health tracking devices
        case lifeMotivation // Moved to last - will be shown after HealthKit
    }
    
    enum StressLevel: CaseIterable {
        case veryLow            // 2.0 - Most positive (very low stress)
        case low                // 3.0 
        case moderateToHigh     // 6.0 - Combined moderate and high
        case veryHigh           // 9.0 - Most negative (very high stress)
        
        var displayName: String {
            switch self {
            case .veryLow: return "Very Low\n(rarely feel stressed)"
            case .low: return "Low\n(occasionally stressed)"
            case .moderateToHigh: return "Moderate to High\n(regular stress)"
            case .veryHigh: return "Very High\n(constantly stressed)"
            }
        }
        
        var stressValue: Double {
            switch self {
            case .veryLow: return 2.0
            case .low: return 3.0
            case .moderateToHigh: return 6.0
            case .veryHigh: return 9.0
            }
        }
    }
    
    enum NutritionQuality: CaseIterable {
        case veryHealthy        // 10.0 - Most positive
        case mostlyHealthy      // 8.0
        case mixedToUnhealthy   // 3.5 - Combined mixed and mostly unhealthy
        case veryUnhealthy      // 1.0 - Most negative
        
        var displayName: String {
            switch self {
            case .veryHealthy: return "Very Healthy\n(whole foods, plant-based)"
            case .mostlyHealthy: return "Mostly Healthy\n(balanced diet)"
            case .mixedToUnhealthy: return "Mixed to Unhealthy\n(some processed foods)"
            case .veryUnhealthy: return "Very Unhealthy\n(fast food, highly processed)"
            }
        }
        
        var nutritionValue: Double {
            switch self {
            case .veryHealthy: return 10.0
            case .mostlyHealthy: return 8.0
            case .mixedToUnhealthy: return 3.5
            case .veryUnhealthy: return 1.0
            }
        }
    }
    
    enum SmokingStatus: CaseIterable {
        case never              // 10.0 - Most positive
        case former             // 7.0
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
            case .never: return 10.0
            case .former: return 7.0
            case .occasionally: return 3.0
            case .daily: return 1.0
            }
        }
    }
    
    enum AlcoholFrequency: CaseIterable {
        case never              // 10.0 - Most positive
        case occasionally       // 8.0
        case severalTimesWeek   // 4.0
        case dailyOrHeavy       // 1.5 - Combined daily and heavy daily
        
        var displayName: String {
            switch self {
            case .never: return "Never"
            case .occasionally: return "Occasionally\n(weekly or less)"
            case .severalTimesWeek: return "Several Times\n(per week)"
            case .dailyOrHeavy: return "Daily or Heavy\n(one or more daily)"
            }
        }
        
        var alcoholValue: Double {
            switch self {
            case .never: return 10.0
            case .occasionally: return 8.0
            case .severalTimesWeek: return 4.0
            case .dailyOrHeavy: return 1.5
            }
        }
    }
    
    enum SocialConnectionsQuality: CaseIterable {
        case veryStrong         // 10.0 - Most positive
        case moderateToGood     // 6.5 - Combined moderate and good
        case limited            // 2.0
        case isolated           // 1.0 - Most negative
        
        var displayName: String {
            switch self {
            case .veryStrong: return "Very Strong\n(daily interactions)"
            case .moderateToGood: return "Moderate to Good\n(regular connections)"
            case .limited: return "Limited\n(rare interactions)"
            case .isolated: return "Isolated\n(minimal social contact)"
            }
        }
        
        var socialValue: Double {
            switch self {
            case .veryStrong: return 10.0
            case .moderateToGood: return 6.5
            case .limited: return 2.0
            case .isolated: return 1.0
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
    
    // MARK: - Properties
    
    // Navigation direction tracking for proper iOS-standard transitions
    @Published var navigationDirection: NavigationDirection = .forward
    
    enum NavigationDirection {
        case forward    // Moving deeper into questionnaire (right to left transition)
        case backward   // Moving back up questionnaire (left to right transition)
    }
    
    // Form data
    @Published var currentQuestion: Question {
        didSet {
            // OPTIMIZED: Move UserDefaults to background queue to prevent main thread blocking
            if currentQuestion != oldValue {
                Task {
                    await persistCurrentQuestion()
                }
            }
        }
    }

    // OPTIMIZED: Pre-computed static values to eliminate repeated calculations
    private static let staticAvailableYears: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        let minYear = currentYear - 120
        let maxYear = currentYear
        return Array(minYear...maxYear)
    }()

    private static let staticMonthNames: [String] = {
        let formatter = DateFormatter()
        return formatter.monthSymbols
    }()

    private static let staticCurrentYear = Calendar.current.component(.year, from: Date())
    private static let staticCurrentMonth = Calendar.current.component(.month, from: Date())
    
    // STEVE JOBS OPTIMIZATION: Pre-computed practical year range for instant picker performance
    private static let staticOptimizedYearRange: [Int] = {
        let currentYear = staticCurrentYear
        let minYear = currentYear - 110  // 110 years old max
        let maxYear = currentYear - 5    // 5 years old min
        return Array(minYear...maxYear)
    }()
    
    // STEVE JOBS OPTIMIZATION: Pre-computed month arrays for instant performance
    private static let staticAllMonths = Array(1...12)
    private static let staticCurrentYearMonths: [Int] = {
        return Array(1...staticCurrentMonth)
    }()

    // Birthdate (replacing age)
    @Published var birthdate: Date = Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date() // Default to 30 years ago

    // Separate month and year selection for improved UX
    @Published var selectedBirthMonth: Int = Calendar.current.component(.month, from: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date())
    @Published var selectedBirthYear: Int = Calendar.current.component(.year, from: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date())

    // PERFORMANCE: Use pre-computed static values
    private let calendar = Calendar.current

    // OPTIMIZED: Async UserDefaults persistence
    private func persistCurrentQuestion() async {
        await Task.detached(priority: .utility) {
            UserDefaults.standard.set(self.currentQuestion.rawValue, forKey: "questionnaire_current_question")
        }.value
    }

    // STEVE JOBS OPTIMIZATION: Batch birthdate updates to minimize @Published triggers
    private func updateBirthdateFromMonthYear() {
        var components = DateComponents()
        components.year = selectedBirthYear
        components.month = selectedBirthMonth
        components.day = 1 // Always use 1st of the month for consistency
        
        if let newDate = calendar.date(from: components) {
            // Only update if the date actually changed to prevent unnecessary @Published triggers
            if newDate != birthdate {
                birthdate = newDate
            }
        }
    }

    // STEVE JOBS OPTIMIZATION: Zero-computation properties using pre-computed static values
    var availableMonths: [Int] {
        if selectedBirthYear == Self.staticCurrentYear {
            // If current year is selected, use pre-computed current year months
            return Self.staticCurrentYearMonths
        } else {
            // For other years, use pre-computed all months array
            return Self.staticAllMonths
        }
    }

    // STEVE JOBS OPTIMIZATION: Direct reference to pre-computed static array
    var availableYears: [Int] {
        return Self.staticAvailableYears
    }

    // STEVE JOBS OPTIMIZATION: Direct reference to pre-computed optimized year range
    var optimizedYearRange: [Int] {
        return Self.staticOptimizedYearRange
    }

    // STEVE JOBS OPTIMIZATION: Direct array access to pre-computed month names
    func monthName(for month: Int) -> String {
        guard month >= 1 && month <= 12 else { return "" }
        return Self.staticMonthNames[month - 1]
    }

    // STEVE JOBS OPTIMIZATION: Efficient month selection with minimal @Published updates
    func updateSelectedMonth(_ month: Int) {
        guard month != selectedBirthMonth else { return } // Prevent unnecessary updates
        selectedBirthMonth = month
        updateBirthdateFromMonthYear()
    }

    // STEVE JOBS OPTIMIZATION: Efficient year selection with minimal @Published updates  
    func updateSelectedYear(_ year: Int) {
        guard year != selectedBirthYear else { return } // Prevent unnecessary updates
        selectedBirthYear = year
        updateBirthdateFromMonthYear()
    }

    // OPTIMIZED: Pre-computed birthdate range
    private static let staticBirthdateRange: ClosedRange<Date> = {
        let maxDate = Date() // Today (no future dates)
        let minDate = Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date() // Max 120 years ago
        return minDate...maxDate
    }()

    var birthdateRange: ClosedRange<Date> {
        return Self.staticBirthdateRange
    }

    // STEVE JOBS OPTIMIZATION: Cached age calculation to prevent repeated date computations
    private var _cachedAge: Int?
    private var _cachedBirthdate: Date?
    
    var age: Int {
        // Only recalculate if birthdate changed
        if _cachedBirthdate != birthdate || _cachedAge == nil {
            let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
            _cachedAge = ageComponents.year ?? 0
            _cachedBirthdate = birthdate
        }
        return _cachedAge ?? 0
    }
    
    // Gender
    @Published var selectedGender: UserProfile.Gender?
    
    // Name
    @Published var userName: String = ""
    
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
    
    // Stress Level
    @Published var selectedStressLevel: StressLevel?
    
    // Progress tracking for indicator
    var currentStep: Int {
        // Personalization Intro is step 1, so the first question starts at step 2
        currentQuestion.rawValue + 2 
    }
    var totalSteps: Int {
        12 // Total steps in the onboarding flow (excluding welcome and dashboard) - added stress question
    }
    
    var isComplete: Bool {
        currentQuestion == Question.lifeMotivation && canProceed
    }
    
    // STEVE JOBS OPTIMIZATION: Efficient validation with minimal computation
    var canProceed: Bool {
        switch currentQuestion {
        case .birthdate:
            // OPTIMIZED: Cache age calculation to prevent repeated date computations
            let currentAge = age
            return currentAge >= 18 && currentAge <= 120
        case .name:
            return !userName.isEmpty
        case .stressLevel:
            return selectedStressLevel != nil
        case .gender:
            return selectedGender != nil
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
            // Set forward direction for iOS-standard right-to-left transition
            navigationDirection = .forward
            // Remove animation here to consolidate animation control in the View
            currentQuestion = nextQuestion
        }
    }
    
    // Move back to previous question with animation
    func moveBackToPreviousQuestion() {
        if let prevQuestion = getPreviousQuestion() {
            // Set backward direction for iOS-standard left-to-right transition
            navigationDirection = .backward
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
        
        // Load saved userName if available
        if let savedName = UserDefaults.standard.string(forKey: "userName") {
            self.userName = savedName
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
        
        // Load saved userName if available
        if let savedName = UserDefaults.standard.string(forKey: "userName") {
            self.userName = savedName
        }
        
        // Sync the separate month/year properties with the default birthdate
        let calendar = Calendar.current
        selectedBirthMonth = calendar.component(.month, from: birthdate)
        selectedBirthYear = calendar.component(.year, from: birthdate)
    }
} 