import SwiftUI
import Combine
import HealthKit
import OSLog
import CoreHaptics

/// Main dashboard view with tab-based navigation
struct DashboardView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingsManager: SettingsManager
    
    // MARK: - State Objects
    @StateObject private var viewModel = DashboardViewModel()
    
    // MARK: - State Variables
    @State private var selectedTab = 0 // 0 = Home, 1 = Dashboard, 2 = Energy, 3 = Profile
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @State private var showingSettings = false
    @State private var showingUpdateHealthProfile = false
    @State private var selectedMetric: HealthMetric?
    @State private var showSignInPopup = false
    @State private var showingProjectionHelp = false
    @State private var showingDetailedAnalysis = false
    @State private var navigationPath = NavigationPath()
    
    // Battery animation state
    @State private var isBatteryAnimating = false
    @State private var showLifeEnergyBattery = false
    
    // Loading states for calculations
    @State private var isCalculatingImpact = true
    @State private var isCalculatingLifespan = true
    @State private var hasInitiallyCalculated = false
    
    // Pull-to-refresh state
    @State private var pullDistance: CGFloat = 0
    @State private var isRefreshing = false
    @State private var refreshIndicatorOpacity: Double = 0
    @State private var refreshIndicatorRotation: Double = 0
    private let refreshThreshold: CGFloat = 60
    private let maxPullDistance: CGFloat = 120
    
    // Logger for debugging
    private let logger = Logger(subsystem: "com.amped.app", category: "DashboardView")
    
    // MARK: - Computed Properties

    /// Convert period type to proper adjective form for display
    private var periodAdjective: String {
        switch selectedPeriod {
        case .day: return "daily"
        case .month: return "monthly"
        case .year: return "yearly"
        }
    }
    
    /// Filtered metrics based on user settings
    private var filteredMetrics: [HealthMetric] {
        var metrics = viewModel.healthMetrics
        
        // If "Show metrics with no data" is enabled, include all HealthKit types
        if settingsManager.showUnavailableMetrics {
            let loadedMetricTypes = Set(metrics.filter { $0.source != .userInput }.map { $0.type })
            
            for metricType in HealthMetricType.healthKitTypes {
                if !loadedMetricTypes.contains(metricType) {
                    let placeholderMetric = HealthMetric(
                        id: UUID().uuidString,
                        type: metricType,
                        value: 0,
                        date: Date(),
                        source: .healthKit,
                        impactDetails: nil
                    )
                    metrics.append(placeholderMetric)
                }
            }
        } else {
            let filtered = metrics.filter { metric in
                return metric.impactDetails != nil
            }
            metrics = filtered
        }
        
        return metrics.sorted { lhs, rhs in
            let lhsImpact = abs(lhs.impactDetails?.lifespanImpactMinutes ?? 0)
            let rhsImpact = abs(rhs.impactDetails?.lifespanImpactMinutes ?? 0)
            return lhsImpact > rhsImpact
        }
    }
    
    
    /// Calculate total time impact using sophisticated LifeImpactService calculation
    private var totalTimeImpact: Double {
        guard let lifeImpact = viewModel.lifeImpactData else {
            logger.warning("⚠️ No lifeImpactData available for headline calculation")
            return 0.0
        }
        
        let signedImpact = lifeImpact.totalImpact.value * (lifeImpact.totalImpact.direction == .positive ? 1.0 : -1.0)
        
        logger.info("📊 Headline impact calculation:")
        logger.info("  📅 Period: \(viewModel.selectedTimePeriod.displayName)")
        logger.info("  🔢 Impact value: \(String(format: "%.2f", signedImpact)) minutes")
        logger.info("  ↗️ Direction: \(lifeImpact.totalImpact.direction == .positive ? "positive" : "negative")")
        
        return signedImpact
    }
    
    /// Format the total time impact for display
    private var formattedTotalImpact: String {
        let absMinutes = abs(totalTimeImpact)
        
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
        case .day: timeFrame = "the last day"
        case .month: timeFrame = "the last month"
        case .year: timeFrame = "the last year"
        }
        
        if totalTimeImpact >= 0 {
            return "You added \(formattedTotalImpact) to your lifespan within \(timeFrame) due to your habits"
        } else {
            return "You lost \(formattedTotalImpact) from your lifespan within \(timeFrame) due to your habits"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
        ZStack {
                Color.black
                    .ignoresSafeArea()
                // Main content based on selected tab
                VStack(spacing: 0) {
                    // Content area
                    Group {
                        switch selectedTab {
                        case 0: // Home tab - Dashboard home with battery character
                            dashboardHomeView
                        case 1: // Dashboard tab - Detailed metrics list
                            dashboardView
                        case 2: // Energy tab - Battery page content
                            energyView
                        case 3: // Profile tab - Profile/settings
                            profileView
                        default:
                            dashboardHomeView
                        }
                    }
                    
                    // Bottom navigation bar
                    bottomNavigationBar
                }
            
            // Error overlay if needed
            if let errorMessage = viewModel.errorMessage {
                errorOverlay(errorMessage: errorMessage)
            }
            
            // Custom info card overlay
            if showingProjectionHelp {
                projectionHelpOverlay
            }
        }
        .withDeepBackground()
        .toolbar {
            // ToolbarItem(placement: .navigationBarTrailing) {
            //     Button {
            //         showingSettings = true
            //     } label: {
            //         Image(systemName: "gearshape.fill")
            //             .font(.system(size: 20, weight: .medium))
            //             .foregroundColor(.white)
            //     }
            //     .accessibilityLabel("Account & Settings")
            //     .accessibilityHint("Double tap to open your account and settings")
            // }
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
        .navigationDestination(for: String.self) { destination in
            if destination == "detailedAnalysis" {
                detailedAnalysisView
            }
        }
        .onAppear {
            configureNavigationBar()
            viewModel.loadData()
            HapticManager.shared.prepareHaptics()
            handleIntroAnimations()
        }
        .animation(.easeInOut(duration: 0.2), value: showingProjectionHelp)
        .animation(.easeInOut(duration: 0.2), value: showSignInPopup)
        }
    }
    
    // MARK: - Dashboard Views
    
    /// Dashboard Home View (1st & 2nd images) - Main screen with battery character
    private var dashboardHomeView: some View {
        VStack(spacing: 0) {
            // Personalized greeting header
                    personalizedHeader
                    
            // Date navigation bar
            dateNavigationBar
            
            // Main content with battery character
            ScrollView {
                VStack(spacing: 24) {
                    // Battery character section
                    batteryCharacterSection
                    
                    // Habits summary section
                    habitsSummarySection
                    
                    // Specific habit detail section
                    habitDetailSection
                    
                    Spacer(minLength: 100) // Space for bottom navigation
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
    
    /// Dashboard View (3rd image) - Detailed metrics list
    private var dashboardView: some View {
        VStack(spacing: 0) {
            // Personalized greeting header
            personalizedHeader
            
            // Date navigation bar
            dateNavigationBar
            
            // Dashboard metrics list with period-based content
            ScrollView {
                VStack(spacing: 16) {
                    // Animated content based on selected period
                    ForEach(Array(getMetricsForPeriod(selectedPeriod).enumerated()), id: \.offset) { index, metric in
                        dashboardMetricCard(
                            icon: metric.icon,
                            iconColor: metric.iconColor,
                            title: metric.title,
                            value: metric.value,
                            unit: metric.unit,
                            status: metric.status,
                            statusColor: metric.statusColor,
                            timestamp: metric.timestamp
                        )
                        .id("\(metric.title)-\(selectedPeriod)-\(index)")
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)).combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .move(edge: .leading)).combined(with: .scale(scale: 1.1))
                        ))
                        .animation(.easeInOut(duration: 0.4).delay(Double(index) * 0.08), value: selectedPeriod)
                    }
                    
                    Spacer(minLength: 100) // Space for bottom navigation
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
    }
    
    /// Energy View - Battery page content (old battery page)
    private var energyView: some View {
        VStack(spacing: 0) {
            // Personalized greeting header
            personalizedHeader
            
            // Lifestyle tabs
            lifestyleTabs
            
            // Battery page content
            ScrollView {
                VStack(spacing: 0) {
                    batteryPageContent
                    
                    Spacer(minLength: 100) // Space for bottom navigation
                }
            }
        }
    }
    
    /// Profile View - Profile/settings placeholder
    private var profileView: some View {
        VStack {
            Text("Profile View")
                .font(.title)
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    // MARK: - Dashboard Home Components
    
    /// Personalized header with greeting and avatar
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: true)
    }
    
    /// Date navigation bar with Day/Month/Year tabs
    private var dateNavigationBar: some View {
        HStack(spacing: 4) {
            ForEach([ImpactDataPoint.PeriodType.day, .month, .year], id: \.self) { period in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPeriod = period
                        let timePeriod = TimePeriod(from: period)
                        viewModel.selectedTimePeriod = timePeriod
                    }
                }) {
                    Text(period.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 100)
                                .fill(selectedPeriod == period ? Color.black : Color.clear)
                        )
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
        .padding(.horizontal, 24)
        .padding(.vertical,12)
    }
    
    /// Battery character section with steptwo image
    private var batteryCharacterSection: some View {
        VStack(spacing: 16) {
            // Battery character with steptwo image
            ZStack {
                // Battery character background
                Image("emma")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 200)

            }
            
            // Impact text below battery
            HStack(spacing: 8) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.ampedRed)
                
                Text("Current habits costing you 8 mins")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.white)
            }
        }
    }
    
    /// Habits summary section with "View all stats" button
    private var habitsSummarySection: some View {
        VStack(spacing: 16) {
            // All habits header with view all button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.ampedRed)
                    
                    Text("All habits")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(
                            Color(red:245/255,green:40/255,blue:40/255)
                        )
                }
                
                Spacer()
                
                Button(action: {
                    navigationPath.append("detailedAnalysis")
                }) {
                    Text("View all stats >")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.ampedYellow)
                }
            }
            
            // Progress bar showing habit breakdown
            VStack(spacing: 8) {
                // Progress bar
                // Time labels
                HStack {
                    Text("1.38 hours")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red:245/255,green:40/255,blue:40/255))
                    
                    Spacer()
                    
                    Text("1.30 hours")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red:67/255,green:228/255,blue:102/255))
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Red segment (negative habits)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.ampedRed)
                            .frame(width: geometry.size.width * 0.5, height: 8)
                        
                        // Green segment (positive habits)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.ampedGreen)
                            .frame(width: geometry.size.width * 0.5, height: 8)
                            .offset(x: geometry.size.width * 0.5)
                        
                        // White divider line
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2, height: 8)
                            .offset(x: geometry.size.width * 0.5 - 1)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
//        .padding(.top,12)
    }
    
    /// Specific habit detail section
    private var habitDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "moon")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 27, height: 27)
                    .background(
                        Circle()
                            .fill(Color(red:252/255, green:238/255,blue: 33/255).opacity(0.8))
                    )
                
                Text("Suboptimal Sleep")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text("Costing you 3 minutes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.ampedRed)
            
            Text("Sleep ")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
            +
            Text("20 minute")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.green)
            +
            Text(" more tonight to add ")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
            +
            Text("2 minute")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.green)
            +
            Text(" to your life")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
    }
    
    /// Detailed metric card for dashboard view
    private func detailedMetricCard(metric: HealthMetric) -> some View {
        VStack(spacing: 16) {
            // Header with icon and title
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: metricIcon(for: metric.type))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(metricColor(for: metric.type))
                    
                    Text(metric.type.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(metricColor(for: metric.type))
                }
                
                Spacer()
                
                // Status text
                let impactMinutes = metric.impactDetails?.lifespanImpactMinutes ?? 0
                let isPositive = impactMinutes >= 0
                Text(isPositive ? "Gained \(Int(abs(impactMinutes))) mins" : "Costing you \(Int(abs(impactMinutes))) mins")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isPositive ? .ampedGreen : .ampedRed)
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    // Progress fill
                    let impactMinutes = metric.impactDetails?.lifespanImpactMinutes ?? 0
                    let isPositive = impactMinutes >= 0
                    let progressPercentage = min(1.0, abs(impactMinutes) / 60.0) // Max 60 minutes
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isPositive ? Color.ampedGreen : Color.ampedRed)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                    
                    // White slider handle
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: 12)
                        .offset(x: geometry.size.width * progressPercentage - 1)
                }
            }
            .frame(height: 8)
            
            // Time values
            HStack {
                Text("8 mins")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                let impactMinutes = metric.impactDetails?.lifespanImpactMinutes ?? 0
                Text("\(Int(abs(impactMinutes))) mins")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(impactMinutes >= 0 ? .ampedGreen : .ampedRed)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    /// Energy View Components (from old battery page)
    
    /// Lifestyle tabs for energy view
    private var lifestyleTabs: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Handle lifestyle tab selection
                }
            }) {
                Text("Current Lifestyle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                    )
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Handle lifestyle tab selection
                }
            }) {
                Text("Better Habits")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.clear)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    /// Battery page content (from old battery page) - Simplified version
    private var batteryPageContent: some View {
        VStack(spacing: 24) {
            // Simple battery visualization placeholder
            VStack(spacing: 16) {
                Text("Life Projection")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                // Simple battery placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.ampedGreen, .ampedYellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 100)
                    .overlay(
                        Text("85.2 years")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                Button(action: {
                    showingProjectionHelp = true
                }) {
                    Text("Learn More")
                        .font(.caption)
                        .foregroundColor(.ampedYellow)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Helper Components
    
    /// Error overlay
    private func errorOverlay(errorMessage: String) -> some View {
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
                
    /// Projection help overlay
    private var projectionHelpOverlay: some View {
        ZStack {
                    // Blurred background
            Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingProjectionHelp = false
                            }
                        }
                    
                    // Info card overlay
                    VStack {
                        Spacer()
                    .frame(height: 0)
                        
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
    
    /// Bottom navigation bar with 4 icons
    private var bottomNavigationBar: some View {
        HStack(spacing: 0) {
            // Home icon
            Button(action: { selectedTab = 0 }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(selectedTab == 0 ? Color.white.opacity(0.2) : Color.clear)
                        )
                }
            }
            
            Spacer()
            
            // Dashboard icon
            Button(action: { selectedTab = 1 }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 1 ? "square.grid.2x2.fill" : "square.grid.2x2")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(selectedTab == 1 ? Color.white.opacity(0.2) : Color.clear)
                        )
                }
            }
            
            Spacer()
            
            // Energy icon
            Button(action: { selectedTab = 2 }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 2 ? "bolt.fill" : "bolt")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(selectedTab == 2 ? Color.white.opacity(0.2) : Color.clear)
                        )
                }
            }
            
                        Spacer()
            
            // Profile icon
            Button(action: { selectedTab = 3 }) {
                VStack(spacing: 4) {
                    Image(systemName: selectedTab == 3 ? "person.fill" : "person")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(selectedTab == 3 ? Color.white.opacity(0.2) : Color.clear)
                        )
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(red:39/255,green:39/255,blue:39/255))
        )
        .padding(.horizontal, 60)
        .padding(.bottom, 20)
    }
    
    /// Detailed Analysis View (slides in from right)
    private var detailedAnalysisView: some View {
        VStack(spacing: 0) {
            // Custom header
            HStack {
                Button(action: {
                    navigationPath.removeLast()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
                        )
                }
                
                Spacer()
                    .frame(width: 16)
                Text("Detailed Analysis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Empty space to balance the back button
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            .background(Color.black)
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                // Heart Rate Card
                detailedAnalysisCard(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    titleColor: .red,
                    status: "Costing you 8 mins",
                    statusColor: .red,
                    leftValue: "8 mins",
                    rightValue: "0 mins",
                    rightValueColor: .white,
                    timeValue: -8, // Current value at minimum (far left)
                    progressColor: .red
                )
                
                // Steps Card
                detailedAnalysisCard(
                    icon: "figure.walk",
                    title: "Steps",
                    titleColor: .blue,
                    status: "Gained 2 mins",
                    statusColor: .green,
                    leftValue: "8 mins",
                    rightValue: "2 mins",
                    rightValueColor: .white,
                    timeValue: 2, // Current value at 2 (25% right)
                    progressColor: .green
                )
                
                // Active Energy Card
                detailedAnalysisCard(
                    icon: "bolt.fill",
                    title: "Active Energy",
                    titleColor: .orange,
                    status: "Gained 3 mins",
                    statusColor: .green,
                    leftValue: "8 mins",
                    rightValue: "3 mins",
                    rightValueColor: .white,
                    timeValue: 3, // Current value at 3 (37.5% right)
                    progressColor: .green
                )
                
                // Sleep Card
                detailedAnalysisCard(
                    icon: "moon.fill",
                    title: "Sleep",
                    titleColor: .yellow,
                    status: "Gained 3 mins",
                    statusColor: .green,
                    leftValue: "8 mins",
                    rightValue: "3 mins",
                    rightValueColor: .white,
                    timeValue: 3, // Current value at 3 (37.5% right)
                    progressColor: .green
                )
                
                // Cardio (VO2) Card
                detailedAnalysisCard(
                    icon: "heart.circle.fill",
                    title: "Cardio (VO2)",
                    titleColor: .blue,
                    status: "Costing you 8 mins",
                    statusColor: .red,
                    leftValue: "8 mins",
                    rightValue: "0 mins",
                    rightValueColor: .white,
                    timeValue: -8, // Current value at minimum (far left)
                    progressColor: .red
                )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .background(Color.black)
        .navigationBarHidden(true)
    }
    
    /// Clean Detailed Analysis Card implementation
    private func detailedAnalysisCard(
        icon: String,
        title: String,
        titleColor: Color,
        status: String,
        statusColor: Color,
        leftValue: String,
        rightValue: String,
        rightValueColor: Color,
        timeValue: Int, // Time value in minutes (negative = red, positive = green)
        progressColor: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon, title, and status
        HStack {
                // Icon and title
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(titleColor)
                    
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(titleColor)
                }
                
                Spacer()
                
                // Status text
                Text(status)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusColor)
            }
            
            // Time values
            HStack {
                Text(leftValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(rightValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(rightValueColor)
            }
            
            // Divergent Bar Chart Implementation
            DivergentBarChart(value: timeValue, maxValue: 8.0)
                .frame(height: 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
    }
    
    /// Help popover for projection battery
    private var projectionHelpPopover: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Life Projection")
                    .font(.headline)
                            .foregroundColor(.white)
                        
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingProjectionHelp = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text("This shows your projected lifespan based on your current health habits and scientific research.")
                        .font(.body)
                            .foregroundColor(.white)
                        
                Text("The projection updates as your habits change, giving you a real-time view of how your lifestyle choices impact your longevity.")
                        .font(.body)
                            .foregroundColor(.white)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Helper Functions
    
    /// Get icon for metric type
    private func metricIcon(for type: HealthMetricType) -> String {
        switch type {
        case .restingHeartRate: return "heart.fill"
        case .steps: return "figure.walk"
        case .activeEnergyBurned: return "bolt.fill"
        case .sleepHours: return "moon.fill"
        case .vo2Max: return "waveform.path.ecg"
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
    
    /// Configure navigation bar appearance
    private func configureNavigationBar() {
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
    }
    
    /// Handle intro animations based on app state
    private func handleIntroAnimations() {
        let shouldAnimate = appState.shouldTriggerIntroAnimations || appState.isFirstDashboardViewAfterOnboarding
        
        if shouldAnimate {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                isBatteryAnimating = true
            }
            
            withAnimation(.easeInOut(duration: 1.0).delay(0.8)) {
                showLifeEnergyBattery = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                appState.markDashboardAnimationsShown()
            }
        } else {
            isBatteryAnimating = true
            showLifeEnergyBattery = true
        }
    }
}

// MARK: - Dashboard Metric Data Model
struct DashboardMetric: Identifiable {
    let id: String
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let status: String
    let statusColor: Color
    let timestamp: String
    
    init(icon: String, iconColor: Color, title: String, value: String, unit: String, status: String, statusColor: Color, timestamp: String) {
        self.id = title // Use title as consistent ID
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.unit = unit
        self.status = status
        self.statusColor = statusColor
        self.timestamp = timestamp
    }
}

// MARK: - Dashboard Metric Card Component
struct DashboardMetricCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let unit: String
    let status: String
    let statusColor: Color
    let timestamp: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Top row - Icon + title on left, timestamp + chevron on right
            HStack {
                HStack(spacing: 8) {
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                        .frame(width: 20, height: 20)
                    
                    // Title
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                Spacer()
                
                // Timestamp and chevron
                HStack(spacing: 4) {
                    Text(timestamp)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            // Bottom row - Value + unit on left, status on right
            HStack(alignment: .bottom) {
                // Value and unit
                HStack(alignment: .bottom, spacing: 4) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                Spacer()
                    .frame(width:12)
                // Status with arrow
                Text(status)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
    }
}

// MARK: - Dashboard Metric Card Helper
extension DashboardView {
    func dashboardMetricCard(
        icon: String,
        iconColor: Color,
        title: String,
        value: String,
        unit: String,
        status: String,
        statusColor: Color,
        timestamp: String
    ) -> some View {
        DashboardMetricCard(
            icon: icon,
            iconColor: iconColor,
            title: title,
            value: value,
            unit: unit,
            status: status,
            statusColor: statusColor,
            timestamp: timestamp
        )
    }
    
    func getMetricsForPeriod(_ period: ImpactDataPoint.PeriodType) -> [DashboardMetric] {
        switch period {
        case .day:
            return [
                DashboardMetric(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Heart Rate",
                    value: "75",
                    unit: "BPM",
                    status: "↑ 4 mins added",
                    statusColor: .green,
                    timestamp: "21:43"
                ),
                DashboardMetric(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: "Steps",
                    value: "3,421",
                    unit: "steps",
                    status: "↓ 2 mins lost",
                    statusColor: .red,
                    timestamp: "21:35"
                ),
                DashboardMetric(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Active Energy",
                    value: "670",
                    unit: "kcal",
                    status: "↓ 2 mins lost",
                    statusColor: .red,
                    timestamp: "21:35"
                ),
                DashboardMetric(
                    icon: "moon.fill",
                    iconColor: .yellow,
                    title: "Sleep",
                    value: "5h 12m",
                    unit: "",
                    status: "↓ 2 mins lost",
                    statusColor: .red,
                    timestamp: "21:35"
                ),
                DashboardMetric(
                    icon: "heart.circle.fill",
                    iconColor: .blue,
                    title: "Cardio (VO2)",
                    value: "56ml/65",
                    unit: "per min",
                    status: "↑ 3 mins added",
                    statusColor: .green,
                    timestamp: "21:35"
                )
            ]
        case .month:
            return [
                DashboardMetric(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Heart Rate",
                    value: "78",
                    unit: "BPM",
                    status: "↑ 12 mins added",
                    statusColor: .green,
                    timestamp: "Dec 15"
                ),
                DashboardMetric(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: "Steps",
                    value: "89,234",
                    unit: "steps",
                    status: "↑ 8 mins added",
                    statusColor: .green,
                    timestamp: "Dec 15"
                ),
                DashboardMetric(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Active Energy",
                    value: "18,450",
                    unit: "kcal",
                    status: "↑ 15 mins added",
                    statusColor: .green,
                    timestamp: "Dec 15"
                ),
                DashboardMetric(
                    icon: "moon.fill",
                    iconColor: .yellow,
                    title: "Sleep",
                    value: "156h 24m",
                    unit: "",
                    status: "↓ 6 mins lost",
                    statusColor: .red,
                    timestamp: "Dec 15"
                ),
                DashboardMetric(
                    icon: "heart.circle.fill",
                    iconColor: .blue,
                    title: "Cardio (VO2)",
                    value: "58ml/65",
                    unit: "per min",
                    status: "↑ 18 mins added",
                    statusColor: .green,
                    timestamp: "Dec 15"
                )
            ]
        case .year:
            return [
                DashboardMetric(
                    icon: "heart.fill",
                    iconColor: .red,
                    title: "Heart Rate",
                    value: "76",
                    unit: "BPM",
                    status: "↑ 45 mins added",
                    statusColor: .green,
                    timestamp: "2024"
                ),
                DashboardMetric(
                    icon: "figure.walk",
                    iconColor: .blue,
                    title: "Steps",
                    value: "1.2M",
                    unit: "steps",
                    status: "↑ 120 mins added",
                    statusColor: .green,
                    timestamp: "2024"
                ),
                DashboardMetric(
                    icon: "flame.fill",
                    iconColor: .orange,
                    title: "Active Energy",
                    value: "245K",
                    unit: "kcal",
                    status: "↑ 180 mins added",
                    statusColor: .green,
                    timestamp: "2024"
                ),
                DashboardMetric(
                    icon: "moon.fill",
                    iconColor: .yellow,
                    title: "Sleep",
                    value: "2.8K hours",
                    unit: "",
                    status: "↓ 72 mins lost",
                    statusColor: .red,
                    timestamp: "2024"
                ),
                DashboardMetric(
                    icon: "heart.circle.fill",
                    iconColor: .blue,
                    title: "Cardio (VO2)",
                    value: "59ml/65",
                    unit: "per min",
                    status: "↑ 95 mins added",
                    statusColor: .green,
                    timestamp: "2024"
                )
            ]
        }
    }
}

// MARK: - Divergent Bar Chart Component
struct DivergentBarChart: View {
    let value: Int
    let maxValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background bar (gray)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                // Center line (0 point) - white separator
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 2, height: 12)
                    .position(x: geometry.size.width * 0.5, y: geometry.size.height * 0.5)
                
                // Divergent fill based on value
                let normalizedMagnitude = abs(Double(value)) / maxValue // 0.0 to 1.0
                let fillWidth = geometry.size.width * normalizedMagnitude * 0.5 // Half width from center
                
                if value < 0 {
                    // Negative values: red fill from center going LEFT
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: fillWidth, height: 8)
                        .position(
                            x: geometry.size.width * 0.5 - fillWidth * 0.5, 
                            y: geometry.size.height * 0.5
                        )
                } else if value > 0 {
                    // Positive values: green fill from center going RIGHT
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.green)
                        .frame(width: fillWidth, height: 8)
                        .position(
                            x: geometry.size.width * 0.5 + fillWidth * 0.5, 
                            y: geometry.size.height * 0.5
                        )
                }
                
                // Current value marker (white dot)
                // let markerX = value < 0 
                //     ? geometry.size.width * 0.5 - geometry.size.width * normalizedMagnitude * 0.25
                //     : geometry.size.width * 0.5 + geometry.size.width * normalizedMagnitude * 0.25
                
                // Circle()
                //     .fill(Color.white)
                //     .frame(width: 8, height: 8)
                //     .position(x: markerX, y: geometry.size.height * 0.5)
            }
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
