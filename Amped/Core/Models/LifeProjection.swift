import Foundation

/// Model for total life expectancy projection
struct LifeProjection: Identifiable, Codable, Equatable {
    let id: UUID
    let calculationDate: Date
    let baselineLifeExpectancyYears: Double
    let adjustedLifeExpectancyYears: Double
    let confidencePercentage: Double
    let confidenceIntervalYears: Double
    
    /// Standard initialization
    init(
        id: UUID = UUID(),
        calculationDate: Date = Date(),
        baselineLifeExpectancyYears: Double,
        adjustedLifeExpectancyYears: Double,
        confidencePercentage: Double = 0.95,
        confidenceIntervalYears: Double = 2.0
    ) {
        self.id = id
        self.calculationDate = calculationDate
        self.baselineLifeExpectancyYears = baselineLifeExpectancyYears
        self.adjustedLifeExpectancyYears = adjustedLifeExpectancyYears
        self.confidencePercentage = confidencePercentage
        self.confidenceIntervalYears = confidenceIntervalYears
    }
    
    /// Returns the net impact on life expectancy in years
    var netImpactYears: Double {
        adjustedLifeExpectancyYears - baselineLifeExpectancyYears
    }
    
    /// Returns the net impact on life expectancy in days
    var netImpactDays: Double {
        netImpactYears * 365.25
    }
    
    /// Returns the lower bound of the confidence interval
    var lowerBoundYears: Double {
        adjustedLifeExpectancyYears - confidenceIntervalYears / 2.0
    }
    
    /// Returns the upper bound of the confidence interval
    var upperBoundYears: Double {
        adjustedLifeExpectancyYears + confidenceIntervalYears / 2.0
    }
    
    /// Returns the percentage change from baseline
    var percentageChange: Double {
        (adjustedLifeExpectancyYears / baselineLifeExpectancyYears - 1.0) * 100.0
    }
    
    /// Returns the remaining percentage of life
    var remainingPercentage: Double {
        // Calculate age from baseline expectancy and adjusted expectancy
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: Date())
        let age = Double(ageComponents.year ?? 0)
        
        // Calculate remaining percentage
        return (adjustedLifeExpectancyYears - age) / adjustedLifeExpectancyYears * 100.0
    }
    
    /// Returns the formatted impact on life expectancy
    var formattedNetImpact: String {
        if abs(netImpactYears) < 1.0 {
            // If less than a year, show in days
            return String(format: "\(netImpactYears >= 0 ? "+" : "")%.0f days", netImpactDays)
        } else {
            // Otherwise show in years
            return String(format: "\(netImpactYears >= 0 ? "+" : "")%.1f years", netImpactYears)
        }
    }
    
    /// Returns a human-readable interpretation of the projection
    var interpretation: String {
        if netImpactYears > 5.0 {
            return "Significantly extending life expectancy"
        } else if netImpactYears > 2.0 {
            return "Moderately extending life expectancy"
        } else if netImpactYears > 0.5 {
            return "Slightly extending life expectancy"
        } else if netImpactYears > -0.5 {
            return "Maintaining baseline life expectancy"
        } else if netImpactYears > -2.0 {
            return "Slightly reducing life expectancy"
        } else if netImpactYears > -5.0 {
            return "Moderately reducing life expectancy"
        } else {
            return "Significantly reducing life expectancy"
        }
    }
    
    static func == (lhs: LifeProjection, rhs: LifeProjection) -> Bool {
        lhs.id == rhs.id &&
        lhs.calculationDate == rhs.calculationDate &&
        lhs.baselineLifeExpectancyYears == rhs.baselineLifeExpectancyYears &&
        lhs.adjustedLifeExpectancyYears == rhs.adjustedLifeExpectancyYears
    }
} 