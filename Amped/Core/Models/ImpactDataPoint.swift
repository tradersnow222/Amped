import Foundation

/// Represents a calculated life impact data point with scientific evidence backing
struct ImpactDataPoint: Identifiable, Codable {
    let id: String
    let date: Date
    let periodType: PeriodType
    let totalImpactMinutes: Double
    let metricImpacts: [HealthMetricType: Double]
    let evidenceQualityScore: Double // Average evidence quality (0-1)
    
    enum PeriodType: String, CaseIterable, Codable {
        case day = "Day"
        case month = "Month"
        case year = "Year"
        
        var displayName: String {
            return self.rawValue
        }
        
        /// Number of days represented by this period
        var daysInPeriod: Double {
            switch self {
            case .day: return 1.0
            case .month: return 30.0
            case .year: return 365.0
            }
        }
    }
    
    init(
        id: String = UUID().uuidString,
        date: Date,
        periodType: PeriodType,
        totalImpactMinutes: Double,
        metricImpacts: [HealthMetricType: Double],
        evidenceQualityScore: Double = 0.8
    ) {
        self.id = id
        self.date = date
        self.periodType = periodType
        self.totalImpactMinutes = totalImpactMinutes
        self.metricImpacts = metricImpacts
        self.evidenceQualityScore = evidenceQualityScore
    }
    
    /// Get daily impact (useful for displaying underlying daily rate)
    var dailyImpactMinutes: Double {
        return totalImpactMinutes / periodType.daysInPeriod
    }
    
    /// Format the lifespan impact for display with appropriate units
    var formattedImpact: String {
        return Self.formatLifespanImpact(minutes: totalImpactMinutes)
    }
    
    /// Format the daily equivalent impact
    var formattedDailyImpact: String {
        return Self.formatLifespanImpact(minutes: dailyImpactMinutes)
    }
    
    /// Get evidence quality as percentage string
    var evidenceQualityPercentage: String {
        return String(format: "%.0f", evidenceQualityScore * 100) + "%"
    }
    
    /// Get evidence quality category
    var evidenceQualityCategory: EvidenceCategory {
        if evidenceQualityScore >= 0.8 {
            return .high
        } else if evidenceQualityScore >= 0.6 {
            return .moderate
        } else if evidenceQualityScore >= 0.4 {
            return .limited
        } else {
            return .weak
        }
    }
    
    enum EvidenceCategory: String, CaseIterable {
        case high = "High"
        case moderate = "Moderate"
        case limited = "Limited"
        case weak = "Weak"
        
        var color: String {
            switch self {
            case .high: return "ampedGreen"
            case .moderate: return "ampedYellow"
            case .limited: return "ampedYellow"
            case .weak: return "ampedRed"
            }
        }
        
        var description: String {
            switch self {
            case .high: return "Strong scientific evidence"
            case .moderate: return "Good scientific evidence"
            case .limited: return "Limited scientific evidence"
            case .weak: return "Weak scientific evidence"
            }
        }
    }
    
    /// Static method to format lifespan impact in appropriate units
    static func formatLifespanImpact(minutes: Double) -> String {
        let absMinutes = abs(minutes)
        let direction = minutes >= 0 ? "gained" : "lost"
        
        // Define time conversions
        let minutesInHour = 60.0
        let minutesInDay = 1440.0 // 60 * 24
        let minutesInWeek = 10080.0 // 60 * 24 * 7
        let minutesInMonth = 43200.0 // 60 * 24 * 30 (approximate)
        let minutesInYear = 525600.0 // 60 * 24 * 365
        
        // Years
        if absMinutes >= minutesInYear {
            let years = absMinutes / minutesInYear
            if years >= 1.0 {
                let unit = years == 1.0 ? "year" : "years"
                let valueString = years.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", years) : String(format: "%.1f", years)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f year %@", years, direction)
            }
        }
        
        // Months
        if absMinutes >= minutesInMonth {
            let months = absMinutes / minutesInMonth
            if months >= 1.0 {
                let unit = months == 1.0 ? "month" : "months"
                let valueString = months.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", months) : String(format: "%.1f", months)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f month %@", months, direction)
            }
        }
        
        // Weeks
        if absMinutes >= minutesInWeek {
            let weeks = absMinutes / minutesInWeek
            if weeks >= 1.0 {
                let unit = weeks == 1.0 ? "week" : "weeks"
                let valueString = weeks.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", weeks) : String(format: "%.1f", weeks)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f week %@", weeks, direction)
            }
        }
        
        // Days
        if absMinutes >= minutesInDay {
            let days = absMinutes / minutesInDay
            if days >= 1.0 {
                let unit = days == 1.0 ? "day" : "days"
                let valueString = days.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", days) : String(format: "%.1f", days)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f day %@", days, direction)
            }
        }
        
        // Hours
        if absMinutes >= minutesInHour {
            let hours = absMinutes / minutesInHour
            if hours >= 1.0 {
                let unit = hours == 1.0 ? "hour" : "hours"
                let valueString = hours.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", hours) : String(format: "%.1f", hours)
                return "\(valueString) \(unit) \(direction)"
            } else {
                return String(format: "%.1f hour %@", hours, direction)
            }
        }
        
        // Minutes
        let displayMinutes = Int(absMinutes)
        if displayMinutes == 0 {
            return "Minimal impact"
        }
        return "\(displayMinutes) minute\(displayMinutes == 1 ? "" : "s") \(direction)"
    }
    
    /// Battery level calculation (0-100%) based on impact
    var batteryLevel: Double {
        // Convert impact to battery level
        // Positive impact = higher battery level
        // Negative impact = lower battery level
        // Base level is 50% for neutral impact
        
        let baseLevel = 50.0
        let maxImpactForFullEffect = 120.0 // 2 hours daily impact = full battery effect
        
        let normalizedImpact = dailyImpactMinutes / maxImpactForFullEffect
        let batteryAdjustment = normalizedImpact * 50.0 // ±50% range
        
        let level = baseLevel + batteryAdjustment
        return max(0, min(100, level))
    }
    
    /// Power level for UI visualization
    var powerLevel: PowerLevel {
        let level = batteryLevel
        
        if level >= 80 {
            return .full
        } else if level >= 60 {
            return .high
        } else if level >= 40 {
            return .medium
        } else if level >= 20 {
            return .low
        } else {
            return .critical
        }
    }
    
    /// Get the top positive and negative impacts for display
    func getTopImpacts(count: Int = 3) -> (positive: [(HealthMetricType, Double)], negative: [(HealthMetricType, Double)]) {
        let sortedImpacts = metricImpacts.sorted { $0.value > $1.value }
        
        let positive = Array(sortedImpacts.filter { $0.value > 0 }.prefix(count))
        let negative = Array(sortedImpacts.filter { $0.value < 0 }.suffix(count).reversed())
        
        return (positive: positive, negative: negative)
    }
    
    /// Check if this impact represents improvement over a baseline
    func isImprovement(comparedTo baseline: ImpactDataPoint) -> Bool {
        return totalImpactMinutes > baseline.totalImpactMinutes
    }
    
    /// Get percentage change compared to baseline
    func percentageChange(comparedTo baseline: ImpactDataPoint) -> Double {
        guard baseline.totalImpactMinutes != 0 else { return 0 }
        return ((totalImpactMinutes - baseline.totalImpactMinutes) / abs(baseline.totalImpactMinutes)) * 100
    }
    
    /// Summary for display in UI
    var displaySummary: String {
        let impactString = formattedImpact
        let evidenceString = evidenceQualityCategory.description
        
        return "\(impactString) • \(evidenceString)"
    }
} 