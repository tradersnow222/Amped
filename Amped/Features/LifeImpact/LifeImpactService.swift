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
                age: userProfile.age ?? 35
            )
            
        case .heartRateVariability:
            return CardiovascularImpactCalculator.calculateHRVImpact(
                ms: metric.value,
                date: metric.date,
                age: userProfile.age ?? 35
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
                age: userProfile.age ?? 35,
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
        return StudyReferenceProvider.getStudyReference(for: metricType)
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
} 