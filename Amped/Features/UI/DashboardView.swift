import SwiftUI
import CoreHaptics

/// Main dashboard view displaying life projection battery
struct DashboardView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @State private var selectedMetric: HealthMetric? = nil
    @State private var showingProjectionHelp = false
    @EnvironmentObject var appState: AppState
    
    // MARK: - Computed Properties
    
    /// Filtered metrics based on user settings
    private var filteredMetrics: [HealthMetric] {
        let allMetrics = viewModel.healthMetrics
        print("🔍 DashboardView: Total metrics available: \(allMetrics.count)")
        for metric in allMetrics {
            print("  - \(metric.type.displayName): value=\(metric.value), source=\(metric.source), hasImpact=\(metric.impactDetails != nil)")
        }
        
        if settingsManager.showUnavailableMetrics {
            // CRITICAL FIX: Filter out manual metrics even when showing unavailable metrics
            let filtered = viewModel.healthMetrics.filter { metric in
                // Exclude manual metrics (questionnaire data) from display
                metric.source != .userInput
            }
            print("🔍 DashboardView: After filtering (showUnavailable=true): \(filtered.count) metrics")
            return filtered
        } else {
            // CRITICAL FIX: Show metrics that have meaningful data
            // This includes both metrics with non-zero values AND metrics with impact details
            let filtered = viewModel.healthMetrics.filter { metric in
                // Exclude manual metrics (questionnaire data) from display
                // AND show metric if it has a meaningful value OR has impact details calculated
                metric.source != .userInput && (
                metric.value > 0 || 
                metric.impactDetails != nil
                )
            }
            print("🔍 DashboardView: After filtering (showUnavailable=false): \(filtered.count) metrics")
            return filtered
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Main content area
            ScrollView {
                VStack(spacing: 0) {
                    // Custom period selector
                    PeriodSelectorView(
                        selectedPeriod: $selectedPeriod,
                        onPeriodChanged: { period in
                            // Update the view model's selected time period
                            let timePeriod = TimePeriod(from: period)
                            viewModel.selectedTimePeriod = timePeriod
                        }
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    
                    // Balanced spacing above battery
                    Spacer()
                        .frame(height: 40)
                    
                    // The dashboard battery system
                    BatterySystemView(
                        lifeProjection: viewModel.lifeProjection,
                        currentUserAge: viewModel.currentUserAge,
                        onProjectionHelpTapped: { showingProjectionHelp = true }
                    )
                    
                    // Balanced spacing below battery
                    Spacer()
                        .frame(height: 40)
                    
                    // Power Sources Metrics section
                    HealthMetricsListView(metrics: filteredMetrics) { metric in
                        selectedMetric = metric
                        HapticManager.shared.playSelection()
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal)
            }
            .withDeepBackground()
            
            // Error overlay if needed
            if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("Unable to load data")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)
                    
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Button("Retry") {
                        viewModel.loadData()
                    }
                    .padding()
                    .background(Color.ampedGreen)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .padding(.top, 8)
                }
                .padding(24)
                .background(Color.black.opacity(0.8))
                .cornerRadius(16)
                .shadow(radius: 10)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: 
                    SettingsView()
                        .environmentObject(settingsManager)
                        .onAppear {
                            print("🐛 SETTINGS: SettingsView successfully appeared!")
                        }
                ) {
                    // Modern profile circle icon instead of gear - following user requirement for modern, sleek, unobtrusive design
                    Image(systemName: "person.crop.circle")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .opacity(0.8)
                        )
                        .overlay(
                            Circle()
                                .stroke(.tertiary, lineWidth: 0.5)
                        )
                        .contentShape(Circle())
                }
                .onAppear {
                    print("🐛 SETTINGS: NavigationLink appeared in toolbar")
                }
                .accessibilityLabel("Account & Settings")
                .accessibilityHint("Double tap to open your account and settings")
            }
        }
        .sheet(item: $selectedMetric) { metric in
            MetricDetailsView(
                metric: metric,
                onClose: {
                    selectedMetric = nil
                }
            )
        }
        .onAppear {
            // Configure navigation bar appearance to match dark theme
            let scrolledAppearance = UINavigationBarAppearance()
            scrolledAppearance.configureWithDefaultBackground()
            scrolledAppearance.backgroundColor = UIColor.black.withAlphaComponent(0.8)
            scrolledAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            scrolledAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            let transparentAppearance = UINavigationBarAppearance()
            transparentAppearance.configureWithTransparentBackground()
            transparentAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            transparentAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            UINavigationBar.appearance().standardAppearance = scrolledAppearance
            UINavigationBar.appearance().scrollEdgeAppearance = transparentAppearance
            UINavigationBar.appearance().compactAppearance = scrolledAppearance
            
            print("🔧 DashboardView appeared")
            viewModel.loadData()
            HapticManager.shared.prepareHaptics()
            
            // Debug navigation context
            print("🔧 DashboardView navigation context check")
        }
        .refreshable {
            viewModel.refreshData()
            HapticManager.shared.playSuccess()
        }
        // Help popovers
        .popover(isPresented: $showingProjectionHelp) {
            projectionHelpPopover
        }
    }
    
    // MARK: - UI Components
    
    /// Help popover for projection battery
    private var projectionHelpPopover: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with battery icon and title
            HStack(spacing: 12) {
                // Battery icon to match theme
                Image(systemName: "battery.100")
                    .font(.title2)
                    .foregroundColor(.ampedGreen)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Life Projection")
                        .style(.cardTitle, color: .white)
                    
                    Text("Battery Indicator")
                        .style(.caption, color: .secondary)
                }
                
                Spacer()
            }
            
            // Main description
            VStack(alignment: .leading, spacing: 12) {
                Text("Shows your approximate (~) remaining lifespan based on your health data and habits.")
                    .style(.body, color: .white)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("This battery updates gradually as your health habits create lasting impact.")
                    .style(.body, color: .white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
                .padding(.vertical, 4)
            
            // Footer with research note
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.caption)
                    .foregroundColor(.ampedYellow)
                
                Text("Based on scientific research and health metrics.")
                    .style(.caption, color: .secondary)
                    .italic()
            }
        }
        .padding(20)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [.ampedGreen.opacity(0.6), .ampedYellow.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .ampedGreen.opacity(0.1), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
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