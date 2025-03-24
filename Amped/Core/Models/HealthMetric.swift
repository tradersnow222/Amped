import Foundation
import HealthKit

/// Represents a single health metric with its value, impact, and display properties
struct HealthMetric: Identifiable, Equatable {
    let id: UUID
    let type: HealthMetricType
    let value: Double
    let date: Date
    let impactDetail: MetricImpactDetail?
    
    /// Standard initialization
    init(id: UUID = UUID(), type: HealthMetricType, value: Double, date: Date = Date(), impactDetail: MetricImpactDetail? = nil) {
        self.id = id
        self.type = type
        self.value = value
        self.date = date
        self.impactDetail = impactDetail
    }
    
    /// Initialization from HealthKit sample
    init?(from sample: HKQuantitySample, for type: HealthMetricType) {
        guard let unit = type.unit else { return nil }
        
        self.id = UUID()
        self.type = type
        self.value = sample.quantity.doubleValue(for: unit)
        self.date = sample.endDate
        self.impactDetail = nil
    }
    
    /// Returns the formatted value with appropriate unit
    var formattedValue: String {
        switch type {
        case .steps:
            return NumberFormatter.localizedString(from: NSNumber(value: Int(value)), number: .decimal)
        case .activeEnergyBurned:
            return String(format: "%.0f kcal", value)
        case .exerciseMinutes:
            return String(format: "%.0f min", value)
        case .restingHeartRate:
            return String(format: "%.0f bpm", value)
        case .heartRateVariability:
            return String(format: "%.0f ms", value)
        case .sleepHours:
            return String(format: "%.1f hrs", value)
        case .vo2Max:
            return String(format: "%.1f ml/kg/min", value)
        case .oxygenSaturation:
            return String(format: "%.1f%%", value)
        case .nutritionQuality, .stressLevel:
            return String(format: "%.1f", value)
        @unknown default:
            return String(format: "%.1f", value)
        }
    }
    
    /// Returns the power level based on the metric value and impact
    var powerLevel: PowerLevel {
        guard let impact = impactDetail else {
            return .medium
        }
        
        // Default logic based on impact direction
        if impact.lifespanImpactMinutes > 120 {
            return .full
        } else if impact.lifespanImpactMinutes > 60 {
            return .high
        } else if impact.lifespanImpactMinutes > -60 {
            return .medium
        } else if impact.lifespanImpactMinutes > -120 {
            return .low
        } else {
            return .critical
        }
    }
    
    /// Power level enumeration for battery visualization
    enum PowerLevel: String, CaseIterable {
        case full
        case high
        case medium
        case low
        case critical
        
        var color: String {
            switch self {
            case .full: return "ampedGreen"
            case .high: return "ampedGreen"
            case .medium: return "ampedYellow"
            case .low: return "ampedRed"
            case .critical: return "ampedRed"
            }
        }
        
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
    
    static func == (lhs: HealthMetric, rhs: HealthMetric) -> Bool {
        lhs.id == rhs.id && 
        lhs.type == rhs.type && 
        lhs.value == rhs.value && 
        lhs.date == rhs.date
    }
}

// MARK: - Mocks for Development and Testing

extension HealthMetric {
    /// Mock steps data for previews and testing
    static var mockSteps: HealthMetric {
        HealthMetric(
            type: .steps,
            value: 8500,
            impactDetail: MetricImpactDetail(
                metricType: .steps,
                lifespanImpactMinutes: 120,
                comparisonToBaseline: .better
            )
        )
    }
    
    /// Mock sleep data for previews and testing
    static var mockSleep: HealthMetric {
        HealthMetric(
            type: .sleepHours,
            value: 7.5,
            impactDetail: MetricImpactDetail(
                metricType: .sleepHours,
                lifespanImpactMinutes: 60,
                comparisonToBaseline: .same
            )
        )
    }
    
    /// Mock heart rate data for previews and testing
    static var mockHeartRate: HealthMetric {
        HealthMetric(
            type: .restingHeartRate,
            value: 65,
            impactDetail: MetricImpactDetail(
                metricType: .restingHeartRate,
                lifespanImpactMinutes: -30,
                comparisonToBaseline: .worse
            )
        )
    }
} 