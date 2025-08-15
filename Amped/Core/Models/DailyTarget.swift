import Foundation

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
    let calculationVersion: Int // CRITICAL: Version to force recalculation when algorithm changes
    
    /// Current calculation version - increment when algorithm changes
    static let currentCalculationVersion = 2 // Version 2: Binary search with actual formulas
    
    /// Create a new daily target
    init(
        id: String = UUID().uuidString,
        metricType: HealthMetricType,
        targetValue: Double,
        originalCurrentValue: Double,
        benefitMinutes: Double,
        calculationDate: Date = Date(),
        period: ImpactDataPoint.PeriodType,
        calculationVersion: Int = DailyTarget.currentCalculationVersion
    ) {
        self.id = id
        self.metricType = metricType
        self.targetValue = targetValue
        self.originalCurrentValue = originalCurrentValue
        self.originalBenefitMinutes = benefitMinutes
        self.calculationDate = calculationDate
        self.period = period
        self.calculationVersion = calculationVersion
    }
    
    /// Check if this target is still valid for today
    var isValidForToday: Bool {
        // CRITICAL: Also check calculation version to force recalculation with new algorithm
        return Calendar.current.isDate(calculationDate, inSameDayAs: Date()) && 
               calculationVersion == DailyTarget.currentCalculationVersion
    }
    
    // MARK: - Custom Decoding
    
    /// Custom decoding to handle old cached targets without calculationVersion
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.metricType = try container.decode(HealthMetricType.self, forKey: .metricType)
        self.targetValue = try container.decode(Double.self, forKey: .targetValue)
        self.originalCurrentValue = try container.decode(Double.self, forKey: .originalCurrentValue)
        self.originalBenefitMinutes = try container.decode(Double.self, forKey: .originalBenefitMinutes)
        self.calculationDate = try container.decode(Date.self, forKey: .calculationDate)
        self.period = try container.decode(ImpactDataPoint.PeriodType.self, forKey: .period)
        
        // Default to version 1 for old cached targets (they'll be invalidated)
        self.calculationVersion = try container.decodeIfPresent(Int.self, forKey: .calculationVersion) ?? 1
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case metricType
        case targetValue
        case originalCurrentValue
        case originalBenefitMinutes
        case calculationDate
        case period
        case calculationVersion
    }
    
    /// Calculate remaining amount needed based on current value
    func remainingAmount(currentValue: Double) -> Double {
        return max(0, targetValue - currentValue)
    }
    
    /// CRITICAL FIX: Calculate current benefit dynamically based on actual current progress
    /// This ensures the benefit text updates in real-time as the user makes progress
    func calculateCurrentBenefit(currentValue: Double, userProfile: UserProfile) -> Double {
        // Create temporary LifeImpactService to calculate current impact
        let lifeImpactService = LifeImpactService(userProfile: userProfile)
        
        // Calculate current impact with actual current value
        let currentMetric = HealthMetric(
            id: UUID().uuidString,
            type: metricType,
            value: currentValue,
            date: Date(),
            source: .healthKit
        )
        let currentImpact = lifeImpactService.calculateImpact(for: currentMetric)
        let currentImpactMinutes = currentImpact.lifespanImpactMinutes
        
        // Calculate current benefit for daily target

        
        // CRITICAL FIX: For negative metrics, benefit is simply reaching neutral (0 impact)
        // This means the benefit is exactly abs(currentImpact), not the difference to target
        if currentImpactMinutes < 0 {
            // Negative impact: benefit is exactly what's needed to reach neutral
            let benefit = abs(currentImpactMinutes)
            print("  ✅ NEGATIVE METRIC: Benefit = abs(\(currentImpactMinutes)) = \(benefit) minutes")
            return benefit
        } else {
            // Positive impact: calculate improvement benefit using target
            let targetMetric = HealthMetric(
                id: UUID().uuidString,
                type: metricType,
                value: targetValue,
                date: Date(),
                source: .healthKit
            )
            let targetImpact = lifeImpactService.calculateImpact(for: targetMetric)
            
            // Return the additional benefit of reaching the target
            let benefit = max(0, targetImpact.lifespanImpactMinutes - currentImpactMinutes)
            print("  ✅ POSITIVE METRIC: Benefit = \(targetImpact.lifespanImpactMinutes) - \(currentImpactMinutes) = \(benefit) minutes")
            return benefit
        }
    }
    
    /// Generate consistent recommendation text using fixed target
    func generateRecommendationText(currentValue: Double, userProfile: UserProfile = UserProfile()) -> String {
        let remaining = remainingAmount(currentValue: currentValue)
        
        // CRITICAL FIX: Calculate benefit dynamically based on current progress and scale for time period
        let dailyBenefit = calculateCurrentBenefit(currentValue: currentValue, userProfile: userProfile)
        
        // Scale benefit by time period duration for month and year periods
        let scaledBenefit: Double
        switch period {
        case .day:
            scaledBenefit = dailyBenefit
        case .month:
            // For month period, show the cumulative benefit over 30 days
            scaledBenefit = dailyBenefit * 30.0
        case .year:
            // For year period, show the cumulative benefit over 365 days
            scaledBenefit = dailyBenefit * 365.0
        }
        
        let benefitText = scaledBenefit.formattedAsTime()
        
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
        
        // CRITICAL FIX: Check if we're currently in negative impact
        // Simple check for negative impact based on metric type and value
        let isCurrentlyNegative = isMetricInNegativeImpact(type: metricType, value: originalCurrentValue)
        
        switch metricType {
        case .steps:
            let formattedSteps = Int(remaining).formatted(.number.grouping(.automatic))
            if isCurrentlyNegative {
                return "Walk \(formattedSteps) more steps today to add \(benefitText) to your lifespan"
            } else {
                return "Walk \(formattedSteps) more steps today to add \(benefitText) to your lifespan"
            }
        case .exerciseMinutes:
            let exerciseTime = remaining.formattedAsTime()
            if isCurrentlyNegative {
                return "Exercise \(exerciseTime) more today to add \(benefitText) to your lifespan"
            } else {
                return "Exercise \(exerciseTime) more today to add \(benefitText) to your lifespan"
            }
        case .sleepHours:
            let sleepTime = (remaining * 60).formattedAsTime()
            if isCurrentlyNegative {
                return "Sleep \(sleepTime) more tonight to add \(benefitText) to your lifespan"
            } else {
                return "Sleep \(sleepTime) more tonight to add \(benefitText) to your lifespan"
            }
        case .activeEnergyBurned:
            if isCurrentlyNegative {
                return "Burn \(Int(remaining)) more calories today to add \(benefitText) to your lifespan"
            } else {
                return "Burn \(Int(remaining)) more calories today to add \(benefitText) to your lifespan"
            }
        case .socialConnectionsQuality:
            if isCurrentlyNegative {
                return "Improve your social connections to add \(benefitText) to your lifespan"
            } else {
                return "Strengthen your social connections to add \(benefitText) to your lifespan"
            }
        case .nutritionQuality:
            if isCurrentlyNegative {
                return "Improve your nutrition to add \(benefitText) to your lifespan"
            } else {
                return "Optimize your nutrition to add \(benefitText) to your lifespan"
            }
        case .stressLevel:
            if isCurrentlyNegative {
                return "Reduce your stress to add \(benefitText) to your lifespan"
            } else {
                return "Manage stress better to add \(benefitText) to your lifespan"
            }
        default:
            if isCurrentlyNegative {
                return "Improve your \(metricType.displayName.lowercased()) to add \(benefitText) to your lifespan"
            } else {
                return "Improve your \(metricType.displayName.lowercased()) to add \(benefitText) to your lifespan"
            }
        }
    }
    
    /// Helper to determine if a metric is currently in negative impact territory
    private func isMetricInNegativeImpact(type: HealthMetricType, value: Double) -> Bool {
        // Simple heuristics for common metrics
        switch type {
        case .steps:
            return value < 4000 // Below 4000 steps typically negative
        case .exerciseMinutes:
            return value < 10 // Less than 10 minutes typically negative
        case .sleepHours:
            return value < 6 || value > 9 // Outside 6-9 hour range
        case .restingHeartRate:
            return value > 75 // Above 75 bpm typically negative
        case .heartRateVariability:
            return value < 30 // Below 30ms typically negative
        default:
            return false // Conservative default
        }
    }
    
    private func generateMonthlyRecommendation(targetValue: Double, benefitText: String) -> String {
        switch metricType {
        case .steps:
            let formattedSteps = Int(targetValue).formatted(.number.grouping(.automatic))
            return "Aim for walking \(formattedSteps) steps daily over the next month to add \(benefitText) to your life"
        case .exerciseMinutes:
            let exerciseTime = targetValue.formattedAsTime()
            return "Aim for exercising \(exerciseTime) daily over the next month to add \(benefitText) to your life"
        case .sleepHours:
            let sleepTime = (targetValue * 60).formattedAsTime()
            return "Aim for sleeping \(sleepTime) nightly over the next month to add \(benefitText) to your life"
        case .activeEnergyBurned:
            return "Aim for burning \(Int(targetValue)) calories daily over the next month to add \(benefitText) to your life"
        case .socialConnectionsQuality:
            return "Aim for strengthening social connections daily over the next month to add \(benefitText) to your life"
        case .nutritionQuality:
            return "Aim for improving nutrition quality daily over the next month to add \(benefitText) to your life"
        case .stressLevel:
            return "Aim for practicing stress management daily over the next month to add \(benefitText) to your life"
        default:
            return "Aim for maintaining optimal \(metricType.displayName.lowercased()) daily over the next month to add \(benefitText) to your life"
        }
    }
    
    private func generateYearlyRecommendation(targetValue: Double, benefitText: String) -> String {
        switch metricType {
        case .steps:
            let formattedSteps = Int(targetValue).formatted(.number.grouping(.automatic))
            return "Aim for walking \(formattedSteps) steps daily over the next year to add \(benefitText) to your life"
        case .exerciseMinutes:
            let exerciseTime = targetValue.formattedAsTime()
            return "Aim for exercising \(exerciseTime) daily over the next year to add \(benefitText) to your life"
        case .sleepHours:
            let sleepTime = (targetValue * 60).formattedAsTime()
            return "Aim for sleeping \(sleepTime) nightly over the next year to add \(benefitText) to your life"
        case .activeEnergyBurned:
            return "Aim for burning \(Int(targetValue)) calories daily over the next year to add \(benefitText) to your life"
        case .socialConnectionsQuality:
            return "Aim for strengthening social connections daily over the next year to add \(benefitText) to your life"
        case .nutritionQuality:
            return "Aim for improving nutrition quality daily over the next year to add \(benefitText) to your life"
        case .stressLevel:
            return "Aim for practicing stress management daily over the next year to add \(benefitText) to your life"
        default:
            return "Aim for maintaining optimal \(metricType.displayName.lowercased()) daily over the next year to add \(benefitText) to your life"
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
    
    /// Clear a specific target for a metric type and period
    func clearTarget(for metricType: HealthMetricType, period: ImpactDataPoint.PeriodType) {
        var targets: [DailyTarget] = loadTargets()
        
        // Remove the specific target
        targets.removeAll { target in
            target.metricType == metricType && target.period == period
        }
        
        // Save updated targets
        cacheManager.saveData(targets, forKey: cacheKey, type: .recommendations)
    }
    
    /// Clear expired targets
    func clearExpiredTargets() {
        var targets: [DailyTarget] = loadTargets()
        targets.removeAll { !$0.isValidForToday }
        cacheManager.saveData(targets, forKey: cacheKey, type: .recommendations)
    }
    
    // MARK: - Private Methods
    
    private func loadTargets() -> [DailyTarget] {
        return cacheManager.loadData(forKey: cacheKey, type: .recommendations) ?? []
    }
} 