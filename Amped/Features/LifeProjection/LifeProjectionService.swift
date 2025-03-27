import Foundation
@preconcurrency import Combine
import OSLog

/// Protocol defining the life projection calculation functionality
protocol LifeProjectionServicing {
    /// Calculate baseline life expectancy based on demographic information
    func calculateBaselineLifeExpectancy(for profile: UserProfile) -> Double
    
    /// Calculate adjusted life expectancy based on health impacts
    func calculateAdjustedLifeExpectancy(baselineYears: Double, cumulativeImpactMinutes: Double) -> Double
    
    /// Generate a full life projection with confidence intervals
    func generateLifeProjection(for profile: UserProfile, cumulativeImpactMinutes: Double) -> LifeProjection
    
    /// Calculate remaining percentage of life based on age and adjusted expectancy
    func calculateRemainingPercentage(age: Int, adjustedLifeExpectancyYears: Double) -> Double
}

/// Service for calculating life expectancy projections
final class LifeProjectionService: LifeProjectionServicing, ObservableObject {
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "LifeProjectionService")
    
    @Published var latestProjection: LifeProjection?
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public methods
    
    func calculateBaselineLifeExpectancy(for profile: UserProfile) -> Double {
        guard let age = profile.age, let gender = profile.gender else {
            logger.warning("Cannot calculate baseline life expectancy: Missing required profile data")
            return 80.0 // Default global average
        }
        
        // Simplified baseline calculation based on WHO data
        // In a real app, this would use more detailed actuarial tables
        var baselineYears: Double
        
        switch gender {
        case .male:
            baselineYears = 76.0
        case .female:
            baselineYears = 81.0
        case .preferNotToSay:
            baselineYears = 78.5
        }
        
        // Adjust for current age (older people have higher life expectancy)
        if age > 60 {
            baselineYears += 1.0
        } else if age > 70 {
            baselineYears += 2.0
        } else if age > 80 {
            baselineYears += 3.0
        }
        
        return baselineYears
    }
    
    func calculateAdjustedLifeExpectancy(baselineYears: Double, cumulativeImpactMinutes: Double) -> Double {
        // Convert impact minutes to years
        let impactYears = cumulativeImpactMinutes / (60.0 * 24.0 * 365.25)
        
        // Apply impact to baseline with a damping factor
        // This prevents unrealistic life extensions or reductions
        let dampingFactor = 0.7
        let adjustedImpactYears = impactYears * dampingFactor
        
        // Calculate adjusted life expectancy
        let adjustedLifeExpectancy = baselineYears + adjustedImpactYears
        
        // Cap the adjustment to prevent unrealistic values
        let minLifeExpectancy = baselineYears * 0.8
        let maxLifeExpectancy = baselineYears * 1.2
        
        return min(max(adjustedLifeExpectancy, minLifeExpectancy), maxLifeExpectancy)
    }
    
    func generateLifeProjection(for profile: UserProfile, cumulativeImpactMinutes: Double) -> LifeProjection {
        // Calculate baseline life expectancy
        let baselineYears = calculateBaselineLifeExpectancy(for: profile)
        
        // Calculate adjusted life expectancy
        let adjustedYears = calculateAdjustedLifeExpectancy(baselineYears: baselineYears, cumulativeImpactMinutes: cumulativeImpactMinutes)
        
        // Calculate confidence interval based on impact magnitude
        let confidenceIntervalYears = calculateConfidenceInterval(baselineYears: baselineYears, adjustedYears: adjustedYears)
        
        // Create projection
        let projection = LifeProjection(
            calculationDate: Date(),
            baselineLifeExpectancyYears: baselineYears,
            adjustedLifeExpectancyYears: adjustedYears,
            confidencePercentage: 0.95,
            confidenceIntervalYears: confidenceIntervalYears
        )
        
        latestProjection = projection
        return projection
    }
    
    func calculateRemainingPercentage(age: Int, adjustedLifeExpectancyYears: Double) -> Double {
        let ageInYears = Double(age)
        let remainingYears = adjustedLifeExpectancyYears - ageInYears
        let remainingPercentage = (remainingYears / adjustedLifeExpectancyYears) * 100.0
        
        return max(min(remainingPercentage, 100.0), 0.0)
    }
    
    // MARK: - Private methods
    
    /// Calculate confidence interval based on impact magnitude
    private func calculateConfidenceInterval(baselineYears: Double, adjustedYears: Double) -> Double {
        // Larger adjustments have more uncertainty
        let adjustment = abs(adjustedYears - baselineYears)
        
        // Base confidence interval is 2 years
        let baseConfidence = 2.0
        
        // Add additional uncertainty for larger adjustments
        let additionalUncertainty = adjustment * 0.5
        
        return baseConfidence + additionalUncertainty
    }
} 