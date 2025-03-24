import Foundation

/// Represents a historical tracking point for life impact
struct ImpactDataPoint: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let periodType: PeriodType
    let totalImpactMinutes: Double
    let metricImpacts: [HealthMetricType: Double]
    
    /// Standard initialization
    init(
        id: UUID = UUID(),
        date: Date,
        periodType: PeriodType,
        totalImpactMinutes: Double,
        metricImpacts: [HealthMetricType: Double]
    ) {
        self.id = id
        self.date = date
        self.periodType = periodType
        self.totalImpactMinutes = totalImpactMinutes
        self.metricImpacts = metricImpacts
    }
    
    /// Returns the impact data formatted based on time period
    var formattedImpact: String {
        // For very small impacts (< 1 hour), use minutes
        if abs(totalImpactMinutes) < 60 {
            let minutes = Int(abs(totalImpactMinutes))
            return "\(totalImpactMinutes >= 0 ? "+" : "-")\(minutes) min"
        }
        
        // For medium impacts (< 1 day), use hours
        let impactHours = totalImpactMinutes / 60.0
        if abs(impactHours) < 24 {
            return String(format: "\(impactHours >= 0 ? "+" : "-")%.1f hrs", abs(impactHours))
        }
        
        // For large impacts, use days
        let impactDays = impactHours / 24.0
        return String(format: "\(impactDays >= 0 ? "+" : "-")%.1f days", abs(impactDays))
    }
    
    /// Returns the top contributing metric type (by absolute value)
    var topContributingMetric: HealthMetricType? {
        metricImpacts.max { abs($0.value) < abs($1.value) }?.key
    }
    
    /// Time period type for impact calculations
    enum PeriodType: String, Codable, CaseIterable {
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
        
        var calendarComponent: Calendar.Component {
            switch self {
            case .day: return .day
            case .month: return .month
            case .year: return .year
            }
        }
    }
    
    static func == (lhs: ImpactDataPoint, rhs: ImpactDataPoint) -> Bool {
        lhs.id == rhs.id &&
        lhs.date == rhs.date &&
        lhs.periodType == rhs.periodType &&
        lhs.totalImpactMinutes == rhs.totalImpactMinutes
    }
} 