import SwiftUI

/// Battery-themed card showing life impact data with glass effects
struct BatteryLifeImpactCard: View {
    // MARK: - Properties
    
    let lifeImpact: LifeImpactData
    let selectedPeriod: TimePeriod
    @State private var animateCharge: Bool = false
    @Environment(\.glassTheme) private var glassTheme
    
    // MARK: - Computed Properties
    
    /// Battery charge level (0.0 to 1.0)
    private var chargeLevel: Double {
        // Convert life impact to charge level representation
        let impactValue = lifeImpact.totalImpactForPeriod(selectedPeriod)
        let impact = impactValue.value // Extract the numeric value
        
        // Normalize impact to 0-100% charge
        // Positive impact = higher charge, negative impact = lower charge
        let baseCharge = 0.5 // 50% baseline
        let impactRange = 0.4 // ±40% range for impact
        
        let normalizedImpact = max(-1.0, min(1.0, impact / 365.0)) // Normalize to ±1 year impact
        let chargeAdjustment = normalizedImpact * impactRange
        
        return max(0.0, min(1.0, baseCharge + chargeAdjustment))
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
    
    /// Formatted impact text
    private var impactText: String {
        let impactValue = lifeImpact.totalImpactForPeriod(selectedPeriod)
        return impactValue.displayString
    }
    
    /// Impact description
    private var impactDescription: String {
        let impactValue = lifeImpact.totalImpactForPeriod(selectedPeriod)
        let impact = impactValue.value
        
        if impact > 0 {
            switch selectedPeriod {
            case .day: return "Your habits are energizing your day"
            case .month: return "Building positive momentum this month"  
            case .year: return "Your healthy choices are powering up your future"
            }
        } else if impact < 0 {
            switch selectedPeriod {
            case .day: return "Some habits are draining your energy today"
            case .month: return "Habits need attention to recharge your battery"
            case .year: return "Small changes can help power up your year"
            }
        } else {
            return "Your battery is maintaining steady power"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView
            
            // Battery visualization
            batteryVisualization
            
            // Impact details
            impactDetailsView
        }
        .padding(20)
        .glassBackground(.thick, cornerRadius: glassTheme.largeGlassCornerRadius)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateCharge = true
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Header section with title and period
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                            Text("Life Impact Battery")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                
                Spacer()
                
                Text(selectedPeriod.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .glassBackground(.ultraThin, cornerRadius: glassTheme.smallGlassCornerRadius)
            }
            
            Text(impactDescription)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// Main battery visualization
    private var batteryVisualization: some View {
        HStack(spacing: 20) {
            // Battery icon
            batteryIcon
            
            // Impact value and details
            VStack(alignment: .leading, spacing: 8) {
                // Large impact value
                Text(impactText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(batteryColor)
                    .shadow(color: batteryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Charge level indicator
                Text("\(Int(chargeLevel * 100))% Charged")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                // Visual charge bar
                chargeBar
            }
            
            Spacer()
        }
    }
    
    /// Battery icon with glass effects
    private var batteryIcon: some View {
        ZStack {
            // Battery outline with glass effect
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 60, height: 35)
            
            // Battery terminal (top nub)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.8))
                .frame(width: 15, height: 6)
                .offset(y: -20)
            
            // Battery charge fill with animation
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [
                                batteryColor,
                                batteryColor.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: geometry.size.height * chargeLevel)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .overlay(
                        // Glass shine effect
                        LinearGradient(
                            colors: [
                                Color.white.opacity(animateCharge ? 0.4 : 0.2),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .mask(RoundedRectangle(cornerRadius: 6))
                    )
                    .animation(.easeInOut(duration: 1.0), value: chargeLevel)
            }
            .frame(width: 54, height: 29)
        }
    }
    
    /// Charge level bar indicator
    private var chargeBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track with glass effect
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                
                // Charge fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                batteryColor,
                                batteryColor.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * chargeLevel)
                    .overlay(
                        // Glass shine effect
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: geometry.size.width * chargeLevel)
                    )
                    .animation(.easeOut(duration: 1.2), value: chargeLevel)
            }
        }
        .frame(height: 8)
    }
    
    /// Impact details section
    private var impactDetailsView: some View {
        VStack(spacing: 12) {
            // Top metrics affecting impact
            if !lifeImpact.metricImpacts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What's Powering You")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(Array(lifeImpact.metricImpacts.prefix(4)), id: \.metricType) { impact in
                            metricImpactRow(impact)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    /// Individual metric impact row with intuitive descriptions
    private func metricImpactRow(_ impact: MetricImpactDetail) -> some View {
        HStack(spacing: 8) {
            // Metric icon
            Image(systemName: impact.metricType.iconName)
                .font(.caption)
                .foregroundColor(.ampedGreen)
                .frame(width: 16)
            
            // Metric name with contextual hint
            VStack(alignment: .leading, spacing: 2) {
                Text(impact.metricType.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                
                // Subtle context about what it's doing
                Text(impactContext(for: impact))
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 0)
            
            // Impact indicator with better visual
            let impactValue = impact.impactForPeriod(selectedPeriod)
            let isPositive = impactValue > 0
            
            Circle()
                .fill(isPositive ? .fullPower : .criticalPower)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .glassBackground(.ultraThin, cornerRadius: 6)
    }
    
    /// Get contextual description for impact
    private func impactContext(for impact: MetricImpactDetail) -> String {
        let impactValue = impact.impactForPeriod(selectedPeriod)
        let isPositive = impactValue > 0
        
        switch impact.metricType {
        case .steps:
            return isPositive ? "fueling energy" : "needs boost"
        case .sleepHours:
            return isPositive ? "recharging well" : "low charge"
        case .exerciseMinutes:
            return isPositive ? "building power" : "needs activity"
        case .heartRateVariability:
            return isPositive ? "good recovery" : "needs rest"
        case .restingHeartRate:
            return isPositive ? "heart strong" : "needs care"
        case .nutritionQuality:
            return isPositive ? "good fuel" : "needs nutrition"
        case .stressLevel:
            return isPositive ? "staying calm" : "high stress"
        default:
            return isPositive ? "helping" : "draining"
        }
    }
}

// MARK: - Extensions

extension HealthMetricType {
    /// Icon name for metric type
    var iconName: String {
        switch self {
        case .steps: return "figure.walk"
        case .exerciseMinutes: return "flame.fill"
        case .sleepHours: return "bed.double.fill"
        case .restingHeartRate: return "heart.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .bodyMass: return "scalemass.fill"
        case .nutritionQuality: return "leaf.fill"
        case .smokingStatus: return "smoke.fill"
        case .alcoholConsumption: return "wineglass.fill"
        case .socialConnectionsQuality: return "person.2.fill"
        case .activeEnergyBurned: return "bolt.fill"
        case .vo2Max: return "lungs.fill"
        case .oxygenSaturation: return "o.circle.fill"
        case .stressLevel: return "brain.head.profile"
        }
    }
}

// MARK: - Preview

struct BatteryLifeImpactCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleImpact = LifeImpactData(
            timePeriod: .day,
            totalImpact: ImpactValue(value: 0.2, unit: .hours, direction: .positive),
            batteryLevel: 75.0,
            metricContributions: [:]
        )
        
        BatteryLifeImpactCard(
            lifeImpact: sampleImpact,
            selectedPeriod: .day
        )
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