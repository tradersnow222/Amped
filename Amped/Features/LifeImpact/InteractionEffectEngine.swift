import Foundation
import OSLog

/// Engine for calculating interaction effects between health metrics based on research
/// Handles synergies and antagonistic effects between different health behaviors
final class InteractionEffectEngine {
    private let logger = Logger(subsystem: "Amped", category: "InteractionEffectEngine")
    
    // MARK: - Interaction Coefficients (Research-Based)
    
    /// Known synergy coefficients from research literature
    private enum InteractionCoefficient {
        // Positive synergies (1.0 = no interaction, >1.0 = positive synergy)
        static let sleepExerciseSynergy = 1.15 // 15% boost when both are optimal
        static let exerciseHRVSynergy = 1.10 // 10% boost to HRV benefits from exercise
        static let nutritionExerciseSynergy = 1.12 // 12% boost when both are good
        
        // Negative interactions (<1.0 = antagonistic effect)
        static let alcoholHRVAntagonism = 0.75 // 25% reduction in HRV benefits
        static let alcoholSleepAntagonism = 0.80 // 20% reduction in sleep benefits
        static let stressSleepAntagonism = 0.85 // 15% reduction in sleep benefits
        
        // Complex interactions
        static let bodyMassActivityThreshold = 200.0 // lbs - above this, activity benefits reduced
        static let bodyMassActivityReduction = 0.90 // 10% reduction per 20 lbs over threshold
    }
    
    // MARK: - Public Interface
    
    /// Calculate adjusted impacts considering all interaction effects
    func calculateAdjustedImpacts(
        impacts: [MetricImpactDetail],
        metrics: [HealthMetric]
    ) -> [MetricImpactDetail] {
        logger.info("🔄 Calculating interaction effects for \(impacts.count) metrics")
        
        // Create lookup dictionaries
        let impactsByType = Dictionary(uniqueKeysWithValues: impacts.map { ($0.metricType, $0) })
        let metricsByType = Dictionary(uniqueKeysWithValues: metrics.map { ($0.type, $0) })
        
        // Calculate all interaction adjustments
        var adjustedImpacts = impacts
        
        // Sleep x Exercise synergy
        if let sleepImpact = impactsByType[.sleepHours],
           let exerciseImpact = impactsByType[.exerciseMinutes] {
            let synergy = calculateSleepExerciseSynergy(
                sleepImpact: sleepImpact,
                exerciseImpact: exerciseImpact,
                metrics: metricsByType
            )
            adjustedImpacts = applyInteraction(
                to: adjustedImpacts,
                types: [.sleepHours, .exerciseMinutes],
                adjustment: synergy
            )
        }
        
        // Alcohol x HRV antagonism
        if let alcoholImpact = impactsByType[.alcoholConsumption],
           let hrvImpact = impactsByType[.heartRateVariability] {
            let antagonism = calculateAlcoholHRVAntagonism(
                alcoholImpact: alcoholImpact,
                hrvImpact: hrvImpact,
                metrics: metricsByType
            )
            adjustedImpacts = applyInteraction(
                to: adjustedImpacts,
                types: [.heartRateVariability],
                adjustment: antagonism
            )
        }
        
        // Body Mass x Activity interaction
        if let bodyMassImpact = impactsByType[.bodyMass],
           let stepsImpact = impactsByType[.steps] {
            let adjustment = calculateBodyMassActivityInteraction(
                bodyMassImpact: bodyMassImpact,
                activityImpact: stepsImpact,
                metrics: metricsByType
            )
            adjustedImpacts = applyInteraction(
                to: adjustedImpacts,
                types: [.steps, .exerciseMinutes],
                adjustment: adjustment
            )
        }
        
        // Stress x Sleep antagonism
        if let stressImpact = impactsByType[.stressLevel],
           let sleepImpact = impactsByType[.sleepHours] {
            let antagonism = calculateStressSleepAntagonism(
                stressImpact: stressImpact,
                sleepImpact: sleepImpact,
                metrics: metricsByType
            )
            adjustedImpacts = applyInteraction(
                to: adjustedImpacts,
                types: [.sleepHours],
                adjustment: antagonism
            )
        }
        
        logger.info("✅ Interaction effects calculated and applied")
        return adjustedImpacts
    }
    
    // MARK: - Specific Interaction Calculations
    
    /// Calculate sleep-exercise synergy effect
    private func calculateSleepExerciseSynergy(
        sleepImpact: MetricImpactDetail,
        exerciseImpact: MetricImpactDetail,
        metrics: [HealthMetricType: HealthMetric]
    ) -> Double {
        guard let sleepMetric = metrics[.sleepHours],
              let exerciseMetric = metrics[.exerciseMinutes] else {
            return 1.0
        }
        
        // Both need to be in healthy ranges for synergy
        let sleepOptimal = sleepMetric.value >= 7.0 && sleepMetric.value <= 8.5
        let exerciseOptimal = exerciseMetric.value >= 20.0 // ~150 min/week
        
        if sleepOptimal && exerciseOptimal {
            logger.info("💪 Sleep-Exercise synergy detected: 15% boost")
            return InteractionCoefficient.sleepExerciseSynergy
        }
        
        return 1.0
    }
    
    /// Calculate alcohol-HRV antagonism
    private func calculateAlcoholHRVAntagonism(
        alcoholImpact: MetricImpactDetail,
        hrvImpact: MetricImpactDetail,
        metrics: [HealthMetricType: HealthMetric]
    ) -> Double {
        guard let alcoholMetric = metrics[.alcoholConsumption] else {
            return 1.0
        }
        
        // Any alcohol consumption reduces HRV benefits
        if alcoholMetric.value < 9.0 { // Not "never" drinker
            logger.info("🍷 Alcohol-HRV antagonism detected: 25% reduction")
            return InteractionCoefficient.alcoholHRVAntagonism
        }
        
        return 1.0
    }
    
    /// Calculate body mass-activity interaction
    private func calculateBodyMassActivityInteraction(
        bodyMassImpact: MetricImpactDetail,
        activityImpact: MetricImpactDetail,
        metrics: [HealthMetricType: HealthMetric]
    ) -> Double {
        guard let bodyMassMetric = metrics[.bodyMass] else {
            return 1.0
        }
        
        // Above threshold, activity benefits are reduced
        if bodyMassMetric.value > InteractionCoefficient.bodyMassActivityThreshold {
            let excess = bodyMassMetric.value - InteractionCoefficient.bodyMassActivityThreshold
            let reductionFactor = InteractionCoefficient.bodyMassActivityReduction
            let adjustment = pow(reductionFactor, excess / 20.0) // 10% per 20 lbs
            
            logger.info("⚖️ Body mass reducing activity benefits: \(String(format: "%.0f%%", (1 - adjustment) * 100))")
            return adjustment
        }
        
        return 1.0
    }
    
    /// Calculate stress-sleep antagonism
    private func calculateStressSleepAntagonism(
        stressImpact: MetricImpactDetail,
        sleepImpact: MetricImpactDetail,
        metrics: [HealthMetricType: HealthMetric]
    ) -> Double {
        guard let stressMetric = metrics[.stressLevel] else {
            return 1.0
        }
        
        // High stress reduces sleep benefits
        if stressMetric.value > 6.0 {
            logger.info("😰 Stress-Sleep antagonism detected: 15% reduction")
            return InteractionCoefficient.stressSleepAntagonism
        }
        
        return 1.0
    }
    
    // MARK: - Helper Methods
    
    /// Apply interaction adjustment to specific metric types
    private func applyInteraction(
        to impacts: [MetricImpactDetail],
        types: [HealthMetricType],
        adjustment: Double
    ) -> [MetricImpactDetail] {
        return impacts.map { impact in
            if types.contains(impact.metricType) {
                // Create adjusted impact
                return MetricImpactDetail(
                    metricType: impact.metricType,
                    currentValue: impact.currentValue,
                    baselineValue: impact.baselineValue,
                    studyReferences: impact.studyReferences,
                    lifespanImpactMinutes: impact.lifespanImpactMinutes * adjustment,
                    calculationMethod: impact.calculationMethod,
                    recommendation: impact.recommendation,
                    improvementPotential: impact.improvementPotential
                )
            }
            return impact
        }
    }
    
    /// Get description of active interactions for UI
    func getActiveInteractions(
        for metrics: [HealthMetric]
    ) -> [InteractionDescription] {
        var interactions: [InteractionDescription] = []
        
        let metricsByType = Dictionary(uniqueKeysWithValues: metrics.map { ($0.type, $0) })
        
        // Check each known interaction
        if let sleep = metricsByType[.sleepHours],
           let exercise = metricsByType[.exerciseMinutes],
           sleep.value >= 7.0 && sleep.value <= 8.5 && exercise.value >= 20.0 {
            interactions.append(InteractionDescription(
                title: "Sleep-Exercise Synergy",
                description: "Your good sleep and regular exercise are amplifying each other's benefits",
                impactModifier: "+15%",
                isPositive: true
            ))
        }
        
        if let alcohol = metricsByType[.alcoholConsumption],
           metricsByType[.heartRateVariability] != nil,
           alcohol.value < 9.0 {
            interactions.append(InteractionDescription(
                title: "Alcohol-HRV Impact",
                description: "Alcohol consumption is reducing your heart rate variability benefits",
                impactModifier: "-25%",
                isPositive: false
            ))
        }
        
        return interactions
    }
}

// MARK: - Supporting Types

/// Description of an active interaction for UI display
struct InteractionDescription {
    let title: String
    let description: String
    let impactModifier: String
    let isPositive: Bool
} 