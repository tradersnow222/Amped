import Foundation

/// Single source of truth for manual metric scoring using low/moderate/high levels.
/// Provides study-aligned numeric values that flow into LifestyleImpactCalculator and cardiovascular calculators.
enum ManualMetric {
    case stress
    case anxiety
    case nutrition
    case smoking
    case alcohol
    case social
    case bloodPressure // systolic mmHg
}

enum ManualLevel: String, CaseIterable, Codable {
    case low
    case moderate
    case high
}

enum ManualMetricScoring {
    /// Map ManualMetric to HealthMetricType
    static func metricType(for metric: ManualMetric) -> HealthMetricType {
        switch metric {
        case .stress:        return .stressLevel
        case .anxiety:       return .stressLevel // Anxiety can be merged with stress (see QuestionnaireManager combine)
        case .nutrition:     return .nutritionQuality
        case .smoking:       return .smokingStatus
        case .alcohol:       return .alcoholConsumption
        case .social:        return .socialConnectionsQuality
        case .bloodPressure: return .bloodPressure
        }
    }
    
    /// Numeric value for a low/moderate/high level per metric.
    /// - Lifestyle metrics return 1–10 scale values expected by LifestyleImpactCalculator.
    /// - Blood pressure returns systolic mmHg used by cardiovascular calculator.
    static func value(for metric: ManualMetric, level: ManualLevel) -> Double {
        switch metric {
        case .stress:
            // 1–10 scale; lower is better for stress (calculator handles direction)
            switch level {
            case .low:      return 10.0
            case .moderate: return 6.0
            case .high:     return 2.0
            }
        case .anxiety:
            // 1–10 scale; lower anxiety risk mapped to higher score for consistency with pipeline
            switch level {
            case .low:      return 10.0
            case .moderate: return 6.0
            case .high:     return 2.0
            }
        case .nutrition:
            // 1–10 scale; higher is better
            switch level {
            case .low:      return 10.0
            case .moderate: return 7.0
            case .high:     return 1.0
            }
        case .smoking:
            // 1–10 scale; 10 = never, 6 = former, 1 = daily
            switch level {
            case .low:      return 10.0
            case .moderate: return 6.0
            case .high:     return 1.0
            }
        case .alcohol:
            // 1–10 scale; 10 = never, 7 = occasionally, 1.5 = daily/heavy
            switch level {
            case .low:      return 10.0
            case .moderate: return 7.0
            case .high:     return 1.5
            }
        case .social:
            // 1–10 scale; higher is better
            switch level {
            case .low:      return 10.0
            case .moderate: return 6.0
            case .high:     return 1.0
            }
        case .bloodPressure:
            // Systolic mmHg; low = <120, moderate = 120–129/Stage 1 cue, high = unknown → baseline
            switch level {
            case .low:      return 115.0
            case .moderate: return 125.0
            case .high:     return HealthMetricType.bloodPressure.baselineValue
            }
        }
    }
    
    /// Robust string-to-level mapping that understands current onboarding labels.
    /// Keeps UI unchanged while removing duplication elsewhere.
    static func level(from string: String, for metric: ManualMetric) -> ManualLevel? {
        let s = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch metric {
        case .stress:
            // StressStatsView: "Low", "Moderate", "High"
            if s.contains("very low") || s == "low" { return .low }
            if s.contains("moderate") { return .moderate }
            if s.contains("very high") || s == "high" { return .high }
        case .anxiety:
            // AnxietyStatsView: "Mild", "Moderate", "Severe"
            if s.contains("minimal") || s == "mild" { return .low }
            if s == "moderate" || s.contains("mild to moderate") { return .moderate }
            if s.contains("severe") { return .high }
        case .nutrition:
            // DietStatsView: "Very Healthy", "Mixed", "Very unhealthy"
            if s.contains("very healthy") { return .low }
            if s.contains("mixed") || s.contains("mostly") { return .moderate }
            if s.contains("unhealthy") { return .high }
        case .smoking:
            // SmokeStatsView: "Never", "Former smoker", "Daily"
            if s.contains("never") { return .low }
            if s.contains("former") { return .moderate }
            if s.contains("daily") || s.contains("current") { return .high }
        case .alcohol:
            // AlcoholicStatsView: "Never", "Occasionally", "Daily or Heavy"
            if s.contains("never") { return .low }
            if s.contains("occasion") || s.contains("weekly") { return .moderate }
            if s.contains("daily") || s.contains("heavy") { return .high }
        case .social:
            // SocialConnectionStatsView: "Very Strong", "Moderate", "Isolated"
            if s.contains("very strong") { return .low }
            if s.contains("moderate") || s.contains("good") { return .moderate }
            if s.contains("isolated") || s.contains("limited") { return .high }
        case .bloodPressure:
            // BloodPressureReadingView: "Below 120/80", "130/80+", "I don’t know"
            if s.contains("below 120") || s.contains("normal") { return .low }
            if s.contains("130") || s.contains("80+") || s.contains("elevated") || s.contains("stage") { return .moderate }
            if s.contains("don") || s.contains("know") || s.contains("unknown") { return .high }
        }
        return nil
    }
}
