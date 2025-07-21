import Foundation
import OSLog

/// Calculates life impact for physical activity metrics using peer-reviewed research
/// All calculations are based on published meta-analyses and prospective cohort studies
class ActivityImpactCalculator {
    private let logger = Logger(subsystem: "Amped", category: "ActivityImpactCalculator")
    
    // MARK: - Global Constants (from Playbook)
    private let baselineLifeMinutes = 78.0 * 365.25 * 24 * 60  // 78 years in minutes
    
    // MARK: - Steps Impact Calculation
    
    /// Calculate steps impact using J-shaped logarithmic model from playbook
    /// Based on Saint-Maurice et al. (2020) JAMA, Paluch et al. (2022) Lancet Public Health
    func calculateStepsImpact(steps: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🚶 Calculating steps impact for \(Int(steps)) steps using J-shaped model")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .steps, userProfile: userProfile)
        let primaryStudy = studies.first ?? StudyReferenceProvider.stepsResearch[0]
        
        // Calculate impact using exact playbook J-shaped model
        let dailyImpactMinutes = calculateStepsLifeImpact(
            currentSteps: steps,
            userProfile: userProfile
        )
        
        // Generate evidence-based recommendation
        let recommendation = generateStepsRecommendation(currentSteps: steps)
        
        return MetricImpactDetail(
            metricType: .steps,
            currentValue: steps,
            baselineValue: 10000.0, // Optimal from playbook
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .interpolatedDoseResponse,
            recommendation: recommendation
        )
    }
    
    /// Research-based steps life impact calculation using exact J-shaped model from playbook
    /// All values match the playbook table exactly
    private func calculateStepsLifeImpact(
        currentSteps: Double,
        userProfile: UserProfile
    ) -> Double {
        let steps = max(0, currentSteps)
        
        let relativeRisk: Double
        
        if steps < 2700 {
            relativeRisk = 1.6 - 0.2 * (steps / 2700)
        } else if steps < 4000 {
            relativeRisk = 1.4 - 0.1 * ((steps - 2700) / (4000 - 2700))
        } else if steps <= 10000 {
            let ratio = (steps - 4000) / (10000 - 4000)
            relativeRisk = 1.3 - 0.35 * log(1 + ratio * (exp(1) - 1))
        } else if steps <= 12000 {
            relativeRisk = 0.95 - 0.05 * ((steps - 10000) / 2000)
        } else if steps <= 20000 {
            relativeRisk = 0.90 + 0.03 * ((steps - 12000) / 8000)
        } else if steps <= 25000 {
            relativeRisk = 0.93 + 0.07 * ((steps - 20000) / 5000)
        } else {
            relativeRisk = 1.00 + 0.15 * min((steps - 25000) / 10000, 1)
        }
        
        // Convert relative risk to daily life minutes using playbook formula
        let riskReduction = 1.0 - relativeRisk
        let impactScaling = 0.082  // 3.2 y gain for 50% RR reduction
        let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
        
        // Convert to daily impact
        let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
        let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
        
        logger.info("📊 Steps impact: \(Int(steps)) steps → \(String(format: "%.1f", dailyImpact)) minutes/day (RR: \(String(format: "%.3f", relativeRisk)))")
        
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
    
    /// Research-based exercise life impact using exact playbook formula
    /// Based on meta-analysis showing 23% mortality reduction for meeting guidelines
    private func calculateExerciseLifeImpact(
        weeklyMinutes: Double,
        optimalWeekly: Double,
        userProfile: UserProfile
    ) -> Double {
        let wkMin = max(0, weeklyMinutes)
        
        // Exact formula from playbook
        let relativeRisk: Double
        
        if wkMin <= 0 {
            relativeRisk = 1.0
        } else if wkMin <= 150 {
            relativeRisk = 1 - 0.23 * log(1 + wkMin/150 * (exp(1) - 1))
        } else if wkMin <= 300 {
            relativeRisk = 0.77 - 0.12 * ((wkMin - 150) / 150)
        } else {
            relativeRisk = 0.65 - 0.05 * min((wkMin - 300) / 300, 1)
        }
        
        // Convert relative risk to daily life minutes using playbook formula
        let riskReduction = 1.0 - relativeRisk
        let impactScaling = 0.126  // 3.4 y gain for 35% RR reduction
        let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
        
        // Convert to daily impact
        let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
        let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
        
        logger.info("📊 Exercise impact: \(String(format: "%.1f", wkMin)) min/week → \(String(format: "%.1f", dailyImpact)) minutes/day (RR: \(String(format: "%.3f", relativeRisk)))")
        
        return dailyImpact
    }
    
    // MARK: - Active Energy Burned Impact Calculation
    
    /// Calculate active energy impact using exact playbook formula
    /// Reference 400 kcal = 0 impact. ±17.4 min per 100 kcal deviation, clamped ±900 kcal
    func calculateActiveEnergyImpact(activeEnergyBurned: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🔥 Calculating active energy impact for \(Int(activeEnergyBurned)) kcal using exact playbook formula")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .activeEnergyBurned, userProfile: userProfile)
        
        let dailyImpactMinutes = calculateActiveEnergyLifeImpact(
            activeEnergy: activeEnergyBurned,
            userProfile: userProfile
        )
        
        let recommendation = generateActiveEnergyRecommendation(currentEnergy: activeEnergyBurned)
        
        return MetricImpactDetail(
            metricType: .activeEnergyBurned,
            currentValue: activeEnergyBurned,
            baselineValue: 400.0, // Reference from playbook
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .expertConsensus,
            recommendation: recommendation
        )
    }
    
    /// Active energy life impact using exact playbook formula
    /// Reference 400 kcal = 0 impact. ±17.4 min per 100 kcal deviation, clamped ±900 kcal
    private func calculateActiveEnergyLifeImpact(activeEnergy: Double, userProfile: UserProfile) -> Double {
        let energy = max(0, min(activeEnergy, 1300))  // Reasonable bounds (0 to 1300 kcal)
        let reference = 400.0  // Reference point from playbook
        
        // Calculate deviation from reference
        let energyDifference = energy - reference
        
        // Clamp to ±900 kcal as specified in playbook
        let clampedDifference = max(-900.0, min(energyDifference, 900.0))
        
        // Direct calculation: ±17.4 min per 100 kcal deviation
        let dailyImpact = (clampedDifference / 100.0) * 17.4
        
        logger.info("📊 Active Energy impact: \(String(format: "%.0f", energy)) kcal → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    // MARK: - Body Mass Impact Calculation
    
    /// Calculate body mass impact using exact playbook formula
    /// Reference 160 lbs (≈24.5 BMI). ±17.4 min impact every ±20 lbs (linear)
    func calculateBodyMassImpact(bodyMass: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("⚖️ Calculating body mass impact for \(String(format: "%.1f", bodyMass)) lbs using exact playbook formula")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .bodyMass, userProfile: userProfile)
        
        let dailyImpactMinutes = calculateBodyMassLifeImpact(
            bodyMass: bodyMass,
            userProfile: userProfile
        )
        
        let recommendation = generateBodyMassRecommendation(currentMass: bodyMass)
        
        return MetricImpactDetail(
            metricType: .bodyMass,
            currentValue: bodyMass,
            baselineValue: 160.0, // Reference from playbook (≈24.5 BMI)
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .expertConsensus,
            recommendation: recommendation
        )
    }
    
    /// Body mass life impact using exact playbook formula
    /// Reference 160 lbs (≈24.5 BMI). ±17.4 min impact every ±20 lbs (linear)
    private func calculateBodyMassLifeImpact(bodyMass: Double, userProfile: UserProfile) -> Double {
        let mass = max(80, min(bodyMass, 400))  // Reasonable bounds (80 to 400 lbs)
        let reference = 160.0  // Reference point from playbook (≈24.5 BMI)
        
        // Calculate deviation from reference
        let massDifference = mass - reference
        
        // Direct calculation: ±17.4 min impact every ±20 lbs (linear)
        let dailyImpact = (massDifference / 20.0) * 17.4
        
        logger.info("📊 Body Mass impact: \(String(format: "%.1f", mass)) lbs → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    // MARK: - VO2 Max Impact Calculation
    
    /// Calculate VO2 Max impact using exact playbook formula
    /// Reference 40. ±21.8 min per ±5 ml difference, capped ±60→±87 min
    func calculateVO2MaxImpact(vo2Max: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🫁 Calculating VO2 Max impact for \(String(format: "%.1f", vo2Max)) ml·kg⁻¹·min⁻¹ using exact playbook formula")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .vo2Max, userProfile: userProfile)
        
        let dailyImpactMinutes = calculateVO2MaxLifeImpact(
            vo2Max: vo2Max,
            userProfile: userProfile
        )
        
        let recommendation = generateVO2MaxRecommendation(currentVO2Max: vo2Max)
        
        return MetricImpactDetail(
            metricType: .vo2Max,
            currentValue: vo2Max,
            baselineValue: 40.0, // Reference from playbook
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .expertConsensus,
            recommendation: recommendation
        )
    }
    
    /// VO2 Max life impact using exact playbook formula
    /// Reference 40. ±21.8 min per ±5 ml difference, capped ±60→±87 min
    private func calculateVO2MaxLifeImpact(vo2Max: Double, userProfile: UserProfile) -> Double {
        let vo2 = max(15, min(vo2Max, 80))  // Reasonable bounds (15 to 80 ml·kg⁻¹·min⁻¹)
        let reference = 40.0  // Reference point from playbook
        
        // Calculate deviation from reference
        let vo2Difference = vo2 - reference
        
        // Clamp to ±60→±87 min as specified in playbook
        let clampedDifference = max(-20.0, min(vo2Difference, 20.0))  // ±20 gives ±87 min
        
        // Direct calculation: ±21.8 min per ±5 ml difference
        let dailyImpact = (clampedDifference / 5.0) * 21.8
        
        logger.info("📊 VO2 Max impact: \(String(format: "%.1f", vo2)) ml·kg⁻¹·min⁻¹ → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    // MARK: - Oxygen Saturation Impact Calculation
    
    /// Calculate oxygen saturation impact using exact playbook formula
    /// Reference 98%. ±8.7 min per ±2% deviation below or above
    func calculateOxygenSaturationImpact(oxygenSaturation: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🫁 Calculating oxygen saturation impact for \(String(format: "%.1f", oxygenSaturation))% using exact playbook formula")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .oxygenSaturation, userProfile: userProfile)
        
        let dailyImpactMinutes = calculateOxygenSaturationLifeImpact(
            oxygenSaturation: oxygenSaturation,
            userProfile: userProfile
        )
        
        let recommendation = generateOxygenSaturationRecommendation(currentSaturation: oxygenSaturation)
        
        return MetricImpactDetail(
            metricType: .oxygenSaturation,
            currentValue: oxygenSaturation,
            baselineValue: 98.0, // Reference from playbook
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .expertConsensus,
            recommendation: recommendation
        )
    }
    
    /// Oxygen saturation life impact using exact playbook formula
    /// Reference 98%. ±8.7 min per ±2% deviation below or above
    private func calculateOxygenSaturationLifeImpact(oxygenSaturation: Double, userProfile: UserProfile) -> Double {
        let saturation = max(80, min(oxygenSaturation, 100))  // Reasonable bounds (80% to 100%)
        let reference = 98.0  // Reference point from playbook
        
        // Calculate deviation from reference
        let saturationDifference = saturation - reference
        
        // Direct calculation: ±8.7 min per ±2% deviation
        let dailyImpact = (saturationDifference / 2.0) * 8.7
        
        logger.info("📊 Oxygen Saturation impact: \(String(format: "%.1f", saturation))% → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    // MARK: - Recommendation Generation
    
    private func generateStepsRecommendation(currentSteps: Double) -> String {
        let optimalSteps = 10000.0
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
    
    private func generateActiveEnergyRecommendation(currentEnergy: Double) -> String {
        let reference = 400.0
        if currentEnergy >= reference + 200 {
            return "Excellent active energy burn! Maintain this level for optimal health benefits."
        } else if currentEnergy >= reference {
            return "Good active energy level. Consider increasing intensity or duration of activities for additional benefits."
        } else {
            let deficit = Int(reference - currentEnergy)
            return "Aim to burn \(deficit) more calories daily through increased physical activity."
        }
    }
    
    private func generateBodyMassRecommendation(currentMass: Double) -> String {
        let reference = 160.0
        let healthyRange = 140.0...180.0
        
        if healthyRange.contains(currentMass) {
            return "Your body mass is in a healthy range. Maintain through balanced nutrition and regular exercise."
        } else if currentMass > healthyRange.upperBound {
            return "Consider gradual weight loss through caloric reduction and increased physical activity. Consult a healthcare provider for personalized guidance."
        } else {
            return "Consider gradual weight gain through increased caloric intake and strength training. Consult a healthcare provider if underweight concerns persist."
        }
    }
    
    private func generateVO2MaxRecommendation(currentVO2Max: Double) -> String {
        let reference = 40.0
        if currentVO2Max >= reference + 10 {
            return "Excellent cardiovascular fitness! Maintain with regular high-intensity exercise."
        } else if currentVO2Max >= reference {
            return "Good cardiovascular fitness. Consider adding interval training to improve further."
        } else {
            return "Focus on improving cardiovascular fitness through regular aerobic exercise and interval training."
        }
    }
    
    private func generateOxygenSaturationRecommendation(currentSaturation: Double) -> String {
        let reference = 98.0
        if currentSaturation >= reference {
            return "Excellent oxygen saturation. Continue maintaining good respiratory health."
        } else if currentSaturation >= 95.0 {
            return "Good oxygen saturation. Practice deep breathing exercises to optimize respiratory function."
        } else {
            return "Low oxygen saturation detected. Consider consulting a healthcare provider, especially if persistent."
        }
    }
}
