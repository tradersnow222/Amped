import SwiftUI
@preconcurrency import Combine

/// Card showing total life projection as a battery with glass effects
struct BatteryLifeProjectionCard: View {
    // MARK: - Properties
    
    let lifeProjection: LifeProjection
    @State private var animateGlow: Bool = false
    @Environment(\.glassTheme) private var glassTheme
    
    // MARK: - Computed Properties
    
    /// Battery charge level based on life projection (0.0 to 1.0)
    private var chargeLevel: Double {
        // Calculate charge based on projected vs. baseline lifespan
        let baselineLifespan: Double = 75.0 // Average baseline
        let projectedLifespan = lifeProjection.projectedTotalYears
        
        // Normalize to 0-100% where 75 years = 50%
        let chargePercent = (projectedLifespan / baselineLifespan) * 0.5
        return max(0.1, min(1.0, chargePercent))
    }
    
    /// Battery color based on charge level
    private var batteryColor: Color {
        switch chargeLevel {
        case 0.8...1.0: return .fullPower
        case 0.6..<0.8: return .highPower
        case 0.4..<0.6: return .mediumPower
        case 0.2..<0.4: return .lowPower
        default: return .criticalPower
        }
    }
    
    /// Formatted projection text
    private var projectionText: String {
        let years = Int(lifeProjection.projectedTotalYears)
        return "\(years) years"
    }
    
    /// Confidence level description
    private var confidenceDescription: String {
        switch lifeProjection.confidenceLevel {
        case 0.9...1.0: return "High confidence"
        case 0.7..<0.9: return "Good confidence"
        case 0.5..<0.7: return "Moderate confidence"
        default: return "Low confidence"
        }
    }
    
    /// Formatted remaining time
    private var remainingTimeText: String {
        let remaining = lifeProjection.projectedTotalYears - lifeProjection.currentAge
        let years = Int(remaining)
        return "\(years) years left"
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            // Main projection display
            projectionVisualization
            
            // Details section
            detailsView
        }
        .padding(20)
        .prominentGlass(cornerRadius: glassTheme.largeGlassCornerRadius)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
                }
            }
            
    // MARK: - Subviews
    
    /// Header section with title
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Life Projection Battery")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(confidenceDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassBackground(.ultraThin, cornerRadius: glassTheme.smallGlassCornerRadius)
            }
            
            Text("Total projected lifespan based on your health data")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// Main projection visualization
    private var projectionVisualization: some View {
        HStack(spacing: 24) {
            // Large battery icon
            largeBatteryIcon
            
            // Projection values
            VStack(alignment: .leading, spacing: 12) {
                // Total years
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Lifespan")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(projectionText)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(batteryColor)
                        .shadow(color: batteryColor.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                
                // Remaining time
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Remaining")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(remainingTimeText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                // Charge level bar
                projectionBar
            }
            
            Spacer()
        }
    }
    
    /// Large battery icon with glass effects
    private var largeBatteryIcon: some View {
        ZStack {
            // Battery outline with prominent glass effect
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: [
                            batteryColor.opacity(0.8),
                            batteryColor.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 4
                )
                .frame(width: 80, height: 50)
            
            // Battery terminal (top nub)
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.9),
                            Color.white.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 20, height: 8)
                .offset(y: -29)
            
            // Battery charge fill with advanced animation
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                batteryColor,
                                batteryColor.opacity(0.8),
                                batteryColor.opacity(0.6)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geometry.size.height * chargeLevel)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .overlay(
                        // Animated glass shine effect
                        LinearGradient(
                            colors: [
                                Color.white.opacity(animateGlow ? 0.6 : 0.3),
                                Color.clear,
                                Color.white.opacity(animateGlow ? 0.4 : 0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(RoundedRectangle(cornerRadius: 10))
                    )
                    .overlay(
                        // Inner glow effect
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .animation(.easeInOut(duration: 1.5), value: chargeLevel)
            }
            .frame(width: 72, height: 42)
        }
        .shadow(color: batteryColor.opacity(0.4), radius: 12, x: 0, y: 6)
    }
    
    /// Projection level bar indicator
    private var projectionBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track with prominent glass effect
                Capsule()
                    .fill(.thickMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                
                // Charge fill with enhanced glass effects
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                batteryColor,
                                batteryColor.opacity(0.8),
                                batteryColor.opacity(0.9)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * chargeLevel)
                    .overlay(
                        // Multi-layer glass shine
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.clear,
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: geometry.size.width * chargeLevel)
                    )
                    .overlay(
                        // Inner highlight
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.5),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 1
                            )
                            .frame(width: geometry.size.width * chargeLevel)
                    )
                    .animation(.easeOut(duration: 2.0), value: chargeLevel)
            }
        }
        .frame(height: 12)
    }
    
    /// Details section with projection information
    private var detailsView: some View {
        VStack(spacing: 12) {
            // Projection factors
            if !lifeProjection.impactFactors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Projection Factors")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(Array(lifeProjection.impactFactors.prefix(4)), id: \.factor) { factor in
                            projectionFactorRow(factor)
                        }
                    }
                }
                .padding(.top, 8)
            }
            
            // Last updated info
            HStack {
                Text("Last updated: \(formattedLastUpdated)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(batteryColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: batteryColor.opacity(0.6), radius: 4)
                    
                    Text("\(Int(chargeLevel * 100))% Life Energy")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.top, 8)
        }
    }
    
    /// Individual projection factor row with glass styling
    private func projectionFactorRow(_ factor: LifeProjection.ImpactFactor) -> some View {
        HStack(spacing: 8) {
            // Factor icon
            Image(systemName: factor.iconName)
                .font(.caption)
                .foregroundColor(.ampedGreen)
                .frame(width: 16)
            
            // Factor name
            Text(factor.factor)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            // Impact indicator
            let isPositive = factor.impact > 0
            
            Text(isPositive ? "+" : "-")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(isPositive ? .fullPower : .criticalPower)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassBackground(.ultraThin, cornerRadius: 6)
    }
    
    /// Formatted last updated date
    private var formattedLastUpdated: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: lifeProjection.lastUpdated)
        }
    }
    
// MARK: - Extensions

extension LifeProjection.ImpactFactor {
    /// Icon name for the impact factor
    var iconName: String {
        switch factor.lowercased() {
        case "exercise", "activity": return "figure.run"
        case "sleep": return "bed.double.fill"
        case "heart", "cardiovascular": return "heart.fill"
        case "nutrition", "diet": return "leaf.fill"
        case "stress": return "brain.head.profile"
        case "weight", "bmi": return "scalemass.fill"
        case "smoking": return "smoke.fill"
        case "alcohol": return "wineglass.fill"
        case "social": return "person.2.fill"
        default: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Preview

struct BatteryLifeProjectionCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleProjection = LifeProjection(
            baselineLifeExpectancyYears: 78.0,
            adjustedLifeExpectancyYears: 82.5,
            currentAge: 35.0,
            confidencePercentage: 0.85
        )
        
        BatteryLifeProjectionCard(lifeProjection: sampleProjection)
        .padding()
            .withGlassTheme()
            .background(
                Image("DeepBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            )
    }
} 