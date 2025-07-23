import SwiftUI

/// Page 1: Impact number and Today's Focus
struct ImpactPageView: View {
    @Binding var selectedPeriod: ImpactDataPoint.PeriodType
    @Binding var isCalculatingImpact: Bool
    @Binding var hasInitiallyCalculated: Bool
    @Binding var showLifeEnergyBattery: Bool
    @Binding var isBatteryAnimating: Bool
    @Binding var isRefreshing: Bool
    @Binding var pullDistance: CGFloat
    @Binding var refreshIndicatorOpacity: Double
    @Binding var refreshIndicatorRotation: Double
    @Binding var showingUpdateHealthProfile: Bool
    @Binding var selectedMetric: HealthMetric?
    @Binding var selectedMetricType: HealthMetricType? // CRITICAL FIX: Add binding for metric type
    
    let totalTimeImpact: Double
    let timePeriodContext: String
    let formattedTotalImpact: String
    let filteredMetrics: [HealthMetric]
    let viewModel: DashboardViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Prominent Total Impact Display - Rules: Enhanced loading experience
                    if isCalculatingImpact && !hasInitiallyCalculated {
                        // Enhanced calculating state with Apple-quality UX
                        EnhancedLoadingView(
                            loadingType: .healthImpact,
                            onComplete: {
                                // Complete the health impact calculation with haptic feedback
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    isCalculatingImpact = false
                                    hasInitiallyCalculated = true
                                }
                                HapticManager.shared.playSuccess()
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    } else if totalTimeImpact != 0 {
                        VStack(spacing: 80) {
                            // Main impact display section - Rules: Better spacing
                            VStack(spacing: 12) {
                                // "Your habits collectively added/reduced" text above the number
                                Text(totalTimeImpact >= 0 ? "\(timePeriodContext) added" : "\(timePeriodContext) reduced")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.85))
                                
                                // Main impact display - PROMINENT NUMBER
                                HStack(spacing: 8) {
                                    Image(systemName: totalTimeImpact >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(totalTimeImpact >= 0 ? .ampedGreen : .ampedRed)
                                        .symbolRenderingMode(.hierarchical)
                                    
                                    Text(formattedTotalImpact)
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                // "to/from your lifespan" text below
                                Text(totalTimeImpact >= 0 ? "to your lifespan 🔥" : "from your lifespan")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            // Jobs-inspired animated battery element - Rules: Cool battery animation
                            if showLifeEnergyBattery {
                                LifeEnergyFlowBattery(
                                    isAnimating: isBatteryAnimating,
                                    timeImpactMinutes: totalTimeImpact
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 40)
                        .padding(.bottom, 40) // Rules: Increased spacing around battery
                    } else {
                        // No impact yet
                        VStack(spacing: 16) { // Rules: Better spacing
                            Text("NO HEALTH DATA YET")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(0.5)
                            
                            Text("Complete your health profile to see your impact")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20) // Rules: Better text width control
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32) // Rules: Reduced vertical padding
                        .padding(.top, 20)
                    }
                    
                    // New Actionable Recommendations Section - Rules: Better spacing
                    if !filteredMetrics.isEmpty && !isCalculatingImpact {
                        ActionableRecommendationsView(
                            metrics: filteredMetrics, 
                            selectedPeriod: selectedPeriod,
                            onMetricTap: { metric in
                                // Rules: Different handling for manual vs HealthKit metrics
                                if metric.source == .userInput {
                                    // For manual metrics, show update health profile
                                    showingUpdateHealthProfile = true
                                } else {
                                    // For HealthKit metrics, show detail view
                                    // CRITICAL FIX: Set both type and metric for fresh data
                                    selectedMetricType = metric.type
                                    selectedMetric = metric
                                }
                                HapticManager.shared.playSelection()
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8) // Rules: Reduced top padding for better flow
                        .padding(.bottom, 20) // Rules: Consistent bottom spacing
                    }
                    
                    // Add consistent padding for page indicators - Rules: Better spacing
                    Spacer()
                        .frame(height: max(40, geometry.safeAreaInsets.bottom + 20))
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