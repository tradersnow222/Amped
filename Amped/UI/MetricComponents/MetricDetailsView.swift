import SwiftUI

/// Detailed view for a specific health metric
struct MetricDetailsView: View {
    // MARK: - Properties
    
    /// The health metric to display
    let metric: HealthMetric
    
    /// Period for data display
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    
    /// Close action
    var onClose: (() -> Void)?
    
    /// View model for fetching real historical data (professional approach)
    @StateObject private var viewModel: MetricDetailViewModel
    
    // MARK: - Initialization
    
    init(metric: HealthMetric, onClose: (() -> Void)? = nil) {
        self.metric = metric
        self.onClose = onClose
        self._viewModel = StateObject(wrappedValue: MetricDetailViewModel(metric: metric))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with metric card
                    BatteryMetricCard(metric: metric, showDetails: true)
                        .padding(.horizontal)
                    
                    // Period selector for chart
                    periodSelector
                        .padding(.horizontal)
                    
                    // Chart section - Professional-style with REAL DATA ONLY
                    if !viewModel.isLoadingHistory {
                        MetricChartSection(
                            metricType: metric.type,
                            dataPoints: viewModel.professionalStyleDataPoints, // REAL DATA ONLY
                            period: selectedPeriod
                        )
                        .padding(.horizontal)
                    } else {
                        ProgressView("Loading real historical data...")
                            .padding()
                    }
                    
                    // Personal history evaluation section
                    HistoryEvaluationCard(metric: metric, dataPoints: viewModel.historyDataPoints, period: selectedPeriod)
                        .padding(.horizontal)
                    
                    // Single recommendation section
                    SingleRecommendationCard(metric: metric)
                        .padding(.horizontal)
                    
                    // Space at bottom for better scrolling
                    Spacer(minLength: 40)
                }
                .padding(.vertical)
            }
            .navigationTitle(metric.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .withDeepBackground()
            .onAppear {
                // Configure navigation bar appearance to match dark theme
                let scrolledAppearance = UINavigationBarAppearance()
                scrolledAppearance.configureWithDefaultBackground()
                scrolledAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
                scrolledAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                
                let transparentAppearance = UINavigationBarAppearance()
                transparentAppearance.configureWithTransparentBackground()
                transparentAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                
                UINavigationBar.appearance().standardAppearance = scrolledAppearance
                UINavigationBar.appearance().scrollEdgeAppearance = transparentAppearance
                UINavigationBar.appearance().compactAppearance = scrolledAppearance
                
                // Load REAL historical data for this metric (professional approach)
                viewModel.loadRealHistoricalData(for: metric, period: selectedPeriod)
            }
            .onChange(of: selectedPeriod) { newPeriod in
                // Reload data when period changes (professional approach)
                viewModel.loadRealHistoricalData(for: metric, period: newPeriod)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onClose?()
                    }
                }
            }
        }
    }
    
    // MARK: - Period Selector
    
    /// Period selector for the chart
    private var periodSelector: some View {
        HStack {
            Text("Time Period:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Picker("Period", selection: $selectedPeriod) {
                Text("Day").tag(ImpactDataPoint.PeriodType.day)
                Text("Month").tag(ImpactDataPoint.PeriodType.month)
                Text("Year").tag(ImpactDataPoint.PeriodType.year)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 200)
        }
    }
}

// MARK: - MetricDetailsViewModel

// REMOVED: Duplicate MetricDetailViewModel class
// Professional approach: Use the real MetricDetailViewModel from Features/UI/ViewModels/ instead

// MARK: - Preview Provider

#Preview {
    MetricDetailsView(
        metric: HealthMetric(
            id: "sample-id",
            type: .steps,
            value: 9500,
            date: Date(),
            source: .healthKit,
            impactDetails: MetricImpactDetail(
                metricType: .steps,
                currentValue: 9500,
                baselineValue: 8000,
                studyReferences: [],
                lifespanImpactMinutes: 45,
                calculationMethod: .metaAnalysisSynthesis,
                recommendation: "Outstanding daily step count! This contributes significantly to your longevity."
            )
        )
    )
}
