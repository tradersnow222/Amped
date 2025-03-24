import Foundation
import HealthKit
import SwiftUI

/// Enumeration of supported health metric types for the Amped app
/// Each case represents a health metric that can be tracked and analyzed
enum HealthMetricType: String, CaseIterable, Identifiable, Codable {
    // HealthKit metrics
    case steps
    case activeEnergyBurned
    case exerciseMinutes
    case restingHeartRate
    case heartRateVariability
    case sleepHours
    case vo2Max
    case oxygenSaturation
    
    // Manual metrics from questionnaire
    case nutritionQuality
    case stressLevel
    
    var id: String { rawValue }
    
    /// Returns the localized display name for this metric type
    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .activeEnergyBurned: return "Active Energy"
        case .exerciseMinutes: return "Exercise"
        case .restingHeartRate: return "Resting Heart Rate"
        case .heartRateVariability: return "Heart Rate Variability"
        case .sleepHours: return "Sleep"
        case .vo2Max: return "VO₂ Max"
        case .oxygenSaturation: return "Oxygen Saturation"
        case .nutritionQuality: return "Nutrition"
        case .stressLevel: return "Stress Level"
        }
    }
    
    /// Returns the corresponding HealthKit quantity type if available
    var healthKitType: HKQuantityType? {
        switch self {
        case .steps:
            return HKQuantityType(.stepCount)
        case .activeEnergyBurned:
            return HKQuantityType(.activeEnergyBurned)
        case .exerciseMinutes:
            return HKQuantityType(.appleExerciseTime)
        case .restingHeartRate:
            return HKQuantityType(.restingHeartRate)
        case .heartRateVariability:
            return HKQuantityType(.heartRateVariabilitySDNN)
        case .sleepHours:
            return nil // Sleep requires special handling with HKCategoryType
        case .vo2Max:
            return HKQuantityType(.vo2Max)
        case .oxygenSaturation:
            return HKQuantityType(.oxygenSaturation)
        case .nutritionQuality, .stressLevel:
            return nil // These are manual metrics, not from HealthKit
        }
    }
    
    /// Returns the appropriate unit for this metric type
    var unit: HKUnit? {
        switch self {
        case .steps:
            return .count()
        case .activeEnergyBurned:
            return .kilocalorie()
        case .exerciseMinutes:
            return .minute()
        case .restingHeartRate:
            return .count().unitDivided(by: .minute())
        case .heartRateVariability:
            return .secondUnit(with: .milli)
        case .sleepHours:
            return .hour()
        case .vo2Max:
            return HKUnit(from: "ml/kg/min")
        case .oxygenSaturation:
            return HKUnit(from: "%")
        case .nutritionQuality, .stressLevel:
            return nil // These use a custom scale, not HealthKit units
        }
    }
    
    /// Returns whether this metric type is derived from HealthKit
    var isHealthKitMetric: Bool {
        switch self {
        case .nutritionQuality, .stressLevel:
            return false
        default:
            return true
        }
    }
    
    /// Returns the SF Symbol name for this metric type
    var symbolName: String {
        switch self {
        case .steps: return "figure.walk"
        case .activeEnergyBurned: return "flame.fill"
        case .exerciseMinutes: return "figure.run"
        case .restingHeartRate: return "heart.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .sleepHours: return "bed.double.fill"
        case .vo2Max: return "lungs.fill"
        case .oxygenSaturation: return "heart.fill"
        case .nutritionQuality: return "fork.knife"
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
        case .steps: return Color.ampedGreen
        case .activeEnergyBurned: return Color.ampedRed
        case .exerciseMinutes: return Color.ampedGreen
        case .restingHeartRate: return Color.ampedSilver
        case .heartRateVariability: return Color.ampedGreen
        case .sleepHours: return Color.ampedSilver
        case .vo2Max: return Color.ampedGreen
        case .oxygenSaturation: return Color.ampedGreen
        case .nutritionQuality: return Color.ampedGreen
        case .stressLevel: return Color.ampedRed
        }
    }
    
    /// Returns the baseline value for comparisons
    var baselineValue: Double {
        switch self {
        case .steps: return 7500
        case .activeEnergyBurned: return 350
        case .exerciseMinutes: return 20
        case .restingHeartRate: return 70
        case .heartRateVariability: return 35
        case .sleepHours: return 7
        case .vo2Max: return 35
        case .oxygenSaturation: return 95
        case .nutritionQuality: return 5
        case .stressLevel: return 5
        }
    }
    
    /// Indicates whether a higher value is better for this metric
    var isHigherBetter: Bool {
        switch self {
        case .steps, .activeEnergyBurned, .exerciseMinutes, .heartRateVariability, .sleepHours, .vo2Max, .oxygenSaturation, .nutritionQuality:
            return true
        case .restingHeartRate, .stressLevel:
            return false
        }
    }
    
    /// Returns the recommended target value for this metric type
    var targetValue: Double? {
        switch self {
        case .steps: return 10000
        case .activeEnergyBurned: return 600
        case .exerciseMinutes: return 30
        case .restingHeartRate: return 60
        case .heartRateVariability: return 50
        case .sleepHours: return 8
        case .vo2Max: return 40
        case .oxygenSaturation: return 95
        case .nutritionQuality: return 8
        case .stressLevel: return 3
        }
    }
} 