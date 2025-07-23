import Foundation
import OSLog

/// Represents a fixed daily target for a health metric
/// Used to provide consistent recommendations throughout the day
struct DailyTarget: Codable, Identifiable, Equatable {
    let id: String
    let metricType: HealthMetricType
    let targetValue: Double
    let originalCurrentValue: Double // Value when target was first calculated
    let originalBenefitMinutes: Double // ORIGINAL life benefit when reaching target (for reference)
    let calculationDate: Date
    let period: ImpactDataPoint.PeriodType
    
    /// Create a new daily target
    init(
        id: String = UUID().uuidString,
        metricType: HealthMetricType,
        targetValue: Double,
        originalCurrentValue: Double,
        benefitMinutes: Double,
        calculationDate: Date = Date(),
        period: ImpactDataPoint.PeriodType
    ) {
        self.id = id
        self.metricType = metricType
        self.targetValue = targetValue
        self.originalCurrentValue = originalCurrentValue
        self.originalBenefitMinutes = benefitMinutes
        self.calculationDate = calculationDate
        self.period = period
    }
    
    /// Check if this target is still valid for today
    var isValidForToday: Bool {
        Calendar.current.isDate(calculationDate, inSameDayAs: Date())
    }
    
    /// Calculate remaining amount needed based on current value
    func remainingAmount(currentValue: Double) -> Double {
        return max(0, targetValue - currentValue)
    }
    
    /// ENHANCED: Calculate current benefit dynamically based on actual current progress
    /// This ensures the benefit text updates in real-time as the user makes progress
    /// with comprehensive edge case handling and detailed logging for debugging
    func calculateCurrentBenefit(currentValue: Double, userProfile: UserProfile) -> Double {
        // Create temporary LifeImpactService to calculate current impact
        let lifeImpactService = LifeImpactService(userProfile: userProfile)
        
        // CRITICAL FIX: Ensure we're using clean, accurate values
        let cleanCurrentValue = max(0, currentValue) // Prevent negative values
        let cleanTargetValue = max(cleanCurrentValue, targetValue) // Target can't be below current
        
        // Calculate current impact with actual current value
        let currentMetric = HealthMetric(
            id: UUID().uuidString,
            type: metricType,
            value: cleanCurrentValue,
            date: Date(),
            source: .healthKit
        )
        let currentImpact = lifeImpactService.calculateImpact(for: currentMetric)
        
        // Calculate target impact to see what we'd achieve
        let targetMetric = HealthMetric(
            id: UUID().uuidString,
            type: metricType,
            value: cleanTargetValue,
            date: Date(),
            source: .healthKit
        )
        let targetImpact = lifeImpactService.calculateImpact(for: targetMetric)
        
        // ENHANCED: Calculate remaining benefit with comprehensive validation
        let remainingBenefit = targetImpact.lifespanImpactMinutes - currentImpact.lifespanImpactMinutes
        let clampedBenefit = max(0, remainingBenefit) // Never show negative remaining benefit
        
        // COMPREHENSIVE LOGGING: Track benefit calculations for debugging
        let logger = OSLog(subsystem: "Amped", category: "DailyTarget")
        os_log("🎯 Benefit Calculation for %{public}@:", log: logger, type: .info, metricType.displayName)
        os_log("   Current Value: %.1f → Impact: %.2f min/day", log: logger, type: .info, cleanCurrentValue, currentImpact.lifespanImpactMinutes)
        os_log("   Target Value: %.1f → Impact: %.2f min/day", log: logger, type: .info, cleanTargetValue, targetImpact.lifespanImpactMinutes)
        os_log("   Remaining Benefit: %.2f minutes", log: logger, type: .info, clampedBenefit)
        
        // EDGE CASE HANDLING: If user has exceeded target, show achievement message
        if cleanCurrentValue >= cleanTargetValue {
            os_log("🎉 User has reached/exceeded target!", log: logger, type: .info)
            return 0.0 // No remaining benefit - they've achieved the goal
        }
        
        // VALIDATION: Ensure benefit makes mathematical sense
        if clampedBenefit < 0.1 {
            os_log("⚠️ Very small benefit calculated (%.3f min), returning 0", log: logger, type: .debug, clampedBenefit)
            return 0.0 // Don't show tiny benefits that confuse users
        }
        
        return clampedBenefit
    }
    
    /// Generate consistent recommendation text using fixed target
    func generateRecommendationText(currentValue: Double, userProfile: UserProfile = UserProfile()) -> String {
        let remaining = remainingAmount(currentValue: currentValue)
        
        // CRITICAL FIX: Calculate benefit dynamically based on current progress
        let currentBenefit = calculateCurrentBenefit(currentValue: currentValue, userProfile: userProfile)
        let benefitText = currentBenefit.formattedAsTime()
        
        switch period {
        case .day:
            return generateDailyRecommendation(remaining: remaining, benefitText: benefitText)
        case .month:
            return generateMonthlyRecommendation(targetValue: targetValue, benefitText: benefitText)
        case .year:
            return generateYearlyRecommendation(targetValue: targetValue, benefitText: benefitText)
        }
    }
    
    private func generateDailyRecommendation(remaining: Double, benefitText: String) -> String {
        if remaining <= 0 {
            return "Great job! You've reached your daily target."
        }
        
        switch metricType {
        case .steps:
            let formattedSteps = Int(remaining).formatted(.number.grouping(.automatic))
            return "Walk \(formattedSteps) more steps today to add \(benefitText) to your life"
        case .exerciseMinutes:
            let exerciseTime = remaining.formattedAsTime()
            return "Exercise \(exerciseTime) more today to add \(benefitText) to your life"
        case .sleepHours:
            let sleepTime = (remaining * 60).formattedAsTime()
            return "Sleep \(sleepTime) more tonight to add \(benefitText) to your life"
        case .activeEnergyBurned:
            return "Burn \(Int(remaining)) more calories today to add \(benefitText) to your life"
        default:
            return "Improve your \(metricType.displayName.lowercased()) to add \(benefitText) to your life"
        }
    }
    
    private func generateMonthlyRecommendation(targetValue: Double, benefitText: String) -> String {
        switch metricType {
        case .steps:
            let formattedSteps = Int(targetValue).formatted(.number.grouping(.automatic))
            return "Walk \(formattedSteps) steps daily this month to add \(benefitText) to your life"
        case .exerciseMinutes:
            let exerciseTime = targetValue.formattedAsTime()
            return "Exercise \(exerciseTime) daily this month to add \(benefitText) to your life"
        case .sleepHours:
            let sleepTime = (targetValue * 60).formattedAsTime()
            return "Sleep \(sleepTime) nightly this month to add \(benefitText) to your life"
        case .activeEnergyBurned:
            return "Burn \(Int(targetValue)) calories daily this month to add \(benefitText) to your life"
        default:
            return "Maintain optimal \(metricType.displayName.lowercased()) daily this month to add \(benefitText) to your life"
        }
    }
    
    private func generateYearlyRecommendation(targetValue: Double, benefitText: String) -> String {
        switch metricType {
        case .steps:
            let formattedSteps = Int(targetValue).formatted(.number.grouping(.automatic))
            return "Walk \(formattedSteps) steps daily this next year to add \(benefitText) to your life"
        case .exerciseMinutes:
            let exerciseTime = targetValue.formattedAsTime()
            return "Exercise \(exerciseTime) daily this next year to add \(benefitText) to your life"
        case .sleepHours:
            let sleepTime = (targetValue * 60).formattedAsTime()
            return "Sleep \(sleepTime) nightly this next year to add \(benefitText) to your life"
        case .activeEnergyBurned:
            return "Burn \(Int(targetValue)) calories daily this next year to add \(benefitText) to your life"
        default:
            return "Maintain optimal \(metricType.displayName.lowercased()) daily this next year to add \(benefitText) to your life"
        }
    }
}

/// Manager for daily targets with caching support
final class DailyTargetManager {
    
    // MARK: - Properties
    
    private let cacheManager = CacheManager.shared
    private let cacheKey = "daily_targets"
    
    // MARK: - Public Methods
    
    /// Get cached daily target for a metric type and period
    func getCachedTarget(for metricType: HealthMetricType, period: ImpactDataPoint.PeriodType) -> DailyTarget? {
        let targets: [DailyTarget] = loadTargets()
        return targets.first { target in
            target.metricType == metricType && 
            target.period == period && 
            target.isValidForToday
        }
    }
    
    /// Save a daily target to cache
    func saveTarget(_ target: DailyTarget) {
        var targets: [DailyTarget] = loadTargets()
        
        // Remove any existing target for the same metric type and period
        targets.removeAll { existingTarget in
            existingTarget.metricType == target.metricType && 
            existingTarget.period == target.period
        }
        
        // Add the new target
        targets.append(target)
        
        // Save to cache
        cacheManager.saveData(targets, forKey: cacheKey, type: .recommendations)
    }
    
    /// Clear all targets (useful for new day or reset)
    func clearTargets() {
        cacheManager.removeData(forKey: cacheKey, type: .recommendations)
    }
    
    /// Clear expired targets
    func clearExpiredTargets() {
        var targets: [DailyTarget] = loadTargets()
        targets.removeAll { !$0.isValidForToday }
        cacheManager.saveData(targets, forKey: cacheKey, type: .recommendations)
    }
    
    /// Clear a specific target for a metric type and period (used by enhanced cache invalidation)
    func clearTarget(for metricType: HealthMetricType, period: ImpactDataPoint.PeriodType) {
        var targets: [DailyTarget] = loadTargets()
        
        // Remove the specific target
        let originalCount = targets.count
        targets.removeAll { target in
            target.metricType == metricType && target.period == period
        }
        
        // Only save if we actually removed something
        if targets.count != originalCount {
            cacheManager.saveData(targets, forKey: cacheKey, type: .recommendations)
            
            // Log the selective clearing for debugging
            let logger = OSLog(subsystem: "Amped", category: "DailyTargetManager")
            os_log("🗑️ Cleared cached target for %{public}@ (%{public}@)", log: logger, type: .info, metricType.displayName, period.rawValue)
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTargets() -> [DailyTarget] {
        return cacheManager.loadData(forKey: cacheKey, type: .recommendations) ?? []
    }
} 