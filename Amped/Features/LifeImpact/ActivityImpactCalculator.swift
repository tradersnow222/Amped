import Foundation

/// Contains impact calculation methods for activity-related health metrics
struct ActivityImpactCalculator {
    
    /// Calculate impact for steps
    static func calculateStepsImpact(steps: Double, date: Date, studyReference: StudyReference?) -> MetricImpactDetail {
        // Baseline: 7500 steps is neutral (based on research)
        // Each 1000 steps over/under affects lifespan by 5 minutes
        
        let baseline = 7500.0
        let stepsImpactPerThousand = 5.0 // minutes per 1000 steps
        
        let difference = steps - baseline
        let impactMinutes = (difference / 1000.0) * stepsImpactPerThousand
        
        let comparison: ComparisonResult
        if steps > baseline * 1.1 {
            comparison = .better
        } else if steps < baseline * 0.9 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .steps,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison,
            scientificReference: studyReference?.citation
        )
    }
    
    /// Calculate impact for active energy burned
    static func calculateActiveEnergyImpact(calories: Double, date: Date) -> MetricImpactDetail {
        // Following rule: ACCURATE DATA DISPLAYED TO THE USER IS KING
        // Always calculate exact impact based on optimal baseline of 400 calories
        // Each 100 calories over/under affects lifespan by 2 minutes
        
        let optimalBaseline = 400.0 // Midpoint of previous neutral zone
        let caloriesImpactPer100 = 2.0 // minutes per 100 calories
        
        // Calculate exact impact from optimal baseline
        let difference = calories - optimalBaseline
        let impactMinutes = (difference / 100.0) * caloriesImpactPer100
        
        let comparison: ComparisonResult
        if calories > optimalBaseline * 1.25 { // Above 500
            comparison = .better
        } else if calories < optimalBaseline * 0.75 { // Below 300
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .activeEnergyBurned,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
    
    /// Calculate impact for exercise minutes
    static func calculateExerciseImpact(minutes: Double, date: Date) -> MetricImpactDetail {
        // Baseline: 30 minutes/day is neutral (based on WHO recommendations)
        // Each 10 minutes over/under affects lifespan by 7 minutes
        
        let baseline = 30.0
        let exerciseImpactPer10Min = 7.0 // minutes of life per 10 minutes of exercise
        
        let difference = minutes - baseline
        let impactMinutes = (difference / 10.0) * exerciseImpactPer10Min
        
        let comparison: ComparisonResult
        if minutes > baseline * 1.3 {
            comparison = .better
        } else if minutes < baseline * 0.7 {
            comparison = .worse
        } else {
            comparison = .same
        }
        
        return MetricImpactDetail(
            metricType: .exerciseMinutes,
            lifespanImpactMinutes: impactMinutes,
            comparisonToBaseline: comparison
        )
    }
} 