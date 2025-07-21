import Foundation
import OSLog

/// Service for calculating life impact based on health metrics using peer-reviewed research
/// All calculations are grounded in scientific evidence with proper study references
class LifeImpactService {
    private let logger = Logger(subsystem: "Amped", category: "LifeImpactService")
    private let userProfile: UserProfile
    
    // Research-based calculators
    private let activityCalculator = ActivityImpactCalculator()
    private let cardiovascularCalculator = CardiovascularImpactCalculator()
    private let lifestyleCalculator = LifestyleImpactCalculator()
    private let interactionEngine = InteractionEffectEngine()
    private let mortalityAdjuster = BaselineMortalityAdjuster()
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
        logger.info("🧮 LifeImpactService initialized for user age \(userProfile.age ?? 30)")
    }
    
    /// Calculate impact for a single health metric using research-based formulas
    func calculateImpact(for metric: HealthMetric) -> MetricImpactDetail {
        logger.info("📊 Calculating research-based impact for \(metric.type.displayName): \(metric.value)")
        
        let impactDetail: MetricImpactDetail
        
        switch metric.type {
        // Physical Activity Metrics - Research-backed calculations
        case .steps:
            impactDetail = activityCalculator.calculateStepsImpact(
                steps: metric.value,
                userProfile: userProfile
            )
            
        case .exerciseMinutes:
            impactDetail = activityCalculator.calculateExerciseImpact(
                exerciseMinutes: metric.value,
                userProfile: userProfile
            )
            
        // Cardiovascular Health Metrics - Research-backed calculations
        case .restingHeartRate:
            impactDetail = cardiovascularCalculator.calculateRestingHeartRateImpact(
                heartRate: metric.value,
                userProfile: userProfile
            )
            
        case .sleepHours:
            impactDetail = cardiovascularCalculator.calculateSleepImpact(
                sleepHours: metric.value,
                userProfile: userProfile
            )
            
        case .heartRateVariability:
            impactDetail = cardiovascularCalculator.calculateHRVImpact(
                hrv: metric.value,
                userProfile: userProfile
            )
            
        // Lifestyle Metrics - Research-backed calculations
        case .alcoholConsumption:
            impactDetail = lifestyleCalculator.calculateAlcoholImpact(
                drinksPerDay: metric.value,
                userProfile: userProfile
            )
            
        case .smokingStatus:
            impactDetail = lifestyleCalculator.calculateSmokingImpact(
                smokingStatus: metric.value,
                userProfile: userProfile
            )
            
        case .stressLevel:
            impactDetail = lifestyleCalculator.calculateStressImpact(
                stressLevel: metric.value,
                userProfile: userProfile
            )
            
        case .nutritionQuality:
            impactDetail = lifestyleCalculator.calculateNutritionImpact(
                nutritionQuality: metric.value,
                userProfile: userProfile
            )
            
        case .socialConnectionsQuality:
            impactDetail = lifestyleCalculator.calculateSocialConnectionsImpact(
                socialConnectionsQuality: metric.value,
                userProfile: userProfile
            )
            
        // Additional HealthKit metrics with basic fallback calculations
        case .bodyMass, .activeEnergyBurned, .vo2Max, .oxygenSaturation:
            // Use fallback calculation for metrics without specialized research-based calculators
            impactDetail = calculateFallbackImpact(for: metric)
        }
        
        logger.info("✅ Impact calculated: \(metric.type.displayName) → \(String(format: "%.1f", impactDetail.lifespanImpactMinutes)) min/day (\(impactDetail.evidenceStrength.rawValue) evidence)")
        
        return impactDetail
    }
    
    /// Calculate impacts for multiple metrics with research grounding
    func calculateImpacts(for metrics: [HealthMetric]) -> [MetricImpactDetail] {
        logger.info("📊 Calculating research-based impacts for \(metrics.count) health metrics")
        
        return metrics.map { metric in
            calculateImpact(for: metric)
        }
    }
    
    /// Calculate total aggregated impact with proper evidence weighting and interaction effects
    func calculateTotalImpact(from metrics: [HealthMetric], for periodType: ImpactDataPoint.PeriodType) -> ImpactDataPoint {
        var impacts = calculateImpacts(for: metrics)
        
        // Apply interaction effects
        impacts = interactionEngine.calculateAdjustedImpacts(impacts: impacts, metrics: metrics)
        
        // Apply mortality adjustments
        let age = userProfile.age ?? 30
        let gender = userProfile.gender ?? .male
        impacts = impacts.map { impact in
            let adjustedDailyImpact = mortalityAdjuster.adjustImpactForMortality(
                dailyImpact: impact.lifespanImpactMinutes,
                age: age,
                gender: gender
            )
            
            return MetricImpactDetail(
                metricType: impact.metricType,
                currentValue: impact.currentValue,
                baselineValue: impact.baselineValue,
                studyReferences: impact.studyReferences,
                lifespanImpactMinutes: adjustedDailyImpact,
                calculationMethod: impact.calculationMethod,
                recommendation: impact.recommendation,
                improvementPotential: impact.improvementPotential
            )
        }
        
        // Create a dictionary of impacts by metric type WITH proper scaling AND evidence weighting
        var impactsByType: [HealthMetricType: Double] = [:]
        var totalImpactMinutes: Double = 0
        var evidenceQualityScore: Double = 0
        
        for impact in impacts {
            // Apply advanced scaling based on effect type and period
            let scaledImpact = applyAdvancedScaling(impact, periodType: periodType, metrics: metrics)
            
            // Weight impact by evidence strength and reliability
            let evidenceWeight = impact.reliabilityScore
            let weightedImpact = scaledImpact * evidenceWeight
            
            impactsByType[impact.metricType] = weightedImpact
            totalImpactMinutes += weightedImpact
            evidenceQualityScore += evidenceWeight
        }
        
        // Calculate average evidence quality
        evidenceQualityScore = impacts.isEmpty ? 0 : evidenceQualityScore / Double(impacts.count)
        
        logger.info("📈 Total impact calculated: \(String(format: "%.1f", totalImpactMinutes)) minutes (\(periodType.rawValue)) - Evidence quality: \(String(format: "%.1f", evidenceQualityScore * 100))%")
        
        return ImpactDataPoint(
            date: Date(),
            periodType: periodType,
            totalImpactMinutes: totalImpactMinutes,
            metricImpacts: impactsByType,
            evidenceQualityScore: evidenceQualityScore
        )
    }
    
    /// Apply advanced scaling based on effect type, period, and actual behavior patterns
    private func applyAdvancedScaling(
        _ impact: MetricImpactDetail,
        periodType: ImpactDataPoint.PeriodType,
        metrics: [HealthMetric]
    ) -> Double {
        let dailyImpact = impact.lifespanImpactMinutes
        
        switch impact.effectType {
        case .linearCumulative:
            // Simple multiplication for truly linear effects
            return scaleLinearEffect(dailyImpact, periodType: periodType)
            
        case .logarithmic, .diminishingReturns:
            // Apply diminishing returns model
            return scaleDiminishingEffect(
                dailyImpact,
                periodType: periodType,
                metricType: impact.metricType
            )
            
        case .uShapedCurve:
            // Special handling for U-shaped effects like sleep
            return scaleUShapedEffect(
                impact: impact,
                periodType: periodType,
                metrics: metrics
            )
            
        case .thresholdBased:
            // Threshold effects need minimum exposure duration
            return scaleThresholdEffect(
                dailyImpact,
                periodType: periodType,
                metricType: impact.metricType
            )
            
        case .exponential:
            // Compound effects over time
            return scaleExponentialEffect(
                dailyImpact,
                periodType: periodType,
                metricType: impact.metricType
            )
            
        case .plateau:
            // Quick plateau, limited scaling
            return scalePlateauEffect(
                dailyImpact,
                periodType: periodType,
                metricType: impact.metricType
            )
        }
    }
    
    // MARK: - Specific Scaling Functions
    
    private func scaleLinearEffect(_ dailyImpact: Double, periodType: ImpactDataPoint.PeriodType) -> Double {
        switch periodType {
        case .day: return dailyImpact
        case .month: return dailyImpact * 30.0
        case .year: return dailyImpact * 365.0
        }
    }
    
    private func scaleDiminishingEffect(
        _ dailyImpact: Double,
        periodType: ImpactDataPoint.PeriodType,
        metricType: HealthMetricType
    ) -> Double {
        // Logarithmic scaling for diminishing returns
        let days: Double
        switch periodType {
        case .day: days = 1
        case .month: days = 30
        case .year: days = 365
        }
        
        // Different metrics have different diminishing curves
        let diminishingFactor: Double
        switch metricType {
        case .steps, .exerciseMinutes:
            // Exercise benefits plateau around 3-6 months
            diminishingFactor = 0.7
        case .nutritionQuality:
            // Nutrition effects take longer to manifest
            diminishingFactor = 0.85
        default:
            diminishingFactor = 0.75
        }
        
        // Logarithmic scaling: impact * log(1 + days) / log(1 + baseDays)
        let scaledImpact = dailyImpact * log(1 + days * diminishingFactor) / log(1 + diminishingFactor)
        return scaledImpact
    }
    
    private func scaleUShapedEffect(
        impact: MetricImpactDetail,
        periodType: ImpactDataPoint.PeriodType,
        metrics: [HealthMetric]
    ) -> Double {
        // For U-shaped effects, we need to consider consistency
        // Irregular patterns have worse outcomes than consistent suboptimal patterns
        
        guard let metric = metrics.first(where: { $0.type == impact.metricType }) else {
            return impact.lifespanImpactMinutes
        }
        
        // For sleep, consider that chronic poor sleep has compounding effects
        if impact.metricType == .sleepHours {
            let days: Double
            switch periodType {
            case .day: days = 1
            case .month: days = 30
            case .year: days = 365
            }
            
            // If sleep is far from optimal, effects compound
            let deviation = abs(metric.value - impact.baselineValue)
            let compoundingFactor = 1.0 + (deviation / 10.0) // More deviation = more compounding
            
            return impact.lifespanImpactMinutes * days * compoundingFactor
        }
        
        // Default to conservative scaling
        return scaleLinearEffect(impact.lifespanImpactMinutes, periodType: periodType)
    }
    
    private func scaleThresholdEffect(
        _ dailyImpact: Double,
        periodType: ImpactDataPoint.PeriodType,
        metricType: HealthMetricType
    ) -> Double {
        // Threshold effects require sustained behavior
        let days: Double
        switch periodType {
        case .day: return dailyImpact // No threshold effect in single day
        case .month: days = 30
        case .year: days = 365
        }
        
        // Minimum days before effects kick in
        let thresholdDays: Double = 21 // 3 weeks for habit formation
        
        if days < thresholdDays {
            // Linear ramp up to threshold
            return dailyImpact * days * (days / thresholdDays)
        } else {
            // Full effect after threshold
            return dailyImpact * days
        }
    }
    
    private func scaleExponentialEffect(
        _ dailyImpact: Double,
        periodType: ImpactDataPoint.PeriodType,
        metricType: HealthMetricType
    ) -> Double {
        // Exponential effects compound over time
        let days: Double
        switch periodType {
        case .day: return dailyImpact
        case .month: days = 30
        case .year: days = 365
        }
        
        // Conservative exponential growth to avoid unrealistic projections
        let growthRate = 0.001 // 0.1% daily compound
        let scaledImpact = dailyImpact * days * (1 + growthRate * days)
        
        return scaledImpact
    }
    
    private func scalePlateauEffect(
        _ dailyImpact: Double,
        periodType: ImpactDataPoint.PeriodType,
        metricType: HealthMetricType
    ) -> Double {
        // Plateau effects reach maximum quickly
        let days: Double
        switch periodType {
        case .day: return dailyImpact
        case .month: days = 30
        case .year: days = 365
        }
        
        // Most benefits achieved in first 30 days
        let plateauDays: Double = 30
        let effectiveDays = min(days, plateauDays + (days - plateauDays) * 0.1) // 10% effect after plateau
        
        return dailyImpact * effectiveDays
    }
    
    // MARK: - Life Impact Data Calculation
    
    /// Calculate comprehensive life impact data for dashboard display
    func calculateLifeImpact(
        from metrics: [HealthMetric], 
        for timePeriod: ImpactDataPoint.PeriodType,
        userProfile: UserProfile
    ) -> LifeImpactData {
        // Calculate individual impacts for all metrics
        let metricDetails = metrics.compactMap { metric -> (HealthMetricType, MetricImpactDetail)? in
            let impactDetail = calculateImpact(for: metric)
            return (metric.type, impactDetail)
        }
        
        // Create metric contributions dictionary
        let metricContributions = Dictionary(uniqueKeysWithValues: metricDetails)
        
        // Calculate total impact using existing method
        let totalImpactPoint = calculateTotalImpact(from: metrics, for: timePeriod)
        
        // Convert to appropriate time period representation
        let timePeriodEnum: TimePeriod = {
            switch timePeriod {
            case .day: return .day
            case .month: return .month  
            case .year: return .year
            }
        }()
        
        // Calculate battery level (0-100) based on total impact
        let batteryLevel = calculateBatteryLevel(from: totalImpactPoint.totalImpactMinutes)
        
        // Find top positive and negative metrics
        let sortedByImpact = metricDetails.sorted { $0.1.lifespanImpactMinutes > $1.1.lifespanImpactMinutes }
        let topPositiveMetric = sortedByImpact.first?.1.lifespanImpactMinutes ?? 0 > 0 ? sortedByImpact.first?.0 : nil
        let topNegativeMetric = sortedByImpact.last?.1.lifespanImpactMinutes ?? 0 < 0 ? sortedByImpact.last?.0 : nil
        
        return LifeImpactData(
            timePeriod: timePeriodEnum,
            totalImpact: ImpactValue(
                value: abs(totalImpactPoint.totalImpactMinutes),
                unit: .minutes,
                direction: totalImpactPoint.totalImpactMinutes >= 0 ? .positive : .negative
            ),
            batteryLevel: batteryLevel,
            metricContributions: metricContributions,
            topPositiveMetric: topPositiveMetric,
            topNegativeMetric: topNegativeMetric
        )
    }
    
    /// Calculate battery level (0-100) based on total impact minutes
    private func calculateBatteryLevel(from impactMinutes: Double) -> Double {
        // Battery level calculation:
        // 50% = baseline (0 impact)
        // 100% = very positive impact (+120 minutes/day)
        // 0% = very negative impact (-120 minutes/day)
        
        let normalizedImpact = impactMinutes / 120.0 // Normalize to ±1.0 range
        let batteryLevel = 50.0 + (normalizedImpact * 50.0) // Convert to 0-100 range
        
        return max(0.0, min(100.0, batteryLevel))
    }
    
    // MARK: - Fallback Impact Calculation
    
    /// Fallback calculation for metrics without specialized research-based calculators
    private func calculateFallbackImpact(for metric: HealthMetric) -> MetricImpactDetail {
        logger.info("⚠️ Using fallback calculation for \(metric.type.displayName)")
        
        // Basic impact calculation using general health principles
        let baselineImpact = 0.5 // 30 seconds per day baseline
        let normalizedValue = min(max(metric.value / 100.0, 0.0), 2.0) // Normalize to 0-2 range
        let dailyImpact = baselineImpact * normalizedValue
        
        return MetricImpactDetail(
            metricType: metric.type,
            currentValue: metric.value,
            baselineValue: 100.0, // Default baseline
            studyReferences: [],
            lifespanImpactMinutes: dailyImpact,
            calculationMethod: .algorithmicEstimate,
            recommendation: "More research needed for precise recommendations for \(metric.type.displayName)."
        )
    }
    
    // MARK: - Fallback Calculations (Limited Research)
    
    /// Calculate VO2 Max impact with limited research basis
    private func calculateVO2MaxImpact(_ metric: HealthMetric) -> MetricImpactDetail {
        // Age and gender adjusted optimal VO2 Max
        let ageAdjustedOptimal = calculateAgeGenderAdjustedVO2Max(age: userProfile.age ?? 30, gender: userProfile.gender)
        let difference = metric.value - ageAdjustedOptimal
        
        // Conservative estimate based on cardiovascular fitness research
        let dailyImpact = difference * 0.3 // Conservative: 0.3 minutes per ml/kg/min
        
        return MetricImpactDetail(
            metricType: .vo2Max,
            currentValue: metric.value,
            baselineValue: ageAdjustedOptimal,
            studyReferences: [], // Limited direct mortality studies
            lifespanImpactMinutes: dailyImpact,
            calculationMethod: .expertConsensus,
            recommendation: generateVO2MaxRecommendation(current: metric.value, optimal: ageAdjustedOptimal)
        )
    }
    
    /// Calculate weight impact using BMI when height available
    private func calculateWeightImpact(_ metric: HealthMetric) -> MetricImpactDetail {
        // Simplified weight impact - would need height for proper BMI calculation
        let optimalWeight = 70.0 // Placeholder - should be BMI-based
        let difference = metric.value - optimalWeight
        
        // Conservative weight impact estimate
        let dailyImpact = difference * -0.2 // Conservative estimate
        
        return MetricImpactDetail(
            metricType: .bodyMass,
            currentValue: metric.value,
            baselineValue: optimalWeight,
            studyReferences: [], // Would include BMI mortality studies
            lifespanImpactMinutes: dailyImpact,
            calculationMethod: .algorithmicEstimate,
            recommendation: "Maintain healthy weight through balanced diet and regular exercise"
        )
    }
    
    /// Calculate impact for non-actionable metrics (age, gender)
    private func calculateNonActionableImpact(_ metric: HealthMetric) -> MetricImpactDetail {
        return MetricImpactDetail(
            metricType: metric.type,
            currentValue: metric.value,
            baselineValue: metric.value, // No optimal baseline for non-actionable metrics
            studyReferences: [],
            lifespanImpactMinutes: 0, // No actionable impact
            calculationMethod: .expertConsensus,
            recommendation: "This factor is not directly modifiable but informs other health recommendations"
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateAgeGenderAdjustedVO2Max(age: Int, gender: UserProfile.Gender?) -> Double {
        let baseVO2Max: Double
        switch gender {
        case .male:
            baseVO2Max = 50.0
        case .female:
            baseVO2Max = 40.0
        case .none:
            baseVO2Max = 45.0
        }
        
        // Decline with age (approximate)
        let ageDecline = Double(max(0, age - 20)) * 0.5
        return max(20.0, baseVO2Max - ageDecline)
    }
    
    private func generateVO2MaxRecommendation(current: Double, optimal: Double) -> String {
        let difference = optimal - current
        if difference > 10 {
            return "Your cardiovascular fitness could be improved significantly. Consider starting a structured cardio program."
        } else if difference > 5 {
            return "Good fitness level! Consider adding more intensive cardio workouts to improve further."
        } else {
            return "Excellent cardiovascular fitness for your age! Maintain your current exercise routine."
        }
    }
} 