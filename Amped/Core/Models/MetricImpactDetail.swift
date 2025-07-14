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
            if years >= 1.0 {
                let unit = years == 1.0 ? "year" : "years"
                let valueString = years.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", years) : String(format: "%.1f", years)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f year %@", years, direction)
            }
        }
        
        // Months
        if absImpact >= minutesInMonth {
            let months = absImpact / minutesInMonth
            if months >= 1.0 {
                let unit = months == 1.0 ? "month" : "months"
                let valueString = months.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", months) : String(format: "%.1f", months)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f month %@", months, direction)
            }
        }
        
        // Weeks
        if absImpact >= minutesInWeek {
            let weeks = absImpact / minutesInWeek
            if weeks >= 1.0 {
                let unit = weeks == 1.0 ? "week" : "weeks"
                let valueString = weeks.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", weeks) : String(format: "%.1f", weeks)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f week %@", weeks, direction)
            }
        }
        
        // Days
        if absImpact >= minutesInDay {
            let days = absImpact / minutesInDay
            if days >= 1.0 {
                let unit = days == 1.0 ? "day" : "days"
                let valueString = days.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", days) : String(format: "%.1f", days)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f day %@", days, direction)
            }
        }
        
        // Hours
        if absImpact >= minutesInHour {
            let hours = absImpact / minutesInHour
            if hours >= 1.0 {
                let unit = hours == 1.0 ? "hour" : "hours"
                let valueString = hours.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", hours) : String(format: "%.1f", hours)
                return "\(valueString) \(unit) \(direction)"
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
    
    // MARK: - UI Compatibility Methods
    
    /// Get impact for a specific period - returns current impact for compatibility
    func impactForPeriod(_ period: TimePeriod) -> Double {
        // For now, return the current lifespanImpactMinutes regardless of period
        // In future iterations, this could calculate period-specific impacts
        return lifespanImpactMinutes
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

 