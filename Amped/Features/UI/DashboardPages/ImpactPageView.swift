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
                        VStack(spacing: 40) {  // Rules: Reduced from 80 to 40 for better screen fit
                            // Main impact display section - Rules: Better spacing
                            VStack(spacing: 12) {
                                // Original headline text format - Rules: Keep headline text the same as before
                                Text(getHeadlineText())
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                
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
                                
                                // Scientific explanation text below
                                VStack(spacing: 4) {
                                    Text("from your lifespan")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.85))
                                        .multilineTextAlignment(.center)
                                    
                                    Text("Based on peer-reviewed health research")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                            }
                            
                            // Collective Impact Chart - Rules: Dynamic height to maximize chart space
                            if showLifeEnergyBattery {
                                CollectiveImpactChartContainer(
                                    viewModel: viewModel,
                                    selectedPeriod: selectedPeriod
                                )
                                .frame(height: calculateOptimalChartHeight(geometry: geometry))
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 20)  // Rules: Reduced from 40 to 20 for better screen fit
                        .padding(.bottom, 20) // Rules: Reduced from 40 to 20 for better screen fit
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
                        .padding(.vertical, 20) // Rules: Reduced from 32 to 20 for better screen fit
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
                                    selectedMetric = metric
                                }
                                HapticManager.shared.playSelection()
                            }
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 4) // Rules: Reduced from 8 to 4 for better screen fit
                        .padding(.bottom, 12) // Rules: Reduced from 20 to 12 for better screen fit
                    }
                    
                    // Add consistent padding for page indicators - Rules: Better spacing
                    Spacer()
                        .frame(height: max(30, geometry.safeAreaInsets.bottom + 15))  // Rules: Reduced from 40/20 to 30/15 for better screen fit
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
    
    private func getHeadlineText() -> String {
        // Rules: Restore original headline format that shows specific impact on lifespan
        let timeFrame: String
        switch selectedPeriod {
        case .day:
            timeFrame = "today"
        case .month:
            timeFrame = "this month"
        case .year:
            timeFrame = "this year"
        }
        
        if totalTimeImpact >= 0 {
            return "\(timeFrame.capitalized), your habits collectively added"
        } else {
            return "\(timeFrame.capitalized), your habits collectively reduced"
        }
    }
    
    /// Calculate optimal chart height to maximize space while keeping recommendations visible
    /// Rules: Conservative sizing to ensure recommendation card is always visible
    private func calculateOptimalChartHeight(geometry: GeometryProxy) -> CGFloat {
        let screenHeight = geometry.size.height
        
        // Be more conservative with space estimates to ensure recommendation card is visible
        let impactSummaryHeight: CGFloat = 160  // Impact text and icon section (increased)
        let recommendationCardHeight: CGFloat = 140  // Recommendation card with margin (increased)
        let paddingAndSpacing: CGFloat = 120  // Total padding, spacing, and safe areas (increased)
        
        // Calculate available space for chart with safety margin
        let usedSpace = impactSummaryHeight + recommendationCardHeight + paddingAndSpacing
        let availableSpace = screenHeight - usedSpace
        
        // Set conservative bounds: minimum 180px, maximum 280px (reduced max)
        let minHeight: CGFloat = 180
        let maxHeight: CGFloat = 280
        
        return max(minHeight, min(maxHeight, availableSpace))
    }
} 