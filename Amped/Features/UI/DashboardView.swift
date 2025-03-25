import SwiftUI

/// Main dashboard view displaying life impact and projection batteries
struct DashboardView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @State private var showMetricDetail: HealthMetric? = nil
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period selector
                PeriodSelector(selectedPeriod: $selectedPeriod)
                    .onChange(of: selectedPeriod) { oldValue, newPeriod in
                        viewModel.calculateImpact(for: newPeriod)
                    }
                
                // Dual battery display
                HStack(alignment: .top, spacing: 16) {
                    // Life impact battery
                    if let impactDataPoint = viewModel.impactDataPoint {
                        BatteryLifeImpactCard(
                            impactDataPoint: impactDataPoint,
                            selectedPeriod: selectedPeriod
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                    
                    // Life projection battery
                    if let lifeProjection = viewModel.lifeProjection {
                        BatteryLifeProjectionCard(
                            lifeProjection: lifeProjection,
                            userAge: viewModel.userProfile.age ?? 30
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)
                
                // Metrics section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Power Sources")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                        ForEach(viewModel.metrics) { metric in
                            BatteryMetricCard(metric: metric)
                                .onTapGesture {
                                    showMetricDetail = metric
                                }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Spacer for ScrollView
                Spacer(minLength: 40)
            }
            .padding(.top)
            
            // Loading overlay during initial loading or background updates
            .overlay(
                Group {
                    if viewModel.isLoading && viewModel.metrics.isEmpty {
                        ProgressView("Charging...")
                            .cornerRadius(10)
                            .padding()
                    }
                }
            )
        }
        .navigationTitle("Battery Status")
        .sheet(item: $showMetricDetail) { metric in
            MetricDetailsView(
                metric: metric,
                onClose: {
                    showMetricDetail = nil
                }
            )
        }
        .onAppear {
            viewModel.loadData()
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }
}

// MARK: - Dashboard ViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    // MARK: - Properties
    
    @Published var metrics: [HealthMetric] = []
    @Published var isLoading: Bool = false
    @Published var impactDataPoint: ImpactDataPoint?
    @Published var lifeProjection: LifeProjection?
    
    // Health services with proper actor isolation
    private let healthDataService: HealthDataService
    
    // Mock user profile
    let userProfile = UserProfile(
        id: UUID().uuidString,
        birthYear: 1990,
        gender: .male,
        isSubscribed: true,
        hasCompletedOnboarding: true,
        hasCompletedQuestionnaire: true,
        hasGrantedHealthKitPermissions: true
    )
    
    private lazy var lifeImpactService = LifeImpactService(userProfile: userProfile)
    private lazy var lifeProjectionService = LifeProjectionService()
    
    init() {
        let healthKitManager = HealthKitManager()
        self.healthDataService = HealthDataService(healthKitManager: healthKitManager)
    }
    
    // MARK: - Public Methods
    
    func loadData() {
        Task {
            isLoading = true
            
            // Request HealthKit permissions if needed
            _ = await healthDataService.fetchLatestMetrics()
            
            // Fetch metrics, calculate impact and projection
            await refreshData()
            
            isLoading = false
        }
    }
    
    func refreshData() async {
        isLoading = true
        
        // Fetch latest health metrics
        let healthMetrics = await healthDataService.fetchLatestMetrics()
        
        // Mock manual metrics (would come from QuestionnaireManager)
        let manualMetrics = [
            ManualMetricInput(metricType: .nutritionQuality, value: 7.0),
            ManualMetricInput(metricType: .stressLevel, value: 4.0)
        ]
        
        // Combine HealthKit and manual metrics
        let combinedMetrics = healthDataService.combineHealthKitAndManualMetrics(
            healthKitMetrics: healthMetrics,
            manualMetrics: manualMetrics
        )
        
        // Calculate impact for each metric
        let metricsWithImpact = combinedMetrics.map { metric in
            _ = metric // Remove unused variable
            let impact = lifeImpactService.calculateImpact(for: metric)
            return HealthMetric(
                id: metric.id,
                type: metric.type,
                value: metric.value,
                date: metric.date,
                impactDetail: impact
            )
        }
        
        // Calculate total impact for selected period
        calculateImpact(for: .day, using: metricsWithImpact)
        
        // Update UI
        self.metrics = metricsWithImpact.sorted {
            // Sort by absolute impact (largest first)
            abs($0.impactDetail?.lifespanImpactMinutes ?? 0) > abs($1.impactDetail?.lifespanImpactMinutes ?? 0)
        }
        
        self.isLoading = false
    }
    
    func calculateImpact(for period: ImpactDataPoint.PeriodType) {
        calculateImpact(for: period, using: metrics)
    }
    
    // MARK: - Private Methods
    
    private func calculateImpact(for period: ImpactDataPoint.PeriodType, using metrics: [HealthMetric]) {
        // Calculate total impact for the selected period
        let impact = lifeImpactService.calculateTotalImpact(
            from: metrics,
            for: period
        )
        
        // Generate life projection based on impact
        let projection = lifeProjectionService.generateLifeProjection(
            for: userProfile,
            cumulativeImpactMinutes: impact.totalImpactMinutes
        )
        
        // Update UI
        impactDataPoint = impact
        lifeProjection = projection
    }
    
    private func updateImpactData() async {
        await refreshData()
    }
}

// MARK: - Extension for UserDefaults

extension UserDefaults {
    /// Get a boolean value with a default fallback
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if self.object(forKey: key) == nil {
            return defaultValue
        }
        return self.bool(forKey: key)
    }
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView()
        }
    }
} 