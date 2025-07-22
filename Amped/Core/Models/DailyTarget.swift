import Foundation

/// Represents a fixed daily target for a health metric
/// Used to provide consistent recommendations throughout the day
struct DailyTarget: Codable, Identifiable, Equatable {
    let id: String
    let metricType: HealthMetricType
    let targetValue: Double
    let originalCurrentValue: Double // Value when target was first calculated
    let benefitMinutes: Double // Life benefit when reaching target
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
        self.benefitMinutes = benefitMinutes
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
    
    /// Generate consistent recommendation text using fixed target
    func generateRecommendationText(currentValue: Double) -> String {
        let remaining = remainingAmount(currentValue: currentValue)
        let benefitText = benefitMinutes.formattedAsTime()
        
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
    
    // MARK: - Private Methods
    
    private func loadTargets() -> [DailyTarget] {
        return cacheManager.loadData(forKey: cacheKey, type: .recommendations) ?? []
    }
} 