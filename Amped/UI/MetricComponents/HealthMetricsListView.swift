import SwiftUI

/// A view that displays health metrics with a simple list layout
struct HealthMetricsListView: View {
    // MARK: - Properties
    
    let metrics: [HealthMetric]
    let onMetricTap: (HealthMetric) -> Void
    /// Optional period to indicate if metrics are showing averaged data
    let selectedPeriod: ImpactDataPoint.PeriodType?
    
    @State private var isAnimating = false
    @Environment(\.glassTheme) private var glassTheme
    @EnvironmentObject private var settingsManager: SettingsManager
    
    // MARK: - Initialization
    
    init(metrics: [HealthMetric], selectedPeriod: ImpactDataPoint.PeriodType? = nil, onMetricTap: @escaping (HealthMetric) -> Void) {
        self.metrics = metrics
        self.selectedPeriod = selectedPeriod
        self.onMetricTap = onMetricTap
    }
    
    // MARK: - Computed Properties
    
    /// Whether to show the average indicator based on selected period
    private var showAverageIndicator: Bool {
        guard let period = selectedPeriod else { return false }
        return period == .month || period == .year
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Simple metrics list
            if metrics.isEmpty {
                emptyStateView
            } else {
                groupedMetricsView
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Health Factors")
        .accessibilityHint("Displays your health metrics with their impact on lifespan")
    }
    
    // MARK: - UI Components
    
    /// Grouped view showing manual and HealthKit metrics separately
    private var groupedMetricsView: some View {
        VStack(spacing: 24) {
            // HealthKit metrics section
            if !healthKitMetrics.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Section header
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Live Health Data")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 8)
                    
                    // Metrics
                    VStack(spacing: 8) {
                        ForEach(sortedHealthKitMetrics) { metric in
                            HealthMetricRow(metric: metric, showingAverage: showAverageIndicator)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onMetricTap(metric)
                                }
                                .transition(.opacity)
                        }
                    }
                }
            }
            
            // Manual metrics section
            if !manualMetrics.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    // Section header
                    HStack {
                        Image(systemName: "person.fill.checkmark")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("Your Health Profile")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    .padding(.horizontal, 8)
                    
                    // Metrics
                    VStack(spacing: 8) {
                        ForEach(sortedManualMetrics) { metric in
                            HealthMetricRow(metric: metric, showingAverage: false) // Manual metrics are not averaged
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onMetricTap(metric)
                                }
                                .transition(.opacity)
                        }
                    }
                }
            }
        }
        .accessibilitySortPriority(1)
    }
    
    /// Simple list of health metrics (ungrouped)
    private var metricsListView: some View {
        VStack(spacing: 8) {
            ForEach(sortedMetrics) { metric in
                HealthMetricRow(metric: metric, showingAverage: showAverageIndicator)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onMetricTap(metric)
                    }
                    .transition(.opacity)
            }
        }
        .accessibilitySortPriority(1)
    }
    
    /// Empty state when no metrics are available
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "battery.0")
                .font(.system(size: 48))
                .foregroundColor(.criticalPower)
            
            Text("No Health Data")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Connect your health data to power up your battery")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .glassBackground(.ultraThin, cornerRadius: glassTheme.glassCornerRadius)
    }
    
    // MARK: - Helper Methods
    
    /// Filter metrics by source
    private var healthKitMetrics: [HealthMetric] {
        metrics.filter { $0.source == .healthKit }
    }
    
    private var manualMetrics: [HealthMetric] {
        metrics.filter { $0.source == .userInput }
    }
    
    /// Sort HealthKit metrics by impact magnitude
    private var sortedHealthKitMetrics: [HealthMetric] {
        return healthKitMetrics.sorted(by: sortByImpact)
    }
    
    /// Sort manual metrics by impact magnitude
    private var sortedManualMetrics: [HealthMetric] {
        return manualMetrics.sorted(by: sortByImpact)
    }
    
    /// Sort all metrics by impact magnitude (highest impact first)
    private var sortedMetrics: [HealthMetric] {
        return metrics.sorted(by: sortByImpact)
    }
    
    /// Sorting function by impact
    private func sortByImpact(_ metric1: HealthMetric, _ metric2: HealthMetric) -> Bool {
        // Sort by absolute impact value if available
        if let impact1 = metric1.impactDetails?.lifespanImpactMinutes,
           let impact2 = metric2.impactDetails?.lifespanImpactMinutes {
            return abs(impact1) > abs(impact2)
        }
        
        // Fallback to power level comparison
        return metric1.powerLevel.sortOrder > metric2.powerLevel.sortOrder
    }
}

// MARK: - Extensions

extension PowerLevel {
    /// Sort order for power levels (higher is better)
    var sortOrder: Int {
        switch self {
        case .full: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        case .critical: return 1
        }
    }
}

// MARK: - Preview

struct HealthMetricsListView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleMetrics = [
            HealthMetric(
                id: UUID().uuidString,
                type: .steps,
                value: 8500,
                date: Date(),
                source: .healthKit,
                impactDetails: MetricImpactDetail(
                    metricType: .steps,
                    lifespanImpactMinutes: 15,
                    comparisonToBaseline: .better,
                    scientificReference: "Daily Steps and Mortality Study"
                )
            ),
            HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: 7.5,
                date: Date(),
                source: .healthKit
            ),
            HealthMetric(
                id: UUID().uuidString,
                type: .heartRateVariability,
                value: 45,
                date: Date(),
                source: .healthKit
            )
        ]
        
        HealthMetricsListView(metrics: sampleMetrics) { _ in }
            .padding()
            .withGlassTheme()
            .background(
                Image("DeepBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
            )
    }
} 