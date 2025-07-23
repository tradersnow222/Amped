import SwiftUI
import CoreHaptics

/// Main dashboard view displaying life projection battery
struct DashboardView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var settingsManager: SettingsManager
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @State private var selectedMetric: HealthMetric? = nil
    @State private var selectedMetricType: HealthMetricType? = nil // Track metric type instead of metric instance
    @State private var showingProjectionHelp = false
    @EnvironmentObject var appState: AppState
    
    // Rules: Add state for showing update health profile
    @State private var showingUpdateHealthProfile = false
    
    // Rules: Add state for sign-in popup
    @State private var showSignInPopup = false
    
    // Pull-to-refresh state - Enhanced for Apple iOS UX standards
    @State private var pullDistance: CGFloat = 0
    @State private var isRefreshing = false
    private let refreshThreshold: CGFloat = 60 // Apple's actual threshold is 60pt
    private let maxPullDistance: CGFloat = 120 // Apple's actual maximum is 120pt
    @State private var refreshIndicatorOpacity: Double = 0
    @State private var refreshIndicatorRotation: Double = 0
    
    // Battery animation state - Rules: Smart intro animations
    @State private var isBatteryAnimating = false
    @State private var showLifeEnergyBattery = false
    
    // Page control state for swipeable views (now 3 pages)
    @State private var currentPage = 0
    
    // Loading states for calculations
    @State private var isCalculatingImpact = true
    @State private var isCalculatingLifespan = true
    @State private var hasInitiallyCalculated = false
    
    // State for lifestyle tabs
    @State private var selectedLifestyleTab = 0 // 0 = Current lifestyle, 1 = Better habits
    @State private var shouldPulseTabsForNewUsers = true // Pulse animation for better discoverability

    
    // MARK: - Computed Properties
    
    /// Get user initials from stored name for profile display
    private var userInitials: String {
        // Implementation for getting user initials
        let defaultName = "User"
        return String(defaultName.prefix(1)).uppercased()
    }
    
    /// CRITICAL FIX: Always get fresh metric data for detail view
    /// This ensures the detail view shows current values instead of stale snapshots
    private var freshSelectedMetric: HealthMetric? {
        guard let metricType = selectedMetricType else { return nil }
        
        // Find the current metric from the dashboard's fresh healthMetrics array
        let freshMetric = viewModel.healthMetrics.first { $0.type == metricType }
        
        if let fresh = freshMetric {
            print("🔄 Providing fresh metric data: \(fresh.type.displayName) = \(fresh.formattedValue) (Impact: \(fresh.impactDetails?.lifespanImpactMinutes ?? 0) min)")
        }
        
        return freshMetric
    }

    /// Convert period type to proper adjective form for display
    private var periodAdjective: String {
        switch selectedPeriod {
        case .day:
            return "daily"
        case .month:
            return "monthly"
        case .year:
            return "yearly"
        }
    }
    /// Filtered metrics based on user settings
    private var filteredMetrics: [HealthMetric] {
        var metrics = viewModel.healthMetrics
        

        
        // If "Show metrics with no data" is enabled, include all HealthKit types
        if settingsManager.showUnavailableMetrics {
            // Get all currently loaded metric types (excluding manual/questionnaire)
            let loadedMetricTypes = Set(metrics.filter { $0.source != .userInput }.map { $0.type })
            
            // Add placeholder metrics for any missing HealthKit types
            for metricType in HealthMetricType.healthKitTypes {
                if !loadedMetricTypes.contains(metricType) {
                    // Create a placeholder metric with no data
                    let placeholderMetric = HealthMetric(
                        id: UUID().uuidString,
                        type: metricType,
                        value: 0,
                        date: Date(),
                        source: .healthKit,
                        impactDetails: nil // No impact data for unavailable metrics
                    )
                    metrics.append(placeholderMetric)
                }
            }
        } else {
            // Filter out unavailable metrics if showUnavailable is false
            let filtered = metrics.filter { metric in
                // A metric is considered available ONLY if it has meaningful impact (>= 1 minute)
                // This ensures consistency with the "No impact data" display logic
                let hasMeaningfulImpact = metric.impactDetails != nil && abs(metric.impactDetails!.lifespanImpactMinutes) >= 1.0
                return hasMeaningfulImpact
            }
            metrics = filtered
        }
        
        // Sort metrics by impact (highest to lowest)
        // Since we now only include metrics with meaningful impact, we can simplify the sorting
        return metrics.sorted { lhs, rhs in
            let lhsImpact = abs(lhs.impactDetails?.lifespanImpactMinutes ?? 0)
            let rhsImpact = abs(rhs.impactDetails?.lifespanImpactMinutes ?? 0)
            
            // Sort by absolute impact value, highest first
            return lhsImpact > rhsImpact
        }
    }
    /// Calculate total time impact from all filtered metrics
    private var totalTimeImpact: Double {
        let totalImpact = filteredMetrics
            .compactMap { $0.impactDetails?.lifespanImpactMinutes }
            .reduce(0, +)
        
        // For month/year views, this is already a daily average
        // The metrics are averaged, so the impacts are also averaged
        return totalImpact
    }
    
    /// Format the total time impact for display
    private var formattedTotalImpact: String {
        let absMinutes = abs(totalTimeImpact)
        
        // Use similar formatting as HealthMetricRow but without the "gained/lost" suffix
        let minutesInHour = 60.0
        let minutesInDay = 1440.0
        let minutesInWeek = 10080.0
        let minutesInMonth = 43200.0
        let minutesInYear = 525600.0
        
        // Years
        if absMinutes >= minutesInYear {
            let years = absMinutes / minutesInYear
            if years >= 1.0 {
                let unit = years == 1.0 ? "year" : "years"
                let valueString = years.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", years) : String(format: "%.1f", years)
                return "\(valueString) \(unit)"
            } else {
                return String(format: "%.1f year", years)
            }
        }
        
        // Months
        if absMinutes >= minutesInMonth {
            let months = absMinutes / minutesInMonth
            if months >= 1.0 {
                let unit = months == 1.0 ? "month" : "months"
                let valueString = months.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", months) : String(format: "%.1f", months)
                return "\(valueString) \(unit)"
            } else {
                return String(format: "%.1f month", months)
            }
        }
        
        // Weeks
        if absMinutes >= minutesInWeek {
            let weeks = absMinutes / minutesInWeek
            if weeks >= 1.0 {
                let unit = weeks == 1.0 ? "week" : "weeks"
                let valueString = weeks.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", weeks) : String(format: "%.1f", weeks)
                return "\(valueString) \(unit)"
            } else {
                return String(format: "%.1f week", weeks)
            }
        }
        
        // Days
        if absMinutes >= minutesInDay {
            let days = absMinutes / minutesInDay
            if days >= 1.0 {
                let unit = days == 1.0 ? "day" : "days"
                let valueString = days.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", days) : String(format: "%.1f", days)
                return "\(valueString) \(unit)"
            } else {
                return String(format: "%.1f day", days)
            }
        }
        
        // Hours
        if absMinutes >= minutesInHour {
            let hours = absMinutes / minutesInHour
            if hours >= 1.0 {
                let unit = hours == 1.0 ? "hour" : "hours"
                let valueString = hours.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", hours) : String(format: "%.1f", hours)
                return "\(valueString) \(unit)"
            } else {
                return String(format: "%.1f hour", hours)
            }
        }
        
        // Minutes
        if absMinutes >= 1.0 {
            let roundedMinutes = Int(round(absMinutes))
            let unit = roundedMinutes == 1 ? "minute" : "minutes"
            return "\(roundedMinutes) \(unit)"
        }
        
        // For values less than 1 minute, show as 0 for display purposes
        // (actual calculations remain unchanged)
        return "0"
    }
    
    /// Time period context text for display
    private var timePeriodContext: String {
        switch viewModel.selectedTimePeriod {
        case .day: return "Today, your habits collectively"
        case .month: return "This month, your habits collectively"
        case .year: return "This year, your habits collectively"
        }
    }
    
    /// Get explanation text for the impact
    private var impactExplanationText: String {
        let timeFrame: String
        switch selectedPeriod {
        case .day:
            timeFrame = "the last day"
        case .month:
            timeFrame = "the last month"
        case .year:
            timeFrame = "the last year"
        }
        
        if totalTimeImpact >= 0 {
            return "You added \(formattedTotalImpact) to your lifespan within \(timeFrame) due to your habits"
        } else {
            return "You lost \(formattedTotalImpact) from your lifespan within \(timeFrame) due to your habits"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Dashboard content layer - can be blurred
            ZStack {
                                // Main content
                VStack(spacing: 0) {
                    // Fixed header section with period selector on impact and metrics pages (pages 0 and 1)
                    if currentPage <= 1 {
                        PeriodSelectorView(
                            selectedPeriod: $selectedPeriod,
                            onPeriodChanged: { period in
                                // Update the view model's selected time period with smooth animation
                                withAnimation(.interpolatingSpring(
                                    mass: 1.8,
                                    stiffness: 80,
                                    damping: 25,
                                    initialVelocity: 0
                                )) {
                                    let timePeriod = TimePeriod(from: period)
                                    viewModel.selectedTimePeriod = timePeriod
                                }
                            }
                        )
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                    
                    // Apple-standard refresh indicator positioned below tabs/selectors
                    // Shows on pages 0 & 1 below PeriodSelector (page 2 has its own in batteryPageWithRefresh)
                    if currentPage <= 1 {
                        AppleStandardRefreshIndicator(
                            isRefreshing: isRefreshing,
                            pullDistance: pullDistance,
                            opacity: refreshIndicatorOpacity,
                            rotation: refreshIndicatorRotation,
                            threshold: refreshThreshold
                        )
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    // Swipeable content pages using custom 3-page container
                    ThreePageDashboardContainer(
                        currentPage: $currentPage,
                        impactPage: AnyView(impactPage),
                        lifespanFactorsPage: AnyView(lifespanFactorsPage), 
                        batteryPage: AnyView(batteryPageWithRefresh),
                        isRefreshing: $isRefreshing,
                        pullDistance: $pullDistance
                    )
                }
                
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
                            .frame(height: 0) // Position card in upper portion of screen
                        
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
            }
            // Apply blur to the entire dashboard content layer
            .blur(radius: showingProjectionHelp ? 6 : (showSignInPopup ? 3 : 0)) // Rules: Different blur levels for different popups
            .brightness(showingProjectionHelp ? 0.1 : 0) // Rules: Darken only for projection help
            .animation(.easeInOut(duration: 0.3), value: showSignInPopup)
            .animation(.easeInOut(duration: 0.2), value: showingProjectionHelp)
            
            // Rules: Sign-in popup overlay - completely outside of blurred content
            if showSignInPopup {
                SignInPopupView(isPresented: $showSignInPopup)
                    .environmentObject(appState)
                    .environmentObject(BatteryThemeManager())
                    .transition(.opacity)
                    .zIndex(10) // Ensure it's on top
            }
        }
        .withDeepBackground()

        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: 
                    SettingsView()
                        .environmentObject(settingsManager)
                ) {
                    // Profile icon - show initials if available, otherwise default icon
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .opacity(0.8)
                            .frame(width: 44, height: 44)
                        
                        Circle()
                            .stroke(.tertiary, lineWidth: 0.5)
                            .frame(width: 44, height: 44)
                        
                        if !userInitials.isEmpty {
                            // Show user initials
                            Text(userInitials)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        } else {
                            // Show default "M" for Matt
                            Text("M")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    .contentShape(Circle())
                }
                .accessibilityLabel("Account & Settings")
                .accessibilityHint("Double tap to open your account and settings")
            }
        }
        .sheet(item: Binding<HealthMetric?>(
            get: { self.freshSelectedMetric },
            set: { newValue in 
                // When sheet is dismissed, clear both the metric and metric type
                if newValue == nil {
                    self.selectedMetric = nil
                    self.selectedMetricType = nil
                    
                    // CRITICAL FIX: Force immediate refresh when returning from detail view
                    // This ensures users see updated recommendations after viewing metrics
                    Task {
                        await viewModel.refreshData()
                    }
                }
            }
        )) { metric in
            MetricDetailView(metric: metric)
        }
        .sheet(isPresented: $showingUpdateHealthProfile) {
            UpdateHealthProfileView()
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
            
            viewModel.loadData()
            HapticManager.shared.prepareHaptics()
            
            // Rules: Smart intro animations - only when appropriate
            handleIntroAnimations()
            
            // Rules: Enhanced loading experience - let the loading components control their own timing
            // The EnhancedLoadingView components will handle their own timing and completion
            
            // Rules: Check if we should show sign-in popup on second app launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                checkAndShowSignInIfNeeded()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingProjectionHelp)
        .animation(.easeInOut(duration: 0.2), value: showSignInPopup) // Rules: Animate sign-in popup
    }
    
    // MARK: - Battery Page with Refresh Indicator
    
    /// Page 3: Battery page - with positioned refresh indicator below lifestyle tabs
    private var batteryPageWithRefresh: some View {
        VStack(spacing: 0) {
            // Minimalist lifestyle tabs - centered and compact (OUTSIDE ScrollView)
            lifestyleTabs
                .padding(.top, 8)
                .padding(.bottom, 24)
            
            // Apple-standard refresh indicator positioned below lifestyle tabs
            if currentPage == 2 {
                AppleStandardRefreshIndicator(
                    isRefreshing: isRefreshing,
                    pullDistance: pullDistance,
                    opacity: refreshIndicatorOpacity,
                    rotation: refreshIndicatorRotation,
                    threshold: refreshThreshold
                )
                .transition(.opacity.combined(with: .scale))
            }
            
            // ScrollView with battery content only
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Main battery content (without the tabs since they're above)
                        batteryPageContent
                        
                        // Add padding at bottom to ensure consistent scrolling behavior
                        Spacer()
                            .frame(height: max(40, geometry.safeAreaInsets.bottom + 20))
                    }
                }
                .refreshable {
                    // Trigger refresh - indicator is handled by parent view
                    isRefreshing = true
                    refreshIndicatorOpacity = 1.0
                    
                    await viewModel.refreshData()
                    HapticManager.shared.playNotification(.success)
                    
                    // Reset state
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isRefreshing = false
                        pullDistance = 0
                        refreshIndicatorOpacity = 0
                        refreshIndicatorRotation = 0
                    }
                }
            }
        }
    }
    
    // MARK: - Dashboard Page Views
    
    /// Page 1: Impact number and Today's Focus
    private var impactPage: some View {
        ImpactPageView(
            selectedPeriod: $selectedPeriod,
            isCalculatingImpact: $isCalculatingImpact,
            hasInitiallyCalculated: $hasInitiallyCalculated,
            showLifeEnergyBattery: $showLifeEnergyBattery,
            isBatteryAnimating: $isBatteryAnimating,
            isRefreshing: $isRefreshing,
            pullDistance: $pullDistance,
            refreshIndicatorOpacity: $refreshIndicatorOpacity,
            refreshIndicatorRotation: $refreshIndicatorRotation,
            showingUpdateHealthProfile: $showingUpdateHealthProfile,
            selectedMetric: $selectedMetric,
            selectedMetricType: $selectedMetricType, // CRITICAL FIX: Add metric type binding
            totalTimeImpact: totalTimeImpact,
            timePeriodContext: timePeriodContext,
            formattedTotalImpact: formattedTotalImpact,
            filteredMetrics: filteredMetrics,
            viewModel: viewModel
        )
    }
    
    /// Page 2: Today's/This Month's/This Year's Impact
    private var lifespanFactorsPage: some View {
        LifespanFactorsPageView(
            selectedPeriod: $selectedPeriod,
            isBatteryAnimating: $isBatteryAnimating,
            isRefreshing: $isRefreshing,
            pullDistance: $pullDistance,
            refreshIndicatorOpacity: $refreshIndicatorOpacity,
            refreshIndicatorRotation: $refreshIndicatorRotation,
            showingUpdateHealthProfile: $showingUpdateHealthProfile,
            selectedMetric: $selectedMetric,
            selectedMetricType: $selectedMetricType, // CRITICAL FIX: Add metric type binding
            filteredMetrics: filteredMetrics,
            viewModel: viewModel
        )
    }


    
    /// Battery page content without tabs (for use in batteryPageWithRefresh)
    private var batteryPageContent: some View {
        BatteryPageContentView(
            isCalculatingLifespan: $isCalculatingLifespan,
            hasInitiallyCalculated: $hasInitiallyCalculated,
            showingProjectionHelp: $showingProjectionHelp,
            selectedLifestyleTab: $selectedLifestyleTab,
            viewModel: viewModel
        )
    }
    
    /// Intuitive lifestyle tabs - designed to match time selector styling
    private var lifestyleTabs: some View {
        LifestyleTabsView(
            selectedLifestyleTab: $selectedLifestyleTab,
            shouldPulseTabsForNewUsers: $shouldPulseTabsForNewUsers
        )
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
    
    // MARK: - Helper Methods
    
    /// Handle intro animations based on app state - Rules: Smart animation triggering
    private func handleIntroAnimations() {
        // Check if we should trigger intro animations
        let shouldAnimate = appState.shouldTriggerIntroAnimations || appState.isFirstDashboardViewAfterOnboarding
        
        if shouldAnimate {
            // Start intro animations with staggered timing for elegant effect
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                isBatteryAnimating = true
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(0.8)) {
                showLifeEnergyBattery = true
            }
            
            // Mark animations as shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                appState.markDashboardAnimationsShown()
            }
        } else {
            // No intro animations, just show content immediately
            isBatteryAnimating = true
            showLifeEnergyBattery = true
        }
    }
    
    /// Apply Apple's exact rubber band effect physics for pull-to-refresh
    /// Based on reverse-engineered UIScrollView behavior
    private func applyAppleRubberBandEffect(to dragDistance: CGFloat, velocity: CGFloat) -> CGFloat {
        guard dragDistance > 0 else { return 0 }
        
        // Apple's rubber band function: f(x) = (1.0 - (1.0 / ((x * c / d) + 1.0))) * d
        // Where c = rubber band coefficient (0.55 for UIScrollView)
        let coefficient: CGFloat = 0.55
        let dimension: CGFloat = refreshThreshold
        
        if dragDistance <= 10 {
            // Initial linear response for immediate feedback
            return dragDistance
        } else if dragDistance <= refreshThreshold {
            // Moderate resistance up to threshold
            let resistance = 1.0 - pow(dragDistance / refreshThreshold, 0.7)
            return dragDistance * (0.7 + resistance * 0.3)
        } else {
            // Strong rubber band resistance beyond threshold
            let beyondThreshold = dragDistance - refreshThreshold
            let rubberBandResult = (1.0 - (1.0 / ((beyondThreshold * coefficient / dimension) + 1.0))) * dimension
            return refreshThreshold + rubberBandResult * 0.8 // Scale down for more resistance
        }
    }
    
    /// Check if we should show the sign-in popup
    private func checkAndShowSignInIfNeeded() {
        // Rules: Show popup on every app launch from second session onwards until user signs in
        let appLaunchCount = UserDefaults.standard.integer(forKey: "appLaunchCount")
        
        // Show popup if:
        // 1. User is not authenticated
        // 2. This is at least the second app launch
        // 3. Haven't shown the popup in this session yet
        if !appState.isAuthenticated && appLaunchCount >= 2 && !appState.hasShownSignInPopupThisSession {
            // Mark that we've shown the popup this session
            appState.hasShownSignInPopupThisSession = true
            
            // Small delay for better UX
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSignInPopup = true
                }
            }
        }
    }
    
    // MARK: - Helper Functions
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView()
        }
    }
} 