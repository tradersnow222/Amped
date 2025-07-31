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

/// Enhanced view for the life projection with interactive timeline slider - Rule: Simplicity is KING
struct EnhancedBatterySystemView: View {
    let lifeProjection: LifeProjection?
    let optimalProjection: LifeProjection?
    let currentUserAge: Double
    let selectedTab: Int // 0 = Current lifestyle, 1 = Better habits
    let onProjectionHelpTapped: () -> Void
    let viewModel: DashboardViewModel
    
    @State private var currentTime = Date()
    @Environment(\.glassTheme) private var glassTheme
    @State private var isCharging = false
    @State private var previousTab: Int = 0
    
    // Timer for realtime updates
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    @State private var secondsPulse = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area with improved spacing
            VStack(spacing: 32) {
                if let lifeProjection = lifeProjection {
                    // Main content section
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
                            
                            // Extra years gained message for better habits tab
                            if selectedTab == 1, let optimalProjection = optimalProjection {
                                let extraYears = optimalProjection.adjustedLifeExpectancyYears - lifeProjection.adjustedLifeExpectancyYears
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
                                }
                            }
                        }
                        
                        // Interactive lifespan timeline slider - moved further down, without labels
                        LifespanTimelineSlider(
                            lifeProjection: lifeProjection,
                            userProfile: viewModel.userProfile,
                            healthMetrics: viewModel.healthMetrics,
                            onTapForDetails: onProjectionHelpTapped,
                            showLabels: false
                        )
                        .frame(height: 50) // Reduced height since no labels
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            
            Spacer(minLength: 20)
            
            // Timeline labels positioned at the bottom
            if let _ = lifeProjection {
                TimelineLabels()
                    .padding(.horizontal, 56) // Match slider padding
                    .padding(.bottom, 8)
            }
            
            // Scientific attribution - positioned at the very bottom above page indicators
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
            .padding(.bottom, 24) // Space above page indicators
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
    
    // MARK: - Helper Methods
    
    /// Format years display based on selected tab
    private func formattedYears(for lifeProjection: LifeProjection) -> String {
        if selectedTab == 0 {
            return String(format: "%.0f", lifeProjection.adjustedLifeExpectancyYears - currentUserAge)
        } else if let optimalProjection = optimalProjection {
            return String(format: "%.0f", optimalProjection.adjustedLifeExpectancyYears - currentUserAge)
        } else {
            return String(format: "%.0f", lifeProjection.adjustedLifeExpectancyYears - currentUserAge)
        }
    }
    
    /// Real-time countdown display
    private func countdownDisplay(for lifeProjection: LifeProjection) -> String {
        let yearsAhead: Double
        if selectedTab == 0 {
            yearsAhead = lifeProjection.adjustedLifeExpectancyYears - currentUserAge
        } else if let optimalProjection = optimalProjection {
            yearsAhead = optimalProjection.adjustedLifeExpectancyYears - currentUserAge
        } else {
            yearsAhead = lifeProjection.adjustedLifeExpectancyYears - currentUserAge
        }
        
        return calculateRemainingTime(yearsAhead: yearsAhead)
    }
    
    /// Calculate remaining time string
    private func calculateRemainingTime(yearsAhead: Double) -> String {
        let totalSeconds = yearsAhead * 365.25 * 24 * 3600
        let remainingSeconds = totalSeconds - (Date().timeIntervalSince1970 - Calendar.current.startOfDay(for: Date()).timeIntervalSince1970)
        
        guard remainingSeconds > 0 else { return "0d · 0h · 0m · 0s" }
        
        let days = Int(remainingSeconds) / (24 * 3600)
        let hours = (Int(remainingSeconds) % (24 * 3600)) / 3600
        let minutes = (Int(remainingSeconds) % 3600) / 60
        let seconds = Int(remainingSeconds) % 60
        
        return "\(days)d · \(hours)h · \(minutes)m · \(seconds)s"
    }
} 