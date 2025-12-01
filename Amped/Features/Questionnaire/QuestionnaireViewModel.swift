import Foundation
import OSLog
import SwiftUI

/// ViewModel for the Questionnaire functionality
final class QuestionnaireViewModel: ObservableObject {
    enum QuestionCategory: String, CaseIterable {
        case basics = "BASICS"
        case lifestyle = "LIFESTYLE" 
        case currentHealth = "CURRENT HEALTH"
        case goalsAndMotivation = "GOALS & MOTIVATION"
        case preferences = "PREFERENCES"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum Question: Int, CaseIterable, Hashable {
        case name
        case birthdate
        case stressLevel        // NEW: Question #4 for stress level
        case anxietyLevel       // NEW: Anxiety question
        case nutritionQuality
        case smokingStatus
        case alcoholConsumption
        case socialConnections
        case bloodPressureAwareness // New health markers question
        case lifeMotivation // Moved to last - will be shown after HealthKit
        case sleepQuality // New sleep quality question
        case deviceTracking // New question about health tracking devices - FINAL STEP
        case framingComfort          // NEW: tactful framing preference cue
        case urgencyResponse         // NEW: response to urgency cue
        
        var category: QuestionCategory {
            switch self {
            case .name, .birthdate:
                return .basics
            case .nutritionQuality, .smokingStatus, .alcoholConsumption:
                return .lifestyle
            case .stressLevel, .anxietyLevel, .socialConnections, .bloodPressureAwareness:
                return .currentHealth
            case .lifeMotivation, .sleepQuality:
                return .goalsAndMotivation
            case .deviceTracking:
                return .preferences
            case .framingComfort, .urgencyResponse:
                return .preferences
            }
        }
    }

    // Blood pressure categories kept simple for MVP
    enum BloodPressureCategory: String, CaseIterable, Codable {
        case normal
        case unknown
        case elevatedToStage1
        case low = "Below 120/80"
        case moderate = "130/80+"
        case high = "I don’t know"

        var displayName: String {
            switch self {
            case .normal: return "Below 120/80 (Normal)"
            case .unknown: return "I don't know"
            case .elevatedToStage1: return "120-129 (Elevated)"
            case .low: return ""
            case .moderate: return ""
            case .high: return ""
            }
        }
        
        var mainText: String {
            switch self {
            case .normal: return "Below 120/80"
            case .unknown: return "I don't know"
            case .elevatedToStage1: return "120-129"
            case .low: return ""
            case .moderate: return ""
            case .high: return ""
            }
        }
        
        var subText: String {
            switch self {
            case .normal: return "Normal"
            case .unknown: return ""
            case .elevatedToStage1: return "Elevated"
            case .low: return ""
            case .moderate: return ""
            case .high: return ""
            }
        }
    }
    
    enum StressLevel: String, CaseIterable {
        case veryLow = "Very Low"
        case low = "Low" 
        case moderate = "Moderate"
        case moderateToHigh = "Moderate To High"
        case high = "High"
        case veryHigh = "Very High"
        
        var displayName: String {
            switch self {
            case .veryLow: return "Very Low\n(rarely feel stressed)"
            case .low: return "(rarely feel stressed)"
            case .moderate: return "(Occassionally stressed)"
            case .moderateToHigh: return "Moderate to High\n(regular stress)"
            case .high: return "(Constantly stressed)"
            case .veryHigh: return "Very High\n(constantly stressed)"
            }
        }
        
        var mainText: String {
            switch self {
            case .veryLow: return "Very Low"
            case .low: return "Low"
            case .moderate: return "Moderate"
            case .moderateToHigh: return "Moderate to High"
            case .high: return "High"
            case .veryHigh: return "Very High"
            }
        }
        
        var subText: String {
            switch self {
            case .veryLow: return "rarely feel stressed"
            case .low: return "Occasionally stressed"
            case .moderate: return "Occasionally stressed"
            case .moderateToHigh: return "Regular Stress"
            case .high: return "Regular Stress"
            case .veryHigh: return "Constantly stressed"
            }
        }
        
        var stressValue: Double {
            switch self {
            case .veryLow: return 1.0
            case .low: return 2.0
            case .moderate: return 6.0
            case .moderateToHigh: return 7.0
            case .high: return 9.0
            case .veryHigh: return 10.0
            }
        }
    }
    
    enum AnxietyLevel: String, CaseIterable {
        case minimal            // 10.0 - Most positive
        case mildToModerate     // 6.5 - Combined mild and moderate
        case severe             // 2.0
        case verySevere         // 1.0 - Most negative
        case low = "Mild"
        case moderate = "Moderate"
        case high = "Severe"
        
        var displayName: String {
            switch self {
            case .minimal: return "Minimal\n(Rarely feel anxious)"
            case .mildToModerate: return "Mild to Moderate\n(Occasional to regular worry)"
            case .severe: return "Severe\n(Frequent anxiety episodes)"
            case .verySevere: return "Very Severe\n(Constant anxiety/panic)"
            case .low: return "(rarely feel anxious)"
            case .moderate: return "(Frequent anxiety episodes)"
            case .high: return "(Frequent anxiety episodes)"
            }
        }
        
        var mainText: String {
            switch self {
            case .minimal: return "Minimal"
            case .mildToModerate: return "Mild to Moderate"
            case .severe: return "Severe"
            case .verySevere: return "Very Severe"
            case .low: return "Mild"
            case .moderate: return "Moderate"
            case .high: return "Severe"
            }
        }
        
        var subText: String {
            switch self {
            case .minimal: return "rarely feel anxious"
            case .mildToModerate: return "Occasionally to regular worry"
            case .severe: return "Frequent anxiety episodes"
            case .verySevere: return "Constantly anxiety/panic"
            case .low: return "rarely feel anxious"
            case .moderate: return "Frequent anxiety episodes"
            case .high: return "Constantly anxiety/panic"
            }
        }
        
        var anxietyValue: Double {
            switch self {
            case .minimal: return 10.0
            case .mildToModerate: return 6.5
            case .severe: return 2.0
            case .verySevere: return 1.0
            case .low: return 10.0
            case .moderate: return 6.0
            case .high: return 2.0
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
    
    enum NutritionQuality: String, CaseIterable {
        case veryHealthy        // 10.0 - Most positive
        case mostlyHealthy      // 8.0
        case mixedToUnhealthy   // 3.5 - Combined mixed and mostly unhealthy
        case veryUnhealthy      // 1.0 - Most negative
        case low = "Very Healthy"
        case moderate = "Mixed"
        case high = "Very unhealthy"
        
        var displayName: String {
            switch self {
            case .veryHealthy: return "Very Healthy\n(whole foods, plant-based)"
            case .mostlyHealthy: return "Mostly Healthy\n(balanced diet)"
            case .mixedToUnhealthy: return "Mixed to Unhealthy\n(some processed foods)"
            case .veryUnhealthy: return "Very Unhealthy\n(fast food, highly processed)"
            case .low: return "(whole foods, plant-based)"
            case .moderate: return "(balanced diet)"
            case .high: return "(fast food, highly processed)"
            }
        }
        
        var mainText: String {
            switch self {
            case .veryHealthy: return "Very Healthy"
            case .mostlyHealthy: return "Mostly Healthy"
            case .mixedToUnhealthy: return "Mixed to unhealthy"
            case .veryUnhealthy: return "Very unhealthy"
            case .low: return "(whole foods, plant-based)"
            case .moderate: return "(balanced diet)"
            case .high: return "(fast food, highly processed)"
            }
        }
        
        var subText: String {
            switch self {
            case .veryHealthy: return "whole foods, plant-based"
            case .mostlyHealthy: return "balanced diet"
            case .mixedToUnhealthy: return "same processed foods"
            case .veryUnhealthy: return "fast food, highly processed"
            case .low: return "(whole foods, plant-based)"
            case .moderate: return "(balanced diet)"
            case .high: return "(fast food, highly processed)"
            }
        }
        
        var nutritionValue: Double {
            switch self {
            case .veryHealthy: return 10.0
            case .mostlyHealthy: return 8.0
            case .mixedToUnhealthy: return 3.5
            case .veryUnhealthy: return 1.0
            case .low: return 10.0
            case .moderate: return 7.0
            case .high: return 1.0
            }
        }
    }
    
    enum SmokingStatus: String, CaseIterable {
        case never              // 10.0 - Most positive
        case former             // 7.0
        case occasionally       // 3.0
        case daily              // 1.0 - Most negative
        case low = "Never"
        case moderate = "Former smoker"
        case high = "Daily"
        
        var displayName: String {
            switch self {
            case .never: return "Never"
            case .former: return "Former smoker\n(quit in the past)"
            case .occasionally: return "Occasionally"
            case .daily: return "Daily"
            case .low: return ""
            case .moderate: return "(quit in the past)"
            case .high: return ""
            }
        }
        
        var mainText: String {
            switch self {
            case .never: return "Never"
            case .former: return "Former smoker"
            case .occasionally: return "Occasionally"
            case .daily: return "Daily"
            case .low: return ""
            case .moderate: return "(quit in the past)"
            case .high: return ""
            }
        }
        
        var subText: String {
            switch self {
            case .never: return ""
            case .former: return "quit in the past"
            case .occasionally: return ""
            case .daily: return ""
            case .low: return ""
            case .moderate: return "(quit in the past)"
            case .high: return ""
            }
        }
        
        var smokingValue: Double {
            switch self {
            case .never: return 10.0
            case .former: return 7.0
            case .occasionally: return 3.0
            case .daily: return 1.0
            case .low: return 10.0
            case .moderate: return 6.0
            case .high: return 1.0
            }
        }
    }
    
    enum AlcoholFrequency: String, CaseIterable {
        case never              // 10.0 - Most positive
        case occasionally       // 8.0
        case severalTimesWeek   // 4.0
        case dailyOrHeavy       // 1.5 - Combined daily and heavy daily
        case low = "Never"
        case moderate = "Occassionally"
        case high = "Daily or Heavy"
        
        var displayName: String {
            switch self {
            case .never: return "Never"
            case .occasionally: return "Occasionally\n(weekly or less)"
            case .severalTimesWeek: return "Several Times\n(per week)"
            case .dailyOrHeavy: return "Daily or Heavy\n(one or more daily)"
            case .low: return ""
            case .moderate: return "(weekly or less)"
            case .high: return ""
            }
        }
        
        var mainText: String {
            switch self {
            case .never: return "Never"
            case .occasionally: return "Occasionally"
            case .severalTimesWeek: return "Several Times"
            case .dailyOrHeavy: return "Daily or Heavy"
            case .low: return ""
            case .moderate: return "(weekly or less)"
            case .high: return ""
            }
        }
        
        var subText: String {
            switch self {
            case .never: return ""
            case .occasionally: return "weekly or less"
            case .severalTimesWeek: return "per week"
            case .dailyOrHeavy: return "one or more daily"
            case .low: return ""
            case .moderate: return "(weekly or less)"
            case .high: return ""
            }
        }
        
        var alcoholValue: Double {
            switch self {
            case .never: return 10.0
            case .occasionally: return 8.0
            case .severalTimesWeek: return 4.0
            case .dailyOrHeavy: return 1.5
            case .low: return 10.0
            case .moderate: return 7.0
            case .high: return 1.5
            }
        }
    }
    
    enum SocialConnectionsQuality: String, CaseIterable {
        case veryStrong         // 10.0 - Most positive
        case moderateToGood     // 6.5 - Combined moderate and good
        case limited            // 2.0
        case isolated           // 1.0 - Most negative
        case low = "Very Strong"
        case moderate = "Moderate"
        case high = "Isolated"
        
        var displayName: String {
            switch self {
            case .veryStrong: return "Very Strong\n(daily interactions)"
            case .moderateToGood: return "Moderate to Good\n(regular connections)"
            case .limited: return "Limited\n(rare interactions)"
            case .isolated: return "Isolated\n(minimal social contact)"
            case .low: return ""
            case .moderate: return "(rare interactions)"
            case .high: return ""
            }
        }
        
        var mainText: String {
            switch self {
            case .veryStrong: return "Very Strong"
            case .moderateToGood: return "Moderate to Good"
            case .limited: return "Limited"
            case .isolated: return "Isolated"
            case .low: return ""
            case .moderate: return "(rare interactions)"
            case .high: return ""
            }
        }
        
        var subText: String {
            switch self {
            case .veryStrong: return "daily interaction"
            case .moderateToGood: return "regular connections"
            case .limited: return "rare interactions"
            case .isolated: return "minimal social contact"
            case .low: return ""
            case .moderate: return "(rare interactions)"
            case .high: return ""
            }
        }
        
        var socialValue: Double {
            switch self {
            case .veryStrong: return 10.0
            case .moderateToGood: return 6.5
            case .limited: return 2.0
            case .isolated: return 1.0
            case .low: return 10.0
            case .moderate: return 6
            case .high: return 1.0
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
        
        var mainText: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .average: return "Average"
            case .poorToVeryPoor: return "Poor to Very Poor"
            }
        }
        
        var subText: String {
            switch self {
            case .excellent: return "7-9 hrs, wake refreshed"
            case .good: return "Usually sleep well"
            case .average: return "Sometimes restless"
            case .poorToVeryPoor: return "Tired, trouble sleeping/insomnia"
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
        
        var mainText: String {
            switch self {
            case .family: return "Watch my family grow"
            case .dreams: return "Achieve my dreams"
            case .experience: return "Simply to experience life longer"
            case .contribution: return "Give more back to the world"
            }
        }
        
        var subText: String {
            return ""
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

    // COLD START FIX: Lazy-computed static values to eliminate cold start blocking
    private static var _staticCurrentYear: Int?
    private static var _staticCurrentMonth: Int?
    private static var _staticOptimizedYearRange: [Int]?
    private static var _staticCurrentYearMonths: [Int]?
    
    private static var staticCurrentYear: Int {
        if let cached = _staticCurrentYear { return cached }
        let value = Calendar.current.component(.year, from: Date())
        _staticCurrentYear = value
        return value
    }
    
    private static var staticCurrentMonth: Int {
        if let cached = _staticCurrentMonth { return cached }
        let value = Calendar.current.component(.month, from: Date())
        _staticCurrentMonth = value
        return value
    }
    
    private static var staticOptimizedYearRange: [Int] {
        if let cached = _staticOptimizedYearRange { return cached }
        let currentYear = staticCurrentYear
        let minYear = currentYear - 110  // 110 years old max
        let maxYear = currentYear - 5    // 5 years old min
        let value = Array(minYear...maxYear)
        _staticOptimizedYearRange = value
        return value
    }
    
    private static var staticCurrentYearMonths: [Int] {
        if let cached = _staticCurrentYearMonths { return cached }
        let value = Array(1...staticCurrentMonth)
        _staticCurrentYearMonths = value
        return value
    }

    // ULTRA-PERFORMANCE FIX: Truly static month names - zero system calls (keep as-is)
    private static let staticMonthNames: [String] = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    
    // STEVE JOBS OPTIMIZATION: Pre-computed month arrays for instant performance
    private static let staticAllMonths = Array(1...12)

    // Birthdate (replacing age)
    @Published var birthdate: Date = Date() // Default to today (age = 0, so no pre-filled value)

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
    
    // NEW: Direct age setting method for age input
    func setAge(_ age: Int) {
        // Calculate birthdate from age
        let currentYear = calendar.component(.year, from: Date())
        let birthYear = currentYear - age
        
        // Set birthdate to January 1st of the birth year
        var components = DateComponents()
        components.year = birthYear
        components.month = 1
        components.day = 1
        
        if let newBirthdate = calendar.date(from: components) {
            birthdate = newBirthdate
            // Update month/year properties for consistency
            selectedBirthMonth = 1
            selectedBirthYear = birthYear
            // Clear cache so age will be recalculated
            _cachedAge = nil
            _cachedBirthdate = nil
        }
    }
    
    // Height setting method (in cm)
    func setHeight(_ height: Double) {
        self.height = height
    }
    
    // Weight setting method (in kg)
    func setWeight(_ weight: Double) {
        self.weight = weight
    }

    // COLD START FIX: Lazy birthdate range to eliminate cold start blocking
    private static var _staticBirthdateRange: ClosedRange<Date>?
    
    private static var staticBirthdateRange: ClosedRange<Date> {
        if let cached = _staticBirthdateRange { return cached }
        let maxDate = Date() // Today (no future dates)
        let minDate = Calendar.current.date(byAdding: .year, value: -120, to: Date()) ?? Date() // Max 120 years ago
        let value = minDate...maxDate
        _staticBirthdateRange = value
        return value
    }

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
    
    // Height and Weight (in cm and kg)
    @Published var height: Double = 0
    @Published var weight: Double = 0
    
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
        // First question (name) should be step 1
        currentQuestion.rawValue + 1 
    }
    var totalSteps: Int {
        12 // Updated to match new design requirement
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
//        guard canProceed else { return }
        
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
        // ULTRA-PERFORMANCE FIX: Absolute minimum initialization for instant creation
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // CRITICAL FIX: Load saved question SYNCHRONOUSLY to prevent flash
        if !startFresh {
            // Load saved question immediately to avoid UI flash
            if let savedQuestionRawValue = UserDefaults.standard.object(forKey: "questionnaire_current_question") as? Int,
               let savedQuestion = Question(rawValue: savedQuestionRawValue) {
                self.currentQuestion = savedQuestion
            } else {
                self.currentQuestion = .name
            }
            
            // Load saved name immediately
            if let savedName = UserDefaults.standard.string(forKey: "userName") {
                self.userName = savedName
            }
        } else {
            // Fresh start - always begin at name question
            self.currentQuestion = .name
            
            // Clear saved data immediately when starting fresh
            UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")
            UserDefaults.standard.removeObject(forKey: "userName")
        }
        
        // PERFORMANCE: Lazy birthdate initialization - defer expensive calendar operations
        // Use pre-computed static values for instant initialization
        self.selectedBirthMonth = Self.staticCurrentMonth
        self.selectedBirthYear = Self.staticCurrentYear - 30 // Default to 30 years ago
        
        _ = CFAbsoluteTimeGetCurrent() - startTime  // Performance timing (unused in release)
        print("🔍 PERFORMANCE_DEBUG: Ultra-fast QuestionnaireViewModel.init() completed")
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
