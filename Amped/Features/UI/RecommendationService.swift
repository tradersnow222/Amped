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
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
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
        
        // Calculate realistic action and its benefit
        let actionSteps: Double
        let actionText: String
        
        if stepsNeeded <= 2000 {
            actionSteps = min(stepsNeeded, 2000)
            actionText = "Take a 20-minute walk"
        } else if stepsNeeded <= 4000 {
            actionSteps = min(stepsNeeded, 3000)
            actionText = "Take a 30-minute walk"
        } else {
            actionSteps = 4000
            actionText = "Take a 40-minute walk"
        }
        
        // Calculate actual benefit of this action
        let newSteps = currentSteps + actionSteps
        let newImpact = calculateStepsImpact(steps: newSteps)
        let incrementalBenefit = newImpact - currentImpact
        
        let formattedBenefit = formatBenefit(incrementalBenefit, period: period)
        
        switch period {
        case .day:
            return "\(actionText) today to add \(formattedBenefit)"
        case .month:
            return "\(actionText) daily this month to add \(formattedBenefit)"
        case .year:
            return "\(actionText) daily this year to add \(formattedBenefit)"
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
        let tempMetric = HealthMetric(
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
        
        let actionMinutes = min(minutesNeeded, 30) // Realistic 30-minute action
        let newMinutes = currentMinutes + actionMinutes
        let newImpact = calculateExerciseImpact(minutes: newMinutes)
        let incrementalBenefit = newImpact - currentImpact
        
        let formattedBenefit = formatBenefit(incrementalBenefit, period: period)
        
        switch period {
        case .day:
            return "Exercise \(Int(actionMinutes)) minutes today to add \(formattedBenefit)"
        case .month:
            return "Exercise \(Int(actionMinutes)) minutes daily this month to add \(formattedBenefit)"
        case .year:
            return "Exercise \(Int(actionMinutes)) minutes daily this year to add \(formattedBenefit)"
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
        
        let formattedBenefit = formatBenefit(incrementalBenefit, period: period)
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(benefit, period: period)
        
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
        let formattedBenefit = formatBenefit(twentyPercentIncrease, period: period)
        
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
    
    // MARK: - Helper Methods
    
    private func calculateNeutralBenefit(for metric: HealthMetric) -> Double {
        // Return the benefit of bringing the metric to neutral (0 impact)
        let currentImpact = metric.impactDetails?.lifespanImpactMinutes ?? 0
        return abs(min(0, currentImpact)) // Only for negative impacts
    }
    
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