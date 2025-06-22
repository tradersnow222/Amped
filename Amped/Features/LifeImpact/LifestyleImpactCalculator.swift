import Foundation

/// Contains impact calculation methods for lifestyle-related health metrics
struct LifestyleImpactCalculator {
    
    /// Calculate impact for sleep hours
    static func calculateSleepImpact(hours: Double, date: Date, studyReference: StudyReference?) -> MetricImpactDetail {
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
        
        let comparison: ComparisonResult
        if hours >= lowerBaseline && hours <= upperBaseline {
            comparison = .better
        } else if hours < 6.0 || hours > 9.0 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .sleepHours,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison,
            scientificReference: studyReference?.citation
        )
    }
    
    /// Calculate impact for nutrition quality
    static func calculateNutritionImpact(quality: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-10, with 7 being baseline (good but not excellent nutrition)
        // Each point affects lifespan by 20 minutes
        
        let baseline = 7.0
        let nutritionImpactPerPoint = 20.0
        
        let difference = quality - baseline
        let impactMinutes = difference * nutritionImpactPerPoint
        
        let comparison: ComparisonResult
        if quality > baseline + 1 {
            comparison = .better
        } else if quality < baseline - 1 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .nutritionQuality,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for stress level
    static func calculateStressImpact(level: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-10, with 0 being lowest stress (best)
        // 3 is baseline (moderate stress)
        // Each point above baseline affects lifespan by -15 minutes
        // Each point below baseline affects lifespan by 10 minutes
        
        let baseline = 3.0
        let stressNegativeImpactPerPoint = 15.0
        let stressPositiveImpactPerPoint = 10.0
        
        let difference = level - baseline
        var impactMinutes: Double
        
        if difference > 0 {
            // Higher stress is bad
            impactMinutes = -1.0 * difference * stressNegativeImpactPerPoint
        } else {
            // Lower stress is good
            impactMinutes = -1.0 * difference * stressPositiveImpactPerPoint
        }
        
        let comparison: ComparisonResult
        if level < baseline - 1 {
            comparison = .better
        } else if level > baseline + 1 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .stressLevel,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for smoking status
    static func calculateSmokingImpact(quality: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-10, with 10 being never smoked, 0 being heavy smoker
        // Each point affects lifespan by 30 minutes compared to baseline (7)
        
        let baseline = 7.0 // Former smoker who quit more than a few years ago
        let smokingImpactPerPoint = 30.0
        
        let difference = quality - baseline
        let impactMinutes = difference * smokingImpactPerPoint
        
        let comparison: ComparisonResult
        if quality > baseline + 1 {
            comparison = .better
        } else if quality < baseline - 1 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .smokingStatus,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for alcohol consumption
    static func calculateAlcoholImpact(quality: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-10, with 10 being never drinks, 0 being heavy drinker
        // Each point affects lifespan by 25 minutes compared to baseline (6)
        
        let baseline = 6.0 // Occasional social drinker
        let alcoholImpactPerPoint = 25.0
        
        let difference = quality - baseline
        let impactMinutes = difference * alcoholImpactPerPoint
        
        let comparison: ComparisonResult
        if quality > baseline + 1 {
            comparison = .better
        } else if quality < baseline - 1 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .alcoholConsumption,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for social connections
    static func calculateSocialConnectionsImpact(quality: Double, date: Date) -> MetricImpactDetail {
        // Scale: 0-10, with 10 being very strong connections
        // Each point affects lifespan by 20 minutes compared to baseline (6)
        
        let baseline = 6.0 // Moderate social connections
        let socialImpactPerPoint = 20.0
        
        let difference = quality - baseline
        let impactMinutes = difference * socialImpactPerPoint
        
        let comparison: ComparisonResult
        if quality > baseline + 1 {
            comparison = .better
        } else if quality < baseline - 1 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .socialConnectionsQuality,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for body mass (weight)
    static func calculateBodyMassImpact(kg: Double, date: Date, height: Double?) -> MetricImpactDetail {
        // Calculate BMI if height is available, otherwise use weight categories
        var impactMinutes: Double = 0
        var comparison: ComparisonResult = .same
        
        if let height = height {
            // Calculate BMI (kg/m²)
            let bmi = kg / (height * height)
            
            // BMI ranges based on WHO standards:
            // Underweight: < 18.5
            // Normal: 18.5-24.9
            // Overweight: 25-29.9
            // Obese: >= 30
            
            if bmi < 18.5 {
                // Underweight - negative impact
                let deficit = 18.5 - bmi
                impactMinutes = -deficit * 15.0
                comparison = .worse
            } else if bmi <= 24.9 {
                // Normal weight - positive impact
                impactMinutes = 10.0
                comparison = .better
            } else if bmi <= 29.9 {
                // Overweight - moderate negative impact
                let excess = bmi - 25.0
                impactMinutes = -excess * 8.0
                comparison = .worse
            } else {
                // Obese - significant negative impact
                let excess = bmi - 30.0
                impactMinutes = -40.0 - (excess * 12.0)
                comparison = .worse
            }
        } else {
            // If no height available, use rough weight categories (less accurate)
            // This is a fallback for when height data isn't available
            if kg < 50 {
                // Potentially underweight
                impactMinutes = -20.0
                comparison = .worse
            } else if kg <= 90 {
                // Reasonable weight range
                impactMinutes = 5.0
                comparison = .same
            } else {
                // Potentially overweight
                let excess = kg - 90
                impactMinutes = -excess * 2.0
                comparison = .worse
            }
        }
        
        return MetricImpactDetail(
            metricType: .bodyMass,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
} 