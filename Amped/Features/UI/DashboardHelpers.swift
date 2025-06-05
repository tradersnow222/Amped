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
            title: "Loading...", 
            value: "--", 
            chargeLevel: 0.0, 
            numberOfSegments: 5, 
            useYellowGradient: false,
            internalText: nil,
            helpAction: nil,
            lifeProjection: nil,
            currentUserAge: nil
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
                        currentUserAge: currentUserAge
                    )
                    .frame(maxWidth: 200) // Fixed width for single battery
                } else {
                    LoadingBatteryPlaceholder()
                    .frame(maxWidth: 200) // Fixed width for single battery
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
        }
    }
} 