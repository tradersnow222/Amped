import SwiftUI
import CoreHaptics
import OSLog

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
    
    /// Play impact haptic feedback with specified intensity
    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Play notification haptic feedback
    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
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

/// Enhanced view for the life projection battery indicator with countdown display - Jobs-inspired simplicity
struct EnhancedBatterySystemView: View {
    let lifeProjection: LifeProjection?
    let optimalProjection: LifeProjection?
    let currentUserAge: Double
    let selectedTab: Int // 0 = Current lifestyle, 1 = Better habits
    let onProjectionHelpTapped: () -> Void
    
    @State private var currentTime = Date()
    @Environment(\.glassTheme) private var glassTheme
    @State private var isCharging = false
    @State private var previousTab: Int = 0
    
    // Timer for realtime updates
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    @State private var secondsPulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            VStack(spacing: 24) {
                if let lifeProjection = lifeProjection {
                    // Cool vertical battery visualization - balanced size
                    simplifiedBattery(lifeProjection: lifeProjection)
                        .frame(width: 120, height: 240) // Slightly bigger battery
                        .padding(.top, 20) // More space above
                        .padding(.bottom, 12)
                    
                    // Clean, aligned countdown display
                    countdownDisplay(lifeProjection: lifeProjection)
                    
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            
            // Push everything above up
            Spacer()
            
            // Scientific attribution - positioned at the very bottom above page indicators
            VStack(spacing: 3) {
                Text("Based on 45+ peer-reviewed studies from")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                Text("Harvard, AHA, & Mayo Clinic")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.bottom, 20) // Space above page indicators
        }
    }
    
    /// Calculate charge level based on selected tab
    private func calculateChargeLevel(lifeProjection: LifeProjection) -> CGFloat {
        if selectedTab == 0 {
            // Current lifestyle - use actual projection
            return lifeProjection.batteryVisualizationPercentage(currentUserAge: currentUserAge)
        } else {
            // Better habits - use optimal projection if available, otherwise simulate improvement
            if let optimal = optimalProjection {
                return optimal.batteryVisualizationPercentage(currentUserAge: currentUserAge)
            } else {
                // Fallback to simulated improvement if optimal projection not available
                let currentCharge = lifeProjection.batteryVisualizationPercentage(currentUserAge: currentUserAge)
                return min(1.0, currentCharge * 1.25) // 25% improvement for visual impact
            }
        }
    }
    
    /// Simplified battery - Vertical with cool aesthetic
    private func simplifiedBattery(lifeProjection: LifeProjection) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let cornerRadius: CGFloat = 14
            let terminalHeight: CGFloat = 8
            let terminalWidth: CGFloat = width * 0.3
            let casingLineWidth: CGFloat = 3
            
            ZStack(alignment: .top) {
                // Battery Terminal - Metallic look
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.gray.opacity(0.7),
                                Color.white.opacity(0.6)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: terminalWidth, height: terminalHeight)
                    .shadow(color: Color.white.opacity(0.3), radius: 2, y: 1)
                
                // Battery body
                VStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        // Glass casing with gradient
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: casingLineWidth
                            )
                            .shadow(color: selectedTab == 1 ? Color.ampedGreen.opacity(0.6) : Color.ampedYellow.opacity(0.6), radius: 15, x: 0, y: 0)
                            .blur(radius: 0.5)
                        
                        // Battery fill with segments effect
                        VStack(spacing: 2) {
                            ForEach(0..<10, id: \.self) { index in
                                let segmentThreshold = CGFloat(10 - index) / 10.0
                                let isFilled = calculateChargeLevel(lifeProjection: lifeProjection) >= segmentThreshold
                                let isTopSegment = index == 0 && isFilled
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        isFilled ?
                                        LinearGradient(
                                            colors: selectedTab == 1 ? 
                                                [Color.ampedGreen.opacity(isTopSegment ? 1.0 : 0.9), 
                                                 Color.ampedGreen.opacity(isTopSegment ? 0.9 : 0.7)] :
                                                [Color.ampedYellow.opacity(isTopSegment ? 1.0 : 0.9), 
                                                 Color.ampedYellow.opacity(isTopSegment ? 0.9 : 0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.1)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        // Shine effect for filled segments
                                        isFilled ?
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isTopSegment ? 0.4 : 0.2),
                                                Color.clear
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .center
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        : nil
                                    )
                                    .scaleEffect(isTopSegment ? 1.05 : 1.0)
                                    .shadow(color: isTopSegment ? (selectedTab == 1 ? Color.ampedGreen : Color.ampedYellow).opacity(0.6) : Color.clear, radius: 4)
                            }
                        }
                        .padding(5)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: selectedTab)
                        .animation(.spring(response: 0.5), value: calculateChargeLevel(lifeProjection: lifeProjection))
                        
                        // Remove percentage - battery speaks for itself
                    }
                }
                .offset(y: terminalHeight - 2)
            }
        }
    }
    
    /// Countdown display showing years, days, hours, minutes, seconds
    private func countdownDisplay(lifeProjection: LifeProjection) -> some View {
        let remainingTime = calculateRemainingTime(lifeProjection: lifeProjection, optimalProjection: optimalProjection)
        
        return VStack(spacing: 16) {
            // Main countdown message
            VStack(spacing: 8) {
                // Context line
                Text(selectedTab == 0 ? "With your current habits" : "With better habits")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                // "you have" line
                Text("you have")
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                
                // Complete countdown - all in one line
                VStack(spacing: 6) {
                    // Years
                    HStack(spacing: 8) {
                        Text("\(remainingTime.years)")
                            .font(.system(size: 72, weight: .heavy, design: .rounded))
                            .foregroundColor(selectedTab == 1 ? .ampedGreen : .ampedYellow)
                            .monospacedDigit()
                        
                        Text("years")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] - 8 }
                    }
                    .scaleEffect(selectedTab == 1 ? 1.05 : 1.0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedTab)
                    
                    // Days, hours, minutes, seconds - more compact
                    HStack(spacing: 8) {
                        // Days
                        HStack(spacing: 1) {
                            Text("\(remainingTime.days)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("d")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        
                        Text("·").opacity(0.3)
                        
                        // Hours
                        HStack(spacing: 1) {
                            Text("\(remainingTime.hours)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("h")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        
                        Text("·").opacity(0.3)
                        
                        // Minutes
                        HStack(spacing: 1) {
                            Text("\(remainingTime.minutes)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("m")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                        }
                        
                        Text("·").opacity(0.3)
                        
                        // Seconds - dramatically emphasized
                        HStack(spacing: 1) {
                            Text("\(remainingTime.seconds)")
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(selectedTab == 1 ? .ampedGreen : .ampedYellow)
                                .monospacedDigit()
                                .shadow(color: selectedTab == 1 ? Color.ampedGreen.opacity(0.6) : Color.ampedYellow.opacity(0.6), radius: 6)
                                .scaleEffect(secondsPulse ? 1.15 : 1.05)
                                .animation(.easeInOut(duration: 0.5), value: secondsPulse)
                            Text("s")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(selectedTab == 1 ? .ampedGreen : .ampedYellow)
                        }
                    }
                    .foregroundColor(.white.opacity(0.9))
                }
                
                // "of life ahead" - positive framing
                Text("of life ahead")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 4)
            }
            
            // Bottom messages and attribution
            VStack(spacing: 8) {
                // Better tab - gain message (only on Better tab)
                if selectedTab == 1 {
                    let extraYears = calculateExtraYears(lifeProjection: lifeProjection, optimalProjection: optimalProjection)
                    if extraYears.years > 0 || extraYears.months > 0 {
                        let yearsText = extraYears.years > 0 ? "\(extraYears.years) year\(extraYears.years == 1 ? "" : "s")" : ""
                        let monthsText = extraYears.months > 0 ? "\(extraYears.months) month\(extraYears.months == 1 ? "" : "s")" : ""
                        let separator = !yearsText.isEmpty && !monthsText.isEmpty ? " and " : ""
                        
                        Text("That's \(yearsText)\(separator)\(monthsText) more!")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.ampedGreen)
                            .shadow(color: Color.ampedGreen.opacity(0.3), radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onReceive(timer) { _ in
            currentTime = Date()
            secondsPulse.toggle()
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
    
    /// Minimal time component for Jobs-inspired design
    private func timeComponentMinimal(value: Int, unit: String) -> some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .monospacedDigit()
            Text(unit)
        }
    }
    
    /// Calculate remaining years properly
    private func calculateRemainingYears(lifeProjection: LifeProjection, optimalProjection: LifeProjection?) -> (current: Double, optimal: Double) {
        let currentRemaining = lifeProjection.adjustedLifeExpectancyYears - currentUserAge
        
        var optimalRemaining = currentRemaining
        if let optimal = optimalProjection {
            optimalRemaining = optimal.adjustedLifeExpectancyYears - currentUserAge
        }
        
        return (
            current: max(0, currentRemaining),
            optimal: max(0, optimalRemaining)
        )
    }
    
    /// Calculate remaining time components
    private func calculateRemainingTime(lifeProjection: LifeProjection, optimalProjection: LifeProjection?) -> (years: Int, days: Int, hours: Int, minutes: Int, seconds: Int) {
        // Use current or optimal based on selected tab
        var adjustedYears = lifeProjection.adjustedLifeExpectancyYears
        if selectedTab == 1, let optimal = optimalProjection {
            adjustedYears = optimal.adjustedLifeExpectancyYears
        }
        
        let remainingYears = adjustedYears - currentUserAge
        
        // Debug logging
        print("🔍 calculateRemainingTime - Tab: \(selectedTab)")
        print("  Current projection: \(lifeProjection.adjustedLifeExpectancyYears)")
        if let optimal = optimalProjection {
            print("  Optimal projection: \(optimal.adjustedLifeExpectancyYears)")
        }
        print("  User age: \(currentUserAge)")
        print("  Remaining years: \(remainingYears)")
        
        // Calculate time elapsed in current year for countdown effect
        let calendar = Calendar.current
        let now = currentTime
        
        // FIXED: Don't round, just truncate to show the actual year difference
        let years = Int(remainingYears) // Truncate instead of round
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
            years: max(0, years), // Ensure non-negative
            days: daysFromFraction,
            hours: hoursLeft,
            minutes: minutesLeft,
            seconds: secondsLeft
        )
    }
    
    /// Calculate extra years gained with better habits
    private func calculateExtraYears(lifeProjection: LifeProjection, optimalProjection: LifeProjection?) -> (years: Int, months: Int) {
        let currentYears = lifeProjection.adjustedLifeExpectancyYears - currentUserAge
        
        if let optimal = optimalProjection {
            let improvedYears = optimal.adjustedLifeExpectancyYears - currentUserAge
            let totalGain = improvedYears - currentYears
            
            let years = Int(totalGain)
            let months = Int((totalGain - Double(years)) * 12)
            
            return (years: max(0, years), months: max(0, months))
        } else {
            // Fallback to research-based estimate if no optimal projection available
            let ageMultiplier = max(0.5, min(1.0, (80 - currentUserAge) / 60))
            let yearsGained = 2.0 + (4.0 * ageMultiplier) // 2-6 years based on age
            
            let years = Int(yearsGained)
            let months = Int((yearsGained - Double(years)) * 12)
            
            return (years: years, months: months)
        }
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