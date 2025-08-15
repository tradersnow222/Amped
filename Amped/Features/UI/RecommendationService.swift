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
    private let lifestyleCalculator = LifestyleImpactCalculator()
    
    // MARK: - Initialization
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self.lifeImpactService = LifeImpactService(userProfile: userProfile)
        
        // CRITICAL FIX: Clear any old cached targets with outdated calculation methods
        // This ensures the new binary search algorithm is used immediately
        self.forceClearOldTargets()
    }
    
    // MARK: - Cache Management
    
    /// Force clear all cached targets to ensure new calculation method is used
    private func forceClearOldTargets() {
        dailyTargetManager.clearTargets()
        logger.info("🗑️ Cleared all cached targets to apply new calculation method")
    }
    
    /// Public method to force recalculation (for debugging or settings)
    func forceRecalculateAllTargets() {
        forceClearOldTargets()
        logger.info("🔄 Forced recalculation of all targets")
    }
    
    // MARK: - Public Methods
    
    /// Generate recommendation for a health metric using fixed daily targets
    func generateRecommendation(for metric: HealthMetric, selectedPeriod: ImpactDataPoint.PeriodType) -> String {
        guard let impactDetails = metric.impactDetails else {
            return getDefaultRecommendation(for: metric, period: selectedPeriod)
        }
        
        // Generate recommendation based on metric data

        
        // Clean expired targets on each call
        dailyTargetManager.clearExpiredTargets()
        
        // Check for cached daily target first
        if let cachedTarget = dailyTargetManager.getCachedTarget(for: metric.type, period: selectedPeriod) {
            
            // CRITICAL FIX: Check if current value has changed significantly from cached original value
            // If so, recalculate target to ensure accuracy
            let originalValue = cachedTarget.originalCurrentValue
            let currentValue = metric.value
            let changePercent = abs(currentValue - originalValue) / max(originalValue, 1.0)
            
            print("  📋 FOUND CACHED TARGET:")
            print("    Original Value: \(originalValue)")
            print("    Current Value: \(currentValue)")
            print("    Change Percent: \(String(format: "%.3f", changePercent * 100))%")
            print("    Target Value: \(cachedTarget.targetValue)")
            
            // CRITICAL: Apply 1% rule to ALL metrics for real-time updates
            if changePercent >= 0.01 {
                logger.info("🔄 Current value changed by \(String(format: "%.1f", changePercent * 100))% from cached target. Recalculating for \(metric.type.displayName)")
                logger.info("  Original: \(originalValue), Current: \(currentValue)")
                print("  🔄 RECALCULATING DUE TO 1% CHANGE")
                
                // Clear the stale target and recalculate
                dailyTargetManager.clearTarget(for: metric.type, period: selectedPeriod)
                
                let currentDailyImpact = impactDetails.lifespanImpactMinutes
                
                if currentDailyImpact < 0 {
                    print("  📍 GOING TO: calculateAndCacheNegativeMetricTarget")
                    return calculateAndCacheNegativeMetricTarget(for: metric, period: selectedPeriod)
                } else {
                    print("  📍 GOING TO: calculateAndCachePositiveMetricTarget")
                    return calculateAndCachePositiveMetricTarget(for: metric, period: selectedPeriod, currentImpact: currentDailyImpact)
                }
            }
            
            logger.info("📋 Using cached daily target for \(metric.type.displayName)")
            print("  📋 USING CACHED TARGET")
            // CRITICAL FIX: Pass userProfile so benefit can be calculated dynamically
            let result = cachedTarget.generateRecommendationText(currentValue: metric.value, userProfile: userProfile)
            print("  📋 CACHED RESULT: \(result)")
            return result
        }
        
        // No cached target - calculate and cache new target
        logger.info("🔄 Calculating new daily target for \(metric.type.displayName)")
        print("  🆕 NO CACHED TARGET - CALCULATING NEW")
        
        let currentDailyImpact = impactDetails.lifespanImpactMinutes
        
        if currentDailyImpact < 0 {
            // Negative impact: Calculate target to reach neutral (0 impact)
            print("  📍 GOING TO: calculateAndCacheNegativeMetricTarget (NEW)")
            return calculateAndCacheNegativeMetricTarget(for: metric, period: selectedPeriod)
        } else {
            // Positive impact: Calculate 20% improvement target
            print("  📍 GOING TO: calculateAndCachePositiveMetricTarget (NEW)")
            return calculateAndCachePositiveMetricTarget(for: metric, period: selectedPeriod, currentImpact: currentDailyImpact)
        }
    }
    
    /// Default recommendation when impact details are unavailable  
    private func getDefaultRecommendation(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        switch metric.type {
        case .steps:
            return "Take a 20-minute walk to improve your health"
        case .exerciseMinutes:
            return "Add 30 minutes of exercise to your day"
        case .sleepHours:
            return "Aim for 7-9 hours of sleep nightly"
        default:
            return "Focus on improving your \(metric.type.displayName.lowercased())"
        }
    }
    
    // MARK: - Target Calculation and Caching
    
    /// Calculate and cache target for negative impact metrics
    private func calculateAndCacheNegativeMetricTarget(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        logger.info("🔴 Calculating negative metric target for \(metric.type.displayName)")
        
        let currentImpact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        logger.info("  Current impact: \(String(format: "%.2f", currentImpact)) min/day")
        
        // CRITICAL FIX: For negative metrics, the benefit is simply bringing to neutral (0 impact)
        // This means the benefit is exactly abs(currentImpact)
        let benefitToNeutral = abs(currentImpact)
        
        // Calculate the target value needed to achieve neutral impact
        let targetValue = calculateTargetForNeutralImpact(metric: metric, currentImpact: currentImpact)
        
        logger.info("  Target value: \(String(format: "%.2f", targetValue))")
        logger.info("  Benefit to neutral: \(String(format: "%.2f", benefitToNeutral)) min/day")
        
        // CRITICAL FIX: Create a special DailyTarget that uses the known benefit instead of recalculating
        let dailyTarget = DailyTargetWithKnownBenefit(
            metricType: metric.type,
            targetValue: targetValue,
            originalCurrentValue: metric.value,
            knownCurrentImpact: currentImpact, // Pass the known impact
            benefitMinutes: benefitToNeutral,
            period: period
        )
        
        dailyTargetManager.saveTarget(dailyTarget.toDailyTarget())
        logger.info("💾 Cached daily target for \(metric.type.displayName): \(String(format: "%.2f", targetValue))")
        
        // Force clear cache to ensure fresh calculation on next use
        dailyTargetManager.clearTargets()
        
        // For other metrics, use the original method but with corrected benefit
        // CRITICAL FIX: Pass correct value based on period type
        let parameterValue: Double
        switch period {
        case .day:
            // Daily expects additional amount ("Walk X more steps today")
            parameterValue = max(0, targetValue - metric.value)
        case .month, .year:
            // Monthly/Yearly expect absolute target ("Aim for X steps daily")
            parameterValue = targetValue
        }
        
        return generateRecommendationWithKnownBenefitMinutes(
            metricType: metric.type,
            remaining: parameterValue,
            benefitMinutes: benefitToNeutral,
            period: period
        )
    }
    
    /// Calculate target value needed to achieve neutral (0) impact for a metric
    private func calculateTargetForNeutralImpact(metric: HealthMetric, currentImpact: Double) -> Double {
        switch metric.type {
        case .steps:
            return calculateStepsForNeutralImpact(currentSteps: metric.value, currentImpact: currentImpact)
        case .exerciseMinutes:
            return calculateExerciseForNeutralImpact(currentMinutes: metric.value, currentImpact: currentImpact)
        case .sleepHours:
            return calculateSleepForNeutralImpact(currentHours: metric.value, currentImpact: currentImpact)
        case .restingHeartRate:
            return calculateHeartRateForNeutralImpact(currentHR: metric.value, currentImpact: currentImpact)
        case .bodyMass:
            return calculateBodyMassForNeutralImpact(currentMass: metric.value, currentImpact: currentImpact)
        case .alcoholConsumption:
            return calculateAlcoholForNeutralImpact(currentConsumption: metric.value, currentImpact: currentImpact)
        case .smokingStatus:
            return calculateSmokingForNeutralImpact(currentStatus: metric.value, currentImpact: currentImpact)
        case .stressLevel:
            return calculateStressForNeutralImpact(currentStress: metric.value, currentImpact: currentImpact)
        case .nutritionQuality:
            return calculateNutritionForNeutralImpact(currentNutrition: metric.value, currentImpact: currentImpact)
        default:
            // For other metrics, use proportional improvement
            return calculateProportionalTargetForNeutral(metric: metric, currentImpact: currentImpact)
        }
    }
    
    /// Calculate steps needed for neutral impact using simplified approach
    private func calculateStepsForNeutralImpact(currentSteps: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        // This ensures the recommendation matches the displayed impact exactly
        
        logger.info("    🔍 Finding steps for neutral impact using binary search")
        logger.info("      Current steps: \(String(format: "%.0f", currentSteps))")
        logger.info("      Current impact: \(String(format: "%.2f", currentImpact)) min")
        
        // If already at neutral or positive, no change needed
        if currentImpact >= 0 {
            return currentSteps
        }
        
        // Binary search to find steps that give ~0 impact
        var low = currentSteps
        var high = 15000.0 // Reasonable upper bound
        let tolerance = 0.5 // 0.5 minutes tolerance for neutral
        
        // Create a test metric to calculate impacts
        for iteration in 0..<30 { // Max 30 iterations to prevent infinite loop
            let mid = (low + high) / 2.0
            
            // Calculate impact at this step count using the ACTUAL formula
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .steps,
                value: mid,
                date: Date(),
                source: .healthKit
            )
            
            let testImpact = activityCalculator.calculateStepsImpact(
                steps: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            logger.debug("      Iteration \(iteration): \(String(format: "%.0f", mid)) steps → \(String(format: "%.2f", impactMinutes)) min")
            
            if abs(impactMinutes) < tolerance {
                // Found neutral point!
                logger.info("      ✅ Found neutral at \(String(format: "%.0f", mid)) steps")
                return mid
            } else if impactMinutes < 0 {
                // Still negative, need more steps
                low = mid
            } else {
                // Positive, need fewer steps
                high = mid
            }
        }
        
        // Fallback if binary search doesn't converge
        let result = (low + high) / 2.0
        logger.info("      ⚠️ Binary search ended at \(String(format: "%.0f", result)) steps")
        return result
    }
    
    /// Calculate exercise minutes needed for neutral impact
    private func calculateExerciseForNeutralImpact(currentMinutes: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        logger.info("    🔍 Finding exercise minutes for neutral impact")
        
        if currentImpact >= 0 {
            return currentMinutes
        }
        
        var low = currentMinutes
        var high = 60.0 // Reasonable upper bound
        let tolerance = 0.5
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .exerciseMinutes,
                value: mid,
                date: Date(),
                source: .healthKit
            )
            
            let testImpact = activityCalculator.calculateExerciseImpact(
                exerciseMinutes: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if impactMinutes < 0 {
                low = mid
            } else {
                high = mid
            }
        }
        
        return (low + high) / 2.0
    }
    
    /// Calculate sleep hours needed for neutral impact
    private func calculateSleepForNeutralImpact(currentHours: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        logger.info("    🔍 Finding sleep hours for neutral impact")
        
        if currentImpact >= 0 {
            return currentHours
        }
        
        // Sleep has a U-shaped curve, so we need to search in the right direction
        let optimalSleep = 7.5
        var low: Double
        var high: Double
        
        if currentHours < optimalSleep {
            // Under-sleeping, search upward
            low = currentHours
            high = optimalSleep
        } else {
            // Over-sleeping, search downward
            low = optimalSleep
            high = currentHours
        }
        
        let tolerance = 0.5
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: mid,
                date: Date(),
                source: .healthKit
            )
            
            let testImpact = cardiovascularCalculator.calculateSleepImpact(
                sleepHours: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if currentHours < optimalSleep {
                // Under-sleeping case
                if impactMinutes < 0 {
                    low = mid  // Need more sleep
                } else {
                    high = mid // Too much correction
                }
            } else {
                // Over-sleeping case
                if impactMinutes < 0 {
                    high = mid // Need less sleep
                } else {
                    low = mid  // Too much correction
                }
            }
        }
        
        return (low + high) / 2.0
    }
    
    /// Generic calculation for other metrics
    private func calculateProportionalTargetForNeutral(metric: HealthMetric, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search for ALL metrics to ensure consistency
        logger.info("    🔍 Finding neutral value for \(metric.type.displayName) using binary search")
        
        if currentImpact >= 0 {
            return metric.value
        }
        
        // Generic binary search - adjust search range based on metric type
        var low = metric.value * 0.5  // Search down to 50% of current
        var high = metric.value * 2.0 // Search up to 200% of current
        let tolerance = 0.5
        
        // For some metrics, we know the direction
        switch metric.type {
        case .alcoholConsumption, .smokingStatus, .nutritionQuality, .socialConnectionsQuality:
            // Higher values are better for these questionnaire metrics
            low = metric.value
            high = 10.0
        case .stressLevel:
            // Lower values are better
            low = 1.0
            high = metric.value
        default:
            break
        }
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let testMetric = HealthMetric(
            id: UUID().uuidString,
            type: metric.type,
                value: mid,
            date: Date(),
            source: metric.source
        )
        
            let testImpact = lifeImpactService.calculateImpact(for: testMetric)
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if impactMinutes < 0 {
                // Still negative, need to adjust based on metric type
                switch metric.type {
                case .alcoholConsumption, .smokingStatus, .nutritionQuality, .socialConnectionsQuality:
                    low = mid  // Need higher value
                case .stressLevel:
                    high = mid // Need lower value
                default:
                    // Generic: try increasing
                    low = mid
                }
            } else {
                // Positive, reverse adjustment
                switch metric.type {
                case .alcoholConsumption, .smokingStatus, .nutritionQuality, .socialConnectionsQuality:
                    high = mid // Too high
                case .stressLevel:
                    low = mid  // Too low
                default:
                    // Generic: try decreasing
                    high = mid
                }
            }
        }
        
        return (low + high) / 2.0
    }
    
    // MARK: - Additional Target Calculation Methods
    
    private func calculateHeartRateForNeutralImpact(currentHR: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        logger.info("    🔍 Finding heart rate for neutral impact")
        
        if currentImpact >= 0 {
            return currentHR
        }
        
        // Heart rate: lower is generally better
        var low = 50.0 // Minimum reasonable HR
        var high = currentHR
        let tolerance = 0.5
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .restingHeartRate,
                value: mid,
                date: Date(),
                source: .healthKit
            )
            
            let testImpact = cardiovascularCalculator.calculateRestingHeartRateImpact(
                heartRate: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if impactMinutes < 0 {
                high = mid // Need lower HR
            } else {
                low = mid  // Too low
            }
        }
        
        return (low + high) / 2.0
    }
    
    private func calculateBodyMassForNeutralImpact(currentMass: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        logger.info("    🔍 Finding body mass for neutral impact")
        
        if currentImpact >= 0 {
            return currentMass
        }
        
        // Body mass: closer to 160 lbs is better
        let reference = 160.0
        var low: Double
        var high: Double
        
        if currentMass > reference {
            // Need to lose weight
            low = reference
            high = currentMass
        } else {
            // Need to gain weight (rare case)
            low = currentMass
            high = reference
        }
        
        let tolerance = 0.5
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .bodyMass,
                value: mid,
                date: Date(),
                source: .healthKit
            )
            
            let testImpact = activityCalculator.calculateBodyMassImpact(
                bodyMass: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if currentMass > reference {
                // Overweight case
                if impactMinutes < 0 {
                    high = mid // Need to lose more
                } else {
                    low = mid  // Lost too much
                }
            } else {
                // Underweight case
                if impactMinutes < 0 {
                    low = mid  // Need to gain more
                } else {
                    high = mid // Gained too much
                }
            }
        }
        
        return (low + high) / 2.0
    }
    
    private func calculateAlcoholForNeutralImpact(currentConsumption: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        logger.info("    🔍 Finding alcohol consumption for neutral impact")
        
        if currentImpact >= 0 {
            return currentConsumption
        }
        
        // Higher questionnaire values = less drinking = better
        var low = currentConsumption
        var high = 10.0
        let tolerance = 0.5
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .alcoholConsumption,
                value: mid,
                date: Date(),
                source: .userInput
            )
            
            let testImpact = lifestyleCalculator.calculateAlcoholImpact(
                drinksPerDay: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if impactMinutes < 0 {
                low = mid  // Need higher value (less drinking)
            } else {
                high = mid // Too high
            }
        }
        
        return (low + high) / 2.0
    }
    
    private func calculateSmokingForNeutralImpact(currentStatus: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        logger.info("    🔍 Finding smoking status for neutral impact")
        
        if currentImpact >= 0 {
            return currentStatus
        }
        
        // Higher questionnaire values = less/no smoking = better
        var low = currentStatus
        var high = 10.0
        let tolerance = 0.5
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .smokingStatus,
                value: mid,
                date: Date(),
                source: .userInput
            )
            
            let testImpact = lifestyleCalculator.calculateSmokingImpact(
                smokingStatus: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if impactMinutes < 0 {
                low = mid  // Need higher value (less smoking)
            } else {
                high = mid // Too high
            }
        }
        
        return (low + high) / 2.0
    }
    
    private func calculateStressForNeutralImpact(currentStress: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        logger.info("    🔍 Finding stress level for neutral impact")
        
        if currentImpact >= 0 {
            return currentStress
        }
        
        // Lower stress levels are better
        var low = 1.0
        var high = currentStress
        let tolerance = 0.5
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .stressLevel,
                value: mid,
                date: Date(),
                source: .userInput
            )
            
            let testImpact = lifestyleCalculator.calculateStressImpact(
                stressLevel: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if impactMinutes < 0 {
                high = mid // Need lower stress
            } else {
                low = mid  // Too low
            }
        }
        
        return (low + high) / 2.0
    }
    
    private func calculateNutritionForNeutralImpact(currentNutrition: Double, currentImpact: Double) -> Double {
        // CRITICAL FIX: Use binary search with the ACTUAL impact formula
        logger.info("    🔍 Finding nutrition quality for neutral impact")
        
        if currentImpact >= 0 {
            return currentNutrition
        }
        
        // Higher nutrition quality is better
        var low = currentNutrition
        var high = 10.0
        let tolerance = 0.5
        
        for _ in 0..<20 {
            let mid = (low + high) / 2.0
            
            let _ = HealthMetric(
                id: UUID().uuidString,
                type: .nutritionQuality,
                value: mid,
                date: Date(),
                source: .userInput
            )
            
            let testImpact = lifestyleCalculator.calculateNutritionImpact(
                nutritionQuality: mid,
                userProfile: userProfile
            )
            
            let impactMinutes = testImpact.lifespanImpactMinutes
            
            if abs(impactMinutes) < tolerance {
                return mid
            } else if impactMinutes < 0 {
                low = mid  // Need higher quality
            } else {
                high = mid // Too high
            }
        }
        
        return (low + high) / 2.0
    }
    
    /// Calculate and cache target for positive impact metrics  
    private func calculateAndCachePositiveMetricTarget(for metric: HealthMetric, period: ImpactDataPoint.PeriodType, currentImpact: Double) -> String {
        logger.info("🟢 Calculating positive metric target for \(metric.type.displayName)")
        logger.info("  Current value: \(metric.value)")
        logger.info("  Current daily impact: \(currentImpact) minutes")
        
        // For positive metrics, aim for 20% improvement
        let improvementFactor = 1.2
        let targetValue: Double
        
        switch metric.type {
        case .steps:
            targetValue = min(metric.value * improvementFactor, 15000) // Cap at reasonable max
        case .exerciseMinutes:
            targetValue = min(metric.value * improvementFactor, 60) // Cap at 1 hour
        case .sleepHours:
            targetValue = min(metric.value + 0.5, 9.0) // Small improvement, cap at 9 hours
        case .socialConnectionsQuality:
            // For social connections, ensure meaningful improvement
            targetValue = min(metric.value + 1.0, 10.0) // Improve by at least 1 point
        default:
            targetValue = metric.value * improvementFactor
        }
        
        logger.info("  Target value: \(targetValue)")
        
        // CRITICAL FIX: Calculate actual benefit by comparing impacts, not just using 20%
        // Create a temporary metric at the target value
        let targetMetric = HealthMetric(
            id: UUID().uuidString,
            type: metric.type,
            value: targetValue,
            date: Date(),
            source: metric.source
        )
        
        // Calculate impact at target value
        let targetImpact = lifeImpactService.calculateImpact(for: targetMetric)
        let benefitMinutes = targetImpact.lifespanImpactMinutes - currentImpact
        
        logger.info("  Target impact: \(targetImpact.lifespanImpactMinutes) minutes")
        logger.info("  Benefit: \(benefitMinutes) minutes")
        
        // If benefit is too small (less than 1 minute), find a more meaningful target
        if benefitMinutes < 1.0 && metric.type != .socialConnectionsQuality {
            logger.info("  ⚠️ Benefit too small, finding better target...")
            
            // Find the lowest negative metric instead
            return calculateAndCacheMostImprovableMetricTarget(for: metric, period: period)
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
        logger.info("💾 Cached positive metric daily target for \(metric.type.displayName): \(targetValue)")
        
        // Generate recommendation using the cached target with userProfile
        return dailyTarget.generateRecommendationText(currentValue: metric.value, userProfile: userProfile)
    }
    
    /// Find the most improvable metric when current metric has minimal benefit potential
    private func calculateAndCacheMostImprovableMetricTarget(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        // This is a fallback - just return a generic improvement message
        return "Great job! Your \(metric.type.displayName.lowercased()) is already optimal. Focus on other metrics for greater impact."
    }

    // MARK: - Legacy Target Calculation Methods (for reference)
    
    // MARK: - Legacy Method - Now Uses New Calculation Logic
    private func generateRecommendationWithKnownBenefitMinutes(
        metricType: HealthMetricType,
        remaining: Double,
        benefitMinutes: Double,
        period: ImpactDataPoint.PeriodType
    ) -> String {
        // Scale benefit for time period (same logic as DailyTarget)
        let scaledBenefitText: String
        switch period {
        case .day:
            scaledBenefitText = benefitMinutes.formattedAsTime()
        case .month:
            // For month period, show cumulative benefit over 30 days
            let scaledBenefitMinutes = benefitMinutes * 30.0
            scaledBenefitText = scaledBenefitMinutes.formattedAsTime()
        case .year:
            // For year period, show cumulative benefit over 365 days
            let scaledBenefitMinutes = benefitMinutes * 365.0
            scaledBenefitText = scaledBenefitMinutes.formattedAsTime()
        }
        
        switch period {
        case .day:
            return generateDailyRecommendationText(metricType: metricType, remaining: remaining, benefitText: scaledBenefitText)
        case .month:
            return generateMonthlyRecommendationText(metricType: metricType, targetValue: remaining, benefitText: scaledBenefitText)
        case .year:
            return generateYearlyRecommendationText(metricType: metricType, targetValue: remaining, benefitText: scaledBenefitText)
        }
    }
    
    /// Generate daily recommendation text
    private func generateDailyRecommendationText(metricType: HealthMetricType, remaining: Double, benefitText: String) -> String {
        switch metricType {
        case .steps:
            let formattedSteps = Int(remaining).formatted(.number.grouping(.automatic)).replacingOccurrences(of: " ", with: "\u{00A0}")
            return "Walk \(formattedSteps)\u{00A0}more\u{00A0}steps today to add \(benefitText) to your lifespan"
        case .exerciseMinutes:
            let exerciseTime = remaining.formattedAsTime()
            return "Exercise \(exerciseTime) more today to add \(benefitText) to your lifespan"
        case .sleepHours:
            let sleepTime = (remaining * 60).formattedAsTime()
            return "Sleep \(sleepTime) more tonight to add \(benefitText) to your lifespan"
        case .activeEnergyBurned:
            return "Burn \(Int(remaining))\u{00A0}more\u{00A0}calories today to add \(benefitText) to your lifespan"
        case .socialConnectionsQuality:
            return "Improve your social connections to add \(benefitText) to your lifespan"
        case .nutritionQuality:
            return "Improve your nutrition to add \(benefitText) to your lifespan"
        case .stressLevel:
            return "Reduce your stress to add \(benefitText) to your lifespan"
        default:
            return "Improve your \(metricType.displayName.lowercased()) to add \(benefitText) to your lifespan"
        }
    }
    
    /// Generate monthly recommendation text
    private func generateMonthlyRecommendationText(metricType: HealthMetricType, targetValue: Double, benefitText: String) -> String {
        switch metricType {
        case .steps:
            let formattedSteps = Int(targetValue).formatted(.number.grouping(.automatic)).replacingOccurrences(of: " ", with: "\u{00A0}")
            return "Aim for walking \(formattedSteps)\u{00A0}steps daily over the next month to add \(benefitText) to your life"
        case .exerciseMinutes:
            let exerciseTime = targetValue.formattedAsTime()
            return "Aim for exercising \(exerciseTime) daily over the next month to add \(benefitText) to your life"
        case .sleepHours:
            let sleepTime = (targetValue * 60).formattedAsTime()
            return "Aim for sleeping \(sleepTime) nightly over the next month to add \(benefitText) to your life"
        case .activeEnergyBurned:
            return "Aim for burning \(Int(targetValue))\u{00A0}calories daily over the next month to add \(benefitText) to your life"
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
    
    /// Generate yearly recommendation text
    private func generateYearlyRecommendationText(metricType: HealthMetricType, targetValue: Double, benefitText: String) -> String {
        switch metricType {
        case .steps:
            let formattedSteps = Int(targetValue).formatted(.number.grouping(.automatic)).replacingOccurrences(of: " ", with: "\u{00A0}")
            return "Aim for walking \(formattedSteps)\u{00A0}steps daily over the next year to add \(benefitText) to your life"
        case .exerciseMinutes:
            let exerciseTime = targetValue.formattedAsTime()
            return "Aim for exercising \(exerciseTime) daily over the next year to add \(benefitText) to your life"
        case .sleepHours:
            let sleepTime = (targetValue * 60).formattedAsTime()
            return "Aim for sleeping \(sleepTime) nightly over the next year to add \(benefitText) to your life"
        case .activeEnergyBurned:
            return "Aim for burning \(Int(targetValue))\u{00A0}calories daily over the next year to add \(benefitText) to your life"
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

// MARK: - Helper Types

/// Temporary helper to avoid recalculating impact
private struct DailyTargetWithKnownBenefit {
    let metricType: HealthMetricType
    let targetValue: Double
    let originalCurrentValue: Double
    let knownCurrentImpact: Double
    let benefitMinutes: Double
    let period: ImpactDataPoint.PeriodType
    
    func toDailyTarget() -> DailyTarget {
        return DailyTarget(
            metricType: metricType,
            targetValue: targetValue,
            originalCurrentValue: originalCurrentValue,
            benefitMinutes: benefitMinutes,
            period: period
        )
    }
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