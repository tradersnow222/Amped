import SwiftUI
import CoreHaptics

/// Main dashboard view displaying life impact and projection batteries
struct DashboardView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @State private var showMetricDetail: HealthMetric? = nil
    @EnvironmentObject var appState: AppState
    
    // State for help popovers
    @State private var showingImpactHelp = false
    @State private var showingProjectionHelp = false
    
    // Animation states
    @State private var hapticEngine: CHHapticEngine?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Deep background is maintained from the app theme
            
            // Main content area
            ScrollView {
                VStack(spacing: 16) {
                    // Custom period selector
                    futuristicPeriodSelector
                        .padding(.top, 8)
                    
                    // The dashboard battery system
                    batterySystemView
                    
                    // Power Sources Metrics section (always visible)
                    metricsSection
                }
                .padding(.horizontal)
            }
            .withDeepBackground()
        }
        .navigationTitle("Energy Dashboard")
        .navigationBarTitleDisplayMode(.large)
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
            prepareHaptics()
        }
        .refreshable {
            await viewModel.refreshData()
            playHapticSuccess()
        }
        // Updated help popovers for better clarity
        .popover(isPresented: $showingImpactHelp) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Impact")
                    .font(.headline)
                    .foregroundColor(.ampedGreen)
                
                Text("Shows how your recent health habits affect your lifespan in the selected time period.")
                    .font(.body)
                
                Text("• Positive values (green) = time gained")
                Text("• Negative values (red) = time lost")
                    .padding(.bottom, 4)
                
                Text("This battery responds quickly to lifestyle changes.")
                    .font(.caption)
                    .italic()
            }
            .padding()
            .frame(width: 300)
        }
        .popover(isPresented: $showingProjectionHelp) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Life Projection")
                    .font(.headline)
                    .foregroundColor(.ampedYellow)
                
                Text("Shows your approximate (~) remaining lifespan based on your health data and habits.")
                    .font(.body)
                
                Text("This battery updates gradually as your health habits create lasting impact.")
                    .padding(.bottom, 4)
                
                Text("Based on scientific research and health metrics.")
                    .font(.caption)
                    .italic()
            }
            .padding()
            .frame(width: 300)
        }
    }
    
    // MARK: - UI Components
    
    /// Futuristic period selector with glowing active state
    private var futuristicPeriodSelector: some View {
        HStack(spacing: 0) {
            ForEach(ImpactDataPoint.PeriodType.allCases, id: \.self) { period in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPeriod = period
                    }
                    playHapticSelection()
                    viewModel.calculateImpact(for: period)
                } label: {
                    Text(period.displayName)
                        .fontWeight(selectedPeriod == period ? .bold : .medium)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selectedPeriod == period {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.ampedGreen.opacity(0.2))
                                    
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.ampedGreen, lineWidth: 1.5)
                                        .shadow(color: Color.ampedGreen.opacity(0.6), radius: 4)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                }
                            }
                        )
                        .foregroundColor(selectedPeriod == period ? Color.ampedGreen : .gray)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .padding(.horizontal, 16)
    }
    
    /// Combined dual battery visualization
    private var batterySystemView: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                // Life Impact Battery
                if let impactDataPoint = viewModel.impactDataPoint {
                    // Calculate the impactValue *before* the View is created
                    let impactValue = calculateFormattedImpactValue(impactDataPoint: impactDataPoint, selectedPeriod: selectedPeriod)

                    BatteryIndicatorView(
                        title: "Today's Impact",
                        value: impactValue,
                        chargeLevel: calculateImpactChargeLevel(impactDataPoint.totalImpactMinutes, period: selectedPeriod),
                        numberOfSegments: 5,
                        useYellowGradient: false,
                        internalText: nil,
                        helpAction: { showingImpactHelp = true }
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    loadingBatteryPlaceholder()
                    .frame(maxWidth: .infinity)
                }

                // Life Projection Battery
                if let lifeProjection = viewModel.lifeProjection {
                    BatteryIndicatorView(
                        title: "Lifespan remaining",
                        value: lifeProjection.formattedProjectionValue(currentUserAge: viewModel.currentUserAge) + " years",
                        chargeLevel: lifeProjection.projectionPercentage(currentUserAge: viewModel.currentUserAge),
                        numberOfSegments: 5,
                        useYellowGradient: true,
                        internalText: nil,
                        helpAction: { showingProjectionHelp = true }
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    loadingBatteryPlaceholder()
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    /// Metrics grid section
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with connecting element to batteries above
            HStack {
                // Improved section header
                Text("Health Factors")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                // Visual connector element
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.ampedGreen.opacity(0.7), Color.ampedGreen.opacity(0)]), 
                                         startPoint: .leading, 
                                         endPoint: .trailing))
                    .frame(height: 1)
                    .padding(.leading, 4)
            }
            .padding(.leading, 8)
            .padding(.top, 16)
            
            // Subtitle explaining connection to batteries
            Text("These factors power your battery life")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .padding(.leading, 8)
                .padding(.top, -4)
            
            // Always visible metrics grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                ForEach(viewModel.metrics) { metric in
                    EnhancedMetricCard(metric: metric)
                        .onTapGesture {
                            showMetricDetail = metric
                            playHapticSelection()
                        }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.bottom, 32)
    }
    
    /// Loading placeholder
    private func loadingBatteryPlaceholder() -> some View {
        BatteryIndicatorView(
            title: "Loading...", 
            value: "--", 
            chargeLevel: 0.0, 
            numberOfSegments: 5, 
            useYellowGradient: false,
            internalText: nil,
            helpAction: nil
        )
        .opacity(0.5)
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the formatted string for the impact value, handling line breaks.
    private func calculateFormattedImpactValue(impactDataPoint: ImpactDataPoint, selectedPeriod: ImpactDataPoint.PeriodType) -> String {
        // Just return the raw impact value without adding "today" or line breaks
        return impactDataPoint.formattedImpact
    }
    
    /// Calculate charge level for the impact battery
    private func calculateImpactChargeLevel(_ impactMinutes: Double, period: ImpactDataPoint.PeriodType) -> CGFloat {
        let maxImpactMinutes: Double
        switch period {
            case .day: maxImpactMinutes = 120 // +/- 2 hours
            case .month: maxImpactMinutes = 120 * 30 // Scaled approx.
            case .year: maxImpactMinutes = 120 * 365 // Scaled approx.
        }
        
        let normalizedImpact = (impactMinutes + maxImpactMinutes) / (maxImpactMinutes * 2)
        return max(0.0, min(1.0, normalizedImpact)) // Clamp between 0 and 1
    }
    
    // MARK: - Haptics
    
    /// Prepare haptic engine
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }
    
    /// Play selection haptic feedback
    private func playHapticSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Play success haptic feedback
    private func playHapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Enhanced Metric Card

/// A more visually appealing metric card
struct EnhancedMetricCard: View {
    let metric: HealthMetric
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and power level
            HStack {
                Image(systemName: metric.type.symbolName)
                    .font(.title3)
                    .foregroundColor(powerColor)
                
                Text(metric.type.displayName)
                    .futuristicText(size: 16, weight: .medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Power level indicator
                HStack(spacing: 2) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(i < powerLevel ? powerColor : Color.gray.opacity(0.3))
                            .frame(width: 3, height: 8 + CGFloat(i))
                    }
                }
            }
            
            // Metric value
            Text(metric.formattedValue)
                .futuristicText(size: 24, weight: .bold)
                .foregroundColor(powerColor)
            
            // Impact
            if let impact = metric.impactDetails {
                HStack(spacing: 4) {
                    Image(systemName: impact.lifespanImpactMinutes >= 0 ? "arrow.up" : "arrow.down")
                        .foregroundColor(impact.lifespanImpactMinutes >= 0 ? .ampedGreen : .ampedRed)
                        .font(.caption)
                    
                    Text(impact.formattedImpact)
                        .futuristicText(size: 14, weight: .medium)
                        .foregroundColor(impact.lifespanImpactMinutes >= 0 ? .ampedGreen : .ampedRed)
                }
            }
        }
        .padding()
        .background(
            ZStack {
                // Base layer
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.5))
                
                // Border with glow
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        powerColor.opacity(isPressed ? 0.8 : 0.4),
                        lineWidth: isPressed ? 2 : 1
                    )
                    .shadow(
                        color: powerColor.opacity(isPressed ? 0.4 : 0.2),
                        radius: isPressed ? 6 : 3
                    )
            }
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onTapGesture {
            // Simulate press/release for feedback
            withAnimation {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
            }
        }
    }
    
    /// Get numeric power level (0-5)
    private var powerLevel: Int {
        switch metric.powerLevel {
        case .full: return 5
        case .high: return 4
        case .medium: return 3
        case .low: return 2
        case .critical: return 1
        }
    }
    
    /// Get power level color
    private var powerColor: Color {
        switch metric.powerLevel {
        case .full: return .fullPower
        case .high: return .highPower
        case .medium: return .mediumPower
        case .low: return .lowPower
        case .critical: return .criticalPower
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
    
    /// Calculated current age of the user
    var currentUserAge: Double {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return Double(currentYear - (userProfile.birthYear ?? currentYear))
    }
    
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
            ManualMetricInput(type: .nutritionQuality, value: 7.0),
            ManualMetricInput(type: .stressLevel, value: 4.0)
        ]
        
        // Combine HealthKit and manual metrics
        let combinedMetrics = healthDataService.combineHealthKitAndManualMetrics(
            healthKitMetrics: healthMetrics,
            manualMetrics: manualMetrics
        )
        
        // Calculate impact for each metric
        let metricsWithImpact = combinedMetrics.map { metric in
            let impact = lifeImpactService.calculateImpact(for: metric)
            return HealthMetric(
                id: metric.id,
                type: metric.type,
                value: metric.value,
                date: metric.date,
                source: metric.source,
                impactDetails: impact
            )
        }
        
        // Calculate total impact for selected period
        calculateImpact(for: .day, using: metricsWithImpact)
        
        // Update UI
        self.metrics = metricsWithImpact.sorted {
            // Sort by absolute impact (largest first)
            abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0)
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
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView()
        }
    }
} 