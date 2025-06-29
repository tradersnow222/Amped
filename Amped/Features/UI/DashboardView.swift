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
    
    // Rules: Track user interactions - following "make it so sign-in only shows after interaction" requirement
    @State private var hasInteractedWithDashboard = false
    @State private var scrollOffset: CGFloat = 0
    
    // Pull-to-refresh state
    @State private var pullDistance: CGFloat = 0
    @State private var isRefreshing = false
    private let refreshThreshold: CGFloat = 80
    private let maxPullDistance: CGFloat = 150 // iOS standard maximum pull distance
    
    // Battery animation state
    @State private var isBatteryAnimating = false
    
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
        
        // Debug: Log the metrics state
        print("🔍 DashboardView: Total metrics before filtering: \(metrics.count)")
        for metric in metrics {
            print("  - \(metric.type.displayName): value=\(metric.value), hasImpact=\(metric.impactDetails != nil)")
        }
        
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
                    print("  + Added placeholder for: \(metricType.displayName)")
                }
            }
        } else {
            // Filter out unavailable metrics if showUnavailable is false
            let filtered = metrics.filter { metric in
                // A metric is considered available if it has either:
                // 1. A non-zero value, OR
                // 2. Valid impact details (even if value is 0)
                let isAvailable = metric.value != 0 || metric.impactDetails != nil
                if !isAvailable {
                    print("  ❌ Filtering out unavailable: \(metric.type.displayName)")
                }
                return isAvailable
            }
            print("🔍 DashboardView: After filtering (showUnavailable=false): \(filtered.count) metrics")
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
        filteredMetrics
            .compactMap { $0.impactDetails?.lifespanImpactMinutes }
            .reduce(0, +)
    }
    
    /// Format the total time impact for display
    private var formattedTotalImpact: String {
        let absMinutes = abs(totalTimeImpact)
        let direction = totalTimeImpact >= 0 ? "gained" : "lost"
        
        // Use similar formatting as HealthMetricRow but for larger values
        let minutesInHour = 60.0
        let minutesInDay = 1440.0
        let minutesInWeek = 10080.0
        let minutesInMonth = 43200.0
        let minutesInYear = 525600.0
        
        // Years
        if absMinutes >= minutesInYear {
            let years = absMinutes / minutesInYear
            if years >= 2 {
                return String(format: "%.0f years %@", years, direction)
            } else {
                return String(format: "%.1f year %@", years, direction)
            }
        }
        
        // Months
        if absMinutes >= minutesInMonth {
            let months = absMinutes / minutesInMonth
            if months >= 2 {
                return String(format: "%.0f months %@", months, direction)
            } else {
                return String(format: "%.1f month %@", months, direction)
            }
        }
        
        // Weeks
        if absMinutes >= minutesInWeek {
            let weeks = absMinutes / minutesInWeek
            if weeks >= 2 {
                return String(format: "%.0f weeks %@", weeks, direction)
            } else {
                return String(format: "%.1f week %@", weeks, direction)
            }
        }
        
        // Days
        if absMinutes >= minutesInDay {
            let days = absMinutes / minutesInDay
            if days >= 2 {
                return String(format: "%.0f days %@", days, direction)
            } else {
                return String(format: "%.1f day %@", days, direction)
            }
        }
        
        // Hours
        if absMinutes >= minutesInHour {
            let hours = absMinutes / minutesInHour
            if hours >= 2 {
                return String(format: "%.0f hours %@", hours, direction)
            } else {
                return String(format: "%.1f hour %@", hours, direction)
            }
        }
        
        // Minutes
        if absMinutes >= 1.0 {
            return "\(Int(absMinutes)) min \(direction)"
        }
        
        // For very small values, show seconds
        let absSeconds = absMinutes * 60.0
        if absSeconds < 0.1 {
            return String(format: "%.3f sec %@", absSeconds, direction)
        } else if absSeconds < 1.0 {
            return String(format: "%.2f sec %@", absSeconds, direction)
        } else if absSeconds < 10.0 {
            return String(format: "%.1f sec %@", absSeconds, direction)
        } else {
            return String(format: "%.0f sec %@", absSeconds, direction)
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pull-to-refresh indicator
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
                }
                
                // Main content area
                VStack(spacing: 0) {
                    // Fixed header section with period selector only
                    PeriodSelectorView(
                        selectedPeriod: $selectedPeriod,
                        onPeriodChanged: { period in
                            // Update the view model's selected time period
                            let timePeriod = TimePeriod(from: period)
                            viewModel.selectedTimePeriod = timePeriod
                            
                            // Rules: Track period selection as user interaction
                            if !hasInteractedWithDashboard {
                                hasInteractedWithDashboard = true
                                checkAndShowSignInIfNeeded()
                            }
                        }
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    // Scrollable content including battery and metrics
                    ScrollView {
                        VStack(spacing: 0) {
                            // Balanced spacing above battery
                            Spacer()
                                .frame(height: 8)
                            
                            // The dashboard battery system
                            BatterySystemView(
                                lifeProjection: viewModel.lifeProjection,
                                currentUserAge: viewModel.currentUserAge,
                                onProjectionHelpTapped: { 
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showingProjectionHelp = true
                                    }
                                    
                                    // Rules: Track battery help tap as user interaction
                                    if !hasInteractedWithDashboard {
                                        hasInteractedWithDashboard = true
                                        checkAndShowSignInIfNeeded()
                                    }
                                }
                            )
                            .padding(.horizontal)
                            
                            // Balanced spacing below battery
                            Spacer()
                                .frame(height: 24)
                            
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
                                    
                                    Text("Powering your lifespan")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 16)
                            .accessibilityAddTraits(.isHeader)
                            
                            // Spacing after header
                            Spacer()
                                .frame(height: 8)
                            
                            // Total Impact Summary - Better visual integration
                            if totalTimeImpact != 0 {
                                VStack(spacing: 4) {
                                    // Period label with more natural wording
                                    Text("Total \(periodAdjective) impact")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.5))
                                        .textCase(.uppercase)
                                        .tracking(0.3)
                                    
                                    // Main impact display
                                    HStack(spacing: 6) {
                                        Image(systemName: totalTimeImpact >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                            .font(.callout)
                                            .foregroundColor(totalTimeImpact >= 0 ? .ampedGreen : .ampedRed)
                                            .symbolRenderingMode(.hierarchical)
                                        
                                        Text(formattedTotalImpact)
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cardBackground)
                                        .opacity(0.6)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            (totalTimeImpact >= 0 ? Color.ampedGreen : Color.ampedRed).opacity(0.2),
                                            lineWidth: 1
                                        )
                                )
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                                .padding(.bottom, 16)
                            }
                            
                            // Power Sources Metrics section
                            HealthMetricsListView(metrics: filteredMetrics) { metric in
                                selectedMetric = metric
                                HapticManager.shared.playSelection()
                                
                                // Rules: Track metric tap as user interaction
                                checkAndShowSignInIfNeeded()
                            }
                            .padding(.horizontal, 8)
                            .padding(.bottom, 32)
                        }
                        
                        // Rules: Track scroll position to detect user interaction
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: -geometry.frame(in: .named("scroll")).origin.y
                            )
                        }
                        .frame(height: 0)
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        // Rules: Track significant scrolling as user interaction
                        scrollOffset = value
                        if abs(value) > 20 && !hasInteractedWithDashboard {
                            hasInteractedWithDashboard = true
                            checkAndShowSignInIfNeeded()
                        }
                    }
                }
                .offset(y: pullDistance)
                .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.85), value: pullDistance)
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
            
            // Start battery animation
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                isBatteryAnimating = true
            }
            
            // Debug navigation context
            print("🔧 DashboardView navigation context check")
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
    
    /// Check if sign-in popup should be shown after user interaction - Rules: Following user requirement
    private func checkAndShowSignInIfNeeded() {
        // Only show popup if user is not authenticated and hasn't seen it before
        if !appState.isAuthenticated && !hasShownSignInPopup && hasInteractedWithDashboard {
            hasShownSignInPopup = true
            
            // Small delay so the interaction feels natural before showing popup
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSignInPopup = true
                }
            }
        }
    }
}

// MARK: - ScrollOffset Preference Key

/// Preference key to track scroll offset - Rules: Track user scrolling interaction
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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