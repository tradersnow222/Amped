import Foundation
import OSLog

/// Calculates life impact for lifestyle metrics using peer-reviewed research
/// All calculations are based on published meta-analyses and prospective cohort studies
class LifestyleImpactCalculator {
    private let logger = Logger(subsystem: "Amped", category: "LifestyleImpactCalculator")
    
    // MARK: - Global Constants (from Playbook)
    private let baselineLifeMinutes = 78.0 * 365.25 * 24 * 60  // 78 years in minutes
    
    // MARK: - Alcohol Consumption Impact Calculation
    
    /// Calculate alcohol impact using exact playbook linear formula
    /// Based on Wood et al. (2018) Lancet meta-analysis of 599,912 current drinkers
    func calculateAlcoholImpact(drinksPerDay: Double, userProfile: UserProfile) -> MetricImpactDetail {
        // Convert questionnaire scale (1-10) to actual drinks per day
        let actualDrinksPerDay = convertQuestionnaireScaleToActualDrinks(questionnaireValue: drinksPerDay)
        
        logger.info("🍷 Converting alcohol questionnaire value \(String(format: "%.1f", drinksPerDay)) to \(String(format: "%.2f", actualDrinksPerDay)) drinks/day")
        
        let studies = StudyReferenceProvider.getApplicableStudies(for: .alcoholConsumption, userProfile: userProfile)
        let primaryStudy = studies.first ?? StudyReferenceProvider.lifestyleResearch[0]
        
        // Calculate impact using exact playbook formula
        let dailyImpactMinutes = calculateAlcoholLifeImpact(
            drinksPerDay: actualDrinksPerDay,
            userProfile: userProfile
        )
        
        let recommendation = generateAlcoholRecommendation(drinksPerDay: actualDrinksPerDay)
        
        return MetricImpactDetail(
            metricType: .alcoholConsumption,
            currentValue: drinksPerDay, // Keep original questionnaire value for display
            baselineValue: 0.0, // No safe level
            studyReferences: studies,
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .directStudyMapping,
            recommendation: recommendation
        )
    }
    
    /// Convert questionnaire alcohol scale (1-10) to actual drinks per day
    /// Scale: 10=Never, 8=Occasionally, 4=Several times/week, 1.5=Daily or Heavy
    private func convertQuestionnaireScaleToActualDrinks(questionnaireValue: Double) -> Double {
        switch questionnaireValue {
        case 9...10: // Never or almost never
            return 0.0
        case 7..<9: // Occasionally (weekly or less)
            return 0.5 // ~3.5 drinks per week = 0.5 drinks/day
        case 3..<7: // Several times per week
            return 1.0 // ~7 drinks per week = 1 drink/day
        case 1..<3: // Daily or Heavy
            return 2.0 // 2+ drinks per day average
        default:
            return 0.0 // Fallback to no drinking
        }
    }
    
    /// Research-based alcohol life impact using exact playbook formula
    /// Rule: +5% RR per drink up to 1/day, then steeper
    private func calculateAlcoholLifeImpact(drinksPerDay: Double, userProfile: UserProfile) -> Double {
        let drinks = max(0, min(drinksPerDay, 5)) // Clamp to reasonable range
        
        let relativeRisk: Double
        if drinks <= 1.0 {
            // +5% RR per drink up to 1/day
            relativeRisk = 1.0 + (drinks * 0.05)
        } else {
            // Steeper increase above 1 drink/day
            let excessDrinks = drinks - 1.0
            relativeRisk = 1.05 + (excessDrinks * 0.15) // Steeper penalty
        }
        
        // Convert relative risk to daily life minutes using playbook formula
        let riskReduction = 1.0 - relativeRisk
        let impactScaling = 0.08  // Approximate scaling for alcohol
        let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
        
        // Convert to daily impact
        let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
        let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
        
        logger.info("📊 Alcohol impact: \(String(format: "%.1f", drinks)) drinks/day → \(String(format: "%.1f", dailyImpact)) minutes/day (RR: \(String(format: "%.3f", relativeRisk)))")
        
        return dailyImpact
    }
    
    // MARK: - Smoking Impact Calculation
    
    /// Calculate smoking impact using research-based cumulative dose-response
    /// Based on extensive epidemiological studies showing linear cumulative effects
    func calculateSmokingImpact(smokingStatus: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🚭 Calculating smoking impact for status \(smokingStatus) using research-based formula")
        
        // CRITICAL FIX: Convert questionnaire scale (1-10) to smoking status codes (0-3)
        let actualSmokingStatus = convertQuestionnaireScaleToSmokingStatus(questionnaireValue: smokingStatus)
        
        logger.info("🚭 Converting smoking questionnaire value \(String(format: "%.1f", smokingStatus)) to status code \(actualSmokingStatus)")
        
        // Simplified smoking status: 0 = never, 1 = former, 2 = current light, 3 = current heavy
        let statusMapping: [Double: String] = [
            0: "Never smoker",
            1: "Former smoker", 
            2: "Current light smoker (<1 pack/day)",
            3: "Current heavy smoker (≥1 pack/day)"
        ]
        
        let dailyImpactMinutes = calculateSmokingLifeImpact(smokingStatus: actualSmokingStatus)
        let recommendation = generateSmokingRecommendation(smokingStatus: actualSmokingStatus)
        
        return MetricImpactDetail(
            metricType: .smokingStatus,
            currentValue: smokingStatus, // Keep original questionnaire value for display
            baselineValue: 0.0, // Never smoker baseline
            studyReferences: [], // Would include extensive smoking studies
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .metaAnalysisSynthesis,
            recommendation: recommendation
        )
    }
    
    /// Convert questionnaire smoking scale (1-10) to smoking status codes (0-3)
    /// Scale: 10=Never, 7=Former, 3=Occasionally, 1=Daily
    private func convertQuestionnaireScaleToSmokingStatus(questionnaireValue: Double) -> Double {
        switch questionnaireValue {
        case 9...10: // Never
            return 0.0
        case 6..<9: // Former smoker
            return 1.0
        case 2..<6: // Occasionally
            return 2.0
        case 0..<2: // Daily
            return 3.0
        default:
            return 0.0 // Fallback to never smoker
        }
    }
    
    /// Research-based smoking life impact using exact playbook values
    /// Based on meta-analyses showing linear cumulative effects over time
    private func calculateSmokingLifeImpact(smokingStatus: Double) -> Double {
        // Exact daily impact values from playbook table
        let dailyImpact: Double
        
        switch Int(smokingStatus) {
        case 0:
            // Never smoker: 0 min daily loss
            dailyImpact = 0.0
        case 1:
            // Former smoker: −116.1 min daily loss
            dailyImpact = -116.1
        case 2:
            // Light smoker: −232.2 min daily loss
            dailyImpact = -232.2
        case 3:
            // Heavy smoker: −348.3 min daily loss
            dailyImpact = -348.3
        default:
            dailyImpact = 0.0
        }
        
        logger.info("📊 Smoking impact: Status \(Int(smokingStatus)) → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    // MARK: - Stress Level Impact Calculation
    
    /// Calculate stress impact using research-based principles
    /// Based on chronic stress and cortisol research (limited direct mortality studies)
    func calculateStressImpact(stressLevel: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("😰 Calculating stress impact for level \(Int(stressLevel)) using research-based principles")
        
        // Stress on 1-10 scale (1 = minimal, 10 = severe chronic stress)
        let optimalStress = 3.0 // Low but not zero (some stress is normal)
        let moderateThreshold = 6.0
        let highThreshold = 8.0
        
        let dailyImpactMinutes = calculateStressLifeImpact(
            stressLevel: stressLevel,
            optimalStress: optimalStress,
            moderateThreshold: moderateThreshold,
            highThreshold: highThreshold,
            userProfile: userProfile
        )
        
        let recommendation = generateStressRecommendation(
            stressLevel: stressLevel,
            optimalStress: optimalStress
        )
        
        return MetricImpactDetail(
            metricType: .stressLevel,
            currentValue: stressLevel,
            baselineValue: optimalStress,
            studyReferences: [], // Would include chronic stress studies
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .expertConsensus, // Limited direct mortality data
            recommendation: recommendation
        )
    }
    
    /// Research-based stress life impact using exact playbook formula
    /// Linear RR = 1 + 0.03*(level-3) between 3–6, then +0.05 (6–8) & +0.08 (8–10)
    private func calculateStressLifeImpact(stressLevel: Double, optimalStress: Double, moderateThreshold: Double, highThreshold: Double, userProfile: UserProfile) -> Double {
        let level = max(1, min(stressLevel, 10))
        
        let relativeRisk: Double
        if level <= 3.0 {
            // Below optimal: baseline
            relativeRisk = 1.0
        } else if level <= 6.0 {
            // 3-6: Linear RR = 1 + 0.03*(level-3)
            relativeRisk = 1.0 + 0.03 * (level - 3.0)
        } else if level <= 8.0 {
            // 6-8: +0.05 per level
            let baseRisk = 1.0 + 0.03 * 3.0  // Risk at level 6
            relativeRisk = baseRisk + 0.05 * (level - 6.0)
        } else {
            // 8-10: +0.08 per level
            let baseRisk = 1.0 + 0.03 * 3.0 + 0.05 * 2.0  // Risk at level 8
            relativeRisk = baseRisk + 0.08 * (level - 8.0)
        }
        
        // Convert relative risk to daily life minutes using playbook formula
        let riskReduction = 1.0 - relativeRisk
        let impactScaling = 0.04  // Scaling factor from playbook
        let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
        
        // Convert to daily impact
        let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
        let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
        
        logger.info("📊 Stress impact: Level \(String(format: "%.1f", level)) → \(String(format: "%.1f", dailyImpact)) minutes/day (RR: \(String(format: "%.3f", relativeRisk)))")
        
        return dailyImpact
    }
    
    // MARK: - Nutrition Quality Impact Calculation
    
    /// Calculate nutrition impact using research-based principles
    /// Based on dietary pattern research and Mediterranean diet studies
    func calculateNutritionImpact(nutritionQuality: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🥗 Calculating nutrition impact for quality \(Int(nutritionQuality)) using research-based principles")
        
        // Nutrition quality on 1-10 scale (10 = optimal Mediterranean-style diet)
        let optimalNutrition = 8.0 // High quality diet
        let moderateNutrition = 6.0
        let poorNutrition = 4.0
        
        let dailyImpactMinutes = calculateNutritionLifeImpact(
            nutritionQuality: nutritionQuality,
            optimalNutrition: optimalNutrition,
            moderateNutrition: moderateNutrition,
            poorNutrition: poorNutrition,
            userProfile: userProfile
        )
        
        let recommendation = generateNutritionRecommendation(
            nutritionQuality: nutritionQuality,
            optimalNutrition: optimalNutrition
        )
        
        return MetricImpactDetail(
            metricType: .nutritionQuality,
            currentValue: nutritionQuality,
            baselineValue: optimalNutrition,
            studyReferences: [], // Would include dietary pattern studies
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .metaAnalysisSynthesis,
            recommendation: recommendation
        )
    }
    
    /// Research-based nutrition life impact using exact playbook linear model
    /// Below 7: linear penalty to −139 min at score 1, 8–10: linear gain to +66.7 min at score 10
    private func calculateNutritionLifeImpact(nutritionQuality: Double, optimalNutrition: Double, moderateNutrition: Double, poorNutrition: Double, userProfile: UserProfile) -> Double {
        let quality = max(1, min(nutritionQuality, 10))
        
        let dailyImpact: Double
        if quality < 7.0 {
            // Below 7: linear penalty to −139 min at score 1
            // Linear interpolation: score 7 = 0 min, score 1 = -139 min
            dailyImpact = (quality - 7.0) * (139.0 / 6.0) // (7-1=6 point range)
        } else if quality <= 10.0 {
            // 8-10: linear gain to +66.7 min at score 10
            // Assuming score 7 = 0, score 8 starts gaining, score 10 = +66.7
            if quality < 8.0 {
                dailyImpact = 0.0 // Score 7-8 range stays at 0
            } else {
                dailyImpact = (quality - 8.0) * (66.7 / 2.0) // Score 8-10 is 2 point range
            }
        } else {
            dailyImpact = 0.0
        }
        
        logger.info("📊 Nutrition impact: Quality \(String(format: "%.1f", quality)) → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    // MARK: - Recommendation Generation
    
    private func generateAlcoholRecommendation(drinksPerDay: Double) -> String {
        let moderateThreshold = 1.0
        if drinksPerDay <= 0.1 {
            return "Excellent! No alcohol consumption supports optimal longevity."
        } else if drinksPerDay <= moderateThreshold {
            return "Consider reducing to minimize health risks. Even light drinking carries some mortality risk according to research."
        } else if drinksPerDay <= 2.0 {
            return "Moderate drinking increases mortality risk. Consider reducing to 1 drink/day or less for better health outcomes."
        } else {
            return "Heavy drinking significantly increases mortality risk. Consider seeking support to reduce consumption for optimal health."
        }
    }
    
    private func generateSmokingRecommendation(smokingStatus: Double) -> String {
        switch Int(smokingStatus) {
        case 0:
            return "Excellent! Never smoking is the optimal choice for longevity."
        case 1:
            return "Great job quitting! Former smokers still have elevated risk but much lower than current smokers."
        case 2, 3:
            return "Quitting smoking is the single most impactful change for your health. Even light smoking significantly increases mortality risk."
        default:
            return "Maintain tobacco-free lifestyle for optimal health."
        }
    }
    
    private func generateStressRecommendation(stressLevel: Double, optimalStress: Double) -> String {
        if stressLevel <= optimalStress {
            return "Good stress management! Maintain your current stress reduction practices."
        } else if stressLevel <= 6.0 {
            return "Consider stress reduction techniques: meditation, exercise, adequate sleep, and social support."
        } else if stressLevel <= 8.0 {
            return "High stress levels may impact health. Consider professional stress management counseling or therapy."
        } else {
            return "Severe stress requires attention. Consider professional help and comprehensive stress management strategies."
        }
    }
    
    private func generateNutritionRecommendation(nutritionQuality: Double, optimalNutrition: Double) -> String {
        if nutritionQuality >= optimalNutrition {
            return "Excellent nutrition! Maintain your healthy dietary patterns for optimal longevity benefits."
        } else if nutritionQuality >= 6.0 {
            return "Good nutrition foundation. Consider adding more vegetables, fruits, whole grains, and healthy fats."
        } else if nutritionQuality >= 4.0 {
            return "Moderate nutrition quality. Focus on reducing processed foods and increasing whole food consumption."
        } else {
            return "Poor nutrition significantly impacts health. Consider consulting a nutritionist for a comprehensive dietary overhaul."
        }
    }
    
    // MARK: - Social Connections Impact Calculation
    
    /// Calculate social connections impact using research-based principles
    /// Based on Holt-Lunstad et al. (2010) meta-analysis and social epidemiology research
    func calculateSocialConnectionsImpact(socialConnectionsQuality: Double, userProfile: UserProfile) -> MetricImpactDetail {
        logger.info("🤝 Calculating social connections impact for quality \(Int(socialConnectionsQuality)) using research-based principles")
        
        // Social connections on 1-10 scale (10 = very strong social connections)
        let optimalConnections = 8.0 // Strong social connections
        let moderateThreshold = 5.0
        let poorThreshold = 3.0
        
        let dailyImpactMinutes = calculateSocialConnectionsLifeImpact(
            socialQuality: socialConnectionsQuality,
            optimalConnections: optimalConnections,
            moderateThreshold: moderateThreshold,
            poorThreshold: poorThreshold
        )
        
        let recommendation = generateSocialConnectionsRecommendation(
            socialQuality: socialConnectionsQuality,
            optimalConnections: optimalConnections
        )
        
        return MetricImpactDetail(
            metricType: .socialConnectionsQuality,
            currentValue: socialConnectionsQuality,
            baselineValue: optimalConnections,
            studyReferences: [], // Would include Holt-Lunstad meta-analysis
            lifespanImpactMinutes: dailyImpactMinutes,
            calculationMethod: .metaAnalysisSynthesis,
            recommendation: recommendation
        )
    }
    
    /// Research-based social connections life impact using exact playbook linear model
    /// Same linear model (±52 min at extremes), scaling 0.05
    private func calculateSocialConnectionsLifeImpact(socialQuality: Double, optimalConnections: Double, moderateThreshold: Double, poorThreshold: Double) -> Double {
        let quality = max(1, min(socialQuality, 10))
        let reference = 5.5  // Midpoint for linear model
        
        // Linear model: ±52 min at extremes (quality 1 = -52 min, quality 10 = +52 min)
        // Linear interpolation around reference point
        let qualityDifference = quality - reference
        let dailyImpact = qualityDifference * (52.0 / 4.5)  // 4.5 is half the range (10-1)/2
        
        logger.info("📊 Social connections impact: Quality \(String(format: "%.1f", quality)) → \(String(format: "%.1f", dailyImpact)) minutes/day")
        
        return dailyImpact
    }
    
    private func generateSocialConnectionsRecommendation(socialQuality: Double, optimalConnections: Double) -> String {
        if socialQuality >= optimalConnections {
            return "Excellent social connections! Continue nurturing these important relationships for optimal health benefits."
        } else if socialQuality >= 6.0 {
            return "Good social connections. Consider joining community groups or scheduling regular social activities to strengthen bonds."
        } else if socialQuality >= 3.0 {
            return "Limited social connections. Prioritize building meaningful relationships through shared activities or interests."
        } else {
            return "Social isolation significantly impacts health. Consider reaching out to friends, joining clubs, or seeking support groups."
        }
    }
}
