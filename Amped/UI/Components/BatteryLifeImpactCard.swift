import SwiftUI
import OSLog

/// Battery-themed card showing life impact data with glass effects
struct BatteryLifeImpactCard: View {
    // MARK: - Properties
    
    let lifeImpact: LifeImpactData
    let selectedPeriod: TimePeriod
    @State private var animateCharge: Bool = false
    @Environment(\.glassTheme) private var glassTheme
    
    // MARK: - Logging
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "BatteryLifeImpactCard")
    
    // MARK: - Computed Properties
    
    /// Battery charge level (0.0 to 1.0)
    private var chargeLevel: Double {
        // CRITICAL FIX: Convert display units back to minutes for consistent calculations
        let impactValue = lifeImpact.totalImpactForPeriod(selectedPeriod)
        let impactMinutes: Double
        
        // Convert back to minutes regardless of display unit
        switch impactValue.unit {
        case .minutes:
            impactMinutes = impactValue.value
        case .hours:
            impactMinutes = impactValue.value * 60.0
        case .days:
            impactMinutes = impactValue.value * 1440.0
        case .years:
            impactMinutes = impactValue.value * 525600.0 // 365 * 24 * 60
        }
        
        // Apply direction (positive or negative)
        let signedImpactMinutes = impactValue.direction == .positive ? impactMinutes : -impactMinutes
        
        // CRITICAL FIX: Use period-appropriate normalization instead of always dividing by 365
        let maxExpectedImpact: Double
        switch selectedPeriod {
        case .day:
            maxExpectedImpact = 240.0 // 4 hours per day maximum expected impact
        case .month:
            maxExpectedImpact = 240.0 * 30.0 // 4 hours per day * 30 days
        case .year:
            maxExpectedImpact = 240.0 * 365.0 // 4 hours per day * 365 days
        }
        
        // Normalize impact to -1.0 to 1.0 range based on period
        let normalizedImpact = max(-1.0, min(1.0, signedImpactMinutes / maxExpectedImpact))
        
        // Convert to 0-100% charge with 50% as neutral baseline
        let baseCharge = 0.5 // 50% baseline (neutral)
        let impactRange = 0.4 // ±40% range for impact (10% buffer on each end)
        let chargeAdjustment = normalizedImpact * impactRange
        
        let finalCharge = baseCharge + chargeAdjustment
        let clampedCharge = max(0.05, min(0.95, finalCharge)) // Clamp to 5-95% for visual clarity
        
        // COMPREHENSIVE LOGGING: Log all battery calculation steps
        logger.info("🔋 Battery Calculation for \(selectedPeriod.rawValue):")
        logger.info("  📊 Impact Value: \(impactValue.value) \(impactValue.unit.abbreviation) (\(impactValue.direction.rawValue))")
        logger.info("  ⏱️ Impact Minutes: \(String(format: "%.1f", signedImpactMinutes))")
        logger.info("  📏 Max Expected Impact: \(String(format: "%.1f", maxExpectedImpact))")
        logger.info("  📐 Normalized Impact: \(String(format: "%.3f", normalizedImpact))")
        logger.info("  🔋 Base Charge: \(String(format: "%.1f", baseCharge * 100))%")
        logger.info("  ⚖️ Charge Adjustment: \(String(format: "%.3f", chargeAdjustment))")
        logger.info("  ⚡ Final Charge: \(String(format: "%.1f", clampedCharge * 100))%")
        
        return clampedCharge
    }
    
    /// Battery color based on impact direction and magnitude
    private var batteryColor: Color {
        let impactValue = lifeImpact.totalImpactForPeriod(selectedPeriod)
        
        if impactValue.direction == .positive {
            // Positive impact: Use green power levels
            switch chargeLevel {
            case 0.8...1.0: return .fullPower
            case 0.6..<0.8: return .highPower
            case 0.5..<0.6: return .mediumPower
            default: return .mediumPower
            }
        } else {
            // Negative impact: Use red power levels
            switch chargeLevel {
            case 0.0..<0.2: return .criticalPower
            case 0.2..<0.4: return .lowPower
            case 0.4..<0.5: return .lowPower
            default: return .mediumPower
            }
        }
    }
    
    /// Formatted impact text
    private var impactText: String {
        let impactValue = lifeImpact.totalImpactForPeriod(selectedPeriod)
        return impactValue.displayString
    }
    
    /// Time period context text for display
    private var timePeriodContext: String {
        switch selectedPeriod {
        case .day: return "Today, your habits collectively"
        case .month: return "This month, your habits collectively"
        case .year: return "This year, your habits collectively"
        }
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
    
    // MARK: - Animation Properties
    
    @State private var animateChargeLevel: Bool = false
    
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
            // Staggered animations for better visual feedback
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animateCharge = true
            }
            
            // Delayed charge level animation for smoother startup
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.8, blendDuration: 0.3)) {
                    animateChargeLevel = true
                }
            }
        }
        .onChange(of: chargeLevel) { newLevel in
            // Animate charge level changes with haptic feedback for significant changes
            let previousLevel = animateChargeLevel ? chargeLevel : 0.5
            let changeMagnitude = abs(newLevel - previousLevel)
            
            if changeMagnitude > 0.1 { // Significant change (10%+)
                // Add haptic feedback for significant battery changes
                let impactValue = lifeImpact.totalImpactForPeriod(selectedPeriod)
                if impactValue.direction == .positive {
                    HapticFeedback.trigger(.success)
                } else {
                    HapticFeedback.trigger(.warning)
                }
                
                // Enhanced spring animation for significant changes
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0.2)) {
                    animateChargeLevel.toggle()
                }
            } else {
                // Subtle animation for minor changes
                withAnimation(.easeInOut(duration: 0.6)) {
                    animateChargeLevel.toggle()
                }
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
                // Text above the big number (made bigger)
                Text(lifeImpact.totalImpactForPeriod(selectedPeriod).direction == .positive ? "\(timePeriodContext) added" : "\(timePeriodContext) reduced")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                // Large impact value
                Text(impactText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(batteryColor)
                    .shadow(color: batteryColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Text below the big number (made bigger, removed time period text)
                Text(lifeImpact.totalImpactForPeriod(selectedPeriod).direction == .positive ? "to your lifespan" : "from your lifespan")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
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
    
    /// Battery icon with glass effects and dual-direction fill
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
            
            // CRITICAL FIX: Dual-direction battery charge fill with neutral line
            GeometryReader { geometry in
                ZStack {
                    // Neutral center line at 50%
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(height: 1)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    // Battery charge fill based on direction
                    let neutralY = geometry.size.height / 2
                    let isPositive = chargeLevel > 0.5
                    let fillHeight = abs(chargeLevel - 0.5) * geometry.size.height
                    
                    if isPositive {
                        // Positive impact: Green fill above neutral line
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
                            .frame(height: fillHeight)
                            .position(x: geometry.size.width / 2, y: neutralY - fillHeight / 2)
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
                                .frame(height: fillHeight)
                                .position(x: geometry.size.width / 2, y: neutralY - fillHeight / 2)
                            )
                    } else if chargeLevel < 0.5 {
                        // Negative impact: Red fill below neutral line
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
                            .frame(height: fillHeight)
                            .position(x: geometry.size.width / 2, y: neutralY + fillHeight / 2)
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
                                .frame(height: fillHeight)
                                .position(x: geometry.size.width / 2, y: neutralY + fillHeight / 2)
                            )
                    }
                    // If chargeLevel == 0.5 exactly, only show neutral line (no fill)
                }
                .animation(.easeInOut(duration: 1.0), value: chargeLevel)
            }
            .frame(width: 54, height: 29)
            .clipped()
        }
    }
    
    /// Charge level bar indicator with dual-direction fill
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
                
                // Neutral center line
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 1)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Charge fill based on direction
                let neutralX = geometry.size.width / 2
                let isPositive = chargeLevel > 0.5
                let fillWidth = abs(chargeLevel - 0.5) * geometry.size.width
                
                if isPositive {
                    // Positive impact: Fill from center to right
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
                        .frame(width: fillWidth)
                        .position(x: neutralX + fillWidth / 2, y: geometry.size.height / 2)
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
                                .frame(width: fillWidth)
                                .position(x: neutralX + fillWidth / 2, y: geometry.size.height / 2)
                        )
                } else if chargeLevel < 0.5 {
                    // Negative impact: Fill from center to left
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
                        .frame(width: fillWidth)
                        .position(x: neutralX - fillWidth / 2, y: geometry.size.height / 2)
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
                                .frame(width: fillWidth)
                                .position(x: neutralX - fillWidth / 2, y: geometry.size.height / 2)
                        )
                }
                // If chargeLevel == 0.5 exactly, only show neutral line
            }
            .animation(.easeOut(duration: 1.2), value: chargeLevel)
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
            let impactValue = getScaledImpact(for: impact, period: selectedPeriod)
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
        let impactValue = getScaledImpact(for: impact, period: selectedPeriod)
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
    
    /// Helper to get scaled impact value for a given metric impact and period
    private func getScaledImpact(for impact: MetricImpactDetail, period: TimePeriod) -> Double {
        let dailyImpact = impact.lifespanImpactMinutes
        
        switch period {
        case .day:
            return dailyImpact
        case .month:
            return dailyImpact * 30.0
        case .year:
            return dailyImpact * 365.0
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