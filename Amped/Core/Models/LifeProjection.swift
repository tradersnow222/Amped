import Foundation

/// Model for total life expectancy projection
struct LifeProjection: Identifiable, Codable, Equatable {
    let id: UUID
    let calculationDate: Date
    let baselineLifeExpectancyYears: Double
    let adjustedLifeExpectancyYears: Double
    let confidencePercentage: Double
    let confidenceIntervalYears: Double
    
    /// Impact factor for UI compatibility
    struct ImpactFactor: Identifiable, Codable, Equatable {
        let id: UUID
        let factor: String
        let impact: Double
        
        init(id: UUID = UUID(), factor: String, impact: Double) {
            self.id = id
            self.factor = factor
            self.impact = impact
        }
    }
    
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
    
    // MARK: - Computed Properties for DashboardView
    
    /// Formatted string for the main value display (e.g., "~52")
    /// - Parameter currentUserAge: The current age of the user.
    /// - Returns: A formatted string representing estimated remaining years as a number.
    func formattedProjectionValue(currentUserAge: Double) -> String {
        let remainingYears = max(0, adjustedLifeExpectancyYears - currentUserAge)
        // Format for better readability, just the number with tilde
        return String(format: "~%.0f", remainingYears)
    }
    
    /// Formatted string for the text inside the battery (e.g., "Lifespan remaining: 52 years")
    /// - Parameter currentUserAge: The current age of the user.
    /// - Returns: A formatted string representing the remaining lifespan description.
    func formattedRemainingLifespanText(currentUserAge: Double) -> String {
         let remainingYears = max(0, adjustedLifeExpectancyYears - currentUserAge)
         return String(format: "Lifespan remaining: %.0f years", remainingYears)
     }

    /// Total projected age - No longer used directly in the main battery view
    var formattedTotalProjectedAge: String {
        return String(format: "Projected age: %.0f", adjustedLifeExpectancyYears)
    }
    
    /// Projection percentage for the battery charge level (0.0 to 1.0)
    /// - Parameter currentUserAge: The current age of the user.
    /// - Returns: A CGFloat between 0.0 and 1.0 representing the fraction of life remaining.
    func projectionPercentage(currentUserAge: Double) -> CGFloat {
        // Represents the fraction of life remaining based on adjusted expectancy
        guard adjustedLifeExpectancyYears > 0, currentUserAge < adjustedLifeExpectancyYears else { return 0.0 }
        let percentage = (adjustedLifeExpectancyYears - currentUserAge) / adjustedLifeExpectancyYears
        return max(0.0, min(1.0, CGFloat(percentage))) // Clamp between 0 and 1
    }
    
    // MARK: - DashboardViewModel Compatibility Properties
    
    /// Baseline life expectancy (alias for baselineLifeExpectancyYears)
    var baselineLifeExpectancy: Double {
        baselineLifeExpectancyYears
    }
    
    /// Projected life expectancy (alias for adjustedLifeExpectancyYears)
    var projectedLifeExpectancy: Double {
        adjustedLifeExpectancyYears
    }
    
    /// Current age in years (calculated from current date and baseline)
    var currentAge: Double {
        let calendar = Calendar.current
        let currentYear = Double(calendar.component(.year, from: Date()))
        // Estimate birth year from baseline expectancy and current year
        // This is approximate since we don't have the actual birth year here
        let estimatedBirthYear = currentYear - (baselineLifeExpectancyYears * 0.5) // Rough estimation
        return currentYear - estimatedBirthYear
    }
    
    /// Health adjustment in years (alias for netImpactYears)
    var healthAdjustment: Double {
        netImpactYears
    }
    
    /// Years remaining based on adjusted life expectancy
    var yearsRemaining: Double {
        let currentAge = self.currentAge
        return max(adjustedLifeExpectancyYears - currentAge, 0)
    }
    
    /// Percentage of life remaining
    var percentageRemaining: Double {
        let remaining = yearsRemaining
        return (remaining / adjustedLifeExpectancyYears) * 100.0
    }
    
    static func == (lhs: LifeProjection, rhs: LifeProjection) -> Bool {
        lhs.id == rhs.id &&
        lhs.calculationDate == rhs.calculationDate &&
        lhs.baselineLifeExpectancyYears == rhs.baselineLifeExpectancyYears &&
        lhs.adjustedLifeExpectancyYears == rhs.adjustedLifeExpectancyYears
    }
    
    // MARK: - UI Compatibility Properties
    
    /// UI alias for adjustedLifeExpectancyYears
    var projectedTotalYears: Double {
        return adjustedLifeExpectancyYears
    }
    
    /// UI alias for confidencePercentage
    var confidenceLevel: Double {
        return confidencePercentage
    }
    
    /// Mock impact factors for UI compatibility
    var impactFactors: [ImpactFactor] {
        return [
            ImpactFactor(factor: "Exercise", impact: 3.2),
            ImpactFactor(factor: "Sleep", impact: 1.8),
            ImpactFactor(factor: "Nutrition", impact: 2.1),
            ImpactFactor(factor: "Stress", impact: -0.5)
        ]
    }
    
    /// UI alias for calculationDate
    var lastUpdated: Date {
        return calculationDate
    }
} 