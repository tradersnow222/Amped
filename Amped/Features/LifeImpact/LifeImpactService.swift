import Foundation
import Combine
import OSLog

/// Protocol defining the life impact calculation functionality
protocol LifeImpactServicing {
    /// Calculate impact for a specific health metric
    func calculateImpact(for metric: HealthMetric) -> MetricImpactDetail
    
    /// Calculate impact for a collection of health metrics
    func calculateImpacts(for metrics: [HealthMetric]) -> [MetricImpactDetail]
    
    /// Calculate total impact from a collection of metrics
    func calculateTotalImpact(from metrics: [HealthMetric], for periodType: ImpactDataPoint.PeriodType) -> ImpactDataPoint
    
    /// Get reference data for scientific studies supporting calculations
    func getStudyReference(for metricType: HealthMetricType) -> StudyReference?
}

/// Service for calculating life impact based on health metrics
final class LifeImpactService: LifeImpactServicing, ObservableObject {
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "LifeImpactService")
    private let userProfile: UserProfile
    
    @Published var calculatedImpacts: [MetricImpactDetail] = []
    @Published var latestImpactDataPoint: ImpactDataPoint?
    
    // MARK: - Initialization
    
    init(userProfile: UserProfile) {
        self.userProfile = userProfile
    }
    
    // MARK: - Public methods
    
    func calculateImpact(for metric: HealthMetric) -> MetricImpactDetail {
        // Calculate impact based on metric type
        switch metric.type {
        case .steps:
            return calculateStepsImpact(steps: metric.value, date: metric.date)
        case .activeEnergyBurned:
            return calculateActiveEnergyImpact(calories: metric.value, date: metric.date)
        case .exerciseMinutes:
            return calculateExerciseImpact(minutes: metric.value, date: metric.date)
        case .restingHeartRate:
            return calculateRestingHeartRateImpact(bpm: metric.value, date: metric.date)
        case .heartRateVariability:
            return calculateHRVImpact(ms: metric.value, date: metric.date)
        case .sleepHours:
            return calculateSleepImpact(hours: metric.value, date: metric.date)
        case .vo2Max:
            return calculateVO2MaxImpact(mlPerKgMin: metric.value, date: metric.date)
        case .oxygenSaturation:
            return calculateOxygenSaturationImpact(percentage: metric.value, date: metric.date)
        case .nutritionQuality:
            return calculateNutritionImpact(quality: metric.value, date: metric.date)
        case .stressLevel:
            return calculateStressImpact(level: metric.value, date: metric.date)
        @unknown default:
            // Default calculation for unknown metric types
            return MetricImpactDetail(
                metricType: metric.type,
                lifespanImpactMinutes: 0,
                comparisonToBaseline: .same
            )
        }
    }
    
    func calculateImpacts(for metrics: [HealthMetric]) -> [MetricImpactDetail] {
        let impacts = metrics.map { calculateImpact(for: $0) }
        calculatedImpacts = impacts
        return impacts
    }
    
    func calculateTotalImpact(from metrics: [HealthMetric], for periodType: ImpactDataPoint.PeriodType) -> ImpactDataPoint {
        let impacts = calculateImpacts(for: metrics)
        
        // Create a dictionary of impacts by metric type
        var impactsByType: [HealthMetricType: Double] = [:]
        var totalImpactMinutes: Double = 0
        
        for impact in impacts {
            impactsByType[impact.metricType] = impact.lifespanImpactMinutes
            totalImpactMinutes += impact.lifespanImpactMinutes
        }
        
        // Scale impact based on period type
        let scaledImpactMinutes = scaleImpact(totalImpactMinutes, for: periodType)
        
        // Create an impact data point
        let impactDataPoint = ImpactDataPoint(
            date: Date(),
            periodType: periodType,
            totalImpactMinutes: scaledImpactMinutes,
            metricImpacts: impactsByType
        )
        
        latestImpactDataPoint = impactDataPoint
        return impactDataPoint
    }
    
    func getStudyReference(for metricType: HealthMetricType) -> StudyReference? {
        // Simplified mock implementation - in production, this would fetch actual study references
        switch metricType {
        case .steps:
            return StudyReference(
                title: "Association of Step Volume and Intensity With All-Cause Mortality in Older Women",
                authors: "I-Min Lee, Eric J. Shiroma, Masamitsu Kamada, David R. Bassett, Charles E. Matthews, Julie E. Buring",
                journalName: "JAMA Internal Medicine",
                publicationYear: 2019,
                doi: "10.1001/jamainternmed.2019.0899",
                url: URL(string: "https://jamanetwork.com/journals/jamainternalmedicine/fullarticle/2734709"),
                summary: "Taking more steps per day was associated with lower mortality rates until approximately 7500 steps/day. Higher step intensity was not associated with lower mortality rates after adjusting for total steps per day."
            )
            
        case .sleepHours:
            return StudyReference(
                title: "Sleep Duration and All-Cause Mortality: A Systematic Review and Meta-Analysis of Prospective Studies",
                authors: "Francesco P. Cappuccio, Lanfranco D'Elia, Pasquale Strazzullo, Michelle A. Miller",
                journalName: "Sleep",
                publicationYear: 2010,
                doi: "10.1093/sleep/33.5.585",
                url: URL(string: "https://academic.oup.com/sleep/article/33/5/585/2454478"),
                summary: "Both short and long duration of sleep are significant predictors of death in prospective studies. 7-8 hours of sleep per night was associated with the lowest mortality risk."
            )
            
        default:
            // In a real implementation, we would provide references for all metric types
            return nil
        }
    }
    
    // MARK: - Private methods
    
    /// Scale impact based on the selected time period
    private func scaleImpact(_ impactMinutes: Double, for periodType: ImpactDataPoint.PeriodType) -> Double {
        switch periodType {
        case .day:
            return impactMinutes
        case .month:
            return impactMinutes * 30 // Simplified approximation
        case .year:
            return impactMinutes * 365 // Simplified approximation
        }
    }
    
    // MARK: - Impact calculation methods
    
    private func calculateStepsImpact(steps: Double, date: Date) -> MetricImpactDetail {
        // Baseline: 7500 steps is neutral (based on research)
        // Each 1000 steps over/under affects lifespan by 5 minutes
        
        let baseline = 7500.0
        let stepsImpactPerThousand = 5.0 // minutes per 1000 steps
        
        let difference = steps - baseline
        let impactMinutes = (difference / 1000.0) * stepsImpactPerThousand
        
        let comparison: MetricImpactDetail.ComparisonResult
        if steps > baseline * 1.1 {
            comparison = .better
        } else if steps < baseline * 0.9 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .steps,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.95,
            comparisonToBaseline: comparison,
            studyReference: getStudyReference(for: .steps)
        )
    }
    
    private func calculateActiveEnergyImpact(calories: Double, date: Date) -> MetricImpactDetail {
        // Baseline: 400 calories/day is neutral (simplified)
        // Each 100 calories over/under affects lifespan by 3 minutes
        
        let baseline = 400.0
        let caloriesImpactPer100 = 3.0 // minutes per 100 calories
        
        let difference = calories - baseline
        let impactMinutes = (difference / 100.0) * caloriesImpactPer100
        
        let comparison: MetricImpactDetail.ComparisonResult
        if calories > baseline * 1.2 {
            comparison = .better
        } else if calories < baseline * 0.8 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .activeEnergyBurned,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.9,
            comparisonToBaseline: comparison
        )
    }
    
    private func calculateExerciseImpact(minutes: Double, date: Date) -> MetricImpactDetail {
        // Baseline: 30 minutes/day is neutral (based on WHO recommendations)
        // Each 10 minutes over/under affects lifespan by 7 minutes
        
        let baseline = 30.0
        let exerciseImpactPer10Min = 7.0 // minutes of life per 10 minutes of exercise
        
        let difference = minutes - baseline
        let impactMinutes = (difference / 10.0) * exerciseImpactPer10Min
        
        let comparison: MetricImpactDetail.ComparisonResult
        if minutes > baseline * 1.3 {
            comparison = .better
        } else if minutes < baseline * 0.7 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .exerciseMinutes,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.95,
            comparisonToBaseline: comparison
        )
    }
    
    private func calculateRestingHeartRateImpact(bpm: Double, date: Date) -> MetricImpactDetail {
        // Baseline depends on age and gender
        // Each 5 bpm over/under affects lifespan differently based on direction
        
        let age = userProfile.age ?? 35 // Default age if not available
        
        // Calculate baseline based on age
        let baseline = 70.0 - (Double(age) / 10.0) // Simplified formula
        
        let difference = bpm - baseline
        
        // Higher resting heart rate is generally worse
        // Lower resting heart rate (to a point) is generally better
        var impactMinutes: Double
        
        if difference > 0 {
            // Higher than baseline (worse)
            impactMinutes = -1.0 * (difference / 5.0) * 10.0
        } else {
            // Lower than baseline (better, to a point)
            // But extremely low can be concerning, so cap the benefit
            let cappedDifference = max(difference, -20.0)
            impactMinutes = -1.0 * (cappedDifference / 5.0) * 8.0
        }
        
        let comparison: MetricImpactDetail.ComparisonResult
        if bpm < baseline - 10 {
            comparison = .better
        } else if bpm > baseline + 10 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .restingHeartRate,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.9,
            comparisonToBaseline: comparison
        )
    }
    
    private func calculateHRVImpact(ms: Double, date: Date) -> MetricImpactDetail {
        // Higher HRV is generally better (indicates better stress recovery)
        // Baseline depends on age
        
        let age = userProfile.age ?? 35 // Default age if not available
        
        // Calculate baseline based on age (simplified)
        let baseline = 60.0 - (Double(age) / 3.0)
        
        let difference = ms - baseline
        
        // Higher HRV is generally better
        let impactMinutes = (difference / 5.0) * 6.0
        
        let comparison: MetricImpactDetail.ComparisonResult
        if ms > baseline * 1.2 {
            comparison = .better
        } else if ms < baseline * 0.8 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .heartRateVariability,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.85,
            comparisonToBaseline: comparison
        )
    }
    
    private func calculateSleepImpact(hours: Double, date: Date) -> MetricImpactDetail {
        // Baseline: 7-8 hours is optimal (based on research)
        // Each hour over/under affects lifespan differently
        
        let lowerBaseline = 7.0
        let upperBaseline = 8.0
        
        var impactMinutes: Double
        
        if hours < lowerBaseline {
            // Less than optimal sleep
            let difference = lowerBaseline - hours
            impactMinutes = -15.0 * difference
        } else if hours > upperBaseline {
            // More than optimal sleep (also negative impact based on research)
            let difference = hours - upperBaseline
            impactMinutes = -10.0 * difference
        } else {
            // Optimal sleep range
            impactMinutes = 10.0
        }
        
        let comparison: MetricImpactDetail.ComparisonResult
        if hours >= lowerBaseline && hours <= upperBaseline {
            comparison = .better
        } else if hours < 6.0 || hours > 9.0 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .sleepHours,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.95,
            comparisonToBaseline: comparison,
            studyReference: getStudyReference(for: .sleepHours)
        )
    }
    
    private func calculateVO2MaxImpact(mlPerKgMin: Double, date: Date) -> MetricImpactDetail {
        // Baseline depends on age and gender
        // Each 1 ml/kg/min over/under affects lifespan by 15 minutes
        
        let age = userProfile.age ?? 35 // Default age if not available
        let gender = userProfile.gender ?? .preferNotToSay
        
        // Calculate baseline based on age and gender (simplified)
        var baseline: Double
        
        switch gender {
        case .male:
            baseline = 60.0 - (Double(age) / 3.0)
        case .female:
            baseline = 50.0 - (Double(age) / 3.0)
        default:
            baseline = 55.0 - (Double(age) / 3.0)
        }
        
        let difference = mlPerKgMin - baseline
        let impactMinutes = difference * 15.0
        
        let comparison: MetricImpactDetail.ComparisonResult
        if mlPerKgMin > baseline * 1.1 {
            comparison = .better
        } else if mlPerKgMin < baseline * 0.9 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .vo2Max,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.9,
            comparisonToBaseline: comparison
        )
    }
    
    private func calculateOxygenSaturationImpact(percentage: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-100, with 100 being baseline
        // Each point above/below affects lifespan by 20 minutes
        
        let baseline = 100.0
        let oxygenSaturationImpactPerPoint = 20.0
        
        let difference = percentage - baseline
        let impactMinutes = difference * oxygenSaturationImpactPerPoint
        
        let comparison: MetricImpactDetail.ComparisonResult
        if percentage > baseline + 1 {
            comparison = .better
        } else if percentage < baseline - 1 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .oxygenSaturation,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.8,
            comparisonToBaseline: comparison
        )
    }
    
    private func calculateNutritionImpact(quality: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-10, with 7 being baseline
        // Each point above/below affects lifespan by 20 minutes
        
        let baseline = 7.0
        let nutritionImpactPerPoint = 20.0
        
        let difference = quality - baseline
        let impactMinutes = difference * nutritionImpactPerPoint
        
        let comparison: MetricImpactDetail.ComparisonResult
        if quality > baseline + 1 {
            comparison = .better
        } else if quality < baseline - 1 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .nutritionQuality,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.8,
            comparisonToBaseline: comparison
        )
    }
    
    private func calculateStressImpact(level: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-10, with 0 being no stress (best) and 10 being extreme stress (worst)
        // Baseline is 5
        // Each point above/below affects lifespan by 15 minutes
        
        let baseline = 5.0
        let stressImpactPerPoint = 15.0
        
        // For stress, lower is better
        let difference = baseline - level
        let impactMinutes = difference * stressImpactPerPoint
        
        let comparison: MetricImpactDetail.ComparisonResult
        if level < baseline - 2 {
            comparison = .better
        } else if level > baseline + 2 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .stressLevel,
            date: date,
            lifespanImpactMinutes: impactMinutes,
            confidencePercentage: 0.85,
            comparisonToBaseline: comparison
        )
    }
} 