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
                    Enhanced3DBatteryIndicatorView(
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

/// Enhanced view for the life projection with Real-Time Life Progress Bar and Lifespan Comparison Card
struct EnhancedBatterySystemView: View {
    let lifeProjection: LifeProjection?
    let optimalProjection: LifeProjection?
    let currentUserAge: Double
    let selectedTab: Int // 0 = Current lifestyle, 1 = Better habits
    let onProjectionHelpTapped: () -> Void
    let viewModel: DashboardViewModel
    let effectiveStyle: SettingsManager.LifespanDisplayStyle
    
    @State private var currentTime = Date()
    @Environment(\.glassTheme) private var glassTheme
    @State private var isCharging = false
    @State private var previousTab: Int = 0
    
    // Timer for realtime updates
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    @State private var secondsPulse = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main display varies by effective style
                if let lifeProjection = lifeProjection {
                    switch effectiveStyle {
                    case .fullProjection:
                        mainLifespanDisplay(lifeProjection: lifeProjection)
                    case .impactOnly:
                        impactOnlyDisplay()
                    case .positiveOnly:
                        positiveOnlyDisplay()
                    case .auto:
                        impactOnlyDisplay()
                    }
                }
                
                // Real-Time bar only in full projection style
                if effectiveStyle == .fullProjection {
                    RealTimeLifeProgressBar(
                        userProfile: viewModel.userProfile,
                        currentProjection: lifeProjection,
                        potentialProjection: optimalProjection,
                        selectedTab: selectedTab
                    )
                }
                
                // Extra years message only in full projection style
                if effectiveStyle == .fullProjection, selectedTab == 1, let optimalProjection = optimalProjection, let currentProjection = lifeProjection {
                    let extraYears = optimalProjection.adjustedLifeExpectancyYears - currentProjection.adjustedLifeExpectancyYears
                    if extraYears > 0 {
                        VStack(spacing: 8) {
                            Text("That's")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                            
                            HStack(alignment: .lastTextBaseline, spacing: 6) {
                                Text(String(format: "%.1f", extraYears))
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundColor(.ampedGreen)
                                
                                Text("extra years")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Text("by improving your habits")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                    }
                }
                
                
                // Scientific attribution
                VStack(spacing: 4) {
                    Text("Based on 45+ peer-reviewed studies from")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                    Text("Harvard, AHA, & Mayo Clinic")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
            
            // Update pulse animation every second
            withAnimation(.easeInOut(duration: 0.3)) {
                secondsPulse.toggle()
            }
        }
        .onChange(of: selectedTab) { newValue in
            // Animate tab changes
            withAnimation(.easeInOut(duration: 0.3)) {
                previousTab = selectedTab
            }
        }
    }
    
    // MARK: - Main Lifespan Display
    
    private func mainLifespanDisplay(lifeProjection: LifeProjection) -> some View {
        VStack(spacing: 28) {
            // Main message with better spacing
            VStack(spacing: 16) {
                // Top text
                VStack(spacing: 8) {
                    Text(selectedTab == 0 ? "With your current habits" : "With better habits")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("you have")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                // Large years display with better spacing
                VStack(spacing: 12) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(formattedYears(for: lifeProjection))
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(.ampedYellow)
                            .contentTransition(.numericText())
                        
                        Text("years")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .offset(y: -4)
                    }
                    
                    // Real-time countdown with improved spacing
                    VStack(spacing: 6) {
                        Text(countdownDisplay(for: lifeProjection))
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .monospacedDigit()
                            .opacity(secondsPulse ? 0.7 : 1.0)
                            .animation(.easeInOut(duration: 0.5), value: secondsPulse)
                        
                        Text("of life ahead")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
            }
            
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Alternative Displays
    @ViewBuilder
    private func impactOnlyDisplay() -> some View {
        VStack(spacing: 16) {
            InteractiveBatteryContainer(
                viewModel: viewModel,
                selectedPeriod: viewModel.selectedTimePeriod.impactDataPointPeriodType,
                onTapToDrillIn: nil
            )
            .frame(height: 280)

            if let impact = viewModel.lifeImpactData?.totalImpact {
                let signedMinutes = impact.value * (impact.direction == .positive ? 1 : -1)
                Text(impactCopy(for: signedMinutes))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    @ViewBuilder
    private func positiveOnlyDisplay() -> some View {
        VStack(spacing: 16) {
            InteractiveBatteryContainer(
                viewModel: viewModel,
                selectedPeriod: viewModel.selectedTimePeriod.impactDataPointPeriodType,
                onTapToDrillIn: nil
            )
            .frame(height: 280)

            if let impact = viewModel.lifeImpactData?.totalImpact {
                let signedMinutes = max(0, impact.value * (impact.direction == .positive ? 1 : -1))
                Text(positiveOnlyCopy(for: signedMinutes))
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
    }

    private func impactCopy(for minutes: Double) -> String {
        let periodText = viewModel.selectedTimePeriod.displayName.lowercased()
        let absMinutes = abs(minutes)
        let formatted: String
        if absMinutes < 60 { formatted = "\(Int(absMinutes)) minute\(Int(absMinutes) == 1 ? "" : "s")" }
        else if absMinutes < 1440 { formatted = String(format: "%.1f hours", absMinutes/60) }
        else { formatted = String(format: "%.1f days", absMinutes/1440) }
        if minutes >= 0 { return "You added \(formatted) to your life \(periodText)." }
        return "You lost \(formatted) \(periodText)."
    }

    private func positiveOnlyCopy(for minutes: Double) -> String {
        let periodText = viewModel.selectedTimePeriod.displayName.lowercased()
        if minutes < 1 { return "Small steps today still help. Keep going." }
        let absMinutes = minutes
        let formatted: String
        if absMinutes < 60 { formatted = "\(Int(absMinutes)) minute\(Int(absMinutes) == 1 ? "" : "s")" }
        else if absMinutes < 1440 { formatted = String(format: "%.1f hours", absMinutes/60) }
        else { formatted = String(format: "%.1f days", absMinutes/1440) }
        return "You gained \(formatted) \(periodText)."
    }
    
    // MARK: - Helper Methods
    
    /// Format years display based on selected tab
    private func formattedYears(for lifeProjection: LifeProjection) -> String {
        // Debug: derive age from the authoritative viewModel profile to avoid stale values
        let liveUserAge = Double(viewModel.userProfile.age ?? Int(currentUserAge))

        let yearsRemaining: Double
        if selectedTab == 0 {
            yearsRemaining = lifeProjection.adjustedLifeExpectancyYears - liveUserAge
        } else if let optimalProjection = optimalProjection {
            yearsRemaining = optimalProjection.adjustedLifeExpectancyYears - liveUserAge
        } else {
            yearsRemaining = lifeProjection.adjustedLifeExpectancyYears - liveUserAge
        }

        // DEBUG LOGS
        os_log("[LifespanUI] formattedYears - userAge=%{public}.1f, adjusted=%{public}.1f, remaining=%{public}.1f",
               log: .default, type: .info, liveUserAge, lifeProjection.adjustedLifeExpectancyYears, yearsRemaining)

        return String(format: "%.0f", max(0, yearsRemaining))
    }
    
    /// Real-time countdown display
    private func countdownDisplay(for lifeProjection: LifeProjection) -> String {
        // Derive age from authoritative source to avoid stale values
        let liveUserAge = Double(viewModel.userProfile.age ?? Int(currentUserAge))
        let yearsAhead: Double

        if selectedTab == 0 {
            yearsAhead = lifeProjection.adjustedLifeExpectancyYears - liveUserAge
        } else if let optimalProjection = optimalProjection {
            yearsAhead = optimalProjection.adjustedLifeExpectancyYears - liveUserAge
        } else {
            yearsAhead = lifeProjection.adjustedLifeExpectancyYears - liveUserAge
        }
        
        return calculateRemainingTime(yearsAhead: max(0, yearsAhead))
    }
    
    /// Calculate remaining time string
    private func calculateRemainingTime(yearsAhead: Double) -> String {
        let totalSeconds = yearsAhead * 365.25 * 24 * 3600
        let remainingSeconds = totalSeconds - (Date().timeIntervalSince1970 - Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)
        
        guard remainingSeconds > 0 else { return "0d · 0h · 0m · 0s" }
        
        // Calculate complete years and remainder
        let completeYears = Int(yearsAhead)
        let remainderSeconds = remainingSeconds - Double(completeYears) * 365.25 * 24 * 3600
        
        // Calculate days, hours, minutes, seconds from the remainder only
        let days = Int(remainderSeconds) / (24 * 3600)
        let hours = (Int(remainderSeconds) % (24 * 3600)) / 3600
        let minutes = (Int(remainderSeconds) % 3600) / 60
        let seconds = Int(remainderSeconds) % 60
        
        return "\(days)d · \(hours)h · \(minutes)m · \(seconds)s"
    }
    
    /// Get the active projection based on selected tab
    private func getActiveProjection() -> LifeProjection? {
        if selectedTab == 0 {
            return lifeProjection
        } else {
            return optimalProjection
        }
    }
    
    /// Calculate daily impact for the currently active tab (current habits vs ideal habits)
    private func calculateDailyImpactForActiveTab() -> Double {
        if selectedTab == 0 {
            return calculateDailyImpact()
        } else {
            return calculateIdealDailyImpact()
        }
    }
    
    /// Calculate daily impact from user's recent health data (current habits)
    private func calculateDailyImpact() -> Double {
        // Use the most recent daily impact calculation from the view model
        if let lifeImpactData = viewModel.lifeImpactData {
            let recentImpact = lifeImpactData.totalImpact
            // Convert to daily impact if needed
                switch lifeImpactData.timePeriod {
            case .day:
                return recentImpact.value * (recentImpact.direction == .positive ? 1.0 : -1.0)
            case .month:
                return (recentImpact.value * (recentImpact.direction == .positive ? 1.0 : -1.0)) / 30.0
            case .year:
                return (recentImpact.value * (recentImpact.direction == .positive ? 1.0 : -1.0)) / 365.0
            }
        }
        
        // Fallback: Calculate from current health metrics using LifeImpactService
        let lifeImpactService = LifeImpactService(userProfile: viewModel.userProfile)
        let dailyImpactDataPoint = lifeImpactService.calculateTotalImpact(
            from: viewModel.healthMetrics,
            for: .day
        )
        
        return dailyImpactDataPoint.totalImpactMinutes
    }
    
    /// Calculate ideal daily impact based on optimal health metrics
    private func calculateIdealDailyImpact() -> Double {
        // Create ideal metrics based on scientific research optimal values
        let idealMetrics = createIdealHealthMetrics()
        
        // Calculate daily impact using the same LifeImpactService with ideal metrics
        let lifeImpactService = LifeImpactService(userProfile: viewModel.userProfile)
        let idealImpactDataPoint = lifeImpactService.calculateTotalImpact(
            from: idealMetrics,
            for: .day
        )
        
        return idealImpactDataPoint.totalImpactMinutes
    }
    
    /// Create ideal health metrics based on scientific research optimal values
    private func createIdealHealthMetrics() -> [HealthMetric] {
        var idealMetrics: [HealthMetric] = []
        let now = Date()
        
        // Physical Activity Metrics - Optimal values from scientific research
        idealMetrics.append(HealthMetric(
            id: "ideal_steps",
            type: .steps,
            value: 10000, // Saint-Maurice et al. 2020 JAMA - optimal steps per day
            date: now,
            source: .calculated
        ))
        
        idealMetrics.append(HealthMetric(
            id: "ideal_exercise",
            type: .exerciseMinutes,
            value: 30, // WHO/AHA guidelines - 30 minutes daily
            date: now,
            source: .calculated
        ))
        
        // Cardiovascular Metrics - Optimal values
        idealMetrics.append(HealthMetric(
            id: "ideal_sleep",
            type: .sleepHours,
            value: 7.5, // Jike et al. 2018 meta-analysis - optimal 7-8 hours
            date: now,
            source: .calculated
        ))
        
        idealMetrics.append(HealthMetric(
            id: "ideal_rhr",
            type: .restingHeartRate,
            value: 60, // Aune et al. 2013 CMAJ - optimal RHR
            date: now,
            source: .calculated
        ))
        
        idealMetrics.append(HealthMetric(
            id: "ideal_hrv",
            type: .heartRateVariability,
            value: 50, // Higher HRV is better, age-adjusted optimal
            date: now,
            source: .calculated
        ))
        
        // Lifestyle Metrics - Ideal questionnaire values (scale 1-10)
        idealMetrics.append(HealthMetric(
            id: "ideal_smoking",
            type: .smokingStatus,
            value: 10, // Never smoked (best possible score)
            date: now,
            source: .calculated
        ))
        
        idealMetrics.append(HealthMetric(
            id: "ideal_alcohol",
            type: .alcoholConsumption,
            value: 9, // Minimal alcohol consumption
            date: now,
            source: .calculated
        ))
        
        idealMetrics.append(HealthMetric(
            id: "ideal_stress",
            type: .stressLevel,
            value: 2, // Very low stress level
            date: now,
            source: .calculated
        ))
        
        idealMetrics.append(HealthMetric(
            id: "ideal_nutrition",
            type: .nutritionQuality,
            value: 9, // Excellent nutrition quality
            date: now,
            source: .calculated
        ))
        
        idealMetrics.append(HealthMetric(
            id: "ideal_social",
            type: .socialConnectionsQuality,
            value: 8, // Strong social connections
            date: now,
            source: .calculated
        ))
        
        // Body Mass - Use healthy weight for user's profile
        let idealWeight = calculateIdealWeight()
        idealMetrics.append(HealthMetric(
            id: "ideal_weight",
            type: .bodyMass,
            value: idealWeight,
            date: now,
            source: .calculated
        ))
        
        // VO2 Max - Age and gender adjusted optimal
        let idealVO2Max = calculateIdealVO2Max()
        idealMetrics.append(HealthMetric(
            id: "ideal_vo2max",
            type: .vo2Max,
            value: idealVO2Max,
            date: now,
            source: .calculated
        ))
        
        // Active Energy - Optimal daily burn
        idealMetrics.append(HealthMetric(
            id: "ideal_energy",
            type: .activeEnergyBurned,
            value: 500, // Optimal active calories per day
            date: now,
            source: .calculated
        ))
        
        // Oxygen Saturation - Optimal
        idealMetrics.append(HealthMetric(
            id: "ideal_oxygen",
            type: .oxygenSaturation,
            value: 98, // Optimal oxygen saturation
            date: now,
            source: .calculated
        ))
        
        return idealMetrics
    }
    
    /// Calculate ideal weight based on user profile (BMI ~22-23)
    private func calculateIdealWeight() -> Double {
        // Use current user weight as reference, or calculate healthy BMI if height available
        if let currentWeightMetric = viewModel.healthMetrics.first(where: { $0.type == .bodyMass }) {
            // If current weight is already healthy (BMI 18.5-24.9), keep it
            // Otherwise, adjust toward healthy range
            return min(max(currentWeightMetric.value, 120), 180) // Reasonable healthy range
        }
        
        // Default healthy weight reference
        return 160 // Reference weight used in calculations (~24.5 BMI)
    }
    
    /// Calculate ideal VO2 Max based on user's age and gender
    private func calculateIdealVO2Max() -> Double {
        let age = Double(viewModel.userProfile.age ?? 30)
        let gender = viewModel.userProfile.gender ?? .male
        
        // Base excellent VO2 max values
        var baseVO2Max: Double = gender == .male ? 50.0 : 44.0 // Excellent fitness levels
        
        // Age adjustment - VO2 max declines with age but we use "excellent for age" values
        if age > 30 {
            let ageDecline = (age - 30) * 0.3 // Slower decline for fit individuals
            baseVO2Max = max(baseVO2Max - ageDecline, gender == .male ? 35.0 : 30.0)
        }
        
        return baseVO2Max
    }
}
