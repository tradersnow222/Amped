import SwiftUI

/// Battery page content without tabs (for use in batteryPageWithRefresh)
struct BatteryPageContentView: View {
    @Binding var isCalculatingLifespan: Bool
    @Binding var hasInitiallyCalculated: Bool
    @Binding var showingProjectionHelp: Bool
    @Binding var selectedLifestyleTab: Int
    
    let viewModel: DashboardViewModel
    @EnvironmentObject private var settingsManager: SettingsManager
    
    var body: some View {
        VStack(spacing: 0) {
            if isCalculatingLifespan && !hasInitiallyCalculated {
                // Enhanced calculating state with Apple-quality UX - Rules: Apple loading standards
                EnhancedLoadingView(
                    loadingType: .lifeProjection,
                    onComplete: {
                        // Complete the life projection calculation with haptic feedback
                        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 25, initialVelocity: 0)) {
                            isCalculatingLifespan = false
                            hasInitiallyCalculated = true
                        }
                        HapticManager.shared.playSuccess()
                    }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Main content - focused on the key message
                EnhancedBatterySystemView(
                    lifeProjection: viewModel.lifeProjection,
                    optimalProjection: viewModel.optimalHabitsProjection,
                    currentUserAge: viewModel.currentUserAge,
                    selectedTab: selectedLifestyleTab,
                    onProjectionHelpTapped: { 
                        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 25, initialVelocity: 0)) {
                            showingProjectionHelp = true
                        }
                    },
                    viewModel: viewModel,
                    effectiveStyle: effectiveStyle()
                )
                
                Spacer()
            }
        }
    }

    private func effectiveStyle() -> SettingsManager.LifespanDisplayStyle {
        let yearsRemaining = viewModel.lifeProjection?.yearsRemaining
        // Soft cues from questionnaire
        let qd = viewModel.getQuestionnaireData()
        let stressLevel10 = qd?.stressLevel
        let deviceTracking = qd?.deviceTrackingStatus?.rawValue
        let emotionalSensitivity10 = qd?.emotionalSensitivity
        let framingComfort10 = qd?.framingComfortScore
        let urgencyResponse10 = qd?.urgencyResponseScore
        return settingsManager.effectiveLifespanDisplayStyle(
            age: viewModel.currentUserAge,
            yearsRemaining: yearsRemaining,
            stressLevel10: stressLevel10,
            deviceTracking: deviceTracking,
            emotionalSensitivity10: emotionalSensitivity10,
            framingComfortScore10: framingComfort10,
            urgencyResponseScore10: urgencyResponse10
        )
    }
} 