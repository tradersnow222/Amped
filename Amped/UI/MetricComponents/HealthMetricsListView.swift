import SwiftUI

/// A view that displays health metrics with a simple list layout
struct HealthMetricsListView: View {
    // MARK: - Properties
    
    let metrics: [HealthMetric]
    let onMetricTap: (HealthMetric) -> Void
    
    @State private var isAnimating = false
    @Environment(\.glassTheme) private var glassTheme
    
    // MARK: - Initialization
    
    init(metrics: [HealthMetric], onMetricTap: @escaping (HealthMetric) -> Void) {
        self.metrics = metrics
        self.onMetricTap = onMetricTap
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header section with battery connection
            headerSection
                .accessibilityAddTraits(.isHeader)
            
            // Simple metrics list
            if metrics.isEmpty {
                emptyStateView
            } else {
                metricsListView
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
    
    /// Header section with visual connection to the battery
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 8) {
            // Battery icon with animation
            ZStack {
                Image(systemName: "battery.100")
                    .font(.title2)
                    .foregroundColor(.fullPower)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Your Health Factors")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Powering your life energy")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
    
    /// Simple list of health metrics
    private var metricsListView: some View {
        VStack(spacing: 8) {
            ForEach(sortedMetrics) { metric in
                HealthMetricRow(metric: metric)
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
    
    /// Sort metrics by impact magnitude (highest impact first)
    private var sortedMetrics: [HealthMetric] {
        return metrics.sorted(by: { metric1, metric2 in
            // Sort by absolute impact value if available
            if let impact1 = metric1.impactDetails?.lifespanImpactMinutes,
               let impact2 = metric2.impactDetails?.lifespanImpactMinutes {
                return abs(impact1) > abs(impact2)
            }
            
            // Fallback to power level comparison
            return metric1.powerLevel.sortOrder > metric2.powerLevel.sortOrder
        })
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