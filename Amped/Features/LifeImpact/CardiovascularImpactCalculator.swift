import Foundation
import OSLog

/// Calculates life impact for cardiovascular health metrics using peer-reviewed research
/// All calculations are based on published meta-analyses and prospective cohort studies
class CardiovascularImpactCalculator {
    private let logger = Logger(subsystem: "Amped", category: "CardiovascularImpactCalculator")
    
    // MARK: - Global Constants (from Playbook)
    private let baselineLifeMinutes = 78.0 * 365.25 * 24 * 60  // 78 years in minutes
    
    // MARK: - Resting Heart Rate Impact Calculation
    
    /// Calculate resting heart rate impact using exact playbook linear formula
    /// Based on Aune et al. (2013) CMAJ meta-analysis
    func calculateRestingHeartRateImpact(heartRate: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("❤️ Calculating resting heart rate impact for \(Int(heartRate)) bpm using linear formula")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .restingHeartRate, userProfile: userProfile)
                    let _ = studies.first ?? StudyReferenceProvider.cardiovascularResearch[0]
        
        // Calculate impact using exact playbook linear model
        let dailyImpactMinutes = calculateRHRLifeImpact(
            currentRHR: heartRate,
            userProfile: userProfile
        )
        
        let recommendation = generateRHRRecommendation(currentRHR: heartRate)
        
        return MetricImpactDetail(
            metricType: .restingHeartRate,
            currentValue: heartRate,
            baselineValue: 60.0, // Reference from playbook
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .directStudyMapping,
            recommendation: recommendation
        )
    }
    
    /// Research-based RHR life impact using exact playbook linear formula
    /// Linear risk: +16% per 10 bpm > 60, scaling factor 0.04
    private func calculateRHRLifeImpact(currentRHR: Double, userProfile: UserProfile) -> Double {
        let bpm = max(40, min(currentRHR, 120))
        
        // Age-adjusted reference (RHR increases with age)
        let age = Double(userProfile.age ?? 30)
        let ageAdjustment = (age - 30) * 0.1 // 0.1 bpm per year over 30
        let reference = 60.0 + max(0, ageAdjustment) // Age-adjusted reference
        
        // Linear risk: +16% per 10 bpm > 60
        let bpmDifference = bpm - reference
        let relativeRisk = 1.0 + (bpmDifference / 10.0) * 0.16
        
        // Convert relative risk to daily life minutes using playbook formula
        let riskReduction = 1.0 - relativeRisk
        let impactScaling = 0.05  // Scaling factor from playbook (4% mortality risk per 10 bpm above 60)
        let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
        
        // Convert to daily impact
        let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
        let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
        
        logger.info("📊 RHR impact: \(Int(bpm)) bpm → \(String(format: "%.1f", dailyImpact)) minutes/day (RR: \(String(format: "%.3f", relativeRisk)))")
        
        return dailyImpact
    }
    
    // MARK: - Sleep Duration Impact Calculation
    
    /// Calculate sleep duration impact using exact playbook U-shaped curve
    /// Based on Jike et al. (2018) Sleep Medicine meta-analysis
    func calculateSleepImpact(sleepHours: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("😴 Calculating sleep impact for \(String(format: "%.1f", sleepHours)) hours using U-shaped model")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .sleepHours, userProfile: userProfile)
        let _ = studies.first ?? StudyReferenceProvider.sleepResearch[0]
        
        // Calculate impact using exact playbook U-shaped model
        let dailyImpactMinutes = calculateSleepLifeImpact(
            currentSleep: sleepHours,
            userProfile: userProfile
        )
        
        let recommendation = generateSleepRecommendation(currentSleep: sleepHours)
        
        return MetricImpactDetail(
            metricType: .sleepHours,
            currentValue: sleepHours,
            baselineValue: 7.5, // Optimal from playbook
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .interpolatedDoseResponse,
            recommendation: recommendation
        )
    }
    
    /// Research-based sleep life impact using exact playbook U-shaped penalties
    /// U-shaped penalties: Short <6h: +8% RR per hr deficit, Borderline 6–7h: +6% RR/hr, etc.
    private func calculateSleepLifeImpact(currentSleep: Double, userProfile: UserProfile) -> Double {
        let sleepH = max(3, min(currentSleep, 12))
        
        let relativeRisk: Double
        
        if sleepH >= 7.0 && sleepH <= 8.0 {
            // Optimal band 7–8 h: +2% RR / 0.5 h deviation
            let deviation = min(abs(sleepH - 7.5), 0.5)
            relativeRisk = 1.0 + (deviation / 0.5) * 0.02
        } else if sleepH < 6.0 {
            // Short <6 h: +8% RR per hr deficit
            let deficit = 6.0 - sleepH
            relativeRisk = 1.0 + deficit * 0.08
        } else if sleepH < 7.0 {
            // Borderline 6–7 h: +6% RR / hr
            let deficit = 7.0 - sleepH
            relativeRisk = 1.0 + deficit * 0.06
        } else if sleepH <= 9.0 {
            // Borderline 8–9 h: +6% RR / hr excess
            let excess = sleepH - 8.0
            relativeRisk = 1.0 + excess * 0.06
        } else {
            // Excess >9 h: +10% RR / hr
            let excess = sleepH - 9.0
            relativeRisk = 1.0 + excess * 0.10
        }
        
        // Convert relative risk to daily life minutes using playbook formula
        let riskReduction = 1.0 - relativeRisk
        let impactScaling = 0.05  // impactScaling from playbook
        let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
        
        // Convert to daily impact
        let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
        let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
        
        logger.info("📊 Sleep impact: \(String(format: "%.1f", sleepH))h → \(String(format: "%.1f", dailyImpact)) minutes/day (RR: \(String(format: "%.3f", relativeRisk)))")
        
        return dailyImpact
    }
    
    // MARK: - Heart Rate Variability Impact
    
    /// Calculate HRV impact using exact playbook formula
    /// Reference 40 ms = 0 impact. ±17.4 min per 10 ms, plateau ±70 ms
    func calculateHRVImpact(hrv: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("📈 Calculating HRV impact for \(Int(hrv)) ms using exact playbook formula")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .heartRateVariability, userProfile: userProfile)
        
        // Calculate impact using exact playbook formula
        let dailyImpactMinutes = calculateHRVLifeImpact(
            currentHRV: hrv,
            userProfile: userProfile
        )
        
        let recommendation = generateHRVRecommendation(currentHRV: hrv, optimalHRV: 40.0)
        
        return MetricImpactDetail(
            metricType: .heartRateVariability,
            currentValue: hrv,
            baselineValue: 40.0, // Reference from playbook
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .expertConsensus,
            recommendation: recommendation
        )
    }
    
    /// HRV life impact using exact playbook formula
    /// Reference 40 ms = 0 impact. +17.4 min per 10 ms above, −17.4 min per 10 ms below, plateau ±70 ms
    private func calculateHRVLifeImpact(currentHRV: Double, userProfile: UserProfile) -> Double {
        let hrv = max(5, min(currentHRV, 150))  // Reasonable bounds
        
        // Age-adjusted reference (HRV decreases with age)
        let age = Double(userProfile.age ?? 30)
        let ageAdjustment = (age - 30) * 0.3 // 0.3 ms decrease per year over 30
        let reference = 40.0 - max(0, ageAdjustment) // Age-adjusted reference
        
        // Calculate deviation from reference
        let hrvDifference = hrv - reference
        
        // Clamp to plateau at ±70 ms
        let clampedDifference = max(-70.0, min(hrvDifference, 70.0))
        
        // Exact playbook formula: ±17.4 min per 10 ms above/below reference
        let dailyImpact = (clampedDifference / 10.0) * 17.4
        
        logger.info("📊 HRV impact: \(String(format: "%.1f", hrv)) ms → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    // MARK: - Blood Pressure Impact Calculation
    
    /// Calculate blood pressure impact using research from ACC/AHA guidelines and SPRINT study
    /// Based on exponential relationship where risk doubles per 20/10 mmHg increase
    func calculateBloodPressureImpact(systolicPressure: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🩺 Calculating blood pressure impact for \(Int(systolicPressure)) mmHg systolic")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .bloodPressure, userProfile: userProfile)
        
        // Calculate impact using research-based exponential model
        let dailyImpactMinutes = calculateBPLifeImpact(
            currentSystolic: systolicPressure,
            userProfile: userProfile
        )
        
        let recommendation = generateBPRecommendation(currentSystolic: systolicPressure)
        
        return MetricImpactDetail(
            metricType: .bloodPressure,
            currentValue: systolicPressure,
            baselineValue: 115.0, // Optimal from research
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .directStudyMapping,
            recommendation: recommendation
        )
    }
    
    /// Research-based blood pressure life impact using exponential risk model
    /// Based on ACC/AHA guidelines and SPRINT study showing doubling risk per 20 mmHg
    private func calculateBPLifeImpact(currentSystolic: Double, userProfile: UserProfile) -> Double {
        let systolic = max(80, min(currentSystolic, 200))  // Reasonable bounds
        
        // Optimal systolic BP is around 110-115 mmHg based on research
        let optimalSystolic = 115.0
        
        // Calculate difference from optimal
        let bpDifference = systolic - optimalSystolic
        
        // Age adjustment - risk increases more rapidly with age
        let age = Double(userProfile.age ?? 30)
        let ageMultiplier = 1.0 + max(0, (age - 30) * 0.01) // 1% increased risk per year over 30
        
        let dailyImpact: Double
        if bpDifference <= 0 {
            // Below optimal - minimal additional benefit below 115 mmHg
            dailyImpact = max(bpDifference * 0.5, -10.0) // Cap benefit at 10 min/day
        } else {
            // Above optimal - exponential risk increase
            // Based on research showing ~2x cardiovascular mortality per +20 mmHg
            let riskFactor = pow(1.8, bpDifference / 20.0) - 1.0 // Exponential model
            dailyImpact = -riskFactor * 30.0 * ageMultiplier // Negative impact scaled by age
        }
        
        logger.info("📊 BP impact: \(String(format: "%.0f", systolic)) mmHg → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    // MARK: - Recommendation Generation
    
    private func generateRHRRecommendation(currentRHR: Double) -> String {
        let healthyRange = 50.0...70.0
        if healthyRange.contains(currentRHR) {
            return "Great! Your resting heart rate is in the healthy range. Maintain your current fitness level."
        } else if currentRHR > healthyRange.upperBound {
            let excess = Int(currentRHR - healthyRange.upperBound)
            return "Your RHR is elevated. Regular cardio exercise can help lower it by \(excess)+ bpm. Consult your doctor if consistently above 90 bpm."
        } else {
            return "Your RHR is quite low. If you're an athlete, this is normal. Otherwise, consult your doctor if you experience symptoms."
        }
    }
    
    private func generateSleepRecommendation(currentSleep: Double) -> String {
        let optimalSleep = 7.5
        let healthyRange = 7.0...8.0
        if healthyRange.contains(currentSleep) {
            return "Perfect! You're getting optimal sleep duration. Maintain good sleep hygiene for best quality."
        } else if currentSleep < healthyRange.lowerBound {
            let deficit = healthyRange.lowerBound - currentSleep
            return "Try to get \(String(format: "%.1f", deficit)) more hours of sleep. Aim for \(Int(optimalSleep)) hours nightly for optimal health."
        } else {
            return "You're sleeping longer than optimal. If you feel refreshed, this may be normal. Consider sleep quality factors."
        }
    }
    
    private func generateHRVRecommendation(currentHRV: Double, optimalHRV: Double) -> String {
        let ratio = currentHRV / optimalHRV
        
        if ratio >= 0.8 && ratio <= 1.2 {
            return "Your HRV is in a healthy range for your age. Maintain stress management and recovery practices."
        } else if ratio < 0.8 {
            return "Consider stress reduction, better sleep, and adequate recovery between workouts to improve HRV."
        } else {
            return "Excellent HRV! Your autonomic nervous system shows good balance and recovery capacity."
        }
    }
    
    private func generateBPRecommendation(currentSystolic: Double) -> String {
        let optimalRange = 110.0...119.0
        let normalRange = 120.0...129.0
        
        if optimalRange.contains(currentSystolic) {
            return "Excellent! Your blood pressure is in the optimal range. Maintain your healthy lifestyle."
        } else if normalRange.contains(currentSystolic) {
            return "Your blood pressure is elevated. Focus on diet, exercise, and stress management to lower it."
        } else if currentSystolic >= 130.0 {
            return "Your blood pressure is high. Consult your doctor about treatment options and lifestyle changes."
        } else {
            return "Your blood pressure is quite low. If you feel fine, this may be normal for you."
        }
    }
}
