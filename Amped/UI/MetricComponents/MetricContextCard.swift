import SwiftUI

/// Card showing contextual information about a health metric
struct MetricContextCard: View {
    // MARK: - Properties
    
    /// The health metric to show context for
    let metric: HealthMetric
    
    @Environment(\.themeManager) private var themeManager
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(metric.type.color)
                
                Text("About \(metric.type.name)")
                    .style(.cardTitle)
                
                Spacer()
            }
            
            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                Text(explanationTitle)
                    .style(.subheadlineBold)
                
                Text(explanationText)
                    .style(.bodySecondary)
                
                if let reference = metric.impactDetail?.studyReference {
                    Divider()
                    
                    // Research reference
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Research Reference")
                            .style(.subheadlineBold)
                        
                        Text(reference.title)
                            .style(.caption)
                        
                        Text(reference.shortCitation)
                            .style(.caption2)
                            .italic()
                    }
                }
            }
            
            // Baseline comparison
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended")
                        .style(.caption)
                    
                    Text("\(formatValue(metric.type.baselineValue)) \(metric.type.unit)")
                        .style(.bodyMedium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Value")
                        .style(.caption)
                    
                    Text("\(formatValue(metric.value)) \(metric.type.unit)")
                        .style(.bodyMedium, color: comparisonColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    /// Explanation title based on metric type
    private var explanationTitle: String {
        switch metric.type {
        case .steps:
            return "Why step count matters"
        case .activeEnergyBurned:
            return "About active calories"
        case .exerciseMinutes:
            return "Exercise and your health"
        case .restingHeartRate:
            return "Understanding resting heart rate"
        case .heartRateVariability:
            return "Heart rate variability"
        case .sleepHours:
            return "Sleep and your health"
        case .vo2Max:
            return "Cardio fitness level"
        case .oxygenSaturation:
            return "Blood oxygen levels"
        case .nutritionQuality:
            return "Nutrition quality"
        case .stressLevel:
            return "Stress management"
        }
    }
    
    /// Explanation text based on metric type
    private var explanationText: String {
        switch metric.type {
        case .steps:
            return "Regular walking can help maintain a healthy weight, strengthen bones, and improve balance and coordination."
        case .activeEnergyBurned:
            return "Active calories represent energy burned during physical activity. Staying active helps manage weight and improves cardiovascular health."
        case .exerciseMinutes:
            return "Regular exercise strengthens your heart, improves lung function, and helps manage weight and stress levels."
        case .restingHeartRate:
            return "Your resting heart rate is a key indicator of heart health and fitness. Lower is generally better, indicating a stronger heart."
        case .heartRateVariability:
            return "HRV measures the variation in time between heartbeats. Higher variability often indicates better cardiovascular health and stress resilience."
        case .sleepHours:
            return "Quality sleep supports immune function, metabolism, and cognitive performance. Adults typically need 7-9 hours per night."
        case .vo2Max:
            return "VO2 max measures the maximum amount of oxygen your body can use during exercise, indicating cardiovascular fitness."
        case .oxygenSaturation:
            return "Blood oxygen saturation indicates how well your lungs are delivering oxygen to your blood. Normal levels are typically 95-100%."
        case .nutritionQuality:
            return "A balanced diet rich in nutrients supports overall health, energy levels, and disease prevention."
        case .stressLevel:
            return "Managing stress is essential for mental health, immune function, and reducing inflammation throughout the body."
        }
    }
    
    /// Color for the comparison value
    private var comparisonColor: Color {
        guard let impact = metric.impactDetail else { return .primary }
        
        switch impact.comparisonToBaseline {
        case .muchBetter, .better, .slightlyBetter:
            return .ampedGreen
        case .nearBaseline, .same:
            return .primary
        case .slightlyWorse, .worse, .muchWorse:
            return .ampedRed
        @unknown default:
            return .primary
        }
    }
    
    /// Format the value with appropriate precision
    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            return String(format: "%.1f", value)
        }
    }
}

#Preview {
    VStack {
        MetricContextCard(
            metric: HealthMetric(
                type: .steps,
                value: 8500,
                date: Date(),
                impactDetail: MetricImpactDetail(
                    metricType: .steps,
                    lifespanImpactMinutes: 12.5,
                    comparisonToBaseline: .better,
                    studyReference: StudyReference(
                        title: "Association of Daily Step Count and Step Intensity With Mortality Among US Adults",
                        authors: "Saint-Maurice PF, Troiano RP, Bassett DR Jr, et al.",
                        journalName: "JAMA",
                        publicationYear: 2020,
                        doi: "10.1001/jama.2020.0030",
                        summary: "This study found that higher daily step counts were associated with lower all-cause mortality."
                    )
                )
            )
        )
        
        MetricContextCard(
            metric: HealthMetric(
                type: .sleepHours,
                value: 6.5,
                date: Date(),
                impactDetail: MetricImpactDetail(
                    metricType: .sleepHours,
                    lifespanImpactMinutes: -5.2,
                    comparisonToBaseline: .slightlyWorse,
                    studyReference: StudyReference(
                        title: "Sleep Duration and All-Cause Mortality: A Systematic Review and Meta-Analysis",
                        authors: "Cappuccio FP, D'Elia L, Strazzullo P, Miller MA",
                        journalName: "Sleep",
                        publicationYear: 2010,
                        doi: "10.1093/sleep/33.5.585",
                        summary: "This meta-analysis found that both short and long duration of sleep are significant predictors of death."
                    )
                )
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 