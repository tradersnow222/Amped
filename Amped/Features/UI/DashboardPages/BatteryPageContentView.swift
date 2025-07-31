import SwiftUI

/// Battery page content without tabs (for use in batteryPageWithRefresh)
struct BatteryPageContentView: View {
    @Binding var isCalculatingLifespan: Bool
    @Binding var hasInitiallyCalculated: Bool
    @Binding var showingProjectionHelp: Bool
    @Binding var selectedLifestyleTab: Int
    
    let viewModel: DashboardViewModel
    
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
                    viewModel: viewModel
                )
                
                Spacer()
            }
        }
    }
} 