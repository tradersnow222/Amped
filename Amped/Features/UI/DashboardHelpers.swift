import SwiftUI
import CoreHaptics

/// Helper functions and utilities for the Dashboard view
struct DashboardHelpers {
    // MARK: - Impact Value Formatting
    
    /// Calculates the formatted string for the impact value, handling line breaks
    static func formatImpactValue(impactDataPoint: ImpactDataPoint, selectedPeriod: ImpactDataPoint.PeriodType) -> String {
        // Just return the raw impact value without adding "today" or line breaks
        return impactDataPoint.formattedImpact
    }
    
    // MARK: - Charge Level Calculation
    
    /// Calculate charge level for the impact battery
    static func calculateImpactChargeLevel(_ impactMinutes: Double, period: ImpactDataPoint.PeriodType) -> CGFloat {
        let maxImpactMinutes: Double
        switch period {
        case .day: maxImpactMinutes = 120 // +/- 2 hours
        case .month: maxImpactMinutes = 120 * 30 // Scaled approx.
        case .year: maxImpactMinutes = 120 * 365 // Scaled approx.
        }
        
        let normalizedImpact = (impactMinutes + maxImpactMinutes) / (maxImpactMinutes * 2)
        return max(0.0, min(1.0, normalizedImpact)) // Clamp between 0 and 1
    }
}

// MARK: - Haptic Feedback Manager

/// Manages haptic feedback for the app
final class HapticManager {
    /// Shared instance for haptic feedback management
    static let shared = HapticManager()
    
    /// Haptic engine for advanced haptic patterns
    private var hapticEngine: CHHapticEngine?
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Prepare haptic engine
    func prepareHaptics() {
        // Early exit if device doesn't support haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { 
            return 
        }
        
        do {
            // Initialize and start the haptic engine
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // Setup engine reset handler
            hapticEngine?.resetHandler = { [weak self] in
                // Restart the engine if it stops unexpectedly
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
        } catch {
            print("Haptic engine initialization error: \(error)")
        }
    }
    
    /// Play selection haptic feedback
    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    /// Play success haptic feedback
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    /// Play error haptic feedback
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Dashboard UI Components

/// Reusable component for period selection in the dashboard
struct PeriodSelectorView: View {
    @Binding var selectedPeriod: ImpactDataPoint.PeriodType
    var onPeriodChanged: (ImpactDataPoint.PeriodType) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ImpactDataPoint.PeriodType.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPeriod = period
                    }
                    HapticManager.shared.playSelection()
                    onPeriodChanged(period)
                } label: {
                    Text(period.displayName)
                        .fontWeight(selectedPeriod == period ? .bold : .medium)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selectedPeriod == period {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.ampedGreen.opacity(0.2))
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.ampedGreen, lineWidth: 1.5)
                                        .shadow(color: Color.ampedGreen.opacity(0.6), radius: 4)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                }
                            }
                        )
                        .foregroundColor(selectedPeriod == period ? Color.ampedGreen : .gray)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .padding(.horizontal, 16)
    }
}

/// Loading placeholder for the battery indicator
struct LoadingBatteryPlaceholder: View {
    var body: some View {
        BatteryIndicatorView(
            title: "", // No title for cleaner look
            value: "--", 
            chargeLevel: 0.0, 
            numberOfSegments: 5, 
            useYellowGradient: false,
            internalText: nil,
            helpAction: nil,
            lifeProjection: nil,
            currentUserAge: nil,
            showValueBelow: false // Hide value for loading placeholder
        )
        .opacity(0.5)
    }
}

/// View for the life projection battery indicator
struct BatterySystemView: View {
    let lifeProjection: LifeProjection?
    let currentUserAge: Double
    let onProjectionHelpTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Only Life Projection Battery (centered)
            HStack {
                Spacer()
                
                if let lifeProjection = lifeProjection {
                    BatteryIndicatorView(
                        title: "Lifespan remaining",
                        value: lifeProjection.formattedProjectionValue(currentUserAge: currentUserAge) + " years",
                        chargeLevel: lifeProjection.projectionPercentage(currentUserAge: currentUserAge),
                        numberOfSegments: 5,
                        useYellowGradient: true,
                        internalText: nil,
                        helpAction: onProjectionHelpTapped,
                        lifeProjection: lifeProjection,
                        currentUserAge: currentUserAge,
                        showValueBelow: false // Hide value below battery
                    )
                    .frame(maxWidth: 200) // Slightly narrower while preserving decimal display
                } else {
                    LoadingBatteryPlaceholder()
                    .frame(maxWidth: 200) // Slightly narrower while preserving decimal display
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
    }
} 

/// Enhanced view for the life projection battery indicator with countdown display
struct EnhancedBatterySystemView: View {
    let lifeProjection: LifeProjection?
    let currentUserAge: Double
    let selectedTab: Int // 0 = Current lifestyle, 1 = Better habits
    let onProjectionHelpTapped: () -> Void
    
    @State private var currentTime = Date()
    @Environment(\.glassTheme) private var glassTheme
    @State private var isCharging = false
    @State private var previousTab: Int = 0
    
    // Timer for realtime updates
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            // Bigger battery visualization - the star of the show
            if let lifeProjection = lifeProjection {
                ZStack {
                    BatteryIndicatorView(
                        title: "", // No title for cleaner look
                        value: lifeProjection.formattedProjectionValue(currentUserAge: currentUserAge) + " years",
                        chargeLevel: calculateChargeLevel(lifeProjection: lifeProjection),
                        numberOfSegments: 5,
                        useYellowGradient: selectedTab == 0, // Yellow for current habits
                        internalText: nil,
                        helpAction: onProjectionHelpTapped,
                        lifeProjection: lifeProjection,
                        currentUserAge: currentUserAge,
                        showValueBelow: false // Hide value below battery
                    )
                    .frame(maxWidth: 240) // Bigger width
                    .frame(height: 340) // Reduced battery height
                    .scaleEffect(1.05) // Reduced scale for more room
                    
                    // Charging effect overlay
                    if isCharging {
                        ChargingEffectView()
                            .frame(maxWidth: 240)
                            .frame(height: 340)
                            .scaleEffect(1.05)
                            .allowsHitTesting(false)
                    }
                }
                .onChange(of: selectedTab) { newValue in
                    if newValue == 1 && previousTab == 0 {
                        // Switching to better habits - show charging effect
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isCharging = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                isCharging = false
                            }
                        }
                    }
                    previousTab = newValue
                }
                
                // Elegant countdown display
                countdownDisplay(lifeProjection: lifeProjection)
                
            } else {
                LoadingBatteryPlaceholder()
                    .frame(height: 340)
                    .scaleEffect(1.05)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }
    
    /// Calculate charge level based on selected tab
    private func calculateChargeLevel(lifeProjection: LifeProjection) -> CGFloat {
        if selectedTab == 0 {
            // Current lifestyle - use actual projection
            return lifeProjection.projectionPercentage(currentUserAge: currentUserAge)
        } else {
            // Better habits - simulate 10-20% improvement
            let currentCharge = lifeProjection.projectionPercentage(currentUserAge: currentUserAge)
            return min(1.0, currentCharge * 1.25) // 25% improvement for more visual impact
        }
    }
    
    /// Countdown display showing years, days, hours, minutes, seconds
    private func countdownDisplay(lifeProjection: LifeProjection) -> some View {
        let remainingTime = calculateRemainingTime(lifeProjection: lifeProjection)
        
        return VStack(spacing: 20) {
            // Add indicator for better habits mode
            if selectedTab == 1 {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.ampedGreen)
                    Text("With Better Habits")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ampedGreen)
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.ampedGreen)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .glassBackground(.ultraThin, cornerRadius: 20)
                .transition(.scale.combined(with: .opacity))
            }
            
            // Main years display with user's name
            VStack(spacing: 4) {
                // Get user's name from UserDefaults
                let userName = UserDefaults.standard.string(forKey: "userName") ?? "You"
                
                Text("\(userName) has")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                
                // Years with unit on same line
                HStack(spacing: 8) {
                    Text("\(remainingTime.years)")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .foregroundColor(selectedTab == 1 ? .ampedGreen : .ampedYellow)
                        .monospacedDigit()
                    
                    Text("years")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .alignmentGuide(.bottom) { d in d[.bottom] - 8 } // Align to bottom of number
                }
            }
            .scaleEffect(selectedTab == 1 ? 1.05 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
            
            // All other time components on one line - no background
            HStack(spacing: 16) {
                timeComponentInline(value: remainingTime.days, unit: "d")
                Text("·").foregroundColor(.white.opacity(0.3))
                timeComponentInline(value: remainingTime.hours, unit: "h")
                Text("·").foregroundColor(.white.opacity(0.3))
                timeComponentInline(value: remainingTime.minutes, unit: "m")
                Text("·").foregroundColor(.white.opacity(0.3))
                timeComponentInline(value: remainingTime.seconds, unit: "s", isAnimated: true)
            }
            .font(.system(size: 34, weight: .medium, design: .rounded))
            .monospacedDigit()
            .padding(.horizontal, 20)
            .padding(.vertical, 6)
            
            // "left to live" below the time components
            Text("left to live")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    /// Inline time component for single-line display
    private func timeComponentInline(value: Int, unit: String, isAnimated: Bool = false) -> some View {
        HStack(spacing: 4) {
            Text("\(value)")
                .foregroundColor(.white)
                .scaleEffect(isAnimated ? 1.02 : 1.0)
                .animation(isAnimated ? .easeInOut(duration: 0.5) : nil, value: value)
            Text(unit)
                .foregroundColor(.white.opacity(0.6))
                .font(.system(size: 16, weight: .regular))
        }
    }
    
    /// Calculate remaining time components
    private func calculateRemainingTime(lifeProjection: LifeProjection) -> (years: Int, days: Int, hours: Int, minutes: Int, seconds: Int) {
        var adjustedYears = lifeProjection.adjustedLifeExpectancyYears
        
        // Apply improvement for better habits tab
        if selectedTab == 1 {
            // Add 20% more years for better habits - more significant improvement
            adjustedYears = adjustedYears * 1.20
        }
        
        let remainingYears = adjustedYears - currentUserAge
        
        // Calculate time elapsed in current year for countdown effect
        let calendar = Calendar.current
        let now = currentTime
        
        // Convert remaining time to components
        let years = Int(remainingYears)
        let fractionalYear = remainingYears - Double(years)
        let daysFromFraction = Int(fractionalYear * 365.25)
        
        // Calculate current time components
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentSecond = calendar.component(.second, from: now)
        
        // Calculate remaining time in current day
        let hoursLeft = 23 - currentHour
        let minutesLeft = 59 - currentMinute
        let secondsLeft = 59 - currentSecond
        
        return (
            years: years,
            days: daysFromFraction,
            hours: hoursLeft,
            minutes: minutesLeft,
            seconds: secondsLeft
        )
    }
}

// Charging effect overlay view - removed lightning bolt animations
struct ChargingEffectView: View {
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        // Empty view - no more charging animations
        EmptyView()
    }
}

// Data structures removed - LightningParticle no longer needed

// MARK: - Data Structures
// ... existing code ... 