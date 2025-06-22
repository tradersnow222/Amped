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
    
    // Rules: Add state for sign-in popup
    @State private var showSignInPopup = false
    @State private var hasShownSignInPopup = false
    
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
        GeometryReader { geometry in
            ZStack {
                // Main content area
                VStack(spacing: 0) {
                    // Fixed header section with period selector
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
                            .frame(height: 24)
                        
                        // The dashboard battery system
                        BatterySystemView(
                            lifeProjection: viewModel.lifeProjection,
                            currentUserAge: viewModel.currentUserAge,
                            onProjectionHelpTapped: { 
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showingProjectionHelp = true
                                }
                            }
                        )
                        
                        // Balanced spacing below battery
                        Spacer()
                            .frame(height: 24)
                    }
                    .padding(.horizontal)
                    
                    // Scrollable metrics section
                    ScrollView {
                        // Power Sources Metrics section
                        HealthMetricsListView(metrics: filteredMetrics) { metric in
                            selectedMetric = metric
                            HapticManager.shared.playSelection()
                        }
                        .padding(.horizontal, 8)
                        .padding(.bottom, 32)
                    }
                }
            .withDeepBackground()
            .blur(radius: showingProjectionHelp || showSignInPopup ? 6 : 0) // Rules: Blur when sign-in popup is shown
            .brightness(showingProjectionHelp || showSignInPopup ? 0.1 : 0) // Rules: Darken when sign-in popup is shown
            
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
            
            // Custom info card overlay
            if showingProjectionHelp {
                // Blurred background
                Color.black.opacity(0.3) // Reduced opacity for brighter background
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingProjectionHelp = false
                        }
                    }
                
                // Info card overlay
                VStack {
                    Spacer()
                        .frame(height: geometry.size.height * 0.2) // Position card in upper portion of screen
                    
                    projectionHelpPopover
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                        .zIndex(1)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .transition(.opacity)
            }
            
            // Rules: Sign-in popup overlay
            if showSignInPopup {
                SignInPopupView(isPresented: $showSignInPopup)
                    .environmentObject(appState)
                    .environmentObject(BatteryThemeManager())
                    .transition(.opacity)
                    .zIndex(2)
            }
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
            
            // Rules: Show sign-in popup after 2 seconds if user hasn't authenticated
            if !appState.isAuthenticated && !hasShownSignInPopup {
                hasShownSignInPopup = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showSignInPopup = true
                    }
                }
            }
        }
        .refreshable {
            viewModel.refreshData()
            HapticManager.shared.playSuccess()
        }
        .animation(.easeInOut(duration: 0.2), value: showingProjectionHelp)
        .animation(.easeInOut(duration: 0.2), value: showSignInPopup) // Rules: Animate sign-in popup
    }
    
    // MARK: - UI Components
    
    /// Help popover for projection battery
    private var projectionHelpPopover: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with battery icon and title
            HStack(spacing: 12) {
                // Battery icon to match theme
                Image(systemName: "battery.100")
                    .font(.largeTitle)
                    .foregroundColor(.ampedGreen)
                    .symbolRenderingMode(.hierarchical)
                
                Text("Life Projection")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Main description with improved readability
            VStack(alignment: .leading, spacing: 16) {
                // Key point 1 with icon
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "clock.fill")
                        .font(.body)
                        .foregroundColor(.ampedGreen)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Years Left")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Your estimated remaining lifespan")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Key point 2 with icon
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body)
                        .foregroundColor(.ampedYellow)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Updates Gradually")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Changes slowly as habits improve")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Key point 3 with icon
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.body)
                        .foregroundColor(.ampedRed)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health-Based")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Calculated from your real data")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            // Visual separator
            HStack(spacing: 8) {
                ForEach(0..<3) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Scientific backing note - simplified
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.ampedGreen.opacity(0.8))
                
                Text("Backed by research")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .fontWeight(.medium)
            }
        }
        .padding(24)
        .frame(idealWidth: 320, maxWidth: 340)
        .glassBackground(.thick, cornerRadius: 16, withBorder: true, withShadow: true) // Changed to thick for better readability
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
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