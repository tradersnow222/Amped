import SwiftUI
import HealthKit

/// Card showing contextual information about a health metric
struct MetricContextCard: View {
    // MARK: - Properties
    
    /// The health metric to show context for
    let metric: HealthMetric
    
    @EnvironmentObject var themeManager: BatteryThemeManager
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            explanationSection
            comparisonSection
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(metric.type.color)
            
            Text("About \(metric.type.name)")
                .font(.headline)
            
            Spacer()
        }
    }
    
    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(explanationTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(explanationText)
                .font(.body)
                .foregroundColor(.secondary)
            
            if let firstStudy = metric.impactDetails?.studyReferences.first {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Research Reference")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(firstStudy.shortCitation)
                        .font(.caption)
                }
            }
        }
    }
    
    private var comparisonSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recommended")
                    .font(.caption)
                
                Text("\(formatValueWithUnit(metric.type.baselineValue, for: metric.type))")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
                .frame(height: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Value")
                    .font(.caption)
                
                Text("\(formatValueWithUnit(metric.value, for: metric.type))")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(comparisonColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
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
        case .bodyMass:
            return "Weight management"
        case .smokingStatus:
            return "Smoking and health"
        case .alcoholConsumption:
            return "Alcohol consumption"
        case .socialConnectionsQuality:
            return "Social connections"
        case .bloodPressure:
            return "Blood pressure management"
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
        case .bodyMass:
            return "Maintaining a healthy weight reduces the risk of chronic diseases and improves overall health and longevity."
        case .smokingStatus:
            return "Avoiding smoking significantly increases life expectancy and reduces the risk of numerous diseases."
        case .alcoholConsumption:
            return "Moderate to no alcohol consumption is associated with better health outcomes and reduced disease risk."
        case .socialConnectionsQuality:
            return "Strong social connections are linked to better mental health, immune function, and overall longevity."
        case .bloodPressure:
            return "Healthy blood pressure reduces the risk of heart disease, stroke, and other cardiovascular complications."
        }
    }
    
    /// Color for the comparison value
    private var comparisonColor: Color {
        guard let impact = metric.impactDetails else { return .primary }
        
        // Calculate comparison based on lifespan impact minutes
        let impactValue = impact.lifespanImpactMinutes
        
        if impactValue > 0 {
            return .ampedGreen // Positive impact
        } else if impactValue < 0 {
            return .ampedRed // Negative impact
        } else {
            return .primary // Neutral impact
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
    
    /// Format value with appropriate unit
    private func formatValueWithUnit(_ value: Double, for metricType: HealthMetricType) -> String {
        switch metricType {
        case .steps:
            return "\(Int(value)) steps"
        case .exerciseMinutes:
            return "\(Int(value)) min"
        case .sleepHours:
            return String(format: "%.1f hrs", value)
        case .heartRateVariability:
            return "\(Int(value)) ms"
        case .restingHeartRate:
            return "\(Int(value)) bpm"
        case .bodyMass:
            let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
            let displayValue = useMetric ? value : value * 2.20462
            return String(format: "%.1f %@", displayValue, useMetric ? "kg" : "lbs")
        case .activeEnergyBurned:
            return "\(Int(value)) cal"
        case .vo2Max:
            return String(format: "%.1f mL/kg/min", value)
        case .oxygenSaturation:
            return String(format: "%.0f%%", value)
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return String(format: "%.1f score", value)
        case .bloodPressure:
            return String(format: "%.0f mmHg", value)
        }
    }
}

#Preview {
    VStack {
        MetricContextCard(
            metric: HealthMetric(
                id: UUID().uuidString,
                type: .steps,
                value: 8500,
                date: Date(),
                source: .healthKit,
                impactDetails: MetricImpactDetail(
                    metricType: .steps,
                    currentValue: 8500,
                    baselineValue: 8000,
                    studyReferences: [],
                    lifespanImpactMinutes: 12.5,
                    calculationMethod: .metaAnalysisSynthesis,
                    recommendation: "Excellent step count! Keep up the great work."
                )
            )
        )
        
        MetricContextCard(
            metric: HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: 6.5,
                date: Date(),
                source: .healthKit,
                impactDetails: MetricImpactDetail(
                    metricType: .sleepHours,
                    currentValue: 6.5,
                    baselineValue: 7.5,
                    studyReferences: [],
                    lifespanImpactMinutes: -5.2,
                    calculationMethod: .metaAnalysisSynthesis,
                    recommendation: "Aim for 7-9 hours of sleep per night for optimal health."
                )
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
} 