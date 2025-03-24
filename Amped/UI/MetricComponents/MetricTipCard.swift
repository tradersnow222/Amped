import Foundation
import SwiftUI

/// Card showing actionable tips for improving a specific health metric
struct MetricTipCard: View {
    // MARK: - Properties
    
    /// The health metric to show tips for
    let metric: HealthMetric
    
    /// Whether the card is in expanded state
    @State private var isExpanded: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Label("Power Up Tip", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            // Tip content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tipTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(primaryTip)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(secondaryTip)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if let actionableStep = actionableStep {
                        Divider()
                        
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.yellow)
                            
                            Text("Quick Action: \(actionableStep)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    /// Background color based on metric type
    private var cardBackgroundColor: Color {
        let baseColor = metric.type.color.opacity(0.1)
        return Color(.systemBackground).opacity(0.8).blended(with: baseColor)
    }
    
    /// Tip title based on metric type
    private var tipTitle: String {
        switch metric.type {
        case .steps:
            return "Increase Your Daily Steps"
        case .sleepHours:
            return "Improve Sleep Quality"
        case .activeEnergyBurned:
            return "Boost Your Active Energy"
        case .restingHeartRate:
            return "Optimize Heart Health"
        case .heartRateVariability:
            return "Enhance Recovery"
        case .oxygenSaturation:
            return "Maintain Optimal Oxygen Levels"
        case .vo2Max:
            return "Increase Cardio Fitness"
        case .nutritionQuality:
            return "Improve Nutrition Quality"
        case .stressLevel:
            return "Manage Stress Levels"
        @unknown default:
            return "Improve Your Health"
        }
    }
    
    /// First tip detail based on metric type
    private var primaryTip: String {
        switch metric.type {
        case .steps:
            return "Take a 10-minute walk after each meal"
        case .sleepHours:
            return "Establish a consistent sleep schedule"
        case .activeEnergyBurned:
            return "Mix cardio and strength training"
        case .restingHeartRate:
            return "Practice deep breathing exercises"
        case .heartRateVariability:
            return "Include recovery days in your routine"
        case .oxygenSaturation:
            return "Practice diaphragmatic breathing"
        case .vo2Max:
            return "Add interval training to your workouts"
        case .nutritionQuality:
            return "Add more colorful vegetables to meals"
        case .stressLevel:
            return "Practice daily mindfulness meditation"
        @unknown default:
            return "Maintain consistent healthy habits"
        }
    }
    
    /// Second tip detail based on metric type
    private var secondaryTip: String {
        switch metric.type {
        case .steps:
            return "Park farther away and take stairs when possible"
        case .sleepHours:
            return "Limit screen time 1 hour before bed"
        case .activeEnergyBurned:
            return "Find activities you enjoy to stay motivated"
        case .restingHeartRate:
            return "Stay well hydrated throughout the day"
        case .heartRateVariability:
            return "Prioritize quality sleep and relaxation"
        case .oxygenSaturation:
            return "Consider air quality in your environment"
        case .vo2Max:
            return "Gradually increase workout intensity"
        case .nutritionQuality:
            return "Focus on whole foods and limit processed items"
        case .stressLevel:
            return "Take a 5-minute mindfulness break"
        @unknown default:
            return "Focus on one small improvement each day"
        }
    }
    
    /// Actionable step based on metric type
    private var actionableStep: String? {
        switch metric.type {
        case .steps:
            return "Take a 10-minute walk after lunch"
        case .sleepHours:
            return "Set a regular bedtime tonight"
        case .activeEnergyBurned:
            return "Schedule a 20-minute workout today"
        case .restingHeartRate:
            return "Practice deep breathing for 5 minutes"
        case .heartRateVariability:
            return "Add a 10-minute recovery session today"
        case .oxygenSaturation:
            return "Practice diaphragmatic breathing"
        case .vo2Max:
            return "Add interval training to your next workout"
        case .nutritionQuality:
            return "Add one extra vegetable serving today"
        case .stressLevel:
            return "Take a 5-minute mindfulness break now"
        @unknown default:
            return "Focus on one health habit today"
        }
    }
    
    private var cardTitle: String {
        switch metric.impactDetail?.comparisonToBaseline {
        case .muchBetter, .better, .slightlyBetter:
            return "Keep up the good work!"
        case .nearBaseline, .same:
            return "You're on the right track"
        case .slightlyWorse:
            return "Room for improvement"
        case .worse, .muchWorse:
            return "Let's focus on this area"
        case nil:
            return "Tips for improvement"
        @unknown default:
            return "Health tips"
        }
    }
}

// MARK: - Helper Extensions

extension Color {
    /// Blend this color with another color
    func blended(with color: Color, ratio: CGFloat = 0.5) -> Color {
        // Create an intermediate Color that blends the two colors
        // This is a simplified implementation - a real implementation would interpolate RGB values
        let r1 = ratio
        let r2 = 1 - ratio
        
        // Using opacity is not accurate for true color blending
        // In a real app, you would implement proper color interpolation
        return self.opacity(r2) * r2 + color.opacity(r1) * r1
    }
}

// Helper operators for color math
extension Color {
    static func * (color: Color, value: CGFloat) -> Color {
        // This is a placeholder implementation
        // In a real app, you would implement proper scaling of color components
        return color.opacity(value)
    }
    
    static func + (lhs: Color, rhs: Color) -> Color {
        // This is a placeholder implementation that just returns the first color
        // In a real app, you would implement proper color addition
        return lhs
    }
}

#Preview {
    VStack(spacing: 20) {
        MetricTipCard(
            metric: HealthMetric(
                type: .steps,
                value: 6500,
                date: Date()
            )
        )
        
        MetricTipCard(
            metric: HealthMetric(
                type: .sleepHours,
                value: 6.5,
                date: Date()
            )
        )
    }
    .padding()
} 