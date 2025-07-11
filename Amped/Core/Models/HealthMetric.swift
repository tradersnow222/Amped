import Foundation
import HealthKit

/// Power level for battery visualization
enum PowerLevel: String, CaseIterable {
    case full
    case high
    case medium
    case low
    case critical
    
    /// Color name for this power level
    var color: String {
        switch self {
        case .full: return "ampedGreen"
        case .high: return "ampedGreen"
        case .medium: return "ampedYellow"
        case .low: return "ampedRed"
        case .critical: return "ampedRed"
        }
    }
    
    /// Fill percentage for battery visualization
    var fillPercent: Double {
        switch self {
        case .full: return 1.0
        case .high: return 0.75
        case .medium: return 0.5
        case .low: return 0.25
        case .critical: return 0.1
        }
    }
}

/// Represents a single health metric with its value and metadata
struct HealthMetric: Identifiable, Equatable {
    /// Unique identifier for the metric
    let id: String
    
    /// The type of health metric
    let type: HealthMetricType
    
    /// The numeric value of the health metric
    let value: Double
    
    /// The date when this metric was recorded
    let date: Date
    
    /// The source of this health metric data
    let source: HealthMetricSource
    
    /// The impact details for this metric (optional)
    var impactDetails: MetricImpactDetail?
    
    /// Get a formatted string for the value
    var formattedValue: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 1
        
        // Access the settings manager to check metric system preference
        // Default to imperial for US/UK locales
        let locale = Locale.current
        let regionIdentifier = locale.region?.identifier ?? ""
        let defaultToMetric = !["US", "GB", "MM", "LR"].contains(regionIdentifier)
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem", defaultValue: defaultToMetric)
        
        switch type {
        case .steps:
            return "\(Int(value))"
        case .heartRateVariability, .restingHeartRate:
            return numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
        case .sleepHours:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        case .exerciseMinutes:
            return "\(Int(value))"
        case .bodyMass:
            // Value is stored in kg internally, convert if user wants imperial
            let displayValue = useMetric ? value : value * 2.20462 // Convert kg to lbs
            return "\(Int(displayValue))"
        case .activeEnergyBurned:
            return "\(Int(value))"
        case .vo2Max:
            return numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
        case .oxygenSaturation:
            return "\(Int(value))"
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            // Manual metrics use a 1-10 scale with context labels
            let rating = Int(value)
            let contextLabel = getContextLabel(for: rating)
            return "\(rating)/10 (\(contextLabel))"
        }
    }
    
    /// Get the unit string for the metric
    var unitString: String {
        // Access the settings manager to check metric system preference
        // Default to imperial for US/UK locales
        let locale = Locale.current
        let regionIdentifier = locale.region?.identifier ?? ""
        let defaultToMetric = !["US", "GB", "MM", "LR"].contains(regionIdentifier)
        let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem", defaultValue: defaultToMetric)
        
        switch type {
        case .steps:
            return "steps"
        case .exerciseMinutes:
            return "min"
        case .sleepHours:
            return "" // Unit already included in formattedValue (e.g., "6h 41m")
        case .restingHeartRate:
            return "bpm"
        case .heartRateVariability:
            return "ms"
        case .bodyMass:
            return useMetric ? "kg" : "lbs"
        case .activeEnergyBurned:
            return "kcal"
        case .vo2Max:
            return "ml/kg/min"
        case .oxygenSaturation:
            return "%"
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return ""
        }
    }
    
    /// Calculate the percent difference from baseline value
    var percentFromBaseline: Double {
        let baseline = type.baselineValue
        guard baseline > 0 else { return 0 }
        
        let percent = ((value - baseline) / baseline) * 100
        
        // For metrics where lower is better, invert the percentage
        return type.isHigherBetter ? percent : -percent
    }
    
    /// Returns whether this value is considered healthy
    var isHealthy: Bool {
        if let target = type.targetValue {
            if type.isHigherBetter {
                return value >= target
            } else {
                return value <= target
            }
        }
        
        // If no target value, compare to baseline
        if type.isHigherBetter {
            return value >= type.baselineValue
        } else {
            return value <= type.baselineValue
        }
    }
    
    /// Returns the power level for this metric based on its impact
    var powerLevel: PowerLevel {
        if let impact = impactDetails?.lifespanImpactMinutes {
            if impact > 120 {
                return .full
            } else if impact > 60 {
                return .high
            } else if impact > 0 {
                return .medium
            } else if impact > -60 {
                return .low
            } else {
                return .critical
            }
        }
        
        // Default to medium if no impact data available
        return .medium
    }
    
    /// Create a simple metric with a specified value (for testing and previews)
    static func sample(type: HealthMetricType, value: Double) -> HealthMetric {
        HealthMetric(
            id: UUID().uuidString,
            type: type,
            value: value,
            date: Date(),
            source: .healthKit
        )
    }
    
    /// Get context label for questionnaire metric ratings (1-10 scale)
    private func getContextLabel(for rating: Int) -> String {
        switch rating {
        case 9...10:
            return "Excellent"
        case 7...8:
            return "Above average"
        case 4...6:
            return "Average"
        case 2...3:
            return "Below Average"
        case 1:
            return "Very poor [ATTENTION NEEDED!]"
        default:
            return "Average" // Fallback for any edge cases
        }
    }
}

/// Source of the health metric data
enum HealthMetricSource: String, Codable {
    case healthKit
    case userInput
    case calculated
} 