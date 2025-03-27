import Foundation
import HealthKit

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
            return "\(Int(value)) min"
        case .bodyMass:
            return "\(Int(value)) kg"
        case .activeEnergyBurned:
            return "\(Int(value)) kcal"
        case .vo2Max:
            return numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
        case .oxygenSaturation:
            return "\(Int(value))%"
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            // Manual metrics use a 1-10 scale
            return "\(Int(value))/10"
        }
    }
    
    /// Get the unit string for the metric
    var unitString: String {
        switch type {
        case .steps:
            return "steps"
        case .exerciseMinutes:
            return "min"
        case .sleepHours:
            return "hours"
        case .restingHeartRate:
            return "bpm"
        case .heartRateVariability:
            return "ms"
        case .bodyMass:
            return "kg"
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
}

/// Source of the health metric data
enum HealthMetricSource: String, Codable {
    case healthKit
    case userInput
    case calculated
}

// MARK: - Mocks for Development and Testing

extension HealthMetric {
    /// Mock steps data for previews and testing
    static var mockSteps: HealthMetric {
        HealthMetric(
            id: UUID().uuidString,
            type: .steps,
            value: 8500,
            date: Date(),
            source: .healthKit
        )
    }
    
    /// Mock sleep data for previews and testing
    static var mockSleep: HealthMetric {
        HealthMetric(
            id: UUID().uuidString,
            type: .sleepHours,
            value: 7.5,
            date: Date(),
            source: .healthKit
        )
    }
    
    /// Mock heart rate data for previews and testing
    static var mockHeartRate: HealthMetric {
        HealthMetric(
            id: UUID().uuidString,
            type: .restingHeartRate,
            value: 65,
            date: Date(),
            source: .healthKit
        )
    }
} 