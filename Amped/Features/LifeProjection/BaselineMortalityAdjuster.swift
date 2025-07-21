import Foundation
import OSLog

/// Service for adjusting life expectancy calculations based on actuarial mortality data
/// Uses WHO and CDC life tables for accurate baseline mortality risk
final class BaselineMortalityAdjuster {
    private let logger = Logger(subsystem: "Amped", category: "BaselineMortalityAdjuster")
    
    // MARK: - Life Tables (WHO Global Average Data)
    
    /// Age-specific mortality rates per 100,000 (simplified for MVP)
    private struct MortalityTable {
        static let maleRates: [Int: Double] = [
            0: 4.5, 10: 0.15, 20: 0.75, 30: 1.2, 40: 2.0,
            50: 4.5, 60: 11.0, 70: 25.0, 80: 60.0, 90: 150.0
        ]
        
        static let femaleRates: [Int: Double] = [
            0: 3.8, 10: 0.12, 20: 0.35, 30: 0.7, 40: 1.4,
            50: 3.0, 60: 7.0, 70: 17.0, 80: 45.0, 90: 130.0
        ]
    }
    
    /// Life expectancy by age and gender (WHO Global 2023)
    private struct LifeExpectancyTable {
        static let male: [Int: Double] = [
            0: 71.4, 10: 62.1, 20: 52.3, 30: 42.8, 40: 33.5,
            50: 24.7, 60: 16.8, 70: 10.1, 80: 5.5, 90: 3.0
        ]
        
        static let female: [Int: Double] = [
            0: 76.8, 10: 67.4, 20: 57.5, 30: 47.7, 40: 38.1,
            50: 28.8, 60: 20.1, 70: 12.5, 80: 6.8, 90: 3.5
        ]
    }
    
    // MARK: - Public Interface
    
    /// Get baseline life expectancy for user profile
    func getBaselineLifeExpectancy(for profile: UserProfile) -> Double {
        let age = profile.age ?? 30
        let gender = profile.gender ?? .male
        
        // Use interpolation for exact age
        let table = gender == .male ? LifeExpectancyTable.male : LifeExpectancyTable.female
        let baselineYears = interpolateLifeExpectancy(age: age, table: table)
        
        // Add current age to get total life expectancy
        let totalExpectancy = Double(age) + baselineYears
        
        logger.info("📊 Baseline life expectancy for \(age)yo \(gender.rawValue): \(String(format: "%.1f", totalExpectancy)) years")
        
        return totalExpectancy
    }
    
    /// Adjust metric impact based on age-specific mortality risk
    func adjustImpactForMortality(
        dailyImpact: Double,
        age: Int,
        gender: UserProfile.Gender
    ) -> Double {
        // Get age-specific mortality rate
        let mortalityRate = getAnnualMortalityRate(age: age, gender: gender)
        
        // Calculate adjustment factor
        // Higher mortality rate = less time for habits to compound
        let baseRate = 0.001 // 0.1% baseline
        let adjustmentFactor = baseRate / max(mortalityRate, baseRate)
        
        // Apply non-linear adjustment (sqrt for more realistic curve)
        let adjustedImpact = dailyImpact * sqrt(adjustmentFactor)
        
        logger.debug("🔧 Mortality adjustment: \(String(format: "%.1f", dailyImpact)) → \(String(format: "%.1f", adjustedImpact)) min/day")
        
        return adjustedImpact
    }
    
    /// Get annual mortality rate for specific age and gender
    func getAnnualMortalityRate(age: Int, gender: UserProfile.Gender) -> Double {
        let table = gender == .male ? MortalityTable.maleRates : MortalityTable.femaleRates
        
        // Find bracketing ages
        let ages = table.keys.sorted()
        guard let lowerAge = ages.last(where: { $0 <= age }) else {
            return table[ages.first!]! / 100000.0
        }
        guard let upperAge = ages.first(where: { $0 > age }) else {
            return table[ages.last!]! / 100000.0
        }
        
        // Linear interpolation
        let lowerRate = table[lowerAge]!
        let upperRate = table[upperAge]!
        let ageDiff = Int(age - lowerAge)
        let rangeDiff = Int(upperAge - lowerAge)
        let fraction = Double(ageDiff) / Double(rangeDiff)
        let rate = lowerRate + (upperRate - lowerRate) * fraction
        
        return rate / 100000.0 // Convert to probability
    }
    
    /// Calculate confidence interval for life expectancy
    func calculateConfidenceInterval(
        baselineExpectancy: Double,
        age: Int,
        gender: UserProfile.Gender
    ) -> (lower: Double, upper: Double) {
        // Confidence interval widens with age due to uncertainty
        let baseInterval = 2.0 // ±2 years at young age
        let ageMultiplier = 1.0 + (Double(age) / 100.0) // Increases with age
        
        let interval = baseInterval * ageMultiplier
        
        return (
            lower: baselineExpectancy - interval,
            upper: baselineExpectancy + interval
        )
    }
    
    /// Apply decay function for future behavior projections
    func applyBehaviorDecay(
        impact: Double,
        yearsInFuture: Double,
        behaviorType: HealthMetricType
    ) -> Double {
        // Different behaviors have different decay rates
        let decayRate: Double
        switch behaviorType {
        case .exerciseMinutes, .steps:
            decayRate = 0.15 // 15% annual decay (harder to maintain)
        case .smokingStatus, .alcoholConsumption:
            decayRate = 0.05 // 5% annual decay (addiction patterns)
        case .sleepHours, .nutritionQuality:
            decayRate = 0.10 // 10% annual decay
        default:
            decayRate = 0.12 // 12% default decay
        }
        
        // Exponential decay model
        let decayFactor = exp(-decayRate * yearsInFuture)
        return impact * decayFactor
    }
    
    // MARK: - Private Helpers
    
    /// Interpolate life expectancy for exact age
    private func interpolateLifeExpectancy(age: Int, table: [Int: Double]) -> Double {
        let ages = table.keys.sorted()
        
        // Find bracketing ages
        guard let lowerAge = ages.last(where: { $0 <= age }) else {
            return table[ages.first!]!
        }
        guard let upperAge = ages.first(where: { $0 > age }) else {
            return table[ages.last!]!
        }
        
        // If exact age exists, return it
        if let exact = table[age] {
            return exact
        }
        
        // Linear interpolation
        let lowerValue = table[lowerAge]!
        let upperValue = table[upperAge]!
        let fraction = Double(age - lowerAge) / Double(upperAge - lowerAge)
        
        return lowerValue - (lowerValue - upperValue) * fraction
    }
    
    /// Get country-specific adjustment factor (future enhancement)
    func getCountryAdjustment(for country: String?) -> Double {
        // MVP: Return 1.0 (no adjustment)
        // Future: Use country-specific life tables
        return 1.0
    }
}

// MARK: - Extensions
// Gender enum is defined in UserProfile.swift 