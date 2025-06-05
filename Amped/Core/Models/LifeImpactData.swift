import Foundation

/// Represents aggregated life impact data for dashboard display
struct LifeImpactData: Identifiable, Codable, Equatable {
    let id: UUID
    let calculationDate: Date
    let timePeriod: TimePeriod
    let totalImpact: ImpactValue
    let batteryLevel: Double // 0.0 to 100.0
    let metricContributions: [HealthMetricType: MetricImpactDetail]
    let topPositiveMetric: HealthMetricType?
    let topNegativeMetric: HealthMetricType?
    
    /// Standard initialization
    init(
        id: UUID = UUID(),
        calculationDate: Date = Date(),
        timePeriod: TimePeriod,
        totalImpact: ImpactValue,
        batteryLevel: Double,
        metricContributions: [HealthMetricType: MetricImpactDetail] = [:],
        topPositiveMetric: HealthMetricType? = nil,
        topNegativeMetric: HealthMetricType? = nil
    ) {
        self.id = id
        self.calculationDate = calculationDate
        self.timePeriod = timePeriod
        self.totalImpact = totalImpact
        self.batteryLevel = batteryLevel
        self.metricContributions = metricContributions
        self.topPositiveMetric = topPositiveMetric
        self.topNegativeMetric = topNegativeMetric
    }
    
    /// Create from ImpactDataPoint
    init(from impactDataPoint: ImpactDataPoint) {
        self.id = impactDataPoint.id
        self.calculationDate = impactDataPoint.date
        self.timePeriod = TimePeriod(from: impactDataPoint.periodType)
        
        // Convert total impact to appropriate display values
        let impactMinutes = impactDataPoint.totalImpactMinutes
        let (value, unit, direction) = Self.convertImpactToDisplayValues(impactMinutes)
        
        self.totalImpact = ImpactValue(
            value: value,
            unit: unit,
            direction: direction
        )
        
        // Calculate battery level (50% is neutral, range 0-100%)
        self.batteryLevel = Self.calculateBatteryLevel(from: impactMinutes, for: impactDataPoint.periodType)
        
        // Convert metric impacts to contributions
        var contributions: [HealthMetricType: MetricImpactDetail] = [:]
        for (metricType, impactValue) in impactDataPoint.metricImpacts {
            let impact = MetricImpactDetail(
                metricType: metricType,
                lifespanImpactMinutes: impactValue,
                comparisonToBaseline: impactValue > 0 ? .better : (impactValue < 0 ? .worse : .same)
            )
            contributions[metricType] = impact
        }
        self.metricContributions = contributions
        
        // Determine top contributors
        let sortedContributions = contributions.sorted { abs($0.value.lifespanImpactMinutes) > abs($1.value.lifespanImpactMinutes) }
        self.topPositiveMetric = sortedContributions.first { $0.value.lifespanImpactMinutes > 0 }?.key
        self.topNegativeMetric = sortedContributions.first { $0.value.lifespanImpactMinutes < 0 }?.key
    }
    
    // MARK: - Helper Methods
    
    /// Convert impact minutes to display-friendly values
    private static func convertImpactToDisplayValues(_ impactMinutes: Double) -> (value: Double, unit: ImpactUnit, direction: ImpactDirection) {
        let absImpact = abs(impactMinutes)
        let direction: ImpactDirection = impactMinutes >= 0 ? .positive : .negative
        
        if absImpact < 60 {
            return (absImpact, .minutes, direction)
        } else if absImpact < 1440 {
            return (absImpact / 60.0, .hours, direction)
        } else {
            return (absImpact / 1440.0, .days, direction)
        }
    }
    
    /// Calculate battery level from impact minutes
    private static func calculateBatteryLevel(from impactMinutes: Double, for periodType: ImpactDataPoint.PeriodType) -> Double {
        // Define maximum expected impacts for normalization
        let maxImpact: Double
        switch periodType {
        case .day:
            maxImpact = 240.0 // 4 hours per day
        case .month:
            maxImpact = 240.0 * 30
        case .year:
            maxImpact = 240.0 * 365
        }
        
        // Normalize to -1.0 to 1.0 range
        let normalizedImpact = impactMinutes / maxImpact
        
        // Convert to 0-100% with 50% as neutral
        let batteryLevel = 50.0 + (normalizedImpact * 50.0)
        
        // Clamp to reasonable range
        return min(max(batteryLevel, 5.0), 95.0)
    }
}

/// Represents an impact value with magnitude, unit, and direction
struct ImpactValue: Codable, Equatable {
    let value: Double
    let unit: ImpactUnit
    let direction: ImpactDirection
    
    /// Formatted display string
    var displayString: String {
        let prefix = direction == .positive ? "+" : "-"
        let formattedValue: String
        
        if unit == .minutes && value < 1 {
            formattedValue = "<1"
        } else if value < 10 {
            formattedValue = String(format: "%.1f", value)
        } else {
            formattedValue = String(format: "%.0f", value)
        }
        
        return "\(prefix)\(formattedValue) \(unit.abbreviation)"
    }
}

/// Units for displaying impact values
enum ImpactUnit: String, Codable, CaseIterable {
    case minutes
    case hours
    case days
    case years
    
    var abbreviation: String {
        switch self {
        case .minutes: return "min"
        case .hours: return "hrs"
        case .days: return "days"
        case .years: return "yrs"
        }
    }
    
    var fullName: String {
        switch self {
        case .minutes: return "minutes"
        case .hours: return "hours"
        case .days: return "days"
        case .years: return "years"
        }
    }
}

/// Direction of impact (positive or negative)
enum ImpactDirection: String, Codable {
    case positive
    case negative
    case neutral
    
    var rawValue: String {
        switch self {
        case .positive: return "positive"
        case .negative: return "negative"
        case .neutral: return "neutral"
        }
    }
}

/// Time period options for impact calculations
enum TimePeriod: String, Codable, CaseIterable {
    case day
    case month
    case year
    
    var displayName: String {
        switch self {
        case .day: return "Day"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
    
    /// Create from ImpactDataPoint.PeriodType
    init(from periodType: ImpactDataPoint.PeriodType) {
        switch periodType {
        case .day: self = .day
        case .month: self = .month
        case .year: self = .year
        }
    }
    
    /// Convert to ImpactDataPoint.PeriodType
    var impactDataPointPeriodType: ImpactDataPoint.PeriodType {
        switch self {
        case .day: return .day
        case .month: return .month
        case .year: return .year
        }
    }
} 