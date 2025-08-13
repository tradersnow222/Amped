import SwiftUI
import HealthKit
import OSLog
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
    
    // Rules: Add state for showing update health profile
    @State private var showingUpdateHealthProfile = false
    
    // Rules: Add state for sign-in popup
    @State private var showSignInPopup = false
    
    // Settings presentation
    @State private var showingSettings = false
    
    // Pull-to-refresh state - Enhanced for Apple iOS UX standards
    @State private var pullDistance: CGFloat = 0
    @State private var isRefreshing = false
    private let refreshThreshold: CGFloat = 60 // Apple's actual threshold is 60pt
    private let maxPullDistance: CGFloat = 120 // Apple's actual maximum is 120pt
    
    // CONSISTENCY FIX: Add logger for validation and debugging
    private let logger = Logger(subsystem: "com.amped.app", category: "DashboardView")
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
                // CRITICAL FIX: Distinguish between "no data" and "no material change"
                // Always show metrics that have impact details (even if impact is < 1 minute)
                // Only hide metrics that truly have no data (impactDetails is nil)
                return metric.impactDetails != nil
            }
            metrics = filtered
        }
        
        // Sort metrics by impact (highest to lowest)
        // Since we now include all metrics with impact details (even minimal impact), sort by absolute impact
        return metrics.sorted { lhs, rhs in
            let lhsImpact = abs(lhs.impactDetails?.lifespanImpactMinutes ?? 0)
            let rhsImpact = abs(rhs.impactDetails?.lifespanImpactMinutes ?? 0)
            
            // Sort by absolute impact value, highest first
            return lhsImpact > rhsImpact
        }
    }
    /// Calculate total time impact using sophisticated LifeImpactService calculation
    /// Rules: Use consistent calculation methods across all views
    private var totalTimeImpact: Double {
        // CONSISTENCY FIX: Use the same sophisticated calculation as the chart
        // This includes interaction effects, mortality adjustments, and evidence weighting
        guard let lifeImpact = viewModel.lifeImpactData else {
            logger.warning("⚠️ No lifeImpactData available for headline calculation")
            return 0.0
        }
        
        // DATA VALIDATION: Ensure we're working with the same metrics as the chart
        let metricsWithImpact = filteredMetrics.filter { $0.impactDetails != nil }
        let metricsInLifeImpact = lifeImpact.metricContributions.count
        
        if metricsWithImpact.count != metricsInLifeImpact {
            logger.warning("⚠️ Metric count mismatch - Filtered: \(metricsWithImpact.count), LifeImpact: \(metricsInLifeImpact)")
        }
        
        // Apply the correct sign based on direction
        let signedImpact = lifeImpact.totalImpact.value * (lifeImpact.totalImpact.direction == .positive ? 1.0 : -1.0)
        
        // ENHANCED DEBUGGING: Log comprehensive calculation details
        logger.info("📊 Headline impact calculation:")
        logger.info("  📅 Period: \(viewModel.selectedTimePeriod.displayName)")
        logger.info("  🔢 Impact value: \(String(format: "%.2f", signedImpact)) minutes")
        logger.info("  ↗️ Direction: \(lifeImpact.totalImpact.direction == .positive ? "positive" : "negative")")
        logger.info("  📈 Raw value: \(String(format: "%.2f", lifeImpact.totalImpact.value))")
        logger.info("  🧮 Metrics count: \(metricsInLifeImpact)")
        
        return signedImpact
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
                    // Personalized greeting header - Rules: Strategic personalization for maximum impact
                    personalizedHeader
                    
                    // Top-level selectors positioned at the top of the screen
                    topLevelSelectors
                    
                    // Apple-standard refresh indicator positioned below tabs/selectors  
                    // Always present to avoid layout shifts during transitions
                    AppleStandardRefreshIndicator(
                        isRefreshing: isRefreshing,
                        pullDistance: pullDistance,
                        opacity: currentPage <= 1 ? refreshIndicatorOpacity : 0,
                        rotation: refreshIndicatorRotation,
                        threshold: refreshThreshold
                    )
                    .animation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 25, initialVelocity: 0), value: currentPage)
                    
                    // Swipeable content pages with consistent 3D Y-axis rotation
                    Enhanced3DPageContainer(
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
                Button {
                    showingSettings = true
                } label: {
                    ProfileImageView(size: 44, showBorder: true)
                }
                .accessibilityLabel("Account & Settings")
                .accessibilityHint("Double tap to open your account and settings")
            }
        }
        .sheet(item: $selectedMetric) { metric in
            MetricDetailView(metric: metric, initialPeriod: selectedPeriod)
        }
        .sheet(isPresented: $showingUpdateHealthProfile) {
            UpdateHealthProfileView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settingsManager)
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
    
    /// Page 3: Battery page - content only (lifestyle tabs now at top level)
    private var batteryPageWithRefresh: some View {
        VStack(spacing: 0) {
            // ScrollView with battery content only (for 3D rotation)
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // Main battery content (lifestyle tabs now at top level)
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
                    withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 25, initialVelocity: 0)) {
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
            currentPage: $currentPage,
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
    
    /// Top-level selectors that appear at the top of the screen based on current page
    private var topLevelSelectors: some View {
        VStack(spacing: 0) {
            // Show appropriate selector based on current page
            Group {
                if currentPage == 0 { // Impact page
                    PeriodSelectorView(
                        selectedPeriod: $selectedPeriod,
                        onPeriodChanged: { period in
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
                } else if currentPage == 1 { // Lifespan factors page
                    PeriodSelectorView(
                        selectedPeriod: $selectedPeriod,
                        onPeriodChanged: { period in
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
                } else if currentPage == 2 { // Battery page
                    lifestyleTabs
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .frame(height: 56) // Consistent height for all selectors (slightly increased for breathing room)
    }
    
    /// Personalized header with greeting - Rules: Strategic personalization for maximum impact
    private var personalizedHeader: some View {
        HStack {
            // Personalized greeting using PersonalizationUtils - positioned top left
            Text(PersonalizationUtils.contextualMessage(
                firstName: PersonalizationUtils.userFirstName(from: viewModel.userProfile),
                context: .dashboardGreeting
            ))
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 4) // Minimal top padding to position as high as possible
        .padding(.bottom, 8)
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
        // Rules: Show popup only after completing onboarding and on second app launch onwards
        
        // Show popup if:
        // 1. User has completed onboarding
        // 2. User is not authenticated
        // 3. This is at least the second app launch
        // 4. Haven't shown the popup in this session yet
        if appState.hasCompletedOnboarding && 
           !appState.isAuthenticated && 
           appState.appLaunchCount >= 2 && 
           !appState.hasShownSignInPopupThisSession {
            
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