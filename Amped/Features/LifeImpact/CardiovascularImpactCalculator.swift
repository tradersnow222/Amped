import Foundation

/// Contains impact calculation methods for cardiovascular-related health metrics
struct CardiovascularImpactCalculator {
    
    /// Calculate impact for resting heart rate
    static func calculateRestingHeartRateImpact(bpm: Double, date: Date, age: Int) -> MetricImpactDetail {
        // Baseline depends on age and gender
        // Each 5 bpm over/under affects lifespan differently based on direction
        
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
        
        let comparison: ComparisonResult
        if bpm < baseline - 10 {
            comparison = .better
        } else if bpm > baseline + 10 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .restingHeartRate,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for heart rate variability
    static func calculateHRVImpact(ms: Double, date: Date, age: Int) -> MetricImpactDetail {
        // Higher HRV is generally better (indicates better stress recovery)
        // Baseline depends on age
        
        // Calculate baseline based on age (simplified)
        let baseline = 60.0 - (Double(age) / 3.0)
        
        let difference = ms - baseline
        
        // Higher HRV is generally better
        let impactMinutes = (difference / 5.0) * 6.0
        
        let comparison: ComparisonResult
        if ms > baseline * 1.2 {
            comparison = .better
        } else if ms < baseline * 0.8 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .heartRateVariability,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for VO2 Max
    static func calculateVO2MaxImpact(mlPerKgMin: Double, date: Date, age: Int, gender: UserProfile.Gender) -> MetricImpactDetail {
        // Baseline depends on age and gender
        // Each 1 ml/kg/min over/under affects lifespan by 15 minutes
        
        // Calculate baseline based on age and gender (simplified)
        var baseline: Double
        
        switch gender {
        case .male:
            baseline = 60.0 - (Double(age) / 3.0)
        case .female:
            baseline = 50.0 - (Double(age) / 3.0)
        case .preferNotToSay:
            baseline = 55.0 - (Double(age) / 3.0)
        }
        
        let difference = mlPerKgMin - baseline
        let impactMinutes = difference * 15.0
        
        let comparison: ComparisonResult
        if mlPerKgMin > baseline * 1.1 {
            comparison = .better
        } else if mlPerKgMin < baseline * 0.9 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .vo2Max,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for oxygen saturation
    static func calculateOxygenSaturationImpact(percentage: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-100, with 100 being baseline
        // Each point above/below affects lifespan by 20 minutes
        
        let baseline = 100.0
        let oxygenSaturationImpactPerPoint = 20.0
        
        let difference = percentage - baseline
        let impactMinutes = difference * oxygenSaturationImpactPerPoint
        
        // Anything below 95% is concerning
        let comparison: ComparisonResult
        if percentage >= 98 {
            comparison = .better
        } else if percentage < 95 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .oxygenSaturation,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
} 