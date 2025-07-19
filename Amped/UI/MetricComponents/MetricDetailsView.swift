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
    
    /// View model for fetching historical data
    @StateObject private var viewModel = MetricDetailsViewModel()
    
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
                    
                    // Chart section
                    if !viewModel.isLoadingHistory {
                        MetricChartSection(
                            metricType: metric.type,
                            dataPoints: viewModel.historyDataPoints,
                            period: selectedPeriod
                        )
                        .padding(.horizontal)
                    } else {
                        ProgressView("Loading history...")
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
            .navigationTitle(metric.type.name)
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
                
                // Load historical data for this metric
                viewModel.loadHistoricalData(for: metric, period: selectedPeriod)
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
        .onChange(of: selectedPeriod) { newValue in
            viewModel.loadHistoricalData(for: metric, period: newValue)
        }
    }
}

// MARK: - MetricDetailsViewModel

/// ViewModel for the MetricDetailsView
final class MetricDetailsViewModel: ObservableObject {
    // MARK: - Properties
    
    /// Historical data points for charting
    @Published var historyDataPoints: [MetricDataPoint] = []
    
    /// Loading state
    @Published var isLoadingHistory: Bool = false
    
    // MARK: - Public Methods
    
    /// Load historical data for a specific metric
    /// - Parameters:
    ///   - metric: The metric to load history for
    ///   - period: The time period to load
    func loadHistoricalData(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) {
        isLoadingHistory = true
        
        // In a real app, we would fetch from HealthKit or local database
        // For the MVP, we'll generate simulated data
        Task {
            // Simulate network delay
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            let dataPoints = generateSimulatedData(for: metric, period: period)
            
            await MainActor.run {
                self.historyDataPoints = dataPoints
                self.isLoadingHistory = false
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Generate simulated historical data for preview and testing
    /// - Parameters:
    ///   - metric: The metric to generate data for
    ///   - period: The time period
    /// - Returns: Array of data points
    private func generateSimulatedData(for metric: HealthMetric, period: ImpactDataPoint.PeriodType) -> [MetricDataPoint] {
        // Current value as baseline
        let baseValue = metric.value
        
        // Number of data points based on period
        let count: Int
        let intervalUnit: Calendar.Component
        
        switch period {
        case .day:
            count = 24
            intervalUnit = .hour
        case .month:
            count = 30
            intervalUnit = .day
        case .year:
            count = 12
            intervalUnit = .month
        }
        
        // Generate data points
        var dataPoints: [MetricDataPoint] = []
        let now = Date()
        let calendar = Calendar.current
        
        for i in 0..<count {
            // Calculate date for this point
            let date: Date
            if i == count - 1 {
                date = now
            } else {
                let components = getDateComponents(for: intervalUnit, count: count - 1 - i)
                date = calendar.date(byAdding: components, to: now) ?? now
            }
            
            // Calculate value with some randomness
            let randomVariation = Double.random(in: -0.15...0.15)
            let variationMultiplier = 1.0 + randomVariation
            let trend = Double(i) / Double(count) * 0.2 // slight upward trend
            let value = baseValue * variationMultiplier * (1 + trend)
            
            dataPoints.append(MetricDataPoint(date: date, value: value))
        }
        
        return dataPoints.sorted { $0.date < $1.date }
    }
    
    /// Get date components for historical calculations
    /// - Parameters:
    ///   - unit: Calendar component
    ///   - count: Number of units
    /// - Returns: DateComponents for the calculation
    private func getDateComponents(for unit: Calendar.Component, count: Int) -> DateComponents {
        var components = DateComponents()
        
        switch unit {
        case .hour:
            components.hour = -count
        case .day:
            components.day = -count
        case .month:
            components.month = -count
        default:
            components.day = -count
        }
        
        return components
    }
}

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
                lifespanImpactMinutes: 45,
                comparisonToBaseline: .better,
                scientificReference: "Daily Step Count and Mortality"
            )
        )
    )
} 