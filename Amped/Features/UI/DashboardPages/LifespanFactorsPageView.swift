import SwiftUI

/// Page 2: Today's/This Month's/This Year's Impact
struct LifespanFactorsPageView: View {
    @Binding var selectedPeriod: ImpactDataPoint.PeriodType
    @Binding var isBatteryAnimating: Bool
    @Binding var isRefreshing: Bool
    @Binding var pullDistance: CGFloat
    @Binding var refreshIndicatorOpacity: Double
    @Binding var refreshIndicatorRotation: Double
    @Binding var showingUpdateHealthProfile: Bool
    @Binding var selectedMetric: HealthMetric?
    
    let filteredMetrics: [HealthMetric]
    let viewModel: DashboardViewModel
    
    private func titleForPeriod(_ period: ImpactDataPoint.PeriodType) -> String {
        switch period {
        case .day:
            return "Today's Impact"
        case .month:
            return "This Month's Impact"
        case .year:
            return "This Year's Impact"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Health factors header
                    HStack(alignment: .center, spacing: 8) {
                        // Battery icon with animation
                        ZStack {
                            Image(systemName: "battery.100")
                                .font(.title2)
                                .foregroundColor(.fullPower)
                                .scaleEffect(isBatteryAnimating ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isBatteryAnimating)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(titleForPeriod(selectedPeriod))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("See how each habit is changing your lifespan")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12) // Rules: Better spacing consistency
                    .accessibilityAddTraits(.isHeader)
                    
                    // Power Sources Metrics section
                    HealthMetricsListView(
                        metrics: filteredMetrics,
                        selectedPeriod: selectedPeriod,
                        onMetricTap: { metric in
                            // Rules: Different handling for manual vs HealthKit metrics
                            if metric.source == .userInput {
                                // For manual metrics, show update health profile
                                showingUpdateHealthProfile = true
                            } else {
                                // For HealthKit metrics, show detail view
                                selectedMetric = metric
                            }
                            HapticManager.shared.playSelection()
                        }
                    )
                    .padding(.horizontal, 8)
                    // Add consistent padding for page indicators - Rules: Better spacing
                    .padding(.bottom, max(40, geometry.safeAreaInsets.bottom + 20))
                }
            }
            .refreshable {
                // Trigger refresh - indicator is handled by parent view
                isRefreshing = true
                refreshIndicatorOpacity = 1.0
                
                await viewModel.refreshData()
                HapticManager.shared.playNotification(.success)
                
                // Reset state
                withAnimation(.easeInOut(duration: 0.4)) {
                    isRefreshing = false
                    pullDistance = 0
                    refreshIndicatorOpacity = 0
                    refreshIndicatorRotation = 0
                }
            }
        }
    }
} 