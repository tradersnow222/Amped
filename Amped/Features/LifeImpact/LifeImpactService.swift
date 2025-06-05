import Foundation
@preconcurrency import Combine
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
        // Get study reference if available
        let studyReference = getStudyReference(for: metric.type)
        
        // Calculate impact based on metric type
        switch metric.type {
        case .steps:
            return ActivityImpactCalculator.calculateStepsImpact(
                steps: metric.value,
                date: metric.date,
                studyReference: studyReference
            )
            
        case .activeEnergyBurned:
            return ActivityImpactCalculator.calculateActiveEnergyImpact(
                calories: metric.value,
                date: metric.date
            )
            
        case .exerciseMinutes:
            return ActivityImpactCalculator.calculateExerciseImpact(
                minutes: metric.value,
                date: metric.date
            )
            
        case .restingHeartRate:
            return CardiovascularImpactCalculator.calculateRestingHeartRateImpact(
                bpm: metric.value,
                date: metric.date,
                age: userProfile.age ?? 0
            )
            
        case .heartRateVariability:
            return CardiovascularImpactCalculator.calculateHRVImpact(
                ms: metric.value,
                date: metric.date,
                age: userProfile.age ?? 0
            )
            
        case .sleepHours:
            return LifestyleImpactCalculator.calculateSleepImpact(
                hours: metric.value,
                date: metric.date,
                studyReference: studyReference
            )
            
        case .vo2Max:
            return CardiovascularImpactCalculator.calculateVO2MaxImpact(
                mlPerKgMin: metric.value,
                date: metric.date,
                age: userProfile.age ?? 0,
                gender: userProfile.gender ?? .preferNotToSay
            )
            
        case .oxygenSaturation:
            return CardiovascularImpactCalculator.calculateOxygenSaturationImpact(
                percentage: metric.value,
                date: metric.date
            )
            
        case .nutritionQuality:
            return LifestyleImpactCalculator.calculateNutritionImpact(
                quality: metric.value,
                date: metric.date
            )
            
        case .stressLevel:
            return LifestyleImpactCalculator.calculateStressImpact(
                level: metric.value,
                date: metric.date
            )
            
        case .smokingStatus:
            return LifestyleImpactCalculator.calculateSmokingImpact(
                quality: metric.value,
                date: metric.date
            )
            
        case .alcoholConsumption:
            return LifestyleImpactCalculator.calculateAlcoholImpact(
                quality: metric.value,
                date: metric.date
            )
            
        case .socialConnectionsQuality:
            return LifestyleImpactCalculator.calculateSocialConnectionsImpact(
                quality: metric.value,
                date: metric.date
            )
            
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
        
        // Create a dictionary of impacts by metric type WITHOUT scaling
        var impactsByType: [HealthMetricType: Double] = [:]
        var totalImpactMinutes: Double = 0
        
        for impact in impacts {
            // CRITICAL FIX: Don't scale impacts - they should reflect the actual metric values
            // The metrics themselves are already aggregated appropriately for the time period
            impactsByType[impact.metricType] = impact.lifespanImpactMinutes
            totalImpactMinutes += impact.lifespanImpactMinutes
        }
        
        // Create an impact data point with the actual impacts
        let impactDataPoint = ImpactDataPoint(
            date: Date(),
            periodType: periodType,
            totalImpactMinutes: totalImpactMinutes,
            metricImpacts: impactsByType
        )
        
        latestImpactDataPoint = impactDataPoint
        return impactDataPoint
    }
    
    func getStudyReference(for metricType: HealthMetricType) -> StudyReference? {
        return StudyReferenceProvider.getStudyReference(for: metricType)
    }
    
    // MARK: - Private methods
    
    /// Scale impact based on the selected time period
    private func scaleImpact(_ impactMinutes: Double, for periodType: ImpactDataPoint.PeriodType) -> Double {
        // CRITICAL FIX: Don't simply multiply all impacts by time period
        // Different metrics should be handled differently based on their nature
        
        switch periodType {
        case .day:
            // Daily view: show the direct daily impact (no scaling needed)
            return impactMinutes
            
        case .month:
            // Monthly view: show cumulative monthly impact
            // This represents the potential total impact if current habits continue for a month
            return impactMinutes * 30
            
        case .year:
            // Yearly view: show cumulative yearly impact
            // This represents the potential total impact if current habits continue for a year
            return impactMinutes * 365
        }
    }
    
    /// Scale impact for a specific metric type based on time period and metric characteristics
    private func scaleMetricImpact(_ impactMinutes: Double, for metricType: HealthMetricType, periodType: ImpactDataPoint.PeriodType) -> Double {
        // Different metric types need different scaling approaches
        
        switch metricType {
        case .sleepHours:
            // Sleep is always "per night" - scale by number of nights in period
            switch periodType {
            case .day: return impactMinutes // One night
            case .month: return impactMinutes * 30 // 30 nights
            case .year: return impactMinutes * 365 // 365 nights
            }
            
        case .steps, .activeEnergyBurned, .exerciseMinutes:
            // Activity metrics: cumulative daily activities
            switch periodType {
            case .day: return impactMinutes // One day
            case .month: return impactMinutes * 30 // 30 days
            case .year: return impactMinutes * 365 // 365 days
            }
            
        case .restingHeartRate, .heartRateVariability, .vo2Max, .oxygenSaturation:
            // Physiological metrics: represent ongoing health status
            // These have sustained impact over time
            switch periodType {
            case .day: return impactMinutes // Current daily impact
            case .month: return impactMinutes * 30 // Sustained over month
            case .year: return impactMinutes * 365 // Sustained over year
            }
            
        case .nutritionQuality, .stressLevel, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality:
            // Lifestyle metrics: represent ongoing habits
            switch periodType {
            case .day: return impactMinutes // One day
            case .month: return impactMinutes * 30 // 30 days of habit
            case .year: return impactMinutes * 365 // 365 days of habit
            }
            
        case .bodyMass:
            // Body composition: represents sustained metabolic impact
            switch periodType {
            case .day: return impactMinutes // Current impact
            case .month: return impactMinutes * 30 // Sustained metabolic effect
            case .year: return impactMinutes * 365 // Long-term metabolic effect
            }
            
        @unknown default:
            // Default scaling for unknown metrics
            return scaleImpact(impactMinutes, for: periodType)
        }
    }
    
    // MARK: - Dashboard Integration Methods
    
    /// Calculate life impact data for dashboard display
    func calculateLifeImpact(from metrics: [HealthMetric], for timePeriod: TimePeriod, userProfile: UserProfile) -> LifeImpactData? {
        logger.info("🔄 Calculating life impact for \(metrics.count) metrics over \(timePeriod.displayName)")
        
        // Calculate total impact using existing methods
        let impactDataPoint = calculateTotalImpact(from: metrics, for: timePeriod.impactDataPointPeriodType)
        
        // Convert to LifeImpactData for dashboard consumption
        let lifeImpactData = LifeImpactData(from: impactDataPoint)
        
        logger.info("✅ Life impact calculated: \(lifeImpactData.totalImpact.displayString) with \(String(format: "%.1f", lifeImpactData.batteryLevel))% battery level")
        
        return lifeImpactData
    }
} 