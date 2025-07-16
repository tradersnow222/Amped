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
    
    // Rules: Add state for showing update health profile
    @State private var showingUpdateHealthProfile = false
    
    // Rules: Add state for sign-in popup
    @State private var showSignInPopup = false
    
    // Pull-to-refresh state
    @State private var pullDistance: CGFloat = 0
    @State private var isRefreshing = false
    private let refreshThreshold: CGFloat = 80
    private let maxPullDistance: CGFloat = 150 // iOS standard maximum pull distance
    
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
    private var userInitials: String? {
        guard let userName = UserDefaults.standard.string(forKey: "userName"),
              !userName.isEmpty else { return nil }
        
        let components = userName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map(String.init)
        
        if initials.count >= 2 {
            return "\(initials[0])\(initials[1])"
        } else if let firstInitial = initials.first {
            return firstInitial
        }
        
        return nil
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
                // A metric is considered available if it has either:
                // 1. A non-zero value, OR
                // 2. Valid impact details (even if value is 0)
                let isAvailable = metric.value != 0 || metric.impactDetails != nil
                return isAvailable
            }
            metrics = filtered
        }
        
        // Sort metrics by impact (highest to lowest), with unavailable metrics at the end
        return metrics.sorted { lhs, rhs in
            // First priority: Check if either metric has no impact data at all
            let lhsHasImpact = lhs.impactDetails != nil
            let rhsHasImpact = rhs.impactDetails != nil
            
            // If one has impact data and the other doesn't, the one with impact comes first
            if lhsHasImpact != rhsHasImpact {
                return lhsHasImpact // Metrics with any impact data come first
            }
            
            // If both have no impact data, maintain their relative order
            if !lhsHasImpact && !rhsHasImpact {
                return false // Keep original order for metrics without impact
            }
            
            // Both have impact data - sort by absolute impact value, highest first
            let lhsImpact = abs(lhs.impactDetails?.lifespanImpactMinutes ?? 0)
            let rhsImpact = abs(rhs.impactDetails?.lifespanImpactMinutes ?? 0)
            
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
        
        // For very small values, show seconds
        let absSeconds = absMinutes * 60.0
        if absSeconds < 0.1 {
            return String(format: "%.3f sec", absSeconds)
        } else if absSeconds < 1.0 {
            return String(format: "%.2f sec", absSeconds)
        } else if absSeconds < 10.0 {
            return String(format: "%.1f sec", absSeconds)
        } else {
            return String(format: "%.0f sec", absSeconds)
        }
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
                    // Fixed header section with period selector only on page 1
                    if currentPage == 0 {
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
                    
                    // Swipeable content pages using custom 3-page container
                    ThreePageDashboardContainer(
                        currentPage: $currentPage,
                        impactPage: AnyView(impactPage),
                        lifespanFactorsPage: AnyView(lifespanFactorsPage), 
                        batteryPage: AnyView(batteryPage)
                    )
                }
                .offset(y: pullDistance)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.85), value: pullDistance)
                
                // Pull-to-refresh indicator overlay
                if pullDistance > 0 || isRefreshing {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 50, height: 50)
                            
                            if isRefreshing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .ampedGreen))
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.ampedGreen)
                                    .rotationEffect(.degrees(pullDistance > refreshThreshold ? 180 : 0))
                                    .animation(.easeInOut(duration: 0.2), value: pullDistance > refreshThreshold)
                            }
                        }
                        .offset(y: min(pullDistance - 50, 40)) // Capped at 40 for cleaner appearance
                        .opacity(min(pullDistance / refreshThreshold, 1))
                        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: pullDistance)
                        
                        Spacer()
                    }
                    .zIndex(1)
                    .allowsHitTesting(false) // Don't interfere with TabView gestures
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
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow downward pull when not already refreshing
                    if !isRefreshing {
                        // Apply iOS-standard rubber band effect
                        pullDistance = applyRubberBandEffect(to: value.translation.height)
                    }
                }
                .onEnded { value in
                    if pullDistance > refreshThreshold && !isRefreshing {
                        // Trigger refresh
                        isRefreshing = true
                        HapticManager.shared.playSelection()
                        
                        // Keep the indicator visible while refreshing
                        withAnimation(.easeOut(duration: 0.2)) {
                            pullDistance = 60
                        }
                        
                        // Perform the refresh
                        Task {
                            await viewModel.refreshData()
                            
                            // Reset states after refresh completes
                            await MainActor.run {
                                HapticManager.shared.playSuccess()
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isRefreshing = false
                                    pullDistance = 0
                                }
                            }
                        }
                    } else {
                        // Spring back if threshold not reached
                        withAnimation(.interactiveSpring(response: 0.3)) {
                            pullDistance = 0
                        }
                    }
                }
        )
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
                        
                        if let initials = userInitials {
                            // Show user initials
                            Text(initials)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        } else {
                            // Show default profile icon
                            Image(systemName: "person.crop.circle")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Circle())
                }
                .accessibilityLabel("Account & Settings")
                .accessibilityHint("Double tap to open your account and settings")
            }
        }
        .sheet(item: $selectedMetric) { metric in
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
            
            // Simulate initial calculations
            if !hasInitiallyCalculated {
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                    await MainActor.run {
                        isCalculatingImpact = false
                        isCalculatingLifespan = false
                        hasInitiallyCalculated = true
                    }
                }
            }
            
            // Rules: Check if we should show sign-in popup on second app launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                checkAndShowSignInIfNeeded()
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showingProjectionHelp)
        .animation(.easeInOut(duration: 0.2), value: showSignInPopup) // Rules: Animate sign-in popup
    }
    
    // MARK: - Swipeable Page Views
    
    /// Page 1: Impact number and Today's Focus
    private var impactPage: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Prominent Total Impact Display
                    if isCalculatingImpact && !hasInitiallyCalculated {
                        // Calculating state
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .ampedGreen))
                                .scaleEffect(1.2)
                            
                            Text("Calculating your health impact...")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cardBackground.opacity(0.3))
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    } else if totalTimeImpact != 0 {
                        VStack(spacing: 40) {
                            // Main impact display section - Rules: Better spacing
                            VStack(spacing: 12) {
                                // "Your habits collectively added/reduced" text above the number
                                Text(totalTimeImpact >= 0 ? "\(timePeriodContext) added" : "\(timePeriodContext) reduced")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                // Main impact display - PROMINENT NUMBER
                                HStack(spacing: 8) {
                                    Image(systemName: totalTimeImpact >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(totalTimeImpact >= 0 ? .ampedGreen : .ampedRed)
                                        .symbolRenderingMode(.hierarchical)
                                    
                                    Text(formattedTotalImpact)
                                        .font(.system(size: 40, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                // "to/from your lifespan" text below
                                Text(totalTimeImpact >= 0 ? "to your lifespan 🔥" : "from your lifespan")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            // Jobs-inspired animated battery element - Rules: Cool battery animation
                            if showLifeEnergyBattery {
                                LifeEnergyFlowBattery(
                                    isAnimating: isBatteryAnimating,
                                    timeImpactMinutes: totalTimeImpact
                                )
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.8).combined(with: .opacity),
                                    removal: .scale(scale: 0.8).combined(with: .opacity)
                                ))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.top, 40)
                        .padding(.bottom, 40) // Rules: Increased spacing around battery
                    } else {
                        // No impact yet
                        VStack(spacing: 16) { // Rules: Better spacing
                            Text("NO HEALTH DATA YET")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(0.5)
                            
                            Text("Complete your health profile to see your impact")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20) // Rules: Better text width control
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32) // Rules: Reduced vertical padding
                        .padding(.top, 20)
                    }
                    
                    // New Actionable Recommendations Section - Rules: Better spacing
                    if !filteredMetrics.isEmpty && !isCalculatingImpact {
                        ActionableRecommendationsView(metrics: filteredMetrics, selectedPeriod: selectedPeriod)
                            .padding(.horizontal, 16)
                            .padding(.top, 8) // Rules: Reduced top padding for better flow
                            .padding(.bottom, 20) // Rules: Consistent bottom spacing
                    }
                    
                    // Add consistent padding for page indicators - Rules: Better spacing
                    Spacer()
                        .frame(height: max(40, geometry.safeAreaInsets.bottom + 20))
                }
            }
            .refreshable {
                await refreshHealthData()
            }
        }
    }
    
    /// Page 2: Today's Lifespan Factors
    private var lifespanFactorsPage: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Health factors header
                    HStack(alignment: .center, spacing: 8) {
                        // Battery icon with animation
                        ZStack {
                            Image(systemName: "battery.100")
                                .font(.title2)
                                .foregroundColor(.fullPower)
                                .scaleEffect(isBatteryAnimating ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isBatteryAnimating)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(titleForPeriod(selectedPeriod))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12) // Rules: Better spacing consistency
                    .accessibilityAddTraits(.isHeader)
                    
                    // Power Sources Metrics section
                    HealthMetricsListView(
                        metrics: filteredMetrics,
                        selectedPeriod: selectedPeriod,
                        onMetricTap: { metric in
                            // Rules: Different handling for manual vs HealthKit metrics
                            if metric.source == .userInput {
                                // For manual metrics, show update health profile
                                showingUpdateHealthProfile = true
                            } else {
                                // For HealthKit metrics, show detail view
                                selectedMetric = metric
                            }
                            HapticManager.shared.playSelection()
                        }
                    )
                    .padding(.horizontal, 8)
                    // Add consistent padding for page indicators - Rules: Better spacing
                    .padding(.bottom, max(40, geometry.safeAreaInsets.bottom + 20))
                }
            }
            .refreshable {
                await refreshHealthData()
            }
        }
    }

    /// Page 3: Lifespan remaining battery - Jobs-inspired focus
    private var batteryPage: some View {
        VStack(spacing: 0) {
            // Minimalist lifestyle tabs - centered and compact
            lifestyleTabs
                .padding(.top, 8)
                .padding(.bottom, 24)
            
            if isCalculatingLifespan && !hasInitiallyCalculated {
                // Calculating state - centered
                Spacer()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("Calculating your lifespan...")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
            } else {
                // Main content - focused on the key message
                EnhancedBatterySystemView(
                    lifeProjection: viewModel.lifeProjection,
                    currentUserAge: viewModel.currentUserAge,
                    selectedTab: selectedLifestyleTab,
                    onProjectionHelpTapped: { 
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showingProjectionHelp = true
                        }
                    }
                )
                
                Spacer()
            }
        }
        .refreshable {
            await refreshLifespanData()
        }
    }
    
    /// Intuitive lifestyle tabs - designed to match time selector styling
    private var lifestyleTabs: some View {
        HStack(spacing: 0) {
            // Current lifespan tab
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedLifestyleTab = 0
                }
                HapticManager.shared.playSelection()
            } label: {
                Text("Current Lifespan")
                    .fontWeight(selectedLifestyleTab == 0 ? .bold : .medium)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if selectedLifestyleTab == 0 {
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
                    .foregroundColor(selectedLifestyleTab == 0 ? Color.ampedGreen : .gray)
            }
            
            // Potential lifespan tab
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedLifestyleTab = 1
                }
                HapticManager.shared.playSelection()
            } label: {
                Text("Potential Lifespan")
                    .fontWeight(selectedLifestyleTab == 1 ? .bold : .medium)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if selectedLifestyleTab == 1 {
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
                    .foregroundColor(selectedLifestyleTab == 1 ? Color.ampedGreen : .gray)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .padding(.horizontal, 16)
        // Keep the pulsing animation for new user discoverability
        .scaleEffect(shouldPulseTabsForNewUsers ? 1.02 : 1.0)
        .animation(
            shouldPulseTabsForNewUsers ? 
                .easeInOut(duration: 1.5).repeatCount(3, autoreverses: true) : 
                .none,
            value: shouldPulseTabsForNewUsers
        )
        .onAppear {
            // Start pulsing animation for new users
            if shouldPulseTabsForNewUsers {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.5).repeatCount(3, autoreverses: true)) {
                        shouldPulseTabsForNewUsers = false
                    }
                    
                    // Stop the pulsing after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        shouldPulseTabsForNewUsers = false
                    }
                }
            }
        }
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
    
    /// Apply iOS-standard rubber band effect to pull distance
    /// Following iOS Human Interface Guidelines for pull-to-refresh
    private func applyRubberBandEffect(to dragDistance: CGFloat) -> CGFloat {
        // Don't apply effect for upward drags
        guard dragDistance > 0 else { return 0 }
        
        // For distances up to the threshold, use 1:1 mapping
        if dragDistance <= refreshThreshold {
            return dragDistance
        }
        
        // Beyond threshold, apply progressive dampening
        let beyondThreshold = dragDistance - refreshThreshold
        let dampingFactor: CGFloat
        
        // Progressive dampening based on how far beyond threshold
        if beyondThreshold <= refreshThreshold {
            // First phase: gentle dampening (0.5 to 0.3)
            let progress = beyondThreshold / refreshThreshold
            dampingFactor = 0.5 - (0.2 * progress)
        } else {
            // Second phase: strong dampening (0.3 to 0.1)
            let progress = min((beyondThreshold - refreshThreshold) / refreshThreshold, 1.0)
            dampingFactor = 0.3 - (0.2 * progress)
        }
        
        // Apply dampening and cap at maximum
        let dampenedDistance = refreshThreshold + (beyondThreshold * dampingFactor)
        return min(dampenedDistance, maxPullDistance)
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
    
    /// Refresh health data and total impact
    private func refreshHealthData() async {
        isCalculatingImpact = true
        
        // Simulate calculation time
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        await viewModel.refreshData()
        
        await MainActor.run {
            isCalculatingImpact = false
            hasInitiallyCalculated = true
        }
    }
    
    /// Refresh lifespan projection data
    private func refreshLifespanData() async {
        isCalculatingLifespan = true
        
        // Simulate calculation time
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        await viewModel.refreshData()
        
        await MainActor.run {
            isCalculatingLifespan = false
            hasInitiallyCalculated = true
        }
    }
    
    // MARK: - Helper Functions
    
    private func titleForPeriod(_ period: ImpactDataPoint.PeriodType) -> String {
        switch period {
        case .day:
            return "Today's Lifespan Factors"
        case .month:
            return "This Month's Lifespan Factors"
        case .year:
            return "This Year's Lifespan Factors"
        }
    }
}

// MARK: - Three Page Dashboard Container

/// Special container for the dashboard's 3-page infinite scrolling
public struct ThreePageDashboardContainer: View {
    @Binding var currentPage: Int
    let impactPage: AnyView
    let lifespanFactorsPage: AnyView 
    let batteryPage: AnyView
    
    /// Internal selection for virtual pages
    @State private var selection: Int = 1500 // Start higher for 3 pages
    
    /// Track if we're currently animating to prevent rapid changes
    @State private var isAnimating = false
    
    public var body: some View {
        VStack(spacing: 0) {
            // TabView with many virtual pages
            TabView(selection: $selection) {
                ForEach(0..<3000, id: \.self) { index in
                    Group {
                        let pageIndex = index % 3
                        if pageIndex == 0 {
                            impactPage
                        } else if pageIndex == 1 {
                            lifespanFactorsPage
                        } else {
                            batteryPage
                        }
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            // Add custom transition animation for much smoother, slower feel
            .animation(.interpolatingSpring(
                mass: 2.5,        // Much heavier mass for slower, more deliberate movement
                stiffness: 50,    // Much lower stiffness for very gentle acceleration
                damping: 25,      // Higher damping for smooth deceleration
                initialVelocity: 0
            ), value: selection)
            .onChange(of: selection) { newSelection in
                // CRITICAL FIX: Always update currentPage for user swipes to prevent period selector persistence bug
                let newPage = newSelection % 3
                if currentPage != newPage {
                    currentPage = newPage
                }
                
                // Only use isAnimating to prevent rapid programmatic changes, not user swipes
                if !isAnimating {
                    isAnimating = true
                    
                    // Add haptic feedback with longer delay for more natural feel
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.prepare()
                        impactFeedback.impactOccurred(intensity: 0.5) // Even gentler feedback
                    }
                    
                    // Reset animation flag after animation completes (longer duration)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        isAnimating = false
                    }
                }
            }
            .onChange(of: currentPage) { newPage in
                if selection % 3 != newPage && !isAnimating {
                    // Use even smoother animation when programmatically changing pages
                    withAnimation(.interpolatingSpring(
                        mass: 2.0,
                        stiffness: 60,
                        damping: 22,
                        initialVelocity: 0
                    )) {
                        selection = 1500 + newPage
                    }
                }
            }
            .onAppear {
                selection = 1500 + currentPage
            }
            
            // Custom page indicators for 3 pages
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { index in
                    let isActive = index == currentPage
                    
                    Circle()
                        .fill(
                            isActive ? 
                                Color.ampedGreen :
                                Color.white.opacity(0.4)
                        )
                        .frame(
                            width: isActive ? 12 : 10,
                            height: isActive ? 12 : 10
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    isActive ? Color.ampedGreen.opacity(0.6) : Color.clear,
                                    lineWidth: isActive ? 1.5 : 0
                                )
                                .blur(radius: isActive ? 0.5 : 0)
                        )
                        .shadow(
                            color: isActive ? Color.ampedGreen.opacity(0.3) : Color.black.opacity(0.1),
                            radius: isActive ? 3 : 1,
                            x: 0,
                            y: 1
                        )
                        // Even smoother animation for dots
                        .animation(.interpolatingSpring(
                            mass: 1.5,
                            stiffness: 200,
                            damping: 30,
                            initialVelocity: 0
                        ), value: currentPage)
                        .scaleEffect(isActive ? 1.0 : 0.9)
                        .animation(.easeInOut(duration: 0.35), value: currentPage) // Longer duration
                        .onTapGesture {
                            if !isAnimating {
                                withAnimation(.interpolatingSpring(
                                    mass: 2.0,
                                    stiffness: 60,
                                    damping: 22,
                                    initialVelocity: 0
                                )) {
                                    currentPage = index
                                }
                                
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.prepare()
                                impactFeedback.impactOccurred(intensity: 0.6)
                            }
                        }
                        .contentShape(Circle().inset(by: -8))
                }
            }
            .padding(.vertical, 16) // Rules: Reduced padding for better spacing
            .padding(.horizontal, 16)
            .padding(.bottom, 8) // Rules: Minimal bottom padding
        }
    }
}

/// Actionable Recommendations View - Redesigned for Apple-level sophistication
struct ActionableRecommendationsView: View {
    let metrics: [HealthMetric]
    let selectedPeriod: ImpactDataPoint.PeriodType
    @State private var showContent = false
    
    // Get the most impactful metric to recommend improvement for
    private var primaryRecommendationMetric: HealthMetric? {
        // First, prioritize HealthKit metrics with significant negative impact (> 30 minutes lost)
        let significantNegativeHealthKitMetrics = metrics
            .filter { $0.source != .userInput && ($0.impactDetails?.lifespanImpactMinutes ?? 0) < -30 }
            .sorted { abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0) }
        
        if let worstHealthKitMetric = significantNegativeHealthKitMetrics.first {
            return worstHealthKitMetric
        }
        
        // If no significant negative HealthKit metrics, look for any negative HealthKit metrics
        let negativeHealthKitMetrics = metrics
            .filter { $0.source != .userInput && ($0.impactDetails?.lifespanImpactMinutes ?? 0) < 0 }
            .sorted { abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0) }
        
        if let negativeHealthKitMetric = negativeHealthKitMetrics.first {
            return negativeHealthKitMetric
        }
        
        // Fall back to questionnaire metrics that could be improved (rating < 8)
        let improvableQuestionnaireMetrics = metrics
            .filter { $0.source == .userInput && $0.value < 8 }
            .sorted { $0.value < $1.value } // Lowest rating first
        
        return improvableQuestionnaireMetrics.first
    }
    
    // Get dynamic recommendation title based on selected period
    private var recommendationTitle: String {
        switch selectedPeriod {
        case .day:
            return "Today's Focus"
        case .month:
            return "This Month's Focus"
        case .year:
            return "This Year's Focus"
        }
    }
    
    var body: some View {
        if let metric = primaryRecommendationMetric {
            VStack(spacing: 0) {
                // Prominent header
                HStack {
                    Text(recommendationTitle)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.2)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                // Main content - clean and focused
                VStack(spacing: 16) {
                    // Metric focus with clean icon treatment
                    HStack(spacing: 16) {
                        // Clean, minimal icon design
                        Image(systemName: metric.type.symbolName)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.ampedGreen)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(.ampedGreen.opacity(0.15))
                            )
                        
                        HStack(spacing: 8) {
                            Text(metric.type.displayName)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(getImpactSummary(for: metric))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(getImpactColor(for: metric))
                            
                            Spacer()
                        }
                        
                        Spacer()
                    }
                    
                    // Clean divider
                    Divider()
                        .background(.white.opacity(0.1))
                        .padding(.horizontal, -4)
                    
                    // Action recommendation - clean and compelling
                    HStack(spacing: 8) {
                        Text(getActionTitle(for: metric))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(getTimeGain(for: metric))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.ampedGreen)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 10)
            }
            .background(
                // Clean glass background matching the app's design
                RoundedRectangle(cornerRadius: 16)
                    .fill(.black.opacity(0.4))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.1),
                                        .clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                    showContent = true
                }
            }
        }
    }
    
    // Get color for impact summary based on positive/negative impact
    private func getImpactColor(for metric: HealthMetric) -> Color {
        if let impact = metric.impactDetails?.lifespanImpactMinutes {
            return impact < 0 ? .ampedRed : .ampedGreen
        } else {
            // For questionnaire metrics, show red if rating is poor (≤5)
            let rating = Int(metric.value)
            return rating <= 5 ? .ampedRed.opacity(0.8) : .white.opacity(0.6)
        }
    }
    
    // Clean, concise impact summary
    private func getImpactSummary(for metric: HealthMetric) -> String {
        if let impact = metric.impactDetails?.lifespanImpactMinutes {
            let absMinutes = abs(impact)
            let isNegative = impact < 0
            
            if absMinutes >= 1440 { // >= 1 day
                let days = Int(absMinutes / 1440)
                return isNegative ? "−\(days) day\(days == 1 ? "" : "s")" : "+\(days) day\(days == 1 ? "" : "s")"
            } else if absMinutes >= 60 { // >= 1 hour
                let hours = Int(absMinutes / 60)
                return isNegative ? "−\(hours) hour\(hours == 1 ? "" : "s")" : "+\(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                let minutes = Int(absMinutes)
                return isNegative ? "−\(minutes) min" : "+\(minutes) min"
            }
        } else {
            // For questionnaire metrics without impact data
            let rating = Int(metric.value)
            if rating <= 5 {
                return "Room for improvement"
            } else {
                return "Could be optimized"
            }
        }
    }
    
    // Get time period text for focus statement
    private func getTimePeriodText() -> String {
        switch selectedPeriod {
        case .day:
            return "today"
        case .month:
            return "this month"
        case .year:
            return "this year"
        }
    }
    
    // Clean, actionable titles
    private func getActionTitle(for metric: HealthMetric) -> String {
        switch metric.type {
        case .steps:
            return "Take a 20-minute walk"
        case .exerciseMinutes:
            return "Add 30 minutes of movement"
        case .sleepHours:
            let hours = metric.value
            return hours < 6 ? "Sleep 2 hours more tonight" : "Get 1 more hour of sleep"
        case .restingHeartRate:
            return "Practice deep breathing"
        case .heartRateVariability:
            return "Try 20 minutes of meditation"
        case .bodyMass:
            return "Track your meals today"
        case .nutritionQuality:
            return "Add 3 servings of vegetables"
        case .smokingStatus:
            return "Take the first step to quit"
        case .alcoholConsumption:
            return "Skip alcohol tonight"
        case .socialConnectionsQuality:
            return "Connect with 2 friends"
        case .stressLevel:
            return "Take 10 deep breaths"
        case .activeEnergyBurned:
            return "Move for 30 more minutes"
        case .vo2Max:
            return "Try 2 sprint intervals"
        case .oxygenSaturation:
            return "Breathe deeply for 10 minutes"
        }
    }
    
    // Calculate and format potential time gain
    private func getTimeGain(for metric: HealthMetric) -> String {
        // For metrics with impact data, calculate gain needed to reach zero impact
        if let currentImpact = metric.impactDetails?.lifespanImpactMinutes, currentImpact < 0 {
            let potentialGain = abs(currentImpact) // Full neutralization of negative impact
            return formatTimeGain(potentialGain)
        }
        
        // For questionnaire metrics, use typical improvement estimates to reach good levels
        if metric.source == .userInput {
            let currentRating = Int(metric.value)
            switch metric.type {
            case .nutritionQuality:
                return currentRating < 5 ? "+2 hours" : "+45 min"
            case .smokingStatus:
                return currentRating < 8 ? "+3 days" : "+8 hours"
            case .alcoholConsumption:
                return currentRating < 7 ? "+90 min" : "+30 min"
            case .socialConnectionsQuality:
                return currentRating < 6 ? "+1 hour" : "+20 min"
            case .stressLevel:
                return currentRating > 6 ? "+45 min" : "+15 min"
            default:
                return "+30 min"
            }
        }
        
        // Default estimates for HealthKit metrics without clear impact data
        switch metric.type {
        case .steps:
            return "+25 min"
        case .exerciseMinutes:
            return "+35 min"
        case .sleepHours:
            return "+1 hour"
        case .restingHeartRate:
            return "+15 min"
        case .heartRateVariability:
            return "+20 min"
        case .bodyMass:
            return "+45 min"
        case .activeEnergyBurned:
            return "+20 min"
        case .vo2Max:
            return "+90 min"
        case .oxygenSaturation:
            return "+10 min"
        default:
            return "+30 min"
        }
    }
    
    // Helper to format time gain values
    private func formatTimeGain(_ minutes: Double) -> String {
        let absMinutes = abs(minutes)
        
        if absMinutes >= 1440 { // >= 1 day
            let days = Int(absMinutes / 1440)
            return "+\(days) day\(days == 1 ? "" : "s")"
        } else if absMinutes >= 60 { // >= 1 hour
            let hours = Int(absMinutes / 60)
            return "+\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            let mins = Int(absMinutes)
            return "+\(mins) min"
        }
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