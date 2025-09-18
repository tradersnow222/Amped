import Foundation
import OSLog

/// Service for calculating life expectancy projections based on research-backed health impacts
/// Uses daily impact rates to project cumulative life expectancy changes over remaining lifespan
class LifeProjectionService {
    private let logger = Logger(subsystem: "Amped", category: "LifeProjectionService")
    private let mortalityAdjuster = BaselineMortalityAdjuster()
    
    /// Calculate life projection from health metrics using daily impact rates
    /// CRITICAL: Uses DAILY impacts, not period-scaled impacts for accurate projections
    func calculateLifeProjection(from metrics: [HealthMetric], userProfile: UserProfile) -> LifeProjection? {
        logger.info("🔮 Calculating life projection from \(metrics.count) health metrics using research-based daily impacts")
        
        // Initialize life impact service for daily calculations
        let lifeImpactService = LifeImpactService(userProfile: userProfile)
        
        // Calculate DAILY impacts (not period-scaled)
        var cumulativeDailyImpactMinutes: Double = 0
        var evidenceQualityScore: Double = 0
        var metricCount = 0
        
        for metric in metrics {
            let impactDetail = lifeImpactService.calculateImpact(for: metric)
            
            // CRITICAL: Use the raw daily impact, not period-scaled impact
            let dailyImpactMinutes = impactDetail.lifespanImpactMinutes
            cumulativeDailyImpactMinutes += dailyImpactMinutes
            
            // Weight evidence quality by reliability
            evidenceQualityScore += impactDetail.reliabilityScore
            metricCount += 1
            
            logger.debug("📊 \(metric.type.displayName): \(String(format: "%.1f", dailyImpactMinutes)) min/day (evidence: \(impactDetail.evidenceStrength.rawValue))")
        }
        
        // Calculate average evidence quality
        evidenceQualityScore = metricCount > 0 ? evidenceQualityScore / Double(metricCount) : 0
        
        logger.info("📊 Cumulative daily impact: \(String(format: "%.2f", cumulativeDailyImpactMinutes)) minutes/day (evidence quality: \(String(format: "%.1f", evidenceQualityScore * 100))%)")
        
        // Generate the life expectancy projection using daily rates
        let projection = generateLifeProjection(
            for: userProfile,
            dailyImpactMinutes: cumulativeDailyImpactMinutes,
            evidenceQuality: evidenceQualityScore
        )
        
        logger.info("🎯 Life projection calculated: \(String(format: "%.1f", projection.adjustedLifeExpectancyYears)) years (baseline: \(String(format: "%.1f", projection.baselineLifeExpectancyYears)))")
        
        return projection
    }
    
    /// Generate life expectancy projection based on daily impact rates
    /// Uses research-based actuarial calculations to project cumulative impact over remaining lifespan
    private func generateLifeProjection(
        for userProfile: UserProfile,
        dailyImpactMinutes: Double,
        evidenceQuality: Double
    ) -> LifeProjection {
        
        // Calculate baseline life expectancy using actuarial tables
        let baselineLifeExpectancy = mortalityAdjuster.getBaselineLifeExpectancy(for: userProfile)
        let userAge = Double(userProfile.age ?? 30) // Default age if not provided
        let remainingYears = max(1.0, baselineLifeExpectancy - userAge)
        
        logger.info("📊 Baseline calculation: \(String(format: "%.1f", baselineLifeExpectancy)) years total, \(String(format: "%.1f", remainingYears)) years remaining")
        
        // Apply behavior decay over time instead of assuming static behavior
        let behaviorDecayRate = 0.02 // 2% decay per year
        let timeHorizon = remainingYears
        let decayFactor = exp(-behaviorDecayRate * timeHorizon / 2.0) // Use half-life for conservative estimate
        
        // FIXED: Convert daily impact minutes directly to total years of impact
        // The daily impact is already in minutes per day, so we multiply by days remaining
        let totalDaysRemaining = timeHorizon * 365.25
        let totalImpactMinutes = dailyImpactMinutes * totalDaysRemaining * decayFactor
        let lifespanImpactYears = totalImpactMinutes / (365.25 * 24 * 60) // Convert total minutes to years
        
        // Apply evidence quality weighting
        let evidenceAdjustedImpact = lifespanImpactYears * evidenceQuality
        
        // Calculate projected lifespan
        let projectedLifespan = baselineLifeExpectancy + evidenceAdjustedImpact
        
        // Ensure reasonable bounds (don't project beyond 120 years or below current age)
        let boundedProjection = max(userAge + 1, min(120.0, projectedLifespan))
        
        logger.info("📊 Life projection details:")
        logger.info("  - Daily impact: \(String(format: "%.1f", dailyImpactMinutes)) minutes/day")
        logger.info("  - Time horizon: \(String(format: "%.1f", timeHorizon)) years")
        logger.info("  - Total impact: \(String(format: "%.2f", lifespanImpactYears)) years")
        logger.info("  - Evidence-adjusted: \(String(format: "%.2f", evidenceAdjustedImpact)) years")
        logger.info("  - Final projection: \(String(format: "%.1f", boundedProjection)) years")
        
        return LifeProjection(
            id: UUID(),
            calculationDate: Date(),
            baselineLifeExpectancyYears: baselineLifeExpectancy,
            adjustedLifeExpectancyYears: boundedProjection,
            currentAge: userAge,
            confidencePercentage: evidenceQuality,
            confidenceIntervalYears: 2.0 // Conservative confidence interval
        )
    }
    
    /// Calculate baseline life expectancy using demographic data and actuarial tables
    /// Based on CDC/WHO life tables adjusted for basic demographics
    private func calculateBaselineLifeExpectancy(userProfile: UserProfile) -> Double {
        let currentAge = Double(userProfile.age ?? 30) // Default age if not provided
        
        // Base life expectancy by gender (US averages)
        var baseLifeExpectancy: Double
        switch userProfile.gender {
        case .male:
            baseLifeExpectancy = 76.3 // US male average
        case .female:
            baseLifeExpectancy = 81.1 // US female average
        case .preferNotToSay:
            baseLifeExpectancy = 78.7 // Combined average
        case .none:
            baseLifeExpectancy = 78.7 // Combined average
        }
        
        // Adjust for current age (remaining life expectancy)
        // People who have already lived to a certain age have higher remaining life expectancy
        if currentAge >= 65 {
            // Older adults who are healthy enough to use this app likely have above-average longevity
            baseLifeExpectancy += 2.0
        } else if currentAge >= 50 {
            // Middle-aged adults using health tracking apps likely health-conscious
            baseLifeExpectancy += 1.0
        } else if currentAge <= 30 {
            // Younger adults have more time to benefit from healthy habits
            baseLifeExpectancy += 0.5
        }
        
        // Conservative bounds
        return max(currentAge + 1, min(95.0, baseLifeExpectancy))
    }
    
    /// Calculate life projection for dashboard display with battery visualization
    func calculateLifeProjectionForDashboard(
        from metrics: [HealthMetric],
        userProfile: UserProfile,
        timePeriod: TimePeriod
    ) -> LifeProjection? {
        
        logger.info("🔄 Calculating life projection for dashboard over \(timePeriod.displayName)")
        
        // Calculate projection using daily impacts (independent of display time period)
        let projection = calculateLifeProjection(from: metrics, userProfile: userProfile)
        
        if let projection = projection {
            let remainingYears = projection.adjustedLifeExpectancyYears - Double(userProfile.age ?? 30)
            logger.info("✅ Dashboard projection: \(String(format: "%.1f", remainingYears)) years remaining with \(String(format: "%.1f", projection.confidencePercentage * 100))% confidence")
        }
        
        return projection
    }
    
    /// Format life projection for battery display
    func formatForBatteryDisplay(projection: LifeProjection, userAge: Int) -> (percentage: Double, displayText: String) {
        // Calculate remaining years based on adjusted life expectancy
        let remainingYears = max(0, projection.adjustedLifeExpectancyYears - Double(userAge))
        
        // Calculate percentage based on remaining years vs. maximum reasonable remaining years
        let maxRemainingYears = 60.0 // Assume maximum 60 years remaining for percentage calculation
        let percentage = min(100.0, max(0.0, (remainingYears / maxRemainingYears) * 100))
        
        let remainingYearsText = String(format: "%.1f", remainingYears)
        let totalProjectedText = String(format: "%.1f", projection.adjustedLifeExpectancyYears)
        
        let displayText = "\(remainingYearsText) years remaining (projected total: \(totalProjectedText) years)"
        
        return (percentage: percentage, displayText: displayText)
    }
    
    /// Get confidence description based on evidence quality
    func getConfidenceDescription(for projection: LifeProjection) -> String {
        let confidencePercentage = Int(projection.confidencePercentage * 100)
        
        if projection.confidencePercentage >= 0.8 {
            return "High confidence (\(confidencePercentage)% evidence quality)"
        } else if projection.confidencePercentage >= 0.6 {
            return "Moderate confidence (\(confidencePercentage)% evidence quality)"
        } else if projection.confidencePercentage >= 0.4 {
            return "Limited confidence (\(confidencePercentage)% evidence quality)"
        } else {
            return "Low confidence (\(confidencePercentage)% evidence quality)"
        }
    }
    
    /// Apply behavior decay to aggregate daily impact
    private func applyBehaviorDecayToAggregate(
        dailyImpact: Double,
        yearsInFuture: Double
    ) -> Double {
        // Average decay rate across all behaviors (conservative estimate)
        let averageDecayRate = 0.10 // 10% annual decay
        
        // Exponential decay model
        let decayFactor = exp(-averageDecayRate * yearsInFuture)
        return dailyImpact * decayFactor
    }
} 