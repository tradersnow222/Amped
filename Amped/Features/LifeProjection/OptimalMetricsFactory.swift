import Foundation

/// Factory that produces scientifically optimal health metrics for a user profile.
/// Applied rules: Simplicity is KING; reuse via a tiny focused helper; no placeholders — values are based on cited research in the codebase.
struct OptimalMetricsFactory {
    static func createScientificallyOptimalMetrics(for userProfile: UserProfile) -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        let now = Date()

        // PHYSICAL ACTIVITY METRICS (research-backed)
        metrics.append(HealthMetric(id: "optimal_steps", type: .steps, value: 12000, date: now, source: .calculated))
        metrics.append(HealthMetric(id: "optimal_exercise", type: .exerciseMinutes, value: 45, date: now, source: .calculated))

        // CARDIOVASCULAR METRICS (research-backed)
        metrics.append(HealthMetric(id: "optimal_sleep", type: .sleepHours, value: 7.5, date: now, source: .calculated))
        metrics.append(HealthMetric(id: "optimal_rhr", type: .restingHeartRate, value: 55, date: now, source: .calculated))

        let age = Double(userProfile.age ?? 30)
        let optimalHRV = max(50.0, 60.0 - (age - 30) * 0.5) // Age-adjusted excellent HRV
        metrics.append(HealthMetric(id: "optimal_hrv", type: .heartRateVariability, value: optimalHRV, date: now, source: .calculated))

        // LIFESTYLE METRICS (questionnaire scales)
        metrics.append(HealthMetric(id: "optimal_smoking", type: .smokingStatus, value: 10, date: now, source: .calculated))
        metrics.append(HealthMetric(id: "optimal_alcohol", type: .alcoholConsumption, value: 9, date: now, source: .calculated))
        metrics.append(HealthMetric(id: "optimal_stress", type: .stressLevel, value: 2, date: now, source: .calculated))
        metrics.append(HealthMetric(id: "optimal_nutrition", type: .nutritionQuality, value: 9, date: now, source: .calculated))
        metrics.append(HealthMetric(id: "optimal_social", type: .socialConnectionsQuality, value: 8, date: now, source: .calculated))

        // BODY COMPOSITION & FITNESS
        let gender = userProfile.gender ?? .male
        let optimalWeight = gender == .male ? 155.0 : 135.0
        metrics.append(HealthMetric(id: "optimal_weight", type: .bodyMass, value: optimalWeight, date: now, source: .calculated))

        let genderMultiplier = gender == .male ? 1.0 : 0.88
        let baseVO2Max = 50.0 * genderMultiplier
        let ageAdjustedVO2Max = max(baseVO2Max - max(0, age - 30) * 0.3, 35.0 * genderMultiplier)
        metrics.append(HealthMetric(id: "optimal_vo2max", type: .vo2Max, value: ageAdjustedVO2Max, date: now, source: .calculated))

        metrics.append(HealthMetric(id: "optimal_energy", type: .activeEnergyBurned, value: 600, date: now, source: .calculated))
        metrics.append(HealthMetric(id: "optimal_oxygen", type: .oxygenSaturation, value: 98, date: now, source: .calculated))

        return metrics
    }
}


