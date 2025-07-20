import Foundation
import OSLog

/// Calculates life impact for physical activity metrics using peer-reviewed research
/// All calculations are based on published meta-analyses and prospective cohort studies
class ActivityImpactCalculator {
    private let logger = Logger(subsystem: "Amped", category: "ActivityImpactCalculator")
    
    // MARK: - Steps Impact Calculation
    
    /// Calculate steps impact using research-based J-shaped dose-response curve
    /// Based on Saint-Maurice et al. (2020) JAMA, Paluch et al. (2022) Lancet Public Health, 
    /// Lee et al. (2019) JAMA Internal Medicine, and overuse injury research
    func calculateStepsImpact(steps: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🚶 Calculating steps impact for \(Int(steps)) steps using research-based formula")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .steps, userProfile: userProfile)
        let primaryStudy = studies.first ?? StudyReferenceProvider.stepsResearch[0]
        
        // Research-based optimal range: 8,000-12,000 steps per day
        let optimalSteps = 10000.0
        let minimumBenefit = 4000.0  // From Saint-Maurice study
        let maximumBenefit = 12000.0 // Point of diminishing returns
        
        // Calculate impact using research-derived logarithmic model
        let dailyImpactMinutes = calculateStepsLifeImpact(
            currentSteps: steps,
            optimalSteps: optimalSteps,
            minimumBenefit: minimumBenefit,
            maximumBenefit: maximumBenefit,
            userProfile: userProfile
        )
        
        // Generate evidence-based recommendation
        let recommendation = generateStepsRecommendation(currentSteps: steps, optimalSteps: optimalSteps)
        
        return MetricImpactDetail(
            metricType: .steps,
            currentValue: steps,
            baselineValue: optimalSteps,
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .interpolatedDoseResponse,
            recommendation: recommendation
        )
    }
    
    /// Research-based steps life impact calculation using J-shaped dose-response
    /// Based on meta-analysis findings showing non-linear benefits and overuse risks
    private func calculateStepsLifeImpact(
        currentSteps: Double,
        optimalSteps: Double,
        minimumBenefit: Double,
        maximumBenefit: Double,
        userProfile: UserProfile
    ) -> Double {
        // Enhanced algorithm based on Saint-Maurice et al. 2020 + overuse injury research
        // J-shaped curve: benefits plateau then decline due to overuse risks
        let clampedSteps = max(500, min(currentSteps, 35000)) // Extended range for realistic calculation
        
        let relativeRisk: Double
        if clampedSteps < 2700 {
            // Very sedentary (below Lee et al. 2019 minimum): Severe risk with gradient
            let sedentaryRatio = clampedSteps / 2700.0
            relativeRisk = 1.6 - (0.2 * sedentaryRatio) // 60% risk decreasing to 40% as steps increase
        } else if clampedSteps < minimumBenefit {
            // Low activity (2700-4000): Moderate risk with gradient improvement
            let lowActivityRatio = (clampedSteps - 2700) / (minimumBenefit - 2700)
            relativeRisk = 1.4 - (0.1 * lowActivityRatio) // 40% risk decreasing to 30% 
        } else if clampedSteps <= optimalSteps {
            // Improvement zone (4000-10000): Logarithmic benefits
            let stepRatio = (clampedSteps - minimumBenefit) / (optimalSteps - minimumBenefit)
            relativeRisk = 1.3 - (0.35 * log(1 + stepRatio * (exp(1) - 1))) // Optimized curve
        } else if clampedSteps <= maximumBenefit {
            // Optimal zone (10000-12000): Peak benefits with diminishing returns
            let additionalRatio = (clampedSteps - optimalSteps) / (maximumBenefit - optimalSteps)
            relativeRisk = 0.95 - (0.05 * additionalRatio) // Small additional benefit to 0.90
        } else if clampedSteps <= 20000 {
            // High activity (12000-20000): Plateaued benefits, emerging injury risk
            let highActivityRatio = (clampedSteps - maximumBenefit) / (20000 - maximumBenefit)
            let injuryRiskPenalty = highActivityRatio * 0.03 // 3% risk increase due to overuse
            relativeRisk = 0.90 + injuryRiskPenalty // Benefits maintained but injury risk grows
        } else if clampedSteps <= 25000 {
            // Very high activity (20000-25000): Net benefits decline due to overuse
            let veryHighRatio = (clampedSteps - 20000) / 5000.0
            relativeRisk = 0.93 + (veryHighRatio * 0.07) // Injury risks outweigh benefits
        } else {
            // Extreme activity (25000+): Net negative due to overuse injuries and stress
            let extremeExcess = min((clampedSteps - 25000) / 10000.0, 1.0) // Cap at 100% excess
            relativeRisk = 1.00 + (extremeExcess * 0.15) // Net harmful: up to 15% increased risk
        }
        
        // Convert relative risk to daily life minutes using research-derived conversion
        // Based on Saint-Maurice et al. (2020): 50% mortality reduction = 3.2 years gained
        let baselineLifeExpectancy = 78.0 * 365.25 * 24 * 60 // Average life expectancy in minutes
        let riskReduction = 1.0 - relativeRisk
        let totalLifeMinutesGained = baselineLifeExpectancy * riskReduction * 0.082 // Research-aligned scaling: 3.2 years for 50% risk reduction
        
        // Convert to daily impact (spread over expected remaining lifespan)
        let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
        let dailyImpact = totalLifeMinutesGained / (remainingYears * 365.25)
        
        logger.info("📊 Steps impact: \(Int(currentSteps)) steps → \(String(format: "%.1f", dailyImpact)) minutes/day (RR: \(String(format: "%.2f", relativeRisk)))")
        
        return dailyImpact
    }
    
    // MARK: - Exercise Minutes Impact Calculation
    
    /// Calculate exercise impact using WHO guidelines and meta-analysis data
    /// Based on Zhao et al. (2020) Circulation Research meta-analysis
    func calculateExerciseImpact(exerciseMinutes: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🏃 Calculating exercise impact for \(Int(exerciseMinutes)) minutes using research-based formula")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .exerciseMinutes, userProfile: userProfile)
        let primaryStudy = studies.first ?? StudyReferenceProvider.exerciseResearch[0]
        
        // Research-based guidelines: 150 minutes moderate exercise per week
        let weeklyOptimal = 150.0
        let dailyOptimal = weeklyOptimal / 7.0 // ~21.4 minutes per day
        
        // Calculate weekly exercise from daily average
        let weeklyExercise = exerciseMinutes * 7.0
        
        // Calculate impact using research-derived dose-response model
        let dailyImpactMinutes = calculateExerciseLifeImpact(
            weeklyMinutes: weeklyExercise,
            optimalWeekly: weeklyOptimal,
            userProfile: userProfile
        )
        
        let recommendation = generateExerciseRecommendation(
            currentDaily: exerciseMinutes,
            optimalDaily: dailyOptimal
        )
        
        return MetricImpactDetail(
            metricType: .exerciseMinutes,
            currentValue: exerciseMinutes,
            baselineValue: dailyOptimal,
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .metaAnalysisSynthesis,
            recommendation: recommendation
        )
    }
    
    /// Research-based exercise life impact using logarithmic dose-response
    /// Based on meta-analysis showing 23% mortality reduction for meeting guidelines
    private func calculateExerciseLifeImpact(
        weeklyMinutes: Double,
        optimalWeekly: Double,
        userProfile: UserProfile
    ) -> Double {
        let effectiveMinutes = max(0, min(weeklyMinutes, 600)) // Research range: 0-600 min/week
        
        // Research findings from meta-analysis:
        // - 0 min/week: Baseline mortality risk
        // - 150 min/week: 23% mortality reduction
        // - 300 min/week: ~35% mortality reduction (diminishing returns)
        
        let relativeRisk: Double
        
        if effectiveMinutes <= 0 {
            relativeRisk = 1.0 // Sedentary baseline
        } else if effectiveMinutes <= optimalWeekly {
            // 0-150 min/week: Steep logarithmic benefits
            let benefitFactor = effectiveMinutes / optimalWeekly
            let logarithmicFactor = log(1 + benefitFactor * (exp(1) - 1))
            relativeRisk = 1.0 - (0.23 * logarithmicFactor) // Up to 23% reduction
        } else if effectiveMinutes <= 300 {
            // 150-300 min/week: Diminishing returns
            let additionalFactor = (effectiveMinutes - optimalWeekly) / (300 - optimalWeekly)
            relativeRisk = 0.77 - (0.12 * additionalFactor) // Additional 12% reduction
        } else {
            // Above 300 min/week: Plateau with possible small additional benefits
            let excessFactor = min(1.0, (effectiveMinutes - 300) / 300)
            relativeRisk = 0.65 - (0.05 * excessFactor) // Small additional benefit
        }
        
        // Convert to daily life minutes using research-derived conversion
        // Based on Zhao et al. (2020): 35% max mortality reduction = 3.4 years gained
        let baselineLifeExpectancy = 78.0 * 365.25 * 24 * 60
        let riskReduction = 1.0 - relativeRisk
        let totalLifeMinutesGained = baselineLifeExpectancy * riskReduction * 0.126 // Research-aligned scaling: 3.4 years for 35% risk reduction
        
        // Convert to daily impact
        let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
        let dailyImpact = totalLifeMinutesGained / (remainingYears * 365.25)
        
        return dailyImpact
    }
    
    // MARK: - Recommendation Generation
    
    private func generateStepsRecommendation(currentSteps: Double, optimalSteps: Double) -> String {        
        if currentSteps >= 25000 {
            return "⚠️ Very high activity level detected. Consider reducing to 15,000-20,000 steps to prevent overuse injuries while maintaining health benefits."
        } else if currentSteps >= 20000 {
            return "High activity level! You're getting great benefits, but consider injury prevention. Stay hydrated and listen to your body."
        } else if currentSteps >= 12000 {
            return "Excellent! You're at optimal step levels. Maintain this activity level for maximum health benefits."
        } else if currentSteps >= 8000 {
            return "Great job! You're in a healthy range. Try to reach \(Int(optimalSteps)) steps for maximum benefits."
        } else if currentSteps >= 4000 {
            let difference = optimalSteps - currentSteps
            return "Good progress! Aim for \(Int(difference)) more steps daily to reach the optimal \(Int(optimalSteps)) steps."
        } else if currentSteps >= 2700 {
            return "You're making progress from a sedentary baseline. Try adding 500-1000 steps daily towards \(Int(optimalSteps)) steps."
        } else {
            return "Start small with short 5-10 minute walks. Gradually build towards 4,000 steps daily, then work up to \(Int(optimalSteps)) steps."
        }
    }
    
    private func generateExerciseRecommendation(currentDaily: Double, optimalDaily: Double) -> String {
        let currentWeekly = currentDaily * 7
        let optimalWeekly = optimalDaily * 7
        
        if currentWeekly >= 300 {
            return "Outstanding! You exceed WHO guidelines. Maintain this excellent exercise routine."
        } else if currentWeekly >= 150 {
            return "Perfect! You meet WHO guidelines for physical activity. Consider gradually increasing for additional benefits."
        } else if currentWeekly >= 75 {
            return "Good progress! Aim for \(Int(150 - currentWeekly)) more minutes weekly to meet WHO guidelines."
        } else {
            return "Start gradually with 10-15 minutes daily. Build towards 150 minutes of moderate exercise per week."
        }
    }
} 