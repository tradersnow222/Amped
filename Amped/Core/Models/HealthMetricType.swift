import Foundation
import HealthKit
import SwiftUI

/// Enumeration of supported health metric types for the Amped app
/// Each case represents a health metric that can be tracked and analyzed
enum HealthMetricType: String, CaseIterable, Identifiable, Codable {
    // HealthKit metrics - only the most impactful ones
    case steps
    case exerciseMinutes
    case sleepHours
    case restingHeartRate
    case heartRateVariability
    case bodyMass
    case activeEnergyBurned
    case vo2Max
    case oxygenSaturation
    
    // Manual metrics from questionnaire
    case nutritionQuality
    case smokingStatus
    case alcoholConsumption
    case socialConnectionsQuality
    case stressLevel
    case bloodPressure
    
    var id: String { rawValue }
    
    /// Returns the localized display name for this metric type (using Apple's official names)
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .exerciseMinutes: return "Exercise"
        case .sleepHours: return "Sleep"
        case .restingHeartRate: return "Resting Heart Rate"
        case .heartRateVariability: return "Heart Rate Variability"
        case .bodyMass: return "Weight"
        case .nutritionQuality: return "Nutrition"
        case .smokingStatus: return "Smoking"
        case .alcoholConsumption: return "Alcohol"
        case .socialConnectionsQuality: return "Social Connections"
        case .activeEnergyBurned: return "Active Energy"
        case .vo2Max: return "Cardio Fitness (VO2 Max)"
        case .oxygenSaturation: return "Blood Oxygen"
        case .stressLevel: return "Stress Level"
        case .bloodPressure: return "Blood Pressure"
        }
    }
    
    /// Subtle contextual description that explains what the metric does for you
    var contextualDescription: String {
        switch self {
        case .steps: return "Daily movement"
        case .exerciseMinutes: return "Active energy burn"
        case .sleepHours: return "Recovery recharge"
        case .restingHeartRate: return "Heart efficiency"
        case .heartRateVariability: return "Recovery readiness"
        case .bodyMass: return "Body composition"
        case .nutritionQuality: return "Fuel quality"
        case .smokingStatus: return "Lung health"
        case .alcoholConsumption: return "System impact"
        case .socialConnectionsQuality: return "Mental wellbeing"
        case .activeEnergyBurned: return "Energy output"
        case .vo2Max: return "Peak performance"
        case .oxygenSaturation: return "Oxygen efficiency"
        case .stressLevel: return "Mental load"
        case .bloodPressure: return "Cardiovascular health"
        }
    }
    
    /// Returns true if this metric should use plural form in questions ("What are...?")
    var isPlural: Bool {
        switch self {
        case .steps, .socialConnectionsQuality:
            return true
        default:
            return false
        }
    }
    
    /// Intuitive grouping by what the metric does for your health
    var functionalGroup: MetricFunctionalGroup {
        switch self {
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            return .energySources
        case .sleepHours, .heartRateVariability, .restingHeartRate:
            return .recoveryIndicators
        case .vo2Max, .oxygenSaturation, .bodyMass:
            return .performanceMetrics
        case .nutritionQuality, .stressLevel, .socialConnectionsQuality:
            return .lifestyleFactors
        case .smokingStatus, .alcoholConsumption, .bloodPressure:
            return .healthRisks
        }
    }
    
    /// Battery-themed power description for different charge levels
    func batteryDescription(for powerLevel: PowerLevel) -> String {
        switch self {
        case .sleepHours:
            switch powerLevel {
            case .full: return "Fully recharged and ready"
            case .high: return "Well-rested energy"
            case .medium: return "Moderate recharge"
            case .low: return "Running low on rest"
            case .critical: return "Energy critically low"
            }
        case .steps, .exerciseMinutes:
            switch powerLevel {
            case .full: return "High energy output"
            case .high: return "Good activity power"
            case .medium: return "Moderate energy burn"
            case .low: return "Low power mode"
            case .critical: return "Minimal energy use"
            }
        case .heartRateVariability:
            switch powerLevel {
            case .full: return "Peak recovery state"
            case .high: return "Good recovery power"
            case .medium: return "Moderate recovery"
            case .low: return "Recovery needed"
            case .critical: return "System strain detected"
            }
        case .vo2Max:
            switch powerLevel {
            case .full: return "Peak performance ready"
            case .high: return "Strong cardio power"
            case .medium: return "Good fitness level"
            case .low: return "Building cardio base"
            case .critical: return "Fitness improvement needed"
            }
        default:
            switch powerLevel {
            case .full: return "Optimal power"
            case .high: return "Good energy"
            case .medium: return "Moderate level"
            case .low: return "Needs attention"
            case .critical: return "Action required"
            }
        }
    }
    
    /// Emotional outcome description - what this metric gives you
    var outcomeDescription: String {
        switch self {
        case .steps: return "Energizes your day"
        case .exerciseMinutes: return "Builds your strength"
        case .sleepHours: return "Powers your recovery"
        case .restingHeartRate: return "Shows heart health"
        case .heartRateVariability: return "Tracks your resilience"
        case .bodyMass: return "Reflects your balance"
        case .nutritionQuality: return "Fuels your potential"
        case .smokingStatus: return "Protects your lungs"
        case .alcoholConsumption: return "Impacts your clarity"
        case .socialConnectionsQuality: return "Nurtures your spirit"
        case .activeEnergyBurned: return "Measures your drive"
        case .vo2Max: return "Shows your endurance"
        case .oxygenSaturation: return "Reflects oxygen flow"
        case .stressLevel: return "Affects your peace"
        case .bloodPressure: return "Powers your circulation"
        }
    }
    
    /// Detailed description for the About section
    var detailedDescription: String {
        switch self {
        case .steps: 
            return "Daily steps directly correlate with cardiovascular health and longevity. Research shows that 8,000–10,000 steps per day is associated with lower mortality."
        case .exerciseMinutes:
            return "Regular exercise strengthens your heart, improves mood, and significantly reduces mortality risk. Aim for at least \(Double(150).formattedAsTime()) weekly."
        case .sleepHours:
            return "Quality sleep is essential for cellular repair, brain health, and immune function. Most adults need 7–9 hours nightly."
        case .restingHeartRate:
            return "A lower resting heart rate indicates better cardiovascular fitness. Many healthy adults target ≤60 bpm."
        case .heartRateVariability:
            return "HRV reflects your body's ability to adapt to stress. Higher variability generally indicates better health and recovery."
        case .bodyMass:
            return "Maintaining a healthy weight reduces strain on your cardiovascular system and joints, supporting long-term health."
        case .nutritionQuality:
            return "A balanced diet rich in nutrients supports overall health, energy levels, and disease prevention."
        case .smokingStatus:
            return "Smoking significantly reduces life expectancy. Quitting at any age provides immediate and long-term health benefits."
        case .alcoholConsumption:
            return "Minimal alcohol intake is associated with better long-term health outcomes."
        case .socialConnectionsQuality:
            return "Strong social connections reduce stress and improve mental wellbeing."
        case .activeEnergyBurned:
            return "Active calories burned through movement and exercise contribute to maintaining a healthy metabolism and weight."
        case .vo2Max:
            return "VO2 Max measures your body's ability to use oxygen during exercise, a strong predictor of cardiovascular health."
        case .oxygenSaturation:
            return "Blood oxygen levels indicate how well your lungs and circulation deliver oxygen to your tissues."
        case .stressLevel:
            return "Chronic stress accelerates aging and increases disease risk. Managing stress is crucial for long-term health."
        case .bloodPressure:
            return "Blood pressure is a key indicator of cardiovascular health. Lower readings generally indicate better heart health and reduced disease risk."
        }
    }
    
    /// Returns the corresponding HealthKit quantity type if available
    var healthKitType: HKQuantityType? {
        switch self {
        case .steps:
            return HKQuantityType.quantityType(forIdentifier: .stepCount)
        case .exerciseMinutes:
            return HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)
        case .restingHeartRate:
            return HKQuantityType.quantityType(forIdentifier: .restingHeartRate)
        case .heartRateVariability:
            return HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
        case .bodyMass:
            return HKQuantityType.quantityType(forIdentifier: .bodyMass)
        case .activeEnergyBurned:
            return HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
        case .vo2Max:
            return HKQuantityType.quantityType(forIdentifier: .vo2Max)
        case .oxygenSaturation:
            return HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)
        case .sleepHours, .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel, .bloodPressure:
            return nil // These are handled separately
        }
    }
    
    /// Returns the appropriate HK unit for this metric type
    var healthKitUnit: HKUnit? {
        switch self {
        case .steps:
            return HKUnit.count()
        case .exerciseMinutes:
            return HKUnit.minute()
        case .restingHeartRate:
            return HKUnit(from: "count/min")
        case .heartRateVariability:
            return HKUnit.secondUnit(with: .milli)
        case .bodyMass:
            return HKUnit.gramUnit(with: .kilo) // Use kg internally, convert to user preference in UI
        case .activeEnergyBurned:
            return HKUnit.kilocalorie()
        case .vo2Max:
            return HKUnit(from: "ml/kg*min")
        case .oxygenSaturation:
            return HKUnit.percent()
        case .sleepHours, .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel, .bloodPressure:
            return nil
        }
    }
    
    /// Alias for healthKitUnit to maintain compatibility
    var unit: HKUnit? {
        return healthKitUnit
    }
    
    /// Returns collection of HealthKit types for requesting permissions
    static var healthKitTypes: [HealthMetricType] {
        return [.steps, .exerciseMinutes, .sleepHours, .restingHeartRate, .heartRateVariability, .bodyMass, .activeEnergyBurned, .vo2Max, .oxygenSaturation]
    }
    
    /// Returns collection of manual/questionnaire types
    static var manualTypes: [HealthMetricType] {
        return [.nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel, .bloodPressure]
    }
    
    /// Returns whether this metric type is derived from HealthKit
    var isHealthKitMetric: Bool {
        switch self {
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel, .bloodPressure:
            return false
        default:
            return true
        }
    }
    
    /// Returns the SF Symbol name for this metric type
    var symbolName: String {
        switch self {
        case .steps: return "figure.walk"
        case .exerciseMinutes: return "figure.run"
        case .restingHeartRate: return "heart.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .sleepHours: return "bed.double.fill"
        case .bodyMass: return "scalemass.fill"
        case .nutritionQuality: return "fork.knife"
        case .smokingStatus: return "smoke.fill"
        case .alcoholConsumption: return "wineglass"
        case .socialConnectionsQuality: return "person.2.fill"
        case .activeEnergyBurned: return "flame.fill"
        case .vo2Max: return "lungs.fill"
        case .oxygenSaturation: return "drop.fill"
        case .stressLevel: return "brain.head.profile"
        case .bloodPressure: return "heart.circle.fill"
        }
    }
    
    /// Returns the name of the metric (alias for displayName for compatibility)
    var name: String {
        return displayName
    }
    
    /// Returns the color associated with this metric type
    var color: Color {
        switch self {
        case .steps, .exerciseMinutes, .heartRateVariability, .sleepHours, .nutritionQuality, .socialConnectionsQuality, .activeEnergyBurned, .vo2Max, .oxygenSaturation:
            return Color.ampedGreen
        case .restingHeartRate, .bodyMass, .smokingStatus, .alcoholConsumption, .stressLevel, .bloodPressure:
            return Color.ampedRed
        }
    }
    
    /// Period-agnostic baseline (used as fallback if a period-specific target is unavailable)
    var baselineValue: Double {
        switch self {
        case .steps: return 7500
        case .exerciseMinutes: return 20
        case .restingHeartRate: return 70
        case .heartRateVariability: return 35
        case .sleepHours: return 7
        case .bodyMass: return 70 // kg for average adult
        case .nutritionQuality: return 5 // 1-10 scale, 5 = average
        case .smokingStatus: return 10 // 1-10 scale, 10 = never smoked
        case .alcoholConsumption: return 8 // 1-10 scale, 8 = occasional drinking
        case .socialConnectionsQuality: return 5 // 1-10 scale, 5 = moderate connections
        case .activeEnergyBurned: return 400 // calories
        case .vo2Max: return 40 // ml/kg/min
        case .oxygenSaturation: return 98 // percent
        case .stressLevel: return 5 // 1-10 scale, 5 = moderate stress
        case .bloodPressure: return 120 // systolic pressure baseline
        }
    }
    
    /// Indicates whether a higher value is better for this metric
    var isHigherBetter: Bool {
        switch self {
        case .steps, .exerciseMinutes, .heartRateVariability, .sleepHours, .nutritionQuality, .socialConnectionsQuality, .activeEnergyBurned, .vo2Max, .oxygenSaturation:
            return true
        case .restingHeartRate, .bodyMass, .smokingStatus, .alcoholConsumption, .stressLevel, .bloodPressure:
            return false
        }
    }
    
    /// Period-agnostic recommended target (kept for compatibility)
    var targetValue: Double? {
        // Prefer using targetValue(for:) below
        switch self {
        case .steps: return 10000
        case .exerciseMinutes: return 30
        case .restingHeartRate: return 60
        case .heartRateVariability: return 50
        case .sleepHours: return 8
        case .bodyMass: return nil // Depends on height, gender, etc.
        case .nutritionQuality: return 8
        case .smokingStatus: return 10
        case .alcoholConsumption: return 10
        case .socialConnectionsQuality: return 8
        case .activeEnergyBurned: return 500
        case .vo2Max: return 45
        case .oxygenSaturation: return 100
        case .stressLevel: return 2
        case .bloodPressure: return 110
        }
    }
    
    /// Period-aware recommended target values
    /// Notes (evidence):
    /// - Steps: 8,000–10,000 steps/day associated with lower mortality (Paluch et al., JAMA Netw Open 2022; Saint-Maurice et al., JAMA 2020).
    /// - Exercise: 150–300 min/week moderate (~30–45 min/day) (WHO/AHA).
    /// - Sleep: 7–9 hours/night optimal (Jike et al., Sleep Med Rev 2018).
    /// - Resting HR: ≤60 bpm is a healthy target for adults (population references).
    /// - HRV: 50 ms is a reasonable adult target; ideally age-adjusted.
    /// - Active energy: ~500 kcal/day is a widely used daily goal (fitness guidance).
    /// - VO2 Max: 45 ml/kg/min is a strong fitness target for adults.
    /// - Oxygen saturation: 98–100% typical; 99–100% target.
    func targetValue(for period: ImpactDataPoint.PeriodType) -> Double? {
        switch self {
        // Cumulative metrics: our charts use daily totals (day/month) or monthly average daily value (year)
        // so we keep a per-day target consistent across periods.
        case .steps:
            // Day: 10,000/day; Month: 10,000 avg/day; Year: 10,000 avg/day
            return 10_000
        case .exerciseMinutes:
            // Day: 30 min/day; Month: 30 avg/day; Year: 30 avg/day (≈ 210 min/week)
            return 30
        case .activeEnergyBurned:
            // Day: 500 kcal/day; Month/Year: 500 avg/day
            return 500
            
        // Recovery / status metrics: targets are per-day averages across periods
        case .sleepHours:
            // Day: 8 h; Month/Year: 8 h average
            return 8
        case .restingHeartRate:
            // Lower is better; 60 bpm target across periods
            return 60
        case .heartRateVariability:
            // Higher is better; 50 ms target across periods (consider age-adjustment elsewhere)
            return 50
        case .vo2Max:
            // Higher is better; 45 ml/kg/min target
            return 45
        case .oxygenSaturation:
            // Higher is better; 99–100% target, use 99 as practical target
            return 99
        
        // Body mass depends on height/gender; leave nil here (compute elsewhere using UserProfile if available)
        case .bodyMass:
            return nil
            
        // Questionnaire/lifestyle metrics (1–10 scale): targets are period-invariant
        case .nutritionQuality:
            return 8
        case .smokingStatus:
            return 10
        case .alcoholConsumption:
            return 10
        case .socialConnectionsQuality:
            return 8
        case .stressLevel:
            return 2
        case .bloodPressure:
            // Systolic target; diastolic not represented here
            return 110
        }
    }
    
    /// Period-aware baseline fallback (used when a target is not defined, e.g., bodyMass)
    func baselineValue(for period: ImpactDataPoint.PeriodType) -> Double {
        // For our charts, values are daily totals or daily averages even in longer periods,
        // so baseline per-day values are appropriate across periods.
        return baselineValue
    }
    
    /// CRITICAL FIX: Determines if this metric type represents cumulative data
    var isCumulative: Bool {
        switch self {
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            return true
        default:
            return false
        }
    }
    
    /// Returns whether this metric type should prioritize sample queries over statistics
    var preferSampleQuery: Bool {
        switch self {
        case .bodyMass, .oxygenSaturation, .vo2Max:
            // These metrics should prioritize most recent reading
            return true
        default:
            return false
        }
    }
    
    /// Returns the appropriate time interval to look back for historic data
    var recommendedTimeInterval: DateComponents {
        switch self {
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            // Activity metrics - last day is most relevant
            return DateComponents(day: 1)
        case .sleepHours:
            // Sleep data needs a week for proper averaging
            return DateComponents(day: 7)
        case .restingHeartRate, .heartRateVariability, .vo2Max:
            // Cardiovascular metrics - last week
            return DateComponents(day: 7)
        case .bodyMass:
            // Body mass doesn't change quickly - 30 days
            return DateComponents(day: 30)
        case .oxygenSaturation:
            // Oxygen saturation - recent readings most relevant
            return DateComponents(day: 2)
        default:
            // Default fallback
            return DateComponents(day: 14)
        }
    }
    
    /// Returns the sample limit to use when fetching this metric type
    var recommendedSampleLimit: Int {
        switch self {
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            return 24 // One per hour for a day
        case .restingHeartRate:
            return 7 // One per day for a week
        case .heartRateVariability:
            return 20 // Multiple readings for averaging
        case .bodyMass, .vo2Max:
            return 1 // Just the most recent
        case .oxygenSaturation:
            return 5 // A few recent readings
        default:
            return 10 // Default reasonable limit
        }
    }
}

/// Functional grouping of metrics by what they do for your health
enum MetricFunctionalGroup: String, CaseIterable {
    case energySources = "Energy Sources"
    case recoveryIndicators = "Recovery Indicators" 
    case performanceMetrics = "Performance Metrics"
    case lifestyleFactors = "Lifestyle Factors"
    case healthRisks = "Health Risks"
    
    /// Subtle description of what this group does
    var description: String {
        switch self {
        case .energySources: return "Fuel your daily power"
        case .recoveryIndicators: return "Track your restoration"
        case .performanceMetrics: return "Measure your potential"
        case .lifestyleFactors: return "Shape your wellbeing"
        case .healthRisks: return "Protect your future"
        }
    }
    
    /// Icon for the functional group
    var iconName: String {
        switch self {
        case .energySources: return "bolt.fill"
        case .recoveryIndicators: return "moon.fill"
        case .performanceMetrics: return "speedometer"
        case .lifestyleFactors: return "heart.fill"
        case .healthRisks: return "shield.fill"
        }
    }
    
    /// Battery metaphor for the group
    var batteryMetaphor: String {
        switch self {
        case .energySources: return "charging your battery"
        case .recoveryIndicators: return "showing charge level"
        case .performanceMetrics: return "measuring max capacity"
        case .lifestyleFactors: return "affecting efficiency"
        case .healthRisks: return "draining your power"
        }
    }
}
