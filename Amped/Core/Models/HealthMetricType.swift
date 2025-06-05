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
    
    var id: String { rawValue }
    
    /// Returns the localized display name for this metric type
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
        case .vo2Max: return "VO2 Max"
        case .oxygenSaturation: return "Oxygen Saturation"
        case .stressLevel: return "Stress Level"
        }
    }
    
    /// Returns the corresponding HealthKit quantity type if available
    var healthKitType: HKQuantityType? {
        switch self {
        case .steps:
            return HKQuantityType(.stepCount)
        case .exerciseMinutes:
            return HKQuantityType(.appleExerciseTime)
        case .restingHeartRate:
            return HKQuantityType(.restingHeartRate)
        case .heartRateVariability:
            return HKQuantityType(.heartRateVariabilitySDNN)
        case .sleepHours:
            return nil // Sleep requires special handling with HKCategoryType
        case .bodyMass:
            return HKQuantityType(.bodyMass)
        case .activeEnergyBurned:
            return HKQuantityType(.activeEnergyBurned)
        case .vo2Max:
            return HKQuantityType(.vo2Max)
        case .oxygenSaturation:
            return HKQuantityType(.oxygenSaturation)
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return nil // These are manual metrics, not from HealthKit
        }
    }
    
    /// Returns the appropriate unit for this metric type
    var unit: HKUnit? {
        switch self {
        case .steps:
            return .count()
        case .exerciseMinutes:
            return .minute()
        case .restingHeartRate:
            return .count().unitDivided(by: .minute())
        case .heartRateVariability:
            return .secondUnit(with: .milli)
        case .sleepHours:
            return .hour()
        case .bodyMass:
            return .gramUnit(with: .kilo)
        case .activeEnergyBurned:
            return .kilocalorie()
        case .vo2Max:
            return HKUnit.literUnit(with: .milli)
                .unitDivided(by: .gramUnit(with: .kilo))
                .unitDivided(by: .minute())
        case .oxygenSaturation:
            return .percent()
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return nil // These use a custom scale, not HealthKit units
        }
    }
    
    /// Returns whether this metric type is derived from HealthKit
    var isHealthKitMetric: Bool {
        switch self {
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
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
        }
    }
    
    /// Returns all metric types that come from HealthKit
    static var healthKitTypes: [HealthMetricType] {
        Self.allCases.filter { $0.isHealthKitMetric }
    }
    
    /// Returns all metric types that are manually entered
    static var manualTypes: [HealthMetricType] {
        Self.allCases.filter { !$0.isHealthKitMetric }
    }
    
    /// Returns the name of the metric (alias for displayName for compatibility)
    var name: String {
        return displayName
    }
    
    /// Returns the color associated with this metric type
    var color: Color {
        switch self {
        case .steps, .exerciseMinutes, .heartRateVariability, .sleepHours, .nutritionQuality, .socialConnectionsQuality, .vo2Max, .oxygenSaturation:
            return Color.ampedGreen
        case .restingHeartRate, .bodyMass, .smokingStatus, .alcoholConsumption, .activeEnergyBurned, .stressLevel:
            return Color.ampedRed
        }
    }
    
    /// Returns the baseline value for comparisons
    var baselineValue: Double {
        switch self {
        case .steps: return 7500
        case .exerciseMinutes: return 20
        case .restingHeartRate: return 70
        case .heartRateVariability: return 35
        case .sleepHours: return 7
        case .bodyMass: return 70 // kg for average adult
        case .nutritionQuality: return 5
        case .smokingStatus: return 0 // 0 = non-smoker
        case .alcoholConsumption: return 1 // 1 drink per day
        case .socialConnectionsQuality: return 5
        case .activeEnergyBurned: return 400 // calories
        case .vo2Max: return 40 // ml/kg/min
        case .oxygenSaturation: return 98 // percent
        case .stressLevel: return 5 // 0-10 scale
        }
    }
    
    /// Indicates whether a higher value is better for this metric
    var isHigherBetter: Bool {
        switch self {
        case .steps, .exerciseMinutes, .heartRateVariability, .sleepHours, .nutritionQuality, .socialConnectionsQuality, .vo2Max, .oxygenSaturation:
            return true
        case .restingHeartRate, .bodyMass, .smokingStatus, .alcoholConsumption, .activeEnergyBurned, .stressLevel:
            return false
        }
    }
    
    /// Returns the recommended target value for this metric type
    var targetValue: Double? {
        switch self {
        case .steps: return 10000
        case .exerciseMinutes: return 30
        case .restingHeartRate: return 60
        case .heartRateVariability: return 50
        case .sleepHours: return 8
        case .bodyMass: return nil // Depends on height, gender, etc.
        case .nutritionQuality: return 8
        case .smokingStatus: return 0
        case .alcoholConsumption: return 0
        case .socialConnectionsQuality: return 8
        case .activeEnergyBurned: return 500
        case .vo2Max: return 45
        case .oxygenSaturation: return 100
        case .stressLevel: return 2
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