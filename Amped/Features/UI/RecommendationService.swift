import Foundation
import OSLog

/// Service for generating health metric recommendations
/// CRITICAL: Uses fixed daily targets to prevent confusing target changes throughout the day
final class RecommendationService {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "Amped", category: "RecommendationService")
    private let dailyTargetManager = DailyTargetManager()
    private let activityCalculator = ActivityImpactCalculator()
    private let cardiovascularCalculator = CardiovascularImpactCalculator()
    private let lifeImpactService: LifeImpactService
    private let userProfile: UserProfile
    
    // MARK: - Initialization
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self.lifeImpactService = LifeImpactService(userProfile: userProfile)
    }
    
    // MARK: - Public Methods
    
    /// Generate recommendation for a health metric using fixed daily targets
    func generateRecommendation(for metric: HealthMetric, selectedPeriod: ImpactDataPoint.PeriodType) -> String {
        // ENHANCED DEBUGGING: Log the input metric data
        logger.info("🎯 Generating recommendation for \(metric.type.displayName):")
        logger.info("   Input Value: \(metric.formattedValue)")
        logger.info("   Input Impact: \(metric.impactDetails?.lifespanImpactMinutes ?? 0) minutes")
        logger.info("   Period: \(selectedPeriod.rawValue)")
        
        guard let impactDetails = metric.impactDetails else {
            logger.warning("⚠️ No impact details for \(metric.type.displayName) - using default recommendation")
            return getDefaultRecommendation(for: metric, period: selectedPeriod)
        }

        // Clean expired targets on each call
        dailyTargetManager.clearExpiredTargets()

        // Check for cached daily target first
        if let cachedTarget = dailyTargetManager.getCachedTarget(for: metric.type, period: selectedPeriod) {
            logger.info("📋 Found cached target for \(metric.type.displayName)")
            logger.info("   Cached Original Value: \(cachedTarget.originalCurrentValue)")
            logger.info("   Cached Target Value: \(cachedTarget.targetValue)")
            
            // ENHANCED: Comprehensive cache invalidation with metric-specific logic
            let shouldInvalidateCache = shouldInvalidateCachedTarget(
                cachedTarget: cachedTarget,
                currentMetric: metric,
                currentImpact: impactDetails.lifespanImpactMinutes
            )
            
            if shouldInvalidateCache.shouldInvalidate {
                logger.info("🔄 Cache invalidation triggered for \(metric.type.displayName): \(shouldInvalidateCache.reason)")
                
                // ENHANCED: Progressive cache clearing strategy
                if shouldInvalidateCache.severity == .high {
                    // High severity: Clear all targets to ensure complete recalculation
                    logger.info("⚡ High severity change detected - clearing ALL cached targets")
                    dailyTargetManager.clearTargets()
                } else {
                    // Medium severity: Clear only this metric's targets
                    logger.info("📝 Medium severity change detected - clearing target for this metric only")
                    dailyTargetManager.clearTarget(for: metric.type, period: selectedPeriod)
                }
                
                // Recalculate with fresh baseline
                let currentDailyImpact = impactDetails.lifespanImpactMinutes
                
                if currentDailyImpact < 0 {
                    logger.info("📊 Recalculating negative metric target with fresh data")
                    return calculateAndCacheNegativeMetricTarget(for: metric, period: selectedPeriod)
                } else {
                    logger.info("📊 Recalculating positive metric target with fresh data")
                    return calculateAndCachePositiveMetricTarget(for: metric, period: selectedPeriod, currentImpact: currentDailyImpact)
                }
            }
            
            logger.info("📋 Using cached daily target for \(metric.type.displayName) (passed validation)")
            // CRITICAL FIX: Pass userProfile so benefit can be calculated dynamically
            let recommendation = cachedTarget.generateRecommendationText(currentValue: metric.value, userProfile: userProfile)
            logger.info("💬 Generated recommendation: \(recommendation)")
            return recommendation
        }

        // No cached target - calculate and cache new target
        logger.info("🔄 Calculating new daily target for \(metric.type.displayName)")
        
        let currentDailyImpact = impactDetails.lifespanImpactMinutes
        
        if currentDailyImpact < 0 {
            // Negative impact: Calculate target to reach neutral (0 impact)
            return calculateAndCacheNegativeMetricTarget(for: metric, period: selectedPeriod)
        } else {
            // Positive impact: Calculate 20% improvement target
            return calculateAndCachePositiveMetricTarget(for: metric, period: selectedPeriod, currentImpact: currentDailyImpact)
        }
    }
    
    // MARK: - Target Calculation and Caching
    
    /// Calculate and cache target for negative impact metrics
    private func calculateAndCacheNegativeMetricTarget(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let targetValue: Double
        let benefitMinutes: Double
        
        // Calculate the target value to reach neutral impact
        switch metric.type {
        case .steps:
            targetValue = findStepsForNeutralImpact(currentSteps: metric.value)
            benefitMinutes = abs(metric.impactDetails?.lifespanImpactMinutes ?? 0)
        case .exerciseMinutes:
            targetValue = findExerciseForNeutralImpact(currentMinutes: metric.value)
            benefitMinutes = abs(metric.impactDetails?.lifespanImpactMinutes ?? 0)
        case .sleepHours:
            targetValue = findSleepForOptimalImpact(currentSleep: metric.value)
            benefitMinutes = abs(metric.impactDetails?.lifespanImpactMinutes ?? 0)
        default:
            // For other metrics, use a simple improvement target
            targetValue = metric.value * 1.1
            benefitMinutes = abs(metric.impactDetails?.lifespanImpactMinutes ?? 0)
        }
        
        // Create and cache the daily target
        let dailyTarget = DailyTarget(
            metricType: metric.type,
            targetValue: targetValue,
            originalCurrentValue: metric.value,
            benefitMinutes: benefitMinutes,
            period: period
        )
        
        dailyTargetManager.saveTarget(dailyTarget)
        logger.info("💾 Cached daily target for \(metric.type.displayName): \(targetValue)")
        
        // Generate recommendation using the cached target with userProfile
        return dailyTarget.generateRecommendationText(currentValue: metric.value, userProfile: userProfile)
    }
    
    /// Calculate and cache target for positive impact metrics  
    private func calculateAndCachePositiveMetricTarget(for metric: HealthMetric, period: ImpactDataPoint.PeriodType, currentImpact: Double) -> String {
        // For positive metrics, aim for 20% improvement
        let improvementFactor = 1.2
        let targetValue: Double
        let benefitMinutes: Double
        
        switch metric.type {
        case .steps:
            targetValue = min(metric.value * improvementFactor, 15000) // Cap at reasonable max
        case .exerciseMinutes:
            targetValue = min(metric.value * improvementFactor, 60) // Cap at 1 hour
        case .sleepHours:
            targetValue = min(metric.value + 0.5, 9.0) // Small improvement, cap at 9 hours
        default:
            targetValue = metric.value * improvementFactor
        }
        
        // Calculate benefit (20% of current positive impact)
        benefitMinutes = currentImpact * 0.2
        
        // Create and cache the daily target
        let dailyTarget = DailyTarget(
            metricType: metric.type,
            targetValue: targetValue,
            originalCurrentValue: metric.value,
            benefitMinutes: benefitMinutes,
            period: period
        )
        
        dailyTargetManager.saveTarget(dailyTarget)
        logger.info("💾 Cached daily target for \(metric.type.displayName): \(targetValue)")
        
        // Generate recommendation using the cached target with userProfile
        return dailyTarget.generateRecommendationText(currentValue: metric.value, userProfile: userProfile)
    }

    // MARK: - Legacy Target Calculation Methods (for reference)
    
    private func generateNegativeMetricRecommendation(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        switch metric.type {
        case .steps:
            return generateStepsRecommendation(metric: metric, period: period)
        case .exerciseMinutes:
            return generateExerciseRecommendation(metric: metric, period: period)
        case .sleepHours:
            return generateSleepRecommendation(metric: metric, period: period)
        case .restingHeartRate:
            return generateHeartRateRecommendation(metric: metric, period: period)
        case .heartRateVariability:
            return generateHRVRecommendation(metric: metric, period: period)
        case .bodyMass:
            return generateBodyMassRecommendation(metric: metric, period: period)
        case .alcoholConsumption:
            return generateAlcoholRecommendation(metric: metric, period: period)
        case .smokingStatus:
            return generateSmokingRecommendation(metric: metric, period: period)
        case .stressLevel:
            return generateStressRecommendation(metric: metric, period: period)
        case .nutritionQuality:
            return generateNutritionRecommendation(metric: metric, period: period)
        case .socialConnectionsQuality:
            return generateSocialRecommendation(metric: metric, period: period)
        case .activeEnergyBurned:
            return generateActiveEnergyRecommendation(metric: metric, period: period)
        case .vo2Max:
            return generateVO2MaxRecommendation(metric: metric, period: period)
        case .oxygenSaturation:
            return generateOxygenRecommendation(metric: metric, period: period)
        }
    }
    
    // MARK: - Steps Recommendations
    
    private func generateStepsRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let currentSteps = metric.value
        let currentImpact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        
        // Calculate steps needed to reach neutral (0 impact)
        let targetSteps = findStepsForNeutralImpact(currentSteps: currentSteps)
        let stepsNeeded = max(0, targetSteps - currentSteps)
        
        // For daily recommendations, show additional steps needed
        // For month/year recommendations, show total daily target
        let actionSteps: Double
        let actionText: String
        
        switch period {
        case .day:
            // Show additional steps for today
            actionSteps = calculateRealisticStepTarget(stepsNeeded: stepsNeeded)
            let formattedSteps = Int(actionSteps).formatted(.number.grouping(.automatic))
            actionText = "Walk \(formattedSteps) more steps"
        case .month, .year:
            // Show total daily target for sustained periods
            actionSteps = targetSteps
            let formattedSteps = Int(actionSteps).formatted(.number.grouping(.automatic))
            actionText = "Walk \(formattedSteps) steps"
        }
        
        // Calculate actual benefit of reaching neutral
        let benefitToNeutral = abs(currentImpact) // How much we gain by reaching 0
        let formattedBenefit = formatBenefitForPeriod(benefitToNeutral, period: period)
        
        switch period {
        case .day:
            return "\(actionText) today to add \(formattedBenefit) to your life"
        case .month:
            return "\(actionText) daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "\(actionText) daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func findStepsForNeutralImpact(currentSteps: Double) -> Double {
        // Use binary search to find steps that give ~0 impact
        var low = currentSteps
        var high = 15000.0
        let tolerance = 0.5 // 0.5 minutes tolerance
        
        for _ in 0..<20 { // Max 20 iterations
            let mid = (low + high) / 2
            let impact = calculateStepsImpact(steps: mid)
            
            if abs(impact) < tolerance {
                return mid
            } else if impact < 0 {
                low = mid
            } else {
                high = mid
            }
        }
        
        return 10000 // Default fallback to optimal
    }
    
    private func calculateStepsImpact(steps: Double) -> Double {
                    let _ = HealthMetric(
            id: UUID().uuidString,
            type: .steps,
            value: steps,
            date: Date(),
            source: .healthKit
        )
        
        let impact = activityCalculator.calculateStepsImpact(steps: steps, userProfile: userProfile)
        return impact.lifespanImpactMinutes
    }
    
    // MARK: - Exercise Recommendations
    
    private func generateExerciseRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let currentMinutes = metric.value
        let currentImpact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        
        // Calculate exercise needed to reach neutral
        let targetMinutes = findExerciseForNeutralImpact(currentMinutes: currentMinutes)
        let minutesNeeded = max(0, targetMinutes - currentMinutes)
        
        // For daily recommendations, show additional minutes needed
        // For month/year recommendations, show total daily target
        let actionMinutes: Double
        let actionText: String
        
        switch period {
        case .day:
            // Show additional minutes for today
            actionMinutes = minutesNeeded
            let exerciseTime = Double(actionMinutes).formattedAsTime()
            actionText = "Exercise \(exerciseTime) more"
        case .month, .year:
            // Show total daily target for sustained periods
            actionMinutes = targetMinutes
            let exerciseTime = Double(actionMinutes).formattedAsTime()
            actionText = "Exercise \(exerciseTime)"
        }
        
        // Calculate actual benefit of reaching neutral
        let benefitToNeutral = abs(currentImpact) // How much we gain by reaching 0
        let formattedBenefit = formatBenefitForPeriod(benefitToNeutral, period: period)
        
        switch period {
        case .day:
            return "\(actionText) today to add \(formattedBenefit) to your life"
        case .month:
            return "\(actionText) daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "\(actionText) daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func findExerciseForNeutralImpact(currentMinutes: Double) -> Double {
        return 21.4 // WHO guideline equivalent (150 min/week ÷ 7 days)
    }
    
    private func findSleepForOptimalImpact(currentSleep: Double) -> Double {
        // Optimal sleep duration based on research (7.5-8 hours)
        let optimalSleep = 7.5
        
        if currentSleep < 6.0 {
            // If severely under-slept, aim for 7 hours as intermediate target
            return 7.0
        } else if currentSleep < 7.0 {
            // If under-slept, aim for optimal
            return optimalSleep
        } else if currentSleep > 9.0 {
            // If over-sleeping, aim for optimal
            return optimalSleep
        }
        
        // Already in reasonable range
        return optimalSleep
    }
    
    private func calculateExerciseImpact(minutes: Double) -> Double {
        let impact = activityCalculator.calculateExerciseImpact(exerciseMinutes: minutes, userProfile: userProfile)
        return impact.lifespanImpactMinutes
    }
    
    // MARK: - Sleep Recommendations
    
    private func generateSleepRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let currentHours = metric.value
        let currentImpact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        
        let targetHours: Double
        if currentHours < 7.5 {
            targetHours = 8.0 // Aim for 8 hours if under optimal
        } else {
            targetHours = 7.5 // Aim for optimal middle
        }
        
        let actionHours = min(2.0, targetHours - currentHours) // Max 2 hour increase
        if actionHours <= 0 {
            return getPositiveMetricRecommendation(for: metric, period: period)
        }
        
        let newHours = currentHours + actionHours
        let newImpact = calculateSleepImpact(hours: newHours)
        let incrementalBenefit = newImpact - currentImpact
        
        let formattedBenefit = formatBenefitForPeriod(incrementalBenefit, period: period)
        
        // Format action text based on period
        let actionText: String
        switch period {
        case .day:
            // Show additional hours for tonight
            let actionMinutes = actionHours * 60
            let hourText = actionMinutes.formattedAsTime()
            actionText = "Sleep \(hourText) more"
        case .month, .year:
            // Show total target for sustained periods
            let targetMinutes = targetHours * 60
            let totalText = targetMinutes.formattedAsTime()
            actionText = "Sleep \(totalText)"
        }
        
        switch period {
        case .day:
            return "\(actionText) tonight to add \(formattedBenefit) to your life"
        case .month:
            return "\(actionText) nightly this month to add \(formattedBenefit) to your life"
        case .year:
            return "\(actionText) nightly this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func calculateSleepImpact(hours: Double) -> Double {
        let impact = cardiovascularCalculator.calculateSleepImpact(sleepHours: hours, userProfile: userProfile)
        return impact.lifespanImpactMinutes
    }
    
    // MARK: - Other Metric Recommendations
    
    private func generateHeartRateRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Practice \(Double(10).formattedAsTime()) of deep breathing today to add \(formattedBenefit) to your life"
        case .month:
            return "Practice \(Double(10).formattedAsTime()) of deep breathing daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Practice \(Double(10).formattedAsTime()) of deep breathing daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateHRVRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Meditate for \(Double(15).formattedAsTime()) today to add \(formattedBenefit) to your life"
        case .month:
            return "Meditate for \(Double(15).formattedAsTime()) daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Meditate for \(Double(15).formattedAsTime()) daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateBodyMassRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Reduce caloric intake by 200 calories today to add \(formattedBenefit) to your life"
        case .month:
            return "Reduce caloric intake by 200 calories daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Reduce caloric intake by 200 calories daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateAlcoholRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Skip alcohol today to add \(formattedBenefit) to your life"
        case .month:
            return "Reduce alcohol consumption daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Reduce alcohol consumption daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateSmokingRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Avoid smoking today to add \(formattedBenefit) to your life"
        case .month:
            return "Reduce smoking daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Quit smoking this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateStressRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Practice stress management for \(Double(15).formattedAsTime()) today to add \(formattedBenefit) to your life"
        case .month:
            return "Practice stress management for \(Double(15).formattedAsTime()) daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Practice stress management for \(Double(15).formattedAsTime()) daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateNutritionRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Add 3 servings of vegetables today to add \(formattedBenefit) to your life"
        case .month:
            return "Add 3 servings of vegetables daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Add 3 servings of vegetables daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateSocialRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Connect with a friend today to add \(formattedBenefit) to your life"
        case .month:
            return "Connect with friends daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Connect with friends daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateActiveEnergyRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Increase daily activity today to add \(formattedBenefit) to your life"
        case .month:
            return "Increase daily activity this month to add \(formattedBenefit) to your life"
        case .year:
            return "Increase daily activity this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateVO2MaxRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Do high-intensity exercise today to add \(formattedBenefit) to your life"
        case .month:
            return "Do high-intensity exercise regularly this month to add \(formattedBenefit) to your life"
        case .year:
            return "Do high-intensity exercise regularly this next year to add \(formattedBenefit) to your life"
        }
    }
    
    private func generateOxygenRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Practice breathing exercises today to add \(formattedBenefit) to your life"
        case .month:
            return "Practice breathing exercises daily this month to add \(formattedBenefit) to your life"
        case .year:
            return "Practice breathing exercises daily this next year to add \(formattedBenefit) to your life"
        }
    }
    
    // MARK: - Positive Impact Recommendations
    
    private func generatePositiveMetricRecommendation(for metric: HealthMetric, period: ImpactDataPoint.PeriodType, currentImpact: Double) -> String {
        let twentyPercentIncrease = currentImpact * 0.2
        let formattedBenefit = formatBenefitForPeriod(twentyPercentIncrease, period: period)
        
        // Format the time period context
        let periodText: String
        let actionFrequency: String
        switch period {
        case .day: 
            periodText = ""  // No additional period text for day
            actionFrequency = "today"
        case .month: 
            periodText = "over the next month"
            actionFrequency = "daily"
        case .year: 
            periodText = "over the next year"
            actionFrequency = "daily"
        }
        
        switch metric.type {
        case .steps:
            if period == .day {
                return "Walk 15min more \(actionFrequency) to add \(formattedBenefit)"
            } else {
                return "Walk 15min more \(actionFrequency) to add \(formattedBenefit) \(periodText)"
            }
        case .exerciseMinutes:
            if period == .day {
                return "Add 10 more minutes of exercise \(actionFrequency) to add \(formattedBenefit)"
            } else {
                return "Add 10 more minutes of exercise \(actionFrequency) to add \(formattedBenefit) \(periodText)"
            }
        case .sleepHours:
            if period == .day {
                return "Optimize sleep quality \(actionFrequency) to add \(formattedBenefit)"
            } else {
                return "Optimize sleep quality \(actionFrequency) to add \(formattedBenefit) \(periodText)"
            }
        default:
            if period == .day {
                return "Improve your \(metric.type.displayName.lowercased()) \(actionFrequency) to add \(formattedBenefit)"
            } else {
                return "Improve your \(metric.type.displayName.lowercased()) \(actionFrequency) to add \(formattedBenefit) \(periodText)"
            }
        }
    }
    
    private func getPositiveMetricRecommendation(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let currentImpact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        return generatePositiveMetricRecommendation(for: metric, period: period, currentImpact: currentImpact)
    }
    
    // MARK: - Prioritization Engine
    
    /// Get prioritized recommendations based on potential life impact
    func getPrioritizedRecommendations(
        for metrics: [HealthMetric],
        selectedPeriod: ImpactDataPoint.PeriodType,
        maxRecommendations: Int = 3
    ) -> [PrioritizedRecommendation] {
        logger.info("🎯 Generating prioritized recommendations for \(metrics.count) metrics")
        
        var recommendations: [PrioritizedRecommendation] = []
        
        // Calculate potential improvement for each metric
        for metric in metrics {
            let currentImpact = metric.impactDetails?.lifespanImpactMinutes ?? 0
            
            // Skip metrics that are already optimal
            if let details = metric.impactDetails,
               abs(details.variance) < 0.1 * abs(details.baselineValue) {
                continue
            }
            
            // Calculate potential improvement
            let potentialImprovement = calculatePotentialImprovement(
                for: metric,
                currentImpact: currentImpact,
                period: selectedPeriod
            )
            
            if potentialImprovement.dailyMinutesGained > 0 {
                let recommendation = generateContextAwareRecommendation(
                    for: metric,
                    improvement: potentialImprovement,
                    period: selectedPeriod
                )
                
                recommendations.append(PrioritizedRecommendation(
                    metric: metric,
                    recommendation: recommendation,
                    potentialDailyGain: potentialImprovement.dailyMinutesGained,
                    potentialPeriodGain: potentialImprovement.periodMinutesGained,
                    difficulty: potentialImprovement.difficulty,
                    priority: calculatePriority(
                        gain: potentialImprovement.periodMinutesGained,
                        difficulty: potentialImprovement.difficulty
                    )
                ))
            }
        }
        
        // Sort by priority and return top N
        return recommendations
            .sorted { $0.priority > $1.priority }
            .prefix(maxRecommendations)
            .map { $0 }
    }
    
    /// Calculate potential improvement for a metric
    private func calculatePotentialImprovement(
        for metric: HealthMetric,
        currentImpact: Double,
        period: ImpactDataPoint.PeriodType
    ) -> (dailyMinutesGained: Double, periodMinutesGained: Double, difficulty: RecommendationDifficulty) {
        
        // Calculate realistic improvement target
        let targetValue = calculateRealisticTarget(for: metric)
        
        // Create hypothetical improved metric
        let improvedMetric = HealthMetric(
            id: UUID().uuidString,
            type: metric.type,
            value: targetValue,
            date: metric.date,
            source: metric.source
        )
        
        // Calculate impact of improved metric
        let improvedImpact = lifeImpactService.calculateImpact(for: improvedMetric)
        let dailyGain = improvedImpact.lifespanImpactMinutes - currentImpact
        
        // Scale for period
        let periodGain: Double
        switch period {
        case .day: periodGain = dailyGain
        case .month: periodGain = dailyGain * 30
        case .year: periodGain = dailyGain * 365
        }
        
        // Assess difficulty
        let difficulty = assessDifficulty(
            metric: metric,
            currentValue: metric.value,
            targetValue: targetValue
        )
        
        return (dailyGain, periodGain, difficulty)
    }
    
    /// Calculate realistic improvement target based on current value
    private func calculateRealisticTarget(for metric: HealthMetric) -> Double {
        switch metric.type {
        case .steps:
            // 20% improvement or 10,000, whichever is lower
            return min(metric.value * 1.2, 10000)
            
        case .sleepHours:
            // Move towards optimal 7.5 hours
            if metric.value < 7 {
                return min(metric.value + 0.5, 7.5)
            } else if metric.value > 8 {
                return max(metric.value - 0.5, 7.5)
            }
            return metric.value
            
        case .exerciseMinutes:
            // 30% improvement or WHO guidelines
            return min(metric.value * 1.3, 30) // 30 min/day
            
        case .restingHeartRate:
            // 5 bpm improvement
            return max(metric.value - 5, 55)
            
        case .heartRateVariability:
            // 10 ms improvement
            return metric.value + 10
            
        case .alcoholConsumption:
            // Reduce by 1 drink per day equivalent
            return max(metric.value + 2, 0) // Higher questionnaire value = less drinking
            
        case .smokingStatus:
            // Move up one category
            return min(metric.value + 3, 10)
            
        case .nutritionQuality:
            // 1 point improvement on 10-point scale
            return min(metric.value + 1, 10)
            
        default:
            // 10% improvement
            return metric.value * 1.1
        }
    }
    
    /// Assess difficulty of achieving target
    private func assessDifficulty(
        metric: HealthMetric,
        currentValue: Double,
        targetValue: Double
    ) -> RecommendationDifficulty {
        let changePercent = abs(targetValue - currentValue) / max(currentValue, 1) * 100
        
        switch metric.type {
        case .smokingStatus, .alcoholConsumption:
            // Addiction-related changes are hardest
            return .hard
            
        case .sleepHours:
            // Sleep changes are moderate
            return changePercent > 20 ? .hard : .moderate
            
        case .steps, .exerciseMinutes:
            // Activity changes depend on magnitude
            if changePercent > 50 {
                return .hard
            } else if changePercent > 25 {
                return .moderate
            }
            return .easy
            
        default:
            // Default based on change magnitude
            if changePercent > 40 {
                return .hard
            } else if changePercent > 20 {
                return .moderate
            }
            return .easy
        }
    }
    
    /// Calculate priority score
    private func calculatePriority(gain: Double, difficulty: RecommendationDifficulty) -> Double {
        // Higher gain = higher priority
        // Easier changes = higher priority
        let difficultyMultiplier: Double
        switch difficulty {
        case .easy: difficultyMultiplier = 1.5
        case .moderate: difficultyMultiplier = 1.0
        case .hard: difficultyMultiplier = 0.7
        }
        
        return gain * difficultyMultiplier
    }
    
    /// Generate context-aware recommendation
    private func generateContextAwareRecommendation(
        for metric: HealthMetric,
        improvement: (dailyMinutesGained: Double, periodMinutesGained: Double, difficulty: RecommendationDifficulty),
        period: ImpactDataPoint.PeriodType
    ) -> String {
        // Check if metric is already in healthy range
        if let details = metric.impactDetails,
           metric.value >= details.baselineValue * 0.9 && metric.value <= details.baselineValue * 1.1 {
            return generateMaintenanceRecommendation(for: metric, period: period)
        }
        
        // Generate improvement recommendation
        return generateImprovementRecommendation(
            for: metric,
            gain: improvement.periodMinutesGained,
            period: period
        )
    }
    
    /// Generate recommendation for metrics already in healthy range
    private func generateMaintenanceRecommendation(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        switch metric.type {
        case .sleepHours:
            return "Your sleep is within the optimal range. Maintain your consistent sleep schedule to preserve these benefits."
        case .steps:
            return "Great step count! Keep up your active lifestyle to maintain these cardiovascular benefits."
        case .exerciseMinutes:
            return "You're meeting exercise guidelines. Continue this routine for sustained health benefits."
        default:
            return "Your \(metric.type.displayName.lowercased()) is in a healthy range. Focus on maintaining this level."
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateNeutralBenefit(for metric: HealthMetric) -> Double {
        // Return the benefit of bringing the metric to neutral (0 impact)
        let currentImpact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        return abs(min(0, currentImpact)) // Only for negative impacts
    }
    
    // MARK: - Realistic Calculation Helpers
    
    /// Calculate realistic step target based on current deficit
    private func calculateRealisticStepTarget(stepsNeeded: Double) -> Double {
        // FIXED: Show the actual steps needed to reach neutral
        // No artificial caps - users deserve to know the truth
        return stepsNeeded
    }
    
    /// Calculate realistic exercise target based on deficit and current level
    private func calculateRealisticExerciseTarget(minutesNeeded: Double, currentMinutes: Double) -> Double {
        // Be more conservative for people who don't exercise regularly
        if currentMinutes < 10 {
            return min(minutesNeeded, 15) // Start with 15 minutes for beginners
        } else if currentMinutes < 20 {
            return min(minutesNeeded, 25) // Moderate increase for light exercisers
        } else {
            return min(minutesNeeded, 40) // Larger increase for regular exercisers
        }
    }
    
    /// Apply realistic bounds to prevent biologically impossible recommendations
    private func applyRealisticBounds(benefit: Double, period: ImpactDataPoint.PeriodType, metricType: HealthMetricType) -> Double {
        // FIXED: Don't artificially cap benefits - show actual impact of reaching neutral
        // The research-based calculations already have realistic limits built in
        return benefit
    }
    
    /// Format benefit appropriately for the selected period
    private func formatBenefitForPeriod(_ dailyMinutes: Double, period: ImpactDataPoint.PeriodType) -> String {
        let totalMinutes: Double
        
        switch period {
        case .day:
            totalMinutes = dailyMinutes // Show daily benefit
        case .month:
            totalMinutes = dailyMinutes * 30.0 // Show monthly total if sustained daily
        case .year:
            totalMinutes = dailyMinutes * 365.0 // Show yearly total if sustained daily
        }
        
        return totalMinutes.formattedAsTime()
    }
    
    @available(*, deprecated, message: "Use formatBenefitForPeriod instead")
    private func formatBenefit(_ dailyMinutes: Double, period: ImpactDataPoint.PeriodType) -> String {
        let totalMinutes = dailyMinutes * period.multiplier
        let absMinutes = abs(totalMinutes)
        
        if absMinutes >= 1440 { // >= 1 day
            let days = absMinutes / 1440
            if days >= 1.0 {
                return String(format: "+%.1f day%@", days, days == 1.0 ? "" : "s")
            } else {
                return "+1 day"
            }
        } else if absMinutes >= 60 { // >= 1 hour
            let hours = absMinutes / 60
            if hours >= 1.0 {
                return String(format: "+%.1f hour%@", hours, hours == 1.0 ? "" : "s")
            } else {
                return "+1 hour"
            }
        } else {
            let mins = max(1, Int(absMinutes)) // Minimum 1 minute
            return "+\(mins) min"
        }
    }
    
    private func getDefaultRecommendation(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        switch metric.type {
        case .steps:
            return "Take a 20-minute walk to improve your health"
        case .exerciseMinutes:
            return "Add \(Double(30).formattedAsTime()) of exercise to your day"
        case .sleepHours:
            return "Aim for \(Double(7 * 60).formattedAsTime()) to \(Double(9 * 60).formattedAsTime()) of sleep nightly"
        default:
            return "Focus on improving your \(metric.type.displayName.lowercased())"
        }
    }
    
    /// Generate improvement recommendation with specific gain
    private func generateImprovementRecommendation(
        for metric: HealthMetric,
        gain: Double,
        period: ImpactDataPoint.PeriodType
    ) -> String {
        let formattedGain = formatBenefitForPeriod(gain / period.multiplier, period: period)
        
        switch metric.type {
        case .steps:
            let currentSteps = Int(metric.value)
            let target = currentSteps < 7000 ? "7,000" : "10,000"
            return "Increase to \(target) steps daily to add \(formattedGain)."
            
        case .sleepHours:
            return "Optimize sleep to \(Double(7 * 60).formattedAsTime()) to \(Double(8 * 60).formattedAsTime()) nightly to add \(formattedGain)."
            
        case .exerciseMinutes:
            return "Reach \(Double(30).formattedAsTime()) of exercise daily to add \(formattedGain)."
            
        case .restingHeartRate:
            return "Improve cardiovascular fitness to add \(formattedGain)."
            
        case .heartRateVariability:
            return "Enhance stress resilience to add \(formattedGain)."
            
        case .nutritionQuality:
            return "Improve diet quality to add \(formattedGain)."
            
        default:
            return "Optimize your \(metric.type.displayName.lowercased()) to add \(formattedGain)."
        }
    }
    
    // MARK: - Enhanced Cache Invalidation System
    
    /// Comprehensive cache invalidation with metric-specific logic and progressive severity
    private func shouldInvalidateCachedTarget(
        cachedTarget: DailyTarget,
        currentMetric: HealthMetric,
        currentImpact: Double
    ) -> CacheInvalidationResult {
        
        let originalValue = cachedTarget.originalCurrentValue
        let currentValue = currentMetric.value
        let metricType = currentMetric.type
        
        // ENHANCED DEBUGGING: Log all values for investigation
        logger.info("🔍 Cache Invalidation Check for \(metricType.displayName):")
        logger.info("   Original Value: \(originalValue) -> Current Value: \(currentValue)")
        logger.info("   Absolute Change: \(abs(currentValue - originalValue))")
        logger.info("   Percentage Change: \(abs(currentValue - originalValue) / max(originalValue, 1.0) * 100)%")
        
        // Time-based invalidation: Targets should refresh periodically regardless of value changes
        let cacheAge = Date().timeIntervalSince(cachedTarget.calculationDate)
        logger.info("   Cache Age: \(Int(cacheAge)) seconds")
        
        if cacheAge > 1800 { // CRITICAL FIX: Reduced from 6 hours to 30 minutes for faster updates
            logger.info("🕰️ Cache expired due to age - invalidating")
            return CacheInvalidationResult(
                shouldInvalidate: true,
                reason: "Cache expired (age: \(Int(cacheAge/60)) minutes)",
                severity: .medium
            )
        }
        
        // Get metric-specific invalidation thresholds
        let thresholds = getInvalidationThresholds(for: metricType)
        logger.info("   Thresholds: \(thresholds.percentageThreshold * 100)% or \(thresholds.absoluteThreshold) absolute")
        
        // Calculate change metrics
        let absoluteChange = abs(currentValue - originalValue)
        let percentageChange = absoluteChange / max(originalValue, 1.0)
        
        logger.info("   Calculated Percentage Change: \(percentageChange * 100)%")
        logger.info("   Threshold Check: \(percentageChange > thresholds.percentageThreshold ? "PASS" : "FAIL") (percentage)")
        logger.info("   Threshold Check: \(absoluteChange > thresholds.absoluteThreshold ? "PASS" : "FAIL") (absolute)")
        
        // Check if thresholds are exceeded
        let percentageExceeded = percentageChange > thresholds.percentageThreshold
        let absoluteExceeded = absoluteChange > thresholds.absoluteThreshold
        
        if percentageExceeded || absoluteExceeded {
            let severity: InvalidationSeverity = percentageChange > (thresholds.percentageThreshold * 5) ? .high : .medium
            let reason = "Value changed significantly: \(String(format: "%.1f", percentageChange * 100))% change, \(String(format: "%.0f", absoluteChange)) absolute change"
            
            logger.info("✅ CACHE INVALIDATION TRIGGERED: \(reason)")
            return CacheInvalidationResult(
                shouldInvalidate: true,
                reason: reason,
                severity: severity
            )
        }
        
        logger.info("⏸️ Cache invalidation not triggered - changes below threshold")
        return CacheInvalidationResult(
            shouldInvalidate: false,
            reason: "Changes below invalidation threshold",
            severity: .low
        )
    }
    
    /// Get metric-specific invalidation thresholds
    private func getInvalidationThresholds(for metricType: HealthMetricType) -> InvalidationThresholds {
        switch metricType {
        case .steps:
            // CRITICAL FIX: Very sensitive to user progress - 1% change or 50 steps
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 50.0)
            
        case .exerciseMinutes:
            // CRITICAL FIX: Very sensitive - 1% change or 1 minute
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 1.0)
            
        case .sleepHours:
            // CRITICAL FIX: Very sensitive - 1% change or 6 minutes (0.1 hours)
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 0.1)
            
        case .restingHeartRate:
            // CRITICAL FIX: Very sensitive - 1% change or 1 bpm
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 1.0)
            
        case .heartRateVariability:
            // CRITICAL FIX: Very sensitive - 1% change or 2 ms
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 2.0)
            
        case .bodyMass:
            // Already sensitive at 1% - keep current
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 0.45)
            
        case .activeEnergyBurned:
            // CRITICAL FIX: Very sensitive - 1% change or 10 calories
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 10.0)
            
        case .vo2Max:
            // CRITICAL FIX: Very sensitive - 1% change or 0.5 units
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 0.5)
            
        case .oxygenSaturation:
            // CRITICAL FIX: Very sensitive - 1% change or 0.5%
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 0.5)
            
        // Manual/Questionnaire metrics - also very sensitive
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, 
             .socialConnectionsQuality, .stressLevel:
            // CRITICAL FIX: Very sensitive - 1% change or 0.1 point on scale
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 0.1)
            
        default:
            // CRITICAL FIX: Default to very sensitive for any other metrics
            return InvalidationThresholds(percentageThreshold: 0.01, absoluteThreshold: 1.0)
        }
    }
    
    /// Check if changes to this metric should invalidate other metrics' caches
    private func shouldInvalidateBasedOnCrossMetricEffects(metricType: HealthMetricType, valueChange: Double) -> Bool {
        switch metricType {
        case .steps, .exerciseMinutes:
            // Large activity changes affect cardiovascular metrics
            return valueChange > 1000 // Large step changes or significant exercise changes
            
        case .sleepHours:
            // Sleep changes affect many other metrics
            return valueChange > 1.0 // 1+ hour sleep changes
            
        case .bodyMass:
            // Weight changes affect activity and cardiovascular metrics
            return valueChange > 2.0 // 2+ lb weight changes
            
        default:
            return false // Other metrics don't typically have cross-effects
        }
    }
    
    // MARK: - Enhanced Cache Invalidation Supporting Types
    
    #if DEBUG
    /// Comprehensive validation test for the three critical fixes
    /// Tests the scenario: 422 steps -> 2,221 steps to ensure proper behavior
    func validateFixesIntegration() -> ValidationResult {
        let logger = Logger(subsystem: "Amped", category: "RecommendationService.Validation")
        logger.info("🧪 Starting comprehensive validation of three critical fixes")
        
        var validationResults: [String] = []
        var hasErrors = false
        
        // Test 1: Benefit Calculation Fix
        logger.info("🧪 Test 1: Validating benefit calculation fix")
        
        let userProfile = UserProfile()
        let originalStepsMetric = HealthMetric(
            id: UUID().uuidString,
            type: .steps,
            value: 422,
            date: Date(),
            source: .healthKit
        )
        
        // Clear any existing targets for clean test
        dailyTargetManager.clearTargets()
        
        // Generate recommendation for 422 steps
        let originalRecommendation = generateRecommendation(for: originalStepsMetric, selectedPeriod: .day)
        validationResults.append("✅ Original (422 steps): \(originalRecommendation)")
        
        // Simulate user improvement to 2,221 steps
        let improvedStepsMetric = HealthMetric(
            id: UUID().uuidString,
            type: .steps,
            value: 2221,
            date: Date(),
            source: .healthKit
        )
        
        // Generate recommendation for improved steps
        let improvedRecommendation = generateRecommendation(for: improvedStepsMetric, selectedPeriod: .day)
        validationResults.append("✅ Improved (2,221 steps): \(improvedRecommendation)")
        
        // Validate that benefit text has changed (should be lower)
        if originalRecommendation == improvedRecommendation {
            hasErrors = true
            validationResults.append("❌ ERROR: Recommendation text unchanged after 1,799 step improvement")
        } else {
            validationResults.append("✅ PASS: Recommendation text properly updated after improvement")
        }
        
        // Test 2: Cache Invalidation Fix
        logger.info("🧪 Test 2: Validating cache invalidation fix")
        
        // Check that cache invalidation triggers for significant changes
        if let cachedTarget = dailyTargetManager.getCachedTarget(for: .steps, period: .day) {
            let invalidationResult = shouldInvalidateCachedTarget(
                cachedTarget: cachedTarget,
                currentMetric: improvedStepsMetric,
                currentImpact: -50.0 // Example impact
            )
            
            if invalidationResult.shouldInvalidate {
                validationResults.append("✅ PASS: Cache invalidation properly triggered: \(invalidationResult.reason)")
            } else {
                hasErrors = true
                validationResults.append("❌ ERROR: Cache invalidation should trigger for 1,799 step change")
            }
        }
        
        // Test 3: Metric-Specific Thresholds
        logger.info("🧪 Test 3: Validating metric-specific thresholds")
        
        let stepsThresholds = getInvalidationThresholds(for: .steps)
        let heartRateThresholds = getInvalidationThresholds(for: .restingHeartRate)
        
        if stepsThresholds.absoluteThreshold == 50.0 && heartRateThresholds.absoluteThreshold == 1.0 { // Changed from 3.0 to 1.0
            validationResults.append("✅ PASS: Metric-specific thresholds correctly configured")
        } else {
            hasErrors = true
            validationResults.append("❌ ERROR: Metric-specific thresholds not properly configured")
        }
        
        // Test 4: Edge Cases
        logger.info("🧪 Test 4: Validating edge cases")
        
        let zeroStepsMetric = HealthMetric(
            id: UUID().uuidString,
            type: .steps,
            value: 0,
            date: Date(),
            source: .healthKit
        )
        
        let zeroStepsRecommendation = generateRecommendation(for: zeroStepsMetric, selectedPeriod: .day)
        if !zeroStepsRecommendation.isEmpty {
            validationResults.append("✅ PASS: Zero steps edge case handled")
        } else {
            hasErrors = true
            validationResults.append("❌ ERROR: Zero steps edge case failed")
        }
        
        let finalResult = ValidationResult(
            passed: !hasErrors,
            details: validationResults,
            summary: hasErrors ? "❌ Validation FAILED - Issues detected" : "✅ All validations PASSED"
        )
        
        logger.info("🧪 Validation completed: \(finalResult.summary)")
        return finalResult
    }
    #endif
}

// MARK: - Enhanced Cache Invalidation Supporting Types

/// Result of cache invalidation analysis with severity and reasoning
struct CacheInvalidationResult {
    let shouldInvalidate: Bool
    let reason: String
    let severity: InvalidationSeverity
}

/// Severity levels for cache invalidation with progressive clearing strategies
enum InvalidationSeverity {
    case low        // No invalidation needed
    case medium     // Clear specific metric's cache
    case high       // Clear all caches for comprehensive recalculation
}

/// Metric-specific thresholds for cache invalidation
struct InvalidationThresholds {
    let percentageThreshold: Double  // Percentage change threshold (0.0 to 1.0)
    let absoluteThreshold: Double    // Absolute value change threshold
}

/// Validation result for comprehensive testing
struct ValidationResult {
    let passed: Bool
    let details: [String]
    let summary: String
}

// MARK: - Supporting Types

/// Difficulty level for recommendations
enum RecommendationDifficulty {
    case easy
    case moderate
    case hard
}

/// Prioritized recommendation with metadata
struct PrioritizedRecommendation {
    let metric: HealthMetric
    let recommendation: String
    let potentialDailyGain: Double
    let potentialPeriodGain: Double
    let difficulty: RecommendationDifficulty
    let priority: Double
}

// MARK: - Extensions

extension ImpactDataPoint.PeriodType {
    var multiplier: Double {
        switch self {
        case .day: return 1.0
        case .month: return 30.0
        case .year: return 365.0
        }
    }
} 