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
        let primaryStudy = studies.first ?? StudyReferenceProvider.cardiovascularResearch[0]
        
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
        let reference = 60.0  // Reference point from playbook
        
        // Linear risk: +16% per 10 bpm > 60
        let bpmDifference = bpm - reference
        let relativeRisk = 1.0 + (bpmDifference / 10.0) * 0.16
        
        // Convert relative risk to daily life minutes using playbook formula
        let riskReduction = 1.0 - relativeRisk
        let impactScaling = 0.04  // Scaling factor from playbook
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
        let primaryStudy = studies.first ?? StudyReferenceProvider.sleepResearch[0]
        
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
        let reference = 40.0  // Reference point from playbook
        
        // Calculate deviation from reference
        let hrvDifference = hrv - reference
        
        // Clamp to plateau at ±70 ms
        let clampedDifference = max(-70.0, min(hrvDifference, 70.0))
        
        // Direct calculation: ±17.4 min per 10 ms deviation
        let dailyImpact = (clampedDifference / 10.0) * 17.4
        
        logger.info("📊 HRV impact: \(String(format: "%.1f", hrv)) ms → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
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
}
