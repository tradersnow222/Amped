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
        // Use consistent theme background with slight metric color tint
        return Color.cardBackground
    }
    
    /// Tip title based on metric type - using battery metaphors
    private var tipTitle: String {
        switch metric.type {
        case .steps:
            return "Charge Up Your Daily Energy"
        case .sleepHours:
            return "Recharge Your Recovery Battery"
        case .activeEnergyBurned:
            return "Boost Your Power Output"
        case .restingHeartRate:
            return "Optimize Your Heart Engine"
        case .heartRateVariability:
            return "Supercharge Your Recovery"
        case .oxygenSaturation:
            return "Maximize Your Oxygen Flow"
        case .vo2Max:
            return "Increase Your Peak Power"
        case .nutritionQuality:
            return "Fuel Your Energy System"
        case .stressLevel:
            return "Protect Your Energy Reserves"
        case .exerciseMinutes:
            return "Power Up Through Movement"
        case .bodyMass:
            return "Balance Your Energy System"
        case .smokingStatus:
            return "Stop Energy Drain"
        case .alcoholConsumption:
            return "Preserve Your System Power"
        case .socialConnectionsQuality:
            return "Energize Through Connection"
        }
    }
    
    /// First tip detail based on metric type - focused on immediate benefits
    private var primaryTip: String {
        switch metric.type {
        case .steps:
            return "A 10-minute walk after meals helps your body process energy more efficiently and keeps your battery charged throughout the day."
        case .sleepHours:
            return "Consistent sleep times help your body's natural recharge cycle work at peak efficiency, giving you more energy when awake."
        case .activeEnergyBurned:
            return "Mixing cardio and strength training creates a powerful energy system that keeps you feeling strong and capable."
        case .restingHeartRate:
            return "Deep breathing exercises train your heart to work more efficiently, like optimizing your body's engine."
        case .heartRateVariability:
            return "Recovery days allow your system to repair and recharge, preventing energy drain from overuse."
        case .oxygenSaturation:
            return "Better breathing techniques help your body use oxygen more efficiently, powering every cell."
        case .vo2Max:
            return "Interval training builds your body's capacity to generate and sustain energy during activities."
        case .nutritionQuality:
            return "Colorful vegetables provide the nutrients your body needs to maintain high energy levels naturally."
        case .stressLevel:
            return "Mindfulness helps prevent stress from draining your energy reserves throughout the day."
        case .exerciseMinutes:
            return "Regular movement keeps your energy systems running smoothly and prevents power loss."
        case .bodyMass:
            return "A balanced approach helps your body operate at its most efficient energy level."
        case .smokingStatus:
            return "Reducing smoking stops one of the biggest energy drains on your system."
        case .alcoholConsumption:
            return "Limiting alcohol helps your body focus energy on repair and restoration instead of processing toxins."
        case .socialConnectionsQuality:
            return "Strong relationships provide emotional energy that powers your overall wellbeing."
        }
    }
    
    /// Second tip detail based on metric type - practical and encouraging
    private var secondaryTip: String {
        switch metric.type {
        case .steps:
            return "Small changes like parking farther away add up to big energy gains over time."
        case .sleepHours:
            return "Your bedroom environment affects how well your body can recharge - keep it cool and dark."
        case .activeEnergyBurned:
            return "Find activities that feel energizing rather than draining - your body will thank you."
        case .restingHeartRate:
            return "Staying hydrated helps your heart pump more efficiently with less effort."
        case .heartRateVariability:
            return "Quality sleep and relaxation are like overnight charging for your recovery system."
        case .oxygenSaturation:
            return "Fresh air and good posture help your breathing system work at peak efficiency."
        case .vo2Max:
            return "Gradual improvements prevent system overload while building your energy capacity."
        case .nutritionQuality:
            return "Think of food as fuel - quality ingredients create sustainable energy without crashes."
        case .stressLevel:
            return "Even short breaks can prevent stress from completely draining your energy reserves."
        case .exerciseMinutes:
            return "Breaking movement into smaller sessions helps maintain steady energy without burnout."
        case .bodyMass:
            return "Focus on habits that give you energy rather than drain it - your body will find its balance."
        case .smokingStatus:
            return "Each cigarette avoided is energy saved for things that matter to you."
        case .alcoholConsumption:
            return "Alcohol-free days give your system time to fully recharge and restore."
        case .socialConnectionsQuality:
            return "Meaningful conversations recharge your emotional battery in ways nothing else can."
        }
    }
    
    /// Actionable step based on metric type - immediate and achievable
    private var actionableStep: String? {
        switch metric.type {
        case .steps:
            return "Take the stairs or walk while talking on the phone"
        case .sleepHours:
            return "Set a phone alarm for your ideal bedtime tonight"
        case .activeEnergyBurned:
            return "Do 10 jumping jacks or push-ups right now"
        case .restingHeartRate:
            return "Take 5 deep breaths and feel your heart rate slow"
        case .heartRateVariability:
            return "Schedule 15 minutes of gentle stretching today"
        case .oxygenSaturation:
            return "Step outside for 5 minutes and breathe deeply"
        case .vo2Max:
            return "Add 30 seconds of high intensity to your next walk"
        case .nutritionQuality:
            return "Add berries or greens to your next meal"
        case .stressLevel:
            return "Close your eyes and breathe deeply for 1 minute"
        case .exerciseMinutes:
            return "Dance to one favorite song or walk around the block"
        case .bodyMass:
            return "Drink a full glass of water before your next meal"
        case .smokingStatus:
            return "Delay your next cigarette by 30 minutes"
        case .alcoholConsumption:
            return "Try sparkling water with lime instead of alcohol today"
        case .socialConnectionsQuality:
            return "Send an encouraging text to someone you care about"
        }
    }
    
    private var cardTitle: String {
        guard let impact = metric.impactDetails else { return "Health Tip" }
        
        let impactValue = impact.lifespanImpactMinutes
        
        if impactValue > 0 {
            return "Keep up the good work!"
        } else if impactValue < 0 {
            return "Room for improvement"
        } else {
            return "You're on the right track"
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
                id: UUID().uuidString,
                type: .steps,
                value: 6500,
                date: Date(),
                source: .healthKit
            )
        )
        
        MetricTipCard(
            metric: HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: 6.5,
                date: Date(),
                source: .healthKit
            )
        )
    }
    .padding()
} 