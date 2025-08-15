import Foundation
import OSLog
import SwiftUI

/// ViewModel for the Questionnaire functionality
final class QuestionnaireViewModel: ObservableObject {
    enum QuestionCategory: String, CaseIterable {
        case basics = "BASICS"
        case lifestyle = "LIFESTYLE" 
        case wellness = "WELLNESS"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum Question: Int, CaseIterable, Hashable {
        case name
        case birthdate
        case stressLevel        // NEW: Question #3 for stress level
        case anxietyLevel       // NEW: Anxiety question
        case gender
        case nutritionQuality
        case smokingStatus
        case alcoholConsumption
        case socialConnections
        case sleepQuality // New sleep quality question
        case bloodPressureAwareness // New health markers question
        case deviceTracking // New question about health tracking devices
        case framingComfort          // NEW: tactful framing preference cue
        case urgencyResponse         // NEW: response to urgency cue
        case lifeMotivation // Moved to last - will be shown after HealthKit
        
        var category: QuestionCategory {
            switch self {
            case .name, .birthdate, .gender:
                return .basics
            case .nutritionQuality, .smokingStatus, .alcoholConsumption:
                return .lifestyle
            case .stressLevel, .anxietyLevel, .socialConnections, .sleepQuality, .bloodPressureAwareness, .deviceTracking, .framingComfort, .urgencyResponse, .lifeMotivation:
                return .wellness
            }
        }
    }

    // Blood pressure categories kept simple for MVP
    enum BloodPressureCategory: String, CaseIterable, Codable {
        case normal
        case unknown
        case elevatedToStage1
        case high

        var displayName: String {
            switch self {
            case .normal: return "Below 120/80 (Normal)"
            case .unknown: return "I don't know"
            case .elevatedToStage1: return "120-129 (Elevated)"
            case .high: return "130/80+ (High)"
            }
        }
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
    
    enum AnxietyLevel: CaseIterable {
        case minimal            // 10.0 - Most positive
        case mildToModerate     // 6.5 - Combined mild and moderate
        case severe             // 2.0
        case verySevere         // 1.0 - Most negative
        
        var displayName: String {
            switch self {
            case .minimal: return "Minimal\n(Rarely feel anxious)"
            case .mildToModerate: return "Mild to Moderate\n(Occasional to regular worry)"
            case .severe: return "Severe\n(Frequent anxiety episodes)"
            case .verySevere: return "Very Severe\n(Constant anxiety/panic)"
            }
        }
        
        var anxietyValue: Double {
            switch self {
            case .minimal: return 10.0
            case .mildToModerate: return 6.5
            case .severe: return 2.0
            case .verySevere: return 1.0
            }
        }
    }

    // NEW: Tactful framing comfort options (no mention of death or countdowns)
    enum FramingComfort: CaseIterable {
        case hardTruths       // prefers direct, complete information
        case encouragingWins  // prefers deltas and supportive tone
        case gainsOnly        // prefers only positive progress

        var displayName: String {
            switch self {
            case .hardTruths: return "I do best with straight facts"
            case .encouragingWins: return "Balanced feedback keeps me steady"
            case .gainsOnly: return "Positive reinforcement keeps me going"
            }
        }
    }

    // NEW: Response to urgency or short timelines, phrased tactfully
    enum UrgencyResponse: CaseIterable {
        case energized     // urgency motivates
        case neutral       // neutral
        case pressured     // urgency feels discouraging

        var displayName: String {
            switch self {
            case .energized: return "Urgency energizes me"
            case .neutral: return "I can work with any pace"
            case .pressured: return "I thrive with low-pressure pacing"
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
    
    enum SleepQuality: CaseIterable {
        case excellent          // 10.0 - Most positive
        case good               // 8.0
        case average            // 6.0
        case poorToVeryPoor     // 2.0 - Combined poor and very poor
        
        var displayName: String {
            switch self {
            case .excellent: return "Excellent\n(7-9 hrs, wake refreshed)"
            case .good: return "Good\n(Usually sleep well)"
            case .average: return "Average\n(Sometimes restless)"
            case .poorToVeryPoor: return "Poor to Very Poor\n(Tired, trouble sleeping/insomnia)"
            }
        }
        
        var sleepValue: Double {
            switch self {
            case .excellent: return 10.0
            case .good: return 8.0
            case .average: return 6.0
            case .poorToVeryPoor: return 2.0
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
    // Track the previously displayed question to allow adaptive transitions
    @Published var previousQuestion: Question? = nil
    // Debug logging
    private let transitionLogger = Logger(subsystem: "com.amped.app", category: "QuestionnaireTransition")
    
    enum NavigationDirection {
        case forward    // Moving deeper into questionnaire (right to left transition)
        case backward   // Moving back up questionnaire (left to right transition)
    }
    
    // Form data - CRITICAL PERFORMANCE FIX: Remove expensive didSet observer
    @Published var currentQuestion: Question

    // OPTIMIZED: Pre-computed static values to eliminate repeated calculations
    private static let staticAvailableYears: [Int] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        let minYear = currentYear - 120
        let maxYear = currentYear
        return Array(minYear...maxYear)
    }()

    // ULTRA-PERFORMANCE FIX: Truly static month names - zero system calls
    private static let staticMonthNames: [String] = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]

    // ULTRA-PERFORMANCE FIX: Pre-computed static date values - calculated once at app launch
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
    // PERFORMANCE FIX: Remove expensive didSet observers that trigger on every picker scroll
    @Published var selectedBirthMonth: Int = Calendar.current.component(.month, from: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date())
    @Published var selectedBirthYear: Int = Calendar.current.component(.year, from: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date())

    // PERFORMANCE: Use pre-computed static values
    private let calendar = Calendar.current
    
    // ULTRA-FAST: Zero-lag synchronous birthdate update - CRITICAL PERFORMANCE FIX
    func updateBirthdateFromMonthYear() {
        // PERFORMANCE: Synchronous, lightweight date calculation - no async overhead
        var components = DateComponents()
        components.year = selectedBirthYear
        components.month = selectedBirthMonth
        components.day = 15 // Use middle of month as default
        
        if let newBirthdate = calendar.date(from: components) {
            birthdate = newBirthdate
            // Clear cache so age will be recalculated
            _cachedAge = nil
            _cachedBirthdate = nil
        }
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
    
    // Sleep Quality
    @Published var selectedSleepQuality: SleepQuality?
    // New: Desired daily lifespan gain minutes (5..120)
    @Published var desiredDailyLifespanGainMinutes: Int = 5
    
    // Blood Pressure
    @Published var selectedBloodPressureCategory: BloodPressureCategory?

    // Device Tracking
    @Published var selectedDeviceTrackingStatus: DeviceTrackingStatus?
    
    // Life Motivation
    @Published var selectedLifeMotivation: LifeMotivation?
    
    // Stress Level
    @Published var selectedStressLevel: StressLevel?
    
    // Anxiety Level
    @Published var selectedAnxietyLevel: AnxietyLevel?

    // NEW: Tactful cues
    @Published var selectedFramingComfort: FramingComfort?
    @Published var selectedUrgencyResponse: UrgencyResponse?
    
    // Progress tracking for indicator
    var currentStep: Int {
        // Personalization Intro is step 1, so the first question starts at step 2
        currentQuestion.rawValue + 2 
    }
    var totalSteps: Int {
        17 // Added framing comfort and urgency response tactful questions
    }
    
    var isComplete: Bool {
        currentQuestion == Question.lifeMotivation && canProceed
    }
    
    // ULTRA-FAST: Lightning-fast validation with zero expensive operations
    var canProceed: Bool {
        switch currentQuestion {
        case .birthdate:
            // ULTRA-PERFORMANCE FIX: Use pre-computed static year for instant validation
            let approximateAge = Self.staticCurrentYear - selectedBirthYear
            return approximateAge >= 18 && approximateAge <= 120
        case .name:
            return !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .stressLevel:
            return selectedStressLevel != nil
        case .anxietyLevel:
            return selectedAnxietyLevel != nil
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
        case .sleepQuality:
            return selectedSleepQuality != nil
        case .bloodPressureAwareness:
            return selectedBloodPressureCategory != nil
        case .deviceTracking:
            return selectedDeviceTrackingStatus != nil
        case .framingComfort:
            return selectedFramingComfort != nil
        case .urgencyResponse:
            return selectedUrgencyResponse != nil
        case .lifeMotivation:
            return selectedLifeMotivation != nil
        }
    }
    
    // Check if it's possible to move back to previous question
    var canMoveBack: Bool {
        return currentQuestion != .name
    }
    
    // Check if we're at the first question
    var isFirstQuestion: Bool {
        return currentQuestion == .name
    }
    
    // Check if we should show a category header for the current question
    var shouldShowCategoryHeader: Bool {
        // Show category header for the first question in each category
        let questionsInOrder = Question.allCases
        guard let currentIndex = questionsInOrder.firstIndex(of: currentQuestion) else { return false }
        
        // Always show for first question
        if currentIndex == 0 { return true }
        
        // Show if the category is different from the previous question
        let previousQuestion = questionsInOrder[currentIndex - 1]
        return currentQuestion.category != previousQuestion.category
    }
    
    // Get the current question's category
    var currentQuestionCategory: QuestionCategory {
        return currentQuestion.category
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
    
    // Proceed to next question with animation - CRITICAL PERFORMANCE FIX
    func proceedToNextQuestion() {
        guard canProceed else { return }
        
        if let nextQuestion = getNextQuestion() {
            // Set forward direction for iOS-standard right-to-left transition
            navigationDirection = .forward
            // Record previous question for adaptive transitions and logging
            let fromQuestion = currentQuestion
            previousQuestion = fromQuestion
            transitionLogger.info("➡️ Proceeding from \(String(describing: fromQuestion)) to \(String(describing: nextQuestion))")
            // CRITICAL FIX (Applied rule: Simplicity is KING):
            // Ensure the transition direction is applied to the CURRENT view before it's removed.
            // We set the direction first, then update the question on the next run loop so the
            // outgoing view uses the correct removal edge on the first transition.
            DispatchQueue.main.async {
                // Applied rule: Simplicity is KING — use consistent spring animation for all transitions
                withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
                    self.currentQuestion = nextQuestion
                }
            }
            
            // PERFORMANCE: Persist state in background to avoid UI blocking
            DispatchQueue.global(qos: .utility).async {
                UserDefaults.standard.set(nextQuestion.rawValue, forKey: "questionnaire_current_question")
            }
        }
    }

    /// Proceed to next question even if current selection is nil (used for "Not sure")
    /// Applied rule: Simplicity is KING; minimal surface area to support inline "Not sure" answers
    func proceedToNextQuestionAllowingNil() {
        if let nextQuestion = getNextQuestion() {
            navigationDirection = .forward
            // Apply same fix as standard proceed for consistent first-transition behavior
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
                    self.currentQuestion = nextQuestion
                }
            }
            DispatchQueue.global(qos: .utility).async {
                UserDefaults.standard.set(nextQuestion.rawValue, forKey: "questionnaire_current_question")
            }
        }
    }
    
    // Move back to previous question with animation
    func moveBackToPreviousQuestion() {
        if let prevQuestion = getPreviousQuestion() {
            // Set backward direction for iOS-standard left-to-right transition
            navigationDirection = .backward
            let fromQuestion = currentQuestion
            previousQuestion = fromQuestion
            transitionLogger.info("⬅️ Moving back from \(String(describing: fromQuestion)) to \(String(describing: prevQuestion))")
            // CRITICAL FIX: Use synchronous update with animation
            // The caller should not wrap this in another animation block
            withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
                self.currentQuestion = prevQuestion
            }
            
            // PERFORMANCE: Persist state in background to avoid UI blocking
            DispatchQueue.global(qos: .utility).async {
                if prevQuestion != .name { // Don't save name as current question to ensure fresh start
                    UserDefaults.standard.set(prevQuestion.rawValue, forKey: "questionnaire_current_question")
                }
            }
        } else {
            print("   ERROR: No previous question found!")
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
    
    // PERFORMANCE FIX: Direct array access to pre-computed month names
    func monthName(for month: Int) -> String {
        guard month >= 1 && month <= 12 else { return "" }
        return Self.staticMonthNames[month - 1]
    }
    
    // PERFORMANCE FIX: Simplified computed properties using pre-computed static values
    var availableMonths: [Int] {
        if selectedBirthYear == Self.staticCurrentYear {
            return Self.staticCurrentYearMonths
        } else {
            return Self.staticAllMonths
        }
    }
    
    var optimizedYearRange: [Int] {
        return Self.staticOptimizedYearRange
    }
    
    // MARK: - Initialization
    
    init(startFresh: Bool = false) {
        // CRITICAL FIX: Allow forcing a fresh start, ignoring saved state
        if startFresh {
            // Always start from name when forcing fresh start
            self.currentQuestion = .name
            
            // Clear any saved state to ensure consistency
            UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")
            UserDefaults.standard.removeObject(forKey: "userName")
        } else {
            // Restore current question from UserDefaults if available
            if let savedQuestionRawValue = UserDefaults.standard.object(forKey: "questionnaire_current_question") as? Int,
               let savedQuestion = Question(rawValue: savedQuestionRawValue) {
                self.currentQuestion = savedQuestion
            } else {
                self.currentQuestion = .name
            }
        }
        
        // Load saved userName if available
        if let savedName = UserDefaults.standard.string(forKey: "userName"), !startFresh {
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
