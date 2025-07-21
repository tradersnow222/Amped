import Foundation
import OSLog

/// Service for generating accurate, science-based recommendations with proper incremental benefit calculations
class RecommendationService {
    private let logger = Logger(subsystem: "Amped", category: "RecommendationService")
    private let userProfile: UserProfile
    
    // Calculators for impact calculations
    private let activityCalculator = ActivityImpactCalculator()
    private let cardiovascularCalculator = CardiovascularImpactCalculator()
    private let lifestyleCalculator = LifestyleImpactCalculator()
    private let lifeImpactService: LifeImpactService
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        self.lifeImpactService = LifeImpactService(userProfile: userProfile)
    }
    
    /// Generate accurate recommendation with proper incremental benefit calculation
    func generateRecommendation(for metric: HealthMetric, selectedPeriod: ImpactDataPoint.PeriodType) -> String {
        guard let impactDetails = metric.impactDetails else {
            return getDefaultRecommendation(for: metric, period: selectedPeriod)
        }
        
        let currentDailyImpact = impactDetails.lifespanImpactMinutes
        
        if currentDailyImpact < 0 {
            // Negative impact: Calculate benefit to reach neutral (0 impact)
            return generateNegativeMetricRecommendation(for: metric, period: selectedPeriod)
        } else {
            // Positive impact: Calculate 20% improvement benefit
            return generatePositiveMetricRecommendation(for: metric, period: selectedPeriod, currentImpact: currentDailyImpact)
        }
    }
    
    // MARK: - Negative Impact Recommendations
    
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
        
        // Calculate realistic action size based on actual deficit
        let actionSteps = calculateRealisticStepTarget(stepsNeeded: stepsNeeded)
        let walkMinutes = Int(actionSteps / 100) // ~100 steps per minute walking
        let actionText = "Walk \(walkMinutes) minutes"
        
        // Calculate actual benefit of this action
        let newSteps = currentSteps + actionSteps
        let newImpact = calculateStepsImpact(steps: newSteps)
        let incrementalBenefit = newImpact - currentImpact
        
        // Apply bounds checking for realistic recommendations
        let clampedBenefit = applyRealisticBounds(benefit: incrementalBenefit, period: period, metricType: .steps)
        let formattedBenefit = formatBenefitForPeriod(clampedBenefit, period: period)
        
        switch period {
        case .day:
            return "\(actionText) today to add \(formattedBenefit) today"
        case .month:
            return "\(actionText) daily to add \(formattedBenefit) this month"
        case .year:
            return "\(actionText) daily to add \(formattedBenefit) this year"
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
        
        // Calculate realistic improvement based on current level
        let actionMinutes = calculateRealisticExerciseTarget(minutesNeeded: minutesNeeded, currentMinutes: currentMinutes)
        let newMinutes = currentMinutes + actionMinutes
        let newImpact = calculateExerciseImpact(minutes: newMinutes)
        let incrementalBenefit = newImpact - currentImpact
        
        // Apply bounds checking
        let clampedBenefit = applyRealisticBounds(benefit: incrementalBenefit, period: period, metricType: .exerciseMinutes)
        let formattedBenefit = formatBenefitForPeriod(clampedBenefit, period: period)
        
        switch period {
        case .day:
            return "Exercise \(Int(actionMinutes)) minutes today to add \(formattedBenefit) today"
        case .month:
            return "Exercise \(Int(actionMinutes)) minutes daily to add \(formattedBenefit) this month"
        case .year:
            return "Exercise \(Int(actionMinutes)) minutes daily to add \(formattedBenefit) this year"
        }
    }
    
    private func findExerciseForNeutralImpact(currentMinutes: Double) -> Double {
        return 21.4 // WHO guideline equivalent (150 min/week ÷ 7 days)
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
        let hourText = actionHours == 1.0 ? "1 hour" : String(format: "%.1f hours", actionHours)
        
        switch period {
        case .day:
            return "Sleep \(hourText) more tonight to add \(formattedBenefit)"
        case .month:
            return "Sleep \(hourText) more nightly this month to add \(formattedBenefit)"
        case .year:
            return "Sleep \(hourText) more nightly this year to add \(formattedBenefit)"
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
            return "Practice 10 minutes of deep breathing today to add \(formattedBenefit)"
        case .month:
            return "Practice 10 minutes of deep breathing daily this month to add \(formattedBenefit)"
        case .year:
            return "Practice 10 minutes of deep breathing daily this year to add \(formattedBenefit)"
        }
    }
    
    private func generateHRVRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Meditate for 15 minutes today to add \(formattedBenefit)"
        case .month:
            return "Meditate for 15 minutes daily this month to add \(formattedBenefit)"
        case .year:
            return "Meditate for 15 minutes daily this year to add \(formattedBenefit)"
        }
    }
    
    private func generateBodyMassRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Reduce caloric intake by 200 calories today to add \(formattedBenefit)"
        case .month:
            return "Reduce caloric intake by 200 calories daily this month to add \(formattedBenefit)"
        case .year:
            return "Reduce caloric intake by 200 calories daily this year to add \(formattedBenefit)"
        }
    }
    
    private func generateAlcoholRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Skip alcohol today to add \(formattedBenefit)"
        case .month:
            return "Reduce alcohol consumption this month to add \(formattedBenefit)"
        case .year:
            return "Reduce alcohol consumption this year to add \(formattedBenefit)"
        }
    }
    
    private func generateSmokingRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Avoid smoking today to add \(formattedBenefit)"
        case .month:
            return "Reduce smoking this month to add \(formattedBenefit)"
        case .year:
            return "Quit smoking this year to add \(formattedBenefit)"
        }
    }
    
    private func generateStressRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Practice stress management for 15 minutes today to add \(formattedBenefit)"
        case .month:
            return "Practice stress management daily this month to add \(formattedBenefit)"
        case .year:
            return "Practice stress management daily this year to add \(formattedBenefit)"
        }
    }
    
    private func generateNutritionRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Add 3 servings of vegetables today to add \(formattedBenefit)"
        case .month:
            return "Improve nutrition daily this month to add \(formattedBenefit)"
        case .year:
            return "Improve nutrition daily this year to add \(formattedBenefit)"
        }
    }
    
    private func generateSocialRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Connect with a friend today to add \(formattedBenefit)"
        case .month:
            return "Strengthen social connections this month to add \(formattedBenefit)"
        case .year:
            return "Strengthen social connections this year to add \(formattedBenefit)"
        }
    }
    
    private func generateActiveEnergyRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Increase daily activity to add \(formattedBenefit)"
        case .month:
            return "Increase daily activity this month to add \(formattedBenefit)"
        case .year:
            return "Increase daily activity this year to add \(formattedBenefit)"
        }
    }
    
    private func generateVO2MaxRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Do high-intensity exercise today to add \(formattedBenefit)"
        case .month:
            return "Do high-intensity exercise regularly this month to add \(formattedBenefit)"
        case .year:
            return "Do high-intensity exercise regularly this year to add \(formattedBenefit)"
        }
    }
    
    private func generateOxygenRecommendation(metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> String {
        let benefit = calculateNeutralBenefit(for: metric)
        let formattedBenefit = formatBenefitForPeriod(benefit, period: period)
        
        switch period {
        case .day:
            return "Practice breathing exercises today to add \(formattedBenefit)"
        case .month:
            return "Practice breathing exercises this month to add \(formattedBenefit)"
        case .year:
            return "Practice breathing exercises this year to add \(formattedBenefit)"
        }
    }
    
    // MARK: - Positive Impact Recommendations
    
    private func generatePositiveMetricRecommendation(for metric: HealthMetric, period: ImpactDataPoint.PeriodType, currentImpact: Double) -> String {
        let twentyPercentIncrease = currentImpact * 0.2
        let formattedBenefit = formatBenefitForPeriod(twentyPercentIncrease, period: period)
        
        switch metric.type {
        case .steps:
            return "Increase your daily steps by 1,000 to add \(formattedBenefit)"
        case .exerciseMinutes:
            return "Add 10 more minutes of exercise to add \(formattedBenefit)"
        case .sleepHours:
            return "Optimize sleep quality to add \(formattedBenefit)"
        default:
            return "Continue your excellent habits to maintain \(formattedBenefit) benefit"
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
        // Cap at reasonable daily increases to avoid unrealistic recommendations
        if stepsNeeded <= 1000 {
            return min(stepsNeeded, 1000) // 10-minute walk max for small deficits
        } else if stepsNeeded <= 3000 {
            return min(stepsNeeded, 2500) // 25-minute walk max for medium deficits
        } else if stepsNeeded <= 5000 {
            return min(stepsNeeded, 4000) // 40-minute walk max for large deficits
        } else {
            return 5000 // 50-minute walk maximum recommendation
        }
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
        let maxDailyBenefit: Double
        
        // Set maximum realistic daily benefits based on research
        switch metricType {
        case .steps:
            maxDailyBenefit = 15.0 // Max ~15 minutes of life gain per day from walking
        case .exerciseMinutes:
            maxDailyBenefit = 20.0 // Max ~20 minutes from exercise
        case .sleepHours:
            maxDailyBenefit = 10.0 // Max ~10 minutes from sleep optimization
        case .nutritionQuality:
            maxDailyBenefit = 8.0 // Max ~8 minutes from nutrition
        default:
            maxDailyBenefit = 12.0 // Conservative default
        }
        
        return min(abs(benefit), maxDailyBenefit) * (benefit >= 0 ? 1 : -1)
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
        
        let absMinutes = abs(totalMinutes)
        
        if absMinutes >= 1440 { // >= 1 day
            let days = absMinutes / 1440
            return String(format: "%.1f day%@", days, days == 1.0 ? "" : "s")
        } else if absMinutes >= 60 { // >= 1 hour
            let hours = absMinutes / 60
            return String(format: "%.1f hour%@", hours, hours == 1.0 ? "" : "s")
        } else {
            let mins = max(1, Int(absMinutes))
            return "\(mins) min"
        }
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
            return "Add 30 minutes of exercise to your day"
        case .sleepHours:
            return "Aim for 7-9 hours of sleep nightly"
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
            return "Optimize sleep to 7-8 hours nightly to add \(formattedGain)."
            
        case .exerciseMinutes:
            return "Reach 30 minutes of exercise daily to add \(formattedGain)."
            
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