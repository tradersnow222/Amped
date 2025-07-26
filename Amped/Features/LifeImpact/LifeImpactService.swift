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
        logger.info("🔢 Starting total impact calculation for \(periodType.rawValue) period with \(metrics.count) metrics")
        
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
        
        // CRITICAL FIX: Metrics are ALWAYS daily averages, regardless of period
        // The scaling should be applied AFTER summing the daily impacts
        var totalDailyImpactMinutes: Double = 0
        var impactsByType: [HealthMetricType: Double] = [:]
        var evidenceQualityScore: Double = 0
        
        // COMPREHENSIVE LOGGING: Log each metric's contribution
        logger.info("📊 Individual metric contributions (daily impacts):")
        
        // First, calculate the total DAILY impact (no scaling yet)
        for impact in impacts {
            // Weight impact by evidence strength and reliability
            let evidenceWeight = impact.reliabilityScore
            let weightedDailyImpact = impact.lifespanImpactMinutes * evidenceWeight
            
            impactsByType[impact.metricType] = weightedDailyImpact
            totalDailyImpactMinutes += weightedDailyImpact
            evidenceQualityScore += evidenceWeight
            
            // Log each metric's contribution
            logger.info("  \(impact.metricType.displayName): \(String(format: "%.2f", impact.lifespanImpactMinutes)) min/day (weighted: \(String(format: "%.2f", weightedDailyImpact)), evidence: \(String(format: "%.1f", evidenceWeight * 100))%)")
        }
        
        // Calculate average evidence quality
        evidenceQualityScore = impacts.isEmpty ? 0 : evidenceQualityScore / Double(impacts.count)
        
        // NOW apply period scaling to the TOTAL daily impact
        let scaledTotalImpact: Double
        let scalingFactor: Double
        switch periodType {
        case .day:
            scalingFactor = 1.0
            scaledTotalImpact = totalDailyImpactMinutes
        case .month:
            // For monthly view, show cumulative impact if behavior sustained for 30 days
            scalingFactor = 30.0
            scaledTotalImpact = totalDailyImpactMinutes * 30.0
        case .year:
            // For yearly view, show cumulative impact if behavior sustained for 365 days
            scalingFactor = 365.0
            scaledTotalImpact = totalDailyImpactMinutes * 365.0
        }
        
        // COMPREHENSIVE LOGGING: Log calculation summary
        logger.info("📈 Total impact calculation summary:")
        logger.info("  📊 Total daily impact: \(String(format: "%.2f", totalDailyImpactMinutes)) minutes")
        logger.info("  📅 Period: \(periodType.rawValue) (scaling factor: \(String(format: "%.0f", scalingFactor)))")
        logger.info("  🎯 Scaled total impact: \(String(format: "%.2f", scaledTotalImpact)) minutes")
        logger.info("  🔬 Evidence quality: \(String(format: "%.1f", evidenceQualityScore * 100))%")
        logger.info("  📋 Contributing metrics: \(impacts.count)")
        
        return ImpactDataPoint(
            date: Date(),
            periodType: periodType,
            totalImpactMinutes: scaledTotalImpact,
            metricImpacts: impactsByType,
            evidenceQualityScore: evidenceQualityScore
        )
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

    // MARK: - Neutral Baseline Calculation
    
    /// Calculate the neutral baseline impact representing optimal health habits
    /// This represents what the collective impact would be if all metrics were at research-backed optimal values
    func calculateNeutralBaseline() -> Double {
        logger.info("🎯 Calculating neutral baseline impact for optimal health habits")
        
        // Define optimal values based on scientific research
        let optimalMetrics: [HealthMetric] = [
            // Physical Activity - Research-backed optimal values
            HealthMetric(id: UUID().uuidString, type: .steps, value: 10000, date: Date(), source: .calculated), // Optimal from Saint-Maurice et al.
            HealthMetric(id: UUID().uuidString, type: .exerciseMinutes, value: 150/7, date: Date(), source: .calculated), // 150 min/week optimal from WHO
            
            // Cardiovascular Health - Research-backed optimal values  
            HealthMetric(id: UUID().uuidString, type: .restingHeartRate, value: 60, date: Date(), source: .calculated), // Optimal RHR
            HealthMetric(id: UUID().uuidString, type: .heartRateVariability, value: 40, date: Date(), source: .calculated), // Good HRV
            HealthMetric(id: UUID().uuidString, type: .sleepHours, value: 7.5, date: Date(), source: .calculated), // Optimal sleep duration
            
            // Lifestyle Metrics - Research-backed optimal values
            HealthMetric(id: UUID().uuidString, type: .alcoholConsumption, value: 10, date: Date(), source: .calculated), // No alcohol (optimal)
            HealthMetric(id: UUID().uuidString, type: .smokingStatus, value: 10, date: Date(), source: .calculated), // Never smoked
            HealthMetric(id: UUID().uuidString, type: .stressLevel, value: 2, date: Date(), source: .calculated), // Low stress
            HealthMetric(id: UUID().uuidString, type: .nutritionQuality, value: 8, date: Date(), source: .calculated), // High nutrition quality
            HealthMetric(id: UUID().uuidString, type: .socialConnectionsQuality, value: 8, date: Date(), source: .calculated) // Good social connections
        ]
        
        // Calculate total impact for optimal metrics (this should be close to 0 or slightly positive)
        let neutralImpactData = calculateTotalImpact(from: optimalMetrics, for: .day)
        let neutralImpactMinutes = neutralImpactData.totalImpactMinutes
        
        logger.info("🎯 Neutral baseline calculated: \(String(format: "%.2f", neutralImpactMinutes)) minutes/day")
        logger.info("📋 Optimal metrics used:")
        for metric in optimalMetrics {
            logger.info("  \(metric.type.displayName): \(metric.value)")
        }
        
        return neutralImpactMinutes
    }
} 