import SwiftUI

/// Card showing contextual information about a health metric
struct MetricContextCard: View {
    // MARK: - Properties
    
    /// The health metric to show context for
    let metric: HealthMetric
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(metric.type.color)
                
                Text("About \(metric.type.name)")
                    .font(.headline)
                
                Spacer()
            }
            
            // Explanation
            VStack(alignment: .leading, spacing: 12) {
                Text(explanationTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(explanationText)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                if let reference = metric.impactDetail?.studyReference {
                    Divider()
                    
                    // Research reference
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Research Reference")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(reference.title)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(reference.shortCitation)
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                            .italic()
                    }
                }
            }
            
            // Baseline comparison
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(formatValue(metric.type.baselineValue)) \(metric.type.unit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Value")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(formatValue(metric.value)) \(metric.type.unit)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(comparisonColor)
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
            return "Why Daily Steps Matter"
        case .sleepHours:
            return "The Importance of Quality Sleep"
        case .activeEnergyBurned:
            return "Active Energy and Longevity"
        case .restingHeartRate:
            return "Resting Heart Rate and Heart Health"
        case .heartRateVariability:
            return "Heart Rate Variability and Recovery"
        case .oxygenSaturation:
            return "Oxygen Saturation and Overall Health"
        case .vo2Max:
            return "VO2 Max and Cardiorespiratory Fitness"
        case .nutritionQuality:
            return "Nutritional Quality and Health Outcomes"
        case .stressLevel:
            return "Stress Management and Aging"
        @unknown default:
            return "Health Metrics and Longevity"
        }
    }
    
    /// Explanation text based on metric type
    private var explanationText: String {
        switch metric.type {
        case .steps:
            return "Regular walking can improve cardiovascular health, help maintain a healthy weight, and reduce risk of chronic diseases. Research suggests that even modest increases in daily steps can decrease mortality risk."
            
        case .sleepHours:
            return "Quality sleep is essential for cellular repair, immune function, and cognitive processing. Both short and long sleep duration have been associated with increased mortality risk and chronic health conditions."
            
        case .activeEnergyBurned:
            return "Physical activity helps maintain muscle mass, supports cardiovascular health, and improves metabolic function. Higher energy expenditure (within reasonable limits) is associated with reduced mortality risk."
            
        case .restingHeartRate:
            return "Your resting heart rate is an indicator of cardiovascular fitness. A lower resting heart rate generally indicates better heart function and has been associated with reduced risk of cardiovascular disease."
            
        case .heartRateVariability:
            return "HRV reflects your autonomic nervous system function and adaptability to stress. Higher HRV indicates better recovery capacity and has been linked to improved resilience, longevity, and reduced risk of cardiovascular issues."
            
        case .oxygenSaturation:
            return "Blood oxygen levels reflect how efficiently your lungs, heart, and circulation are working together. Maintaining optimal oxygen saturation supports all bodily functions and is essential for cellular health and energy production."
            
        case .vo2Max:
            return "VO2 Max is one of the best predictors of overall health and longevity. This measure of cardiorespiratory fitness indicates how efficiently your body uses oxygen and has strong associations with reduced all-cause mortality."
            
        case .nutritionQuality:
            return "Diets rich in whole foods and limited in processed foods are associated with reduced inflammation and 20-30% lower mortality risk."
            
        case .stressLevel:
            return "Chronic high stress levels may accelerate biological aging by 2-6 years through telomere shortening and increased oxidative stress."
            
        @unknown default:
            return "Your health metrics provide valuable insights into your biological age and longevity. Regular monitoring and gradual improvements can significantly impact your long-term health outcomes."
        }
    }
    
    /// Format value based on metric type
    private func formatValue(_ value: Double) -> String {
        switch metric.type {
        case .steps:
            return "\(Int(value))"
        case .sleepHours:
            return String(format: "%.1f", value)
        case .activeEnergyBurned:
            return "\(Int(value))"
        case .restingHeartRate:
            return "\(Int(value))"
        case .heartRateVariability:
            return String(format: "%.1f", value)
        case .oxygenSaturation:
            return String(format: "%.1f%%", value)
        case .vo2Max:
            return String(format: "%.1f", value)
        case .nutritionQuality, .stressLevel:
            return String(format: "%.1f", value)
        @unknown default:
            return "N/A"
        }
    }
    
    /// Get color for comparison based on whether the user's value is better or worse than baseline
    private var comparisonColor: Color {
        guard let comparison = metric.impactDetail?.comparisonToBaseline else {
            return .primary
        }
        
        switch comparison {
        case .muchBetter, .better:
            return .green
        case .slightlyBetter, .nearBaseline, .slightlyWorse:
            return .primary
        case .worse, .muchWorse:
            return .red
        case .same:
            return .primary
        case nil:
            return .secondary
        @unknown default:
            return .secondary
        }
    }
    
    /// Visual interpretation of comparison result
    private var comparisonDescription: String {
        switch metric.impactDetail?.comparisonToBaseline {
        case .muchBetter, .better:
            return "Significantly better than baseline"
        case .slightlyBetter, .nearBaseline, .slightlyWorse:
            return "Near your baseline"
        case .worse, .muchWorse:
            return "Below your baseline"
        case .same:
            return "At your baseline"
        case nil:
            return "No comparison data available"
        @unknown default:
            return "Comparison data available"
        }
    }
    
    private var valueText: String {
        switch metric.type {
        case .steps:
            return NumberFormatter.localizedString(from: NSNumber(value: Int(metric.value)), number: .decimal)
        case .activeEnergyBurned:
            return String(format: "%.0f kcal", metric.value)
        case .exerciseMinutes:
            return String(format: "%.0f min", metric.value)
        case .restingHeartRate:
            return String(format: "%.0f bpm", metric.value)
        case .heartRateVariability:
            return String(format: "%.0f ms", metric.value)
        case .sleepHours:
            return String(format: "%.1f hrs", metric.value)
        case .vo2Max:
            return String(format: "%.1f ml/kg/min", metric.value)
        case .oxygenSaturation:
            return String(format: "%.1f%%", metric.value)
        case .nutritionQuality:
            return String(format: "%.1f/10", metric.value)
        case .stressLevel:
            return String(format: "%.1f/10", metric.value)
        @unknown default:
            return String(format: "%.1f", metric.value)
        }
    }
    
    private var unitText: String {
        switch metric.type {
        case .steps:
            return "steps"
        case .activeEnergyBurned:
            return "kcal"
        case .exerciseMinutes:
            return "min"
        case .restingHeartRate:
            return "bpm"
        case .heartRateVariability:
            return "ms"
        case .sleepHours:
            return "hrs"
        case .vo2Max:
            return "ml/kg/min"
        case .oxygenSaturation:
            return "%"
        case .nutritionQuality, .stressLevel:
            return "/10"
        @unknown default:
            return ""
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