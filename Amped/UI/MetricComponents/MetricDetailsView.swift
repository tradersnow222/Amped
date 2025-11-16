import SwiftUI
import Charts

/// Detailed view for a specific health metric
struct MetricDetailsView: View {
    // MARK: - Properties
    
    /// The health metric to display
//    let metric: HealthMetric
    
    /// Period for data display
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @State private var metric: HealthMetric
    
    /// Close action
    var onClose: (() -> Void)?
    
    /// View model for fetching real historical data (professional approach)
    @StateObject private var viewModel: MetricDetailViewModel
    @StateObject private var dashboardViewModel = DashboardViewModel()
    
    @Binding var navigationPath: NavigationPath
        
    // MARK: - Initialization
    
    init(navigationPath: Binding<NavigationPath>, metric: HealthMetric, selectedPeriod: ImpactDataPoint.PeriodType, onClose: (() -> Void)? = nil) {
        self.onClose = onClose
        self._navigationPath = navigationPath
        self._viewModel = StateObject(wrappedValue: MetricDetailViewModel(metric: metric, initialPeriod: selectedPeriod))
        self._metric = State(wrappedValue: metric)
        self._selectedPeriod = State(wrappedValue: selectedPeriod)
    }
    
    // MARK: - Body
    
    var body: some View {
//        NavigationView {
//            ScrollView {
        ZStack {
            Color.black.ignoresSafeArea(.all)
            LinearGradient.grayGradient.ignoresSafeArea()
            
                VStack(spacing: 4) {
                    // Header with metric card
                    // Header
                    HStack(spacing: 12) {
                        Button(action: {
                            onClose?()
                            DispatchQueue.main.async {
                                navigationPath.removeLast()
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle().fill(Color.white.opacity(0.08))
                                )
                        }

                        personalizedHeader
                    }
                    .padding(.horizontal, 16)

                    // Date navigation bar
                    dateNavigationBar(defaultSelected: selectedPeriod)
                    
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Status sentence
                            // Status text
                            if let latestMetric = dashboardViewModel.healthMetrics.first(where: { $0.type == metric.type }) {
                                let impactMinutes = latestMetric.impactDetails?.lifespanImpactMinutes ?? 0
                                let isPositive = impactMinutes >= 0
                                let minutes = Int(abs(impactMinutes))
                                let lostOrGained = isPositive ? "gained" : "lost"
                                let mainColor: Color = isPositive ? .ampedGreen : .ampedRed
                                //                            let metric = metricTitle.lowercased()
                                let periodLabel: String = {
                                    switch selectedPeriod {
                                    case .day: return "Today"
                                    case .month: return "This month"
                                    case .year: return "This year"
                                    }
                                }()
                                
                                // Descriptive sentence (period-aware)
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    
                                    // Example: "This month you've"
                                    Text("\(periodLabel) you've")
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("\(lostOrGained) \(minutes) mins")
                                        .foregroundColor(mainColor)
                                        .fontWeight(.semibold)
                                    
                                    // Correct grammar for lost/gained
                                    if isPositive {
                                        Text("thanks to your \(title(for: latestMetric.type)).")
                                            .foregroundColor(.white.opacity(0.8))
                                    } else {
                                        Text("due to poor \(title(for: latestMetric.type)).")
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.top, 6)
                                // Big metric value
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text(latestMetric.formattedValue)
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        Text(metricUnit(for: latestMetric.type))
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    
                                    Text(Date.now, style: .date)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                
                                // Chart container with native Swift Charts
                                // Chart section - Professional-style with REAL DATA ONLY
                                if !viewModel.isLoadingHistory {
                                    MetricChartSection2(
                                        metricType: metric.type,
                                        dataPoints: viewModel.professionalStyleDataPoints, // REAL DATA ONLY
                                        period: selectedPeriod
                                    )
                                    .padding(.horizontal)
                                } else {
                                    ProgressView("Loading real historical data...")
                                        .padding()
                                }
                                
                                // Recommendations header
                                //                            if let healthMetric = selectedHealthMetric {
                                Text("\(title(for: latestMetric.type)) Recommendations")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 6)
                                
                                // Recommendation card
                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle().fill(Color.yellow.opacity(0.15))
                                        Image(systemName: iconName(for: latestMetric.type))
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 18, weight: .semibold))
                                    }
                                    .frame(width: 36, height: 36)
                                    
                                    Text(latestMetric.impactDetails?.recommendation ?? "")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.9))
                                    Spacer(minLength: 0)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                                
                                // Secondary tip row
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.white.opacity(0.5))
                                    Text("Tap to see what XX research studies tell us about \(title(for: latestMetric.type))")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.5))
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                //                            }
                                
                                Spacer(minLength: 40)
                            }
                        }
                    }
                }
//            }
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
                
                let timePeriod = TimePeriod(from: selectedPeriod)
                if self.dashboardViewModel.selectedTimePeriod != timePeriod {
                    self.dashboardViewModel.selectedTimePeriod = timePeriod
                }
                
                // Load REAL historical data for this metric (professional approach)
                viewModel.loadRealHistoricalData(for: metric, period: selectedPeriod)
            }
            .onChange(of: selectedPeriod) { newPeriod in
                
                // Reload data when period changes (professional approach)
                viewModel.loadRealHistoricalData(for: metric, period: newPeriod)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Period Selector
    
    private func changePeriod(to period: ImpactDataPoint.PeriodType) {
        guard selectedPeriod != period else { return }
        
        selectedPeriod = period
        
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
//                self.selectedPeriod = period
                let timePeriod = TimePeriod(from: period)
                if self.dashboardViewModel.selectedTimePeriod != timePeriod {
                    self.dashboardViewModel.selectedTimePeriod = timePeriod
                }
            }
            
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
        
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: false)
            .padding(.top, 10)
    }
        
    private func dateNavigationBar(defaultSelected defaultPeriod: ImpactDataPoint.PeriodType = .day) -> some View {
        HStack(spacing: 4) {
            ForEach([ImpactDataPoint.PeriodType.day, .month, .year], id: \.self) { period in
                Button(action: {
                    changePeriod(to: period)
                }) {
                    Text(period.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#318AFC"),
                                            Color(hex: "#18EF47").opacity(0.58)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .opacity(selectedPeriod == period ? 1 : 0)
                        )
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(hex: "#828282").opacity(0.45))
        )
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .onAppear {
            // Apply default selection only once if nothing else selected
//            if selectedPeriod != .day && selectedPeriod != .month && selectedPeriod != .year {
                changePeriod(to: defaultPeriod)
//            }
        }
    }
    
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
        navigationPath: .constant(NavigationPath("")),
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
        ), selectedPeriod: .day
    )
}

extension MetricDetailsView {
    func title(for type: HealthMetricType) -> String {
        switch type {
        case .restingHeartRate: return "Heart Rate"
        case .steps: return "Steps"
        case .activeEnergyBurned: return "Activity"
        case .sleepHours: return "Sleep"
        case .vo2Max: return "Cardio (VO2)"
        case .bodyMass: return "Weight"
        default: return type.displayName
        }
    }

    func iconName(for type: HealthMetricType) -> String {
        switch type {
        case .restingHeartRate: return "heart.fill"
        case .steps: return "figure.walk"
        case .activeEnergyBurned: return "flame.fill"
        case .sleepHours: return "moon.fill"
        case .vo2Max: return "cardioIcon"
        case .bodyMass: return "scalemass.fill"
        default: return "heart.fill"
        }
    }
    
    /// Get color for metric type
    private func metricColor(for type: HealthMetricType) -> Color {
        switch type {
        case .restingHeartRate: return .ampedRed
        case .steps: return .blue
        case .activeEnergyBurned: return .orange
        case .sleepHours: return .ampedYellow
        case .vo2Max: return .blue
        default: return .ampedRed
        }
    }
    
    func metricUnit(for type: HealthMetricType) -> String {
        // These map to your existing asset names used by MetricCard (e.g., "heartRateIcon", "stepsIcon", etc.)
        switch type {
        case .restingHeartRate: return "BPM"
        case .steps: return "Steps"
        case .activeEnergyBurned: return "Kcal"
        case .sleepHours: return ""
        case .vo2Max: return ""
        case .bodyMass: return "KG"
        default: return ""
        }
    }
}
