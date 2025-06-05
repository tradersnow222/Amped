import SwiftUI

/// A view that displays a sorted list of health metrics with their impact on battery life
struct HealthMetricsListView: View {
    // MARK: - Properties
    
    let metrics: [HealthMetric]
    let onMetricTap: (HealthMetric) -> Void
    
    @State private var isAnimating = false
    
    // MARK: - Initialization
    
    init(metrics: [HealthMetric], onMetricTap: @escaping (HealthMetric) -> Void) {
        // Sort metrics by absolute impact (most impactful first)
        self.metrics = metrics.sorted {
            abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0)
        }
        self.onMetricTap = onMetricTap
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header section with connection to battery
            headerSection
                .accessibilityAddTraits(.isHeader)
            
            // List of metrics
            if metrics.isEmpty {
                emptyStateView
            } else {
                metricsList
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Health Factors")
        .accessibilityHint("Displays health metrics that impact your battery life, sorted by most impactful")
    }
    
    // MARK: - UI Components
    
    /// Header section with visual connection to the battery
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title with connection to battery
            HStack(spacing: 8) {
                // Energy flow icon
                Image(systemName: "bolt.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.ampedGreen)
                    .opacity(isAnimating ? 1 : 0)
                    .scaleEffect(isAnimating ? 1 : 0.5)
                    .accessibilityHidden(true)
                
                Text("Health Factors")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                // Visual connector to battery
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.ampedGreen.opacity(0.7), Color.ampedGreen.opacity(0)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    // Animated energy pulse
                    if isAnimating {
                        HStack(spacing: 8) {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(Color.ampedGreen)
                                    .frame(width: 3, height: 3)
                                    .offset(x: isAnimating ? 30 : 0)
                                    .opacity(isAnimating ? 0 : 1)
                                    .animation(
                                        Animation.easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: false)
                                            .delay(Double(index) * 0.3),
                                        value: isAnimating
                                    )
                            }
                        }
                    }
                }
                .accessibilityHidden(true)
            }
            
            // Subtitle explaining connection to battery
            Text("These factors power your battery life")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.leading, 2)
                .padding(.bottom, 4)
        }
    }
    
    /// List of health metrics
    private var metricsList: some View {
        VStack(spacing: 12) {
            ForEach(metrics) { metric in
                HealthMetricRow(metric: metric)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onMetricTap(metric)
                    }
                    .transition(.opacity)
            }
        }
        .accessibilitySortPriority(1) // Prioritize metrics list in accessibility focus order
    }
    
    /// Empty state when no metrics are available
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)
                .padding(.top, 24)
                .accessibilityHidden(true)
            
            Text("No health data available")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text("Check your Health app permissions or complete the health questionnaire")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No health data available")
        .accessibilityHint("Check your Health app permissions or complete the health questionnaire")
    }
    
    /// State when permissions are granted but no health data exists yet
    private var placeholderStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk")
                .font(.system(size: 40))
                .foregroundColor(.ampedGreen)
                .padding(.top, 24)
                .accessibilityHidden(true)
            
            Text("Health tracking ready")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text("Permissions granted! Start using the Health app or your Apple Watch to record health metrics and they'll appear here.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Health tracking ready")
        .accessibilityHint("Start using the Health app or your Apple Watch to record health metrics")
    }
}

// MARK: - Preview

#Preview {
    // Preview with metrics
    HealthMetricsListView(
        metrics: [
            // Sleep - positive impact
            HealthMetric(
                id: UUID().uuidString,
                type: .sleepHours,
                value: 7.5,
                date: Date(),
                source: .healthKit,
                impactDetails: MetricImpactDetail(
                    metricType: .sleepHours,
                    lifespanImpactMinutes: 45,
                    comparisonToBaseline: .better
                )
            ),
            // Stress - negative impact
            HealthMetric(
                id: UUID().uuidString,
                type: .stressLevel,
                value: 7.0,
                date: Date(),
                source: .userInput,
                impactDetails: MetricImpactDetail(
                    metricType: .stressLevel,
                    lifespanImpactMinutes: -15,
                    comparisonToBaseline: .worse
                )
            ),
            // Nutrition - positive impact
            HealthMetric(
                id: UUID().uuidString,
                type: .nutritionQuality,
                value: 7.0,
                date: Date(),
                source: .userInput,
                impactDetails: MetricImpactDetail(
                    metricType: .nutritionQuality,
                    lifespanImpactMinutes: 30,
                    comparisonToBaseline: .better
                )
            )
        ],
        onMetricTap: { _ in }
    )
    .padding()
    .background(Color.black)
} 