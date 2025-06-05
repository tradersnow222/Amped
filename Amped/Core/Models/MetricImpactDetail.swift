import Foundation

/// Represents the calculated impact details of a health metric
struct MetricImpactDetail: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    /// Unique identifier
    let id: String
    
    /// The type of health metric
    let metricType: HealthMetricType
    
    /// Impact on lifespan in minutes (positive or negative)
    let lifespanImpactMinutes: Double
    
    /// Comparison to baseline
    let comparisonToBaseline: ComparisonResult
    
    /// Scientific reference for the impact calculation (optional)
    let scientificReference: String?
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        metricType: HealthMetricType,
        lifespanImpactMinutes: Double,
        comparisonToBaseline: ComparisonResult,
        scientificReference: String? = nil
    ) {
        self.id = id
        self.metricType = metricType
        self.lifespanImpactMinutes = lifespanImpactMinutes
        self.comparisonToBaseline = comparisonToBaseline
        self.scientificReference = scientificReference
    }
    
    // MARK: - Computed Properties
    
    /// The impact converted to hours (for display purposes)
    var lifespanImpactHours: Double {
        lifespanImpactMinutes / 60.0
    }
    
    /// The impact converted to days (for display purposes)
    var lifespanImpactDays: Double {
        lifespanImpactHours / 24.0
    }
    
    /// A user-friendly description of the impact
    var impactDescription: String {
        let absImpact = abs(lifespanImpactMinutes)
        let direction = lifespanImpactMinutes >= 0 ? "gained" : "lost"
        
        // Define time conversions
        let minutesInHour = 60.0
        let minutesInDay = 1440.0 // 60 * 24
        let minutesInWeek = 10080.0 // 60 * 24 * 7
        let minutesInMonth = 43200.0 // 60 * 24 * 30 (approximate)
        let minutesInYear = 525600.0 // 60 * 24 * 365
        
        // Years
        if absImpact >= minutesInYear {
            let years = absImpact / minutesInYear
            if years >= 2 {
                return String(format: "%.0f years %@", years, direction)
            } else {
                return String(format: "%.1f year %@", years, direction)
            }
        }
        
        // Months
        if absImpact >= minutesInMonth {
            let months = absImpact / minutesInMonth
            if months >= 2 {
                return String(format: "%.0f months %@", months, direction)
            } else {
                return String(format: "%.1f month %@", months, direction)
            }
        }
        
        // Weeks
        if absImpact >= minutesInWeek {
            let weeks = absImpact / minutesInWeek
            if weeks >= 2 {
                return String(format: "%.0f weeks %@", weeks, direction)
            } else {
                return String(format: "%.1f week %@", weeks, direction)
            }
        }
        
        // Days
        if absImpact >= minutesInDay {
            let days = absImpact / minutesInDay
            if days >= 2 {
                return String(format: "%.0f days %@", days, direction)
            } else {
                return String(format: "%.1f day %@", days, direction)
            }
        }
        
        // Hours
        if absImpact >= minutesInHour {
            let hours = absImpact / minutesInHour
            if hours >= 2 {
                return String(format: "%.0f hours %@", hours, direction)
            } else {
                return String(format: "%.1f hour %@", hours, direction)
            }
        }
        
        // Minutes
        let minutes = Int(absImpact)
        return "\(minutes) minute\(minutes == 1 ? "" : "s") \(direction)"
    }
    
    /// Formatted impact for UI display
    var formattedImpact: String {
        impactDescription
    }
    
    // MARK: - Battery Power Level
    
    /// Returns the power level for battery visualization
    var powerLevel: PowerLevel {
        if lifespanImpactMinutes > 120 {
            return .full
        } else if lifespanImpactMinutes > 60 {
            return .high
        } else if lifespanImpactMinutes > -60 {
            return .medium
        } else if lifespanImpactMinutes > -120 {
            return .low
        } else {
            return .critical
        }
    }
}

/// Result of comparing a metric to baseline
enum ComparisonResult: String, Codable {
    case better
    case same
    case worse
}

extension ComparisonResult {
    var symbol: String {
        switch self {
        case .better: return "arrow.up.circle.fill"
        case .same: return "equal.circle.fill"
        case .worse: return "arrow.down.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .better: return "ampedGreen"
        case .same: return "ampedYellow"
        case .worse: return "ampedRed"
        }
    }
    
    var description: String {
        switch self {
        case .better: return "better than recommended"
        case .same: return "at the recommended level"
        case .worse: return "below the recommended level"
        }
    }
}

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