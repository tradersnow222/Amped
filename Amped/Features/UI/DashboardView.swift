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
    
    // Battery animation state
    @State private var isBatteryAnimating = false
    
    // Page control state for swipeable views
    @State private var currentPage = 0
    
    // Loading states for calculations
    @State private var isCalculatingImpact = true
    @State private var isCalculatingLifespan = true
    @State private var hasInitiallyCalculated = false
    
    // State for lifestyle tabs
    @State private var selectedLifestyleTab = 0 // 0 = Current lifestyle, 1 = Better habits
    
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
            if years > 1 {
                return String(format: "%.0f years", years)
            } else {
                return String(format: "%.1f year", years)
            }
        }
        
        // Months
        if absMinutes >= minutesInMonth {
            let months = absMinutes / minutesInMonth
            if months > 1 {
                return String(format: "%.0f months", months)
            } else {
                return String(format: "%.1f month", months)
            }
        }
        
        // Weeks
        if absMinutes >= minutesInWeek {
            let weeks = absMinutes / minutesInWeek
            if weeks > 1 {
                return String(format: "%.0f weeks", weeks)
            } else {
                return String(format: "%.1f week", weeks)
            }
        }
        
        // Days
        if absMinutes >= minutesInDay {
            let days = absMinutes / minutesInDay
            if days > 1 {
                return String(format: "%.0f days", days)
            } else {
                return String(format: "%.1f day", days)
            }
        }
        
        // Hours
        if absMinutes >= minutesInHour {
            let hours = absMinutes / minutesInHour
            if hours > 1 {
                return String(format: "%.0f hours", hours)
            } else {
                return String(format: "%.1f hour", hours)
            }
        }
        
        // Minutes
        if absMinutes >= 1.0 {
            return "\(Int(absMinutes)) min"
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
        case .day: return "Today you've"
        case .month: return "This month you've"
        case .year: return "This year you've"
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
                                // Update the view model's selected time period
                                let timePeriod = TimePeriod(from: period)
                                viewModel.selectedTimePeriod = timePeriod
                            }
                        )
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                    
                    // Swipeable content pages using custom container
                    // Rules: Using SwipeablePageContainer to ensure page dots never overlap content
                    SwipeablePageContainer(currentPage: $currentPage, pageCount: 2) {
                        // Page 1: Health Factors with Total Impact
                        healthFactorsPage
                            .swipeablePage(0)
                        
                        // Page 2: Lifespan Remaining Battery
                        lifespanBatteryPage
                            .swipeablePage(1)
                    }
                    .onChange(of: currentPage) { newPage in
                        // Add haptic feedback on page change for better user experience
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
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
            
            // Start battery animation
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                isBatteryAnimating = true
            }
            
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
    
    /// Page 1: Health factors with prominent total impact
    private var healthFactorsPage: some View {
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
                        VStack(spacing: 8) {
                            // "You've added/lost" text above the number
                            Text(totalTimeImpact >= 0 ? "\(timePeriodContext) added" : "\(timePeriodContext) lost")
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
                            
                            // "to your life" text below (removed time period reference)
                            Text("to your life")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            (totalTimeImpact >= 0 ? Color.ampedGreen : Color.ampedRed).opacity(0.15),
                                            (totalTimeImpact >= 0 ? Color.ampedGreen : Color.ampedRed).opacity(0.05)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    (totalTimeImpact >= 0 ? Color.ampedGreen : Color.ampedRed).opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    } else {
                        // No impact yet
                        VStack(spacing: 12) {
                            Text("NO HEALTH DATA YET")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.6))
                                .tracking(0.5)
                            
                            Text("Complete your health profile to see your impact")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .padding(.top, 20)
                    }
                    
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
                            Text("Your Health Factors")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Powering your lifespan within the last \(selectedPeriod.rawValue)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 16)
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
                    // Add padding based on safe area to ensure content doesn't go under page indicators
                    .padding(.bottom, max(60, geometry.safeAreaInsets.bottom + 40))
                }
            }
            .refreshable {
                await refreshHealthData()
            }
        }
    }
    
    /// Page 2: Lifespan remaining battery
    private var lifespanBatteryPage: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Lifestyle tabs at the top - more compact
                lifestyleTabs
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                // No ScrollView - everything fits perfectly
                VStack(spacing: 16) {
                    if isCalculatingLifespan && !hasInitiallyCalculated {
                        // Calculating state - centered
                        Spacer()
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .ampedYellow))
                                .scaleEffect(1.2)
                            
                            Text("Calculating your projected lifespan...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                    } else {
                        // Compact, elegant battery and countdown display
                        VStack(spacing: 12) {
                            // Enhanced battery system - more compact
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
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .refreshable {
            await refreshLifespanData()
        }
    }
    
    /// Lifestyle tabs view
    private var lifestyleTabs: some View {
        HStack(spacing: 0) {
            // Current lifestyle tab
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedLifestyleTab = 0
                }
                HapticManager.shared.playSelection()
            } label: {
                Text("Current Habits")
                    .fontWeight(selectedLifestyleTab == 0 ? .bold : .medium)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            if selectedLifestyleTab == 0 {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.ampedYellow.opacity(0.2))
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.ampedYellow, lineWidth: 1.5)
                                    .shadow(color: Color.ampedYellow.opacity(0.6), radius: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            }
                        }
                    )
                    .foregroundColor(selectedLifestyleTab == 0 ? .ampedYellow : .gray)
            }
            
            // Better habits tab
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedLifestyleTab = 1
                }
                HapticManager.shared.playSelection()
            } label: {
                Text("Better Habits")
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
                    .foregroundColor(selectedLifestyleTab == 1 ? .ampedGreen : .gray)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .padding(.horizontal, 16)
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
}

// MARK: - Preview

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView()
        }
    }
} 