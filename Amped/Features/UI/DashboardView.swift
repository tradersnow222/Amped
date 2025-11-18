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
    @State private var hasLoadedInitialData = false
    
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
    /// PERFORMANCE FIX: Simplified to prevent excessive recalculations in view body
    private var filteredMetrics: [HealthMetric] {
        let metrics = viewModel.healthMetrics
        
        if settingsManager.showUnavailableMetrics {
            return metrics // Return all metrics when showing unavailable ones
        } else {
            return metrics.filter { $0.impactDetails != nil }
                .sorted { abs($0.impactDetails?.lifespanImpactMinutes ?? 0) > abs($1.impactDetails?.lifespanImpactMinutes ?? 0) }
        }
    }
    
    
    /// Calculate total time impact using sophisticated LifeImpactService calculation
    /// CRITICAL FIX: Removed logging to prevent infinite loops in SwiftUI view body
    private var totalTimeImpact: Double {
        guard let lifeImpact = viewModel.lifeImpactData else {
            return 0.0
        }
        
        let signedImpact = lifeImpact.totalImpact.value * (lifeImpact.totalImpact.direction == .positive ? 1.0 : -1.0)
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
            ZStack(alignment: .bottom) {
                
                LinearGradient.customBlueToDarkGray
                    .ignoresSafeArea()
                
                // Main content
                TabView(selection: $selectedTab) {
                    dashboardHomeView.tag(0)
                    metricView.tag(1)
                    energyView
                        .id(selectedTab == 2 ? UUID() : UUID())
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never)) // hides native tabs
                
                // Custom tab bar overlay
                customTabBar
                
                // Error overlay if needed
                if let errorMessage = viewModel.errorMessage {
                    errorOverlay(errorMessage: errorMessage)
                }
                
                // Custom info card overlay
                if showingProjectionHelp {
                    projectionHelpOverlay
                }
            }
            .ignoresSafeArea(.keyboard)
            .sheet(isPresented: $showingUpdateHealthProfile) {
                UpdateHealthProfileView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(settingsManager)
            }
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .metricDetail(let type, let period):
                    if let metric = viewModel.getLatestMetricValue(for: type) {
                        MetricDetailsView(navigationPath: $navigationPath, metric: metric, selectedPeriod: period, onClose: {
                            
                        })
                    }
                case .subscription:
                    SubscriptionView(isFromOnboarding: true) { isSubscribed in
                        if isSubscribed {
                            appState.updateSubscriptionStatus(true)
                        }
                        
                        navigationPath.removeLast()
                    }
                default: EmptyView()
                    
                }
            }
            .onAppear {
                // For testing, remove it before release
//                appState.updateSubscriptionStatus(true)
                configureNavigationBar()
                HapticManager.shared.prepareHaptics()
                handleIntroAnimations()
            }
        }
    }
    
    
    private var customTabBar: some View {
        HStack(spacing: 20) {
            tabButton(index: 0, icon: "house.fill", title: "Home")
            tabButton(index: 1, icon: "square.grid.2x2.fill", title: "Metrics")
            tabButton(index: 2, icon: "bolt.fill", title: "Lifespan")
            //            tabButton(index: 3, icon: "person.fill", title: "Lifespan")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.8)
        )
        .padding(.bottom, 20)
    }
    
    @ViewBuilder
    private func tabButton(index: Int, icon: String, title: String? = nil) -> some View {
        
        let isSelected = selectedTab == index
        
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            
            if let title = title, isSelected {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
        }
        .padding(.horizontal, isSelected ? 16 : 12)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(isSelected ? Color.green.opacity(0.9) : Color.clear)
        )
        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTab = index
            }
            //            HapticManager.shared.tap()
        }
    }
    
    /// Metric Detail View - Shows detailed view for individual metrics
    private func metricDetailView(for destination: String) -> some View {
        let components = destination.components(separatedBy: "-")
        guard components.count >= 3 else { return AnyView(Text("Error")) }
        
        let metricTitle = components[1]
        let period = components[2]
        let periodType = ImpactDataPoint.PeriodType(rawValue: period) ?? .day
                
        if let metric = selectedMetric {
            return AnyView(
                MetricDetailsView(navigationPath: $navigationPath, metric: metric, selectedPeriod: periodType, onClose: {
                    
                })
            )
        } else {
            
            return AnyView(
                MetricDetailContentView(
                    metricTitle: metricTitle,
                    period: period,
                    periodType: periodType,
                    navigationPath: $navigationPath,
                    selectedHealthMetric: selectedMetric
                )
            )
        }
    }
    
    // MARK: - Period Change Methods
    
    /// Change to a specific period with animation and haptic feedback
    private func changePeriod(to period: ImpactDataPoint.PeriodType) {
        // Prevent infinite loops by checking if period is already selected
        guard selectedPeriod != period else { return }
        
        // Prevent multiple updates per frame by using async dispatch
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.selectedPeriod = period
                let timePeriod = TimePeriod(from: period)
                // Only update if it's actually different to prevent subscription loops
                if self.viewModel.selectedTimePeriod != timePeriod {
                    self.viewModel.selectedTimePeriod = timePeriod
                }
            }
            
            // Add haptic feedback for period change
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    /// Swipe to the next period (Day → Month → Year → Day)
    private func swipeToNextPeriod() {
        let periods: [ImpactDataPoint.PeriodType] = [.day, .month, .year]
        guard let currentIndex = periods.firstIndex(of: selectedPeriod) else { return }
        
        let nextIndex = (currentIndex + 1) % periods.count
        let nextPeriod = periods[nextIndex]
        
        changePeriod(to: nextPeriod)
    }
    
    /// Swipe to the previous period (Year → Month → Day → Year)
    private func swipeToPreviousPeriod() {
        let periods: [ImpactDataPoint.PeriodType] = [.day, .month, .year]
        guard let currentIndex = periods.firstIndex(of: selectedPeriod) else { return }
        
        let previousIndex = currentIndex == 0 ? periods.count - 1 : currentIndex - 1
        let previousPeriod = periods[previousIndex]
        
        changePeriod(to: previousPeriod)
    }
    
    // MARK: - Dashboard Views
    
    /// Dashboard Home View (1st & 2nd images) - Main screen with battery character
    private var dashboardHomeView: some View {
        ZStack {
            VStack(spacing: 0) {
                
                // Personalized greeting header
                personalizedHeader
                
                // Date navigation bar
                dateNavigationBar
                
                // Scrollable main content
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 24) {
                        
                        Spacer().frame(height: 10)
                        
                        // Battery character section
                        batteryCharacterSection
                        
                        // Habit detail card
                        habitDetailSection
                        
                        // Streak card
                        streakCard
                        
                        Spacer(minLength: 80)  // space before bottom tabs
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                .gesture(
                    DragGesture(minimumDistance: 100, coordinateSpace: .local)
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = abs(value.translation.height)
                            
                            // Keep your EXACT swipe logic
                            if abs(horizontalAmount) > verticalAmount && abs(horizontalAmount) > 100 {
                                if horizontalAmount > 0 {
                                    swipeToPreviousPeriod()
                                } else {
                                    swipeToNextPeriod()
                                }
                            }
                        }
                )
            }
            .opacity(viewModel.isLoading ? 0.3 : 1)   // hide dashboard when loading
            
            // Fullscreen loading overlay
            if viewModel.isLoading {
                Color.black.opacity(0.4).ignoresSafeArea()
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            }
        }
    }
    
    private var metricView: some View {
        MetricGridView(
            onCardTap: { title, period, healthMetric  in
                selectedMetric = healthMetric
                if let metric = healthMetric {
                    navigationPath.append(
                        NavigationRoute.metricDetail(
                            type: metric.type,
                            period: period
                        )
                    )
                }
            }) {
                navigationPath.append(NavigationRoute.subscription)
            }
    }
    
    /// Dashboard View (3rd image) - Detailed metrics list
    private var dashboardView: some View {
        VStack(spacing: 0) {
            // Personalized greeting header
            personalizedHeader
            
            // Date navigation bar
            dateNavigationBar
            
            // Dashboard metrics grid
            ScrollView {
                let metricsForPeriod = getMetricsForPeriodWithRealData(selectedPeriod)
                
                // Define two flexible columns
                let columns = [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ]
                
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(Array(metricsForPeriod.enumerated()), id: \.offset) { index, metric in
                        metricCardButton(for: metric, at: index)
                            .transition(.asymmetric(
                                insertion: .opacity
                                    .combined(with: .move(edge: .trailing))
                                    .combined(with: .scale(scale: 0.95)),
                                removal: .opacity
                                    .combined(with: .move(edge: .leading))
                                    .combined(with: .scale(scale: 1.05))
                            ))
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2)
                                .delay(Double(index) * 0.05),
                                value: selectedPeriod
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100) // Space for bottom navigation
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 50, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = abs(value.translation.height)
                        let velocity = value.velocity
                        
                        let isHorizontalSwipe = abs(horizontalAmount) > 50 &&
                        abs(velocity.width) > abs(velocity.height) &&
                        abs(velocity.width) > 200
                        
                        if isHorizontalSwipe {
                            if horizontalAmount > 0 {
                                swipeToPreviousPeriod()
                            } else {
                                swipeToNextPeriod()
                            }
                        }
                    }
            )
        }
    }
    
    
    /// Energy View - Battery page content using EnergyView component
    private var energyView: some View {
        EnergyView {
            // Go to subscription
            navigationPath.append(NavigationRoute.subscription)
        }
    }
    
    /// Profile View - Profile/settings using ProfileView component
    private var profileView: some View {
        ProfileView()
    }
    
    // MARK: - Dashboard Home Components
    
    /// Personalized header with greeting and avatar
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: false)
    }
    
    /// Date navigation bar with Day/Month/Year tabs and swipe gesture support
    private var dateNavigationBar: some View {
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
                                .fill(LinearGradient.dateNavLinearGradient)
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
        .padding(.vertical,12)
        .gesture(
            DragGesture(minimumDistance: 50, coordinateSpace: .local)
                .onEnded { value in
                    let horizontalAmount = value.translation.width
                    let verticalAmount = abs(value.translation.height)
                    
                    // Only respond to horizontal swipes (not vertical)
                    if abs(horizontalAmount) > verticalAmount {
                        if horizontalAmount > 0 {
                            // Swipe right - go to previous period
                            swipeToPreviousPeriod()
                        } else {
                            // Swipe left - go to next period
                            swipeToNextPeriod()
                        }
                    }
                }
        )
    }
    
    /// Battery character section with steptwo image
    private var batteryCharacterSection: some View {
        VStack(spacing: 12) {
            
            // Character + Arrow
            ZStack(alignment: .topTrailing) {
                Image("emma")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                
                Image(systemName: totalTimeImpact >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(totalTimeImpact >= 0 ? .ampedGreen : .ampedRed)
                    .padding(.trailing, 4)
                    .padding(.top, 8)
            }
            
            // Header line (centered)
            Text("Today, your habits collectively \(totalTimeImpact >= 0 ? "added" : "reduced")")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            // Main impact (large bold)
            Text("\(formattedTotalImpact) \(totalTimeImpact >= 0 ? "to your lifespan" : "from your lifespan")")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Sub text
            Text("Based on peer-reviewed scientific research")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.5))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    /// Specific habit detail section
    private var habitDetailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Title
            Text("Today's focus:")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            // Card
            HStack(alignment: .top, spacing: 10) {
                
                let isPremium = UserDefaults.standard.bool(forKey: "is_premium_user")
                if !isPremium {
                    UnlockSubscriptionView(buttonText: "Unlock it by subcribing") {
                        // Got to subscription
                        navigationPath.append(NavigationRoute.subscription)
                    }
                    .frame(height: 130)
                } else {
                    
                    Image(systemName: getTopMetricIcon())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 34, height: 34)
                        .background(
                            Circle()
                                .fill(getTopMetricIconColor().opacity(0.9))
                        )
                    
                    VStack(alignment: .leading) {
                        // Icon + Title Row
                        HStack(spacing: 1) {
                            Text(getTopMetricDisplayName()+" - ")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                            
                            // Red impact line
                            Text(getTopMetricImpactText())
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(getTopMetricImpactColor())
                        }
                        
                        // Recommendation line (styled like screenshot)
                        (
                            Text(getTopMetricImpactReccomendationText())
                                .foregroundColor(.white)
                            //                        +
                            //                        Text("20 minutes ")
                            //                            .foregroundColor(.white)
                            //                            .fontWeight(.bold)
                            //                        +
                            //                        Text("more tonight to earn it back.")
                                .foregroundColor(.white)
                        )
                        .font(.system(size: 14))
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.cardBgBackground) // lighter than main bg
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1) // subtle border
                    )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // Streak card
    private var streakCard: some View {
        HStack(spacing: 1) {
            
            let isPremium = UserDefaults.standard.bool(forKey: "is_premium_user")
            if !isPremium {
                UnlockSubscriptionView(buttonText: "Unlock streak by subcribing") {
                    // Got to subscription
                    navigationPath.append(NavigationRoute.subscription)
                }
                .frame(height: 130)
            } else {
                Spacer()
                
                // Flame icon
                Image("fireStreak")  // your asset name
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                
                Spacer()
                
                VStack {
                    // Count + label
                    HStack(spacing: 4) {
                        Text("\(viewModel.currentStreak.currentStreak)")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("day streak!")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Start button
                    Button {
                        //                startStreakPressed()
                    } label: {
                        Text(viewModel.currentStreak.streakLevel.displayName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 32)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.9),
                                        Color.green.opacity(0.9)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.cardBgBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
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
                    // Use DispatchQueue to prevent multiple navigation updates per frame
                    DispatchQueue.main.async {
                        navigationPath.append("detailedAnalysis")
                    }
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
    
    func getDateForPeriod(_ period: String) -> String {
        switch period {
        case "day":
            return "Today"
        case "month":
            return "This Month"
        case "year":
            return "This Year"
        default:
            return "Today"
        }
    }
    
    func getIconForMetric(_ metricTitle: String) -> String {
        switch metricTitle {
        case "Heart Rate":
            return "heart.fill"
        case "Steps":
            return "figure.walk"
        case "Active Energy":
            return "flame.fill"
        case "Sleep":
            return "moon.fill"
        case "Cardio (VO2)":
            return "heart.circle.fill"
        default:
            return "heart.fill"
        }
    }
    
    func getColorForMetric(_ metricTitle: String) -> Color {
        switch metricTitle {
        case "Heart Rate":
            return .red
        case "Steps":
            return .blue
        case "Active Energy":
            return .orange
        case "Sleep":
            return .yellow
        case "Cardio (VO2)":
            return .blue
        default:
            return .white
        }
    }
    
    func getRecommendationForMetric(_ metricTitle: String) -> String {
        switch metricTitle {
        case "Heart Rate":
            return "Maintaining a healthy heart rate is essential for cardiovascular health and longevity."
        case "Steps":
            return "Regular walking helps improve circulation, strengthen your heart, and boost overall fitness."
        case "Active Energy":
            return "Active energy expenditure through exercise is crucial for maintaining a healthy metabolism."
        case "Sleep":
            return "Getting a solid 8 hours of sleep is essential for your overall health."
        case "Cardio (VO2)":
            return "Improving your VO2 max through cardio exercise can significantly extend your lifespan."
        default:
            return "Keep up the great work with your health metrics!"
        }
    }
    
    func getActionForMetric(_ metricTitle: String) -> String {
        switch metricTitle {
        case "Heart Rate":
            return "Add 10 mins by maintaining optimal heart rate"
        case "Steps":
            return "Add 15 mins by walking 10,000 steps daily"
        case "Active Energy":
            return "Add 20 mins by burning 500 calories daily"
        case "Sleep":
            return "Add 10 mins by taking 8 hours of sleep"
        case "Cardio (VO2)":
            return "Add 25 mins by improving cardio fitness"
        default:
            return "Continue healthy habits"
        }
    }
    
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
    
    // MARK: - Helper Functions
    
    /// Create a metric card button with proper styling and navigation
    private func metricCardButton(for metric: DashboardMetric, at index: Int) -> some View {
        Button(action: {
            // Use DispatchQueue to prevent multiple navigation updates per frame
            DispatchQueue.main.async {
                navigationPath.append("metricDetail-\(metric.title)-\(selectedPeriod)")
            }
        }) {
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
        }
        .buttonStyle(PlainButtonStyle())
        .id("\(metric.title)-\(selectedPeriod)-\(index)")
    }
    
    /// Get metrics for period using real calculated data for the original 5 metrics
    private func getMetricsForPeriodWithRealData(_ period: ImpactDataPoint.PeriodType) -> [DashboardMetric] {
        // Keep the original 5 metrics but populate with real data
        let targetMetrics: [HealthMetricType] = [.restingHeartRate, .steps, .activeEnergyBurned, .sleepHours, .vo2Max, .bodyMass]
        
        return targetMetrics.compactMap { metricType in
            // Find the real health metric data for this type
            if let realMetric = viewModel.healthMetrics.first(where: { $0.type == metricType }) {
                return DashboardMetric(
                    icon: getIconForHealthMetric(realMetric.type),
                    iconColor: getColorForHealthMetric(realMetric.type),
                    title: getRealMetricTitle(realMetric.type),
                    value: realMetric.formattedValue,
                    unit: getUnitForHealthMetric(realMetric.type),
                    status: getStatusForHealthMetric(realMetric),
                    statusColor: getStatusColorForHealthMetric(realMetric),
                    timestamp: getTimestampForHealthMetric(realMetric)
                )
            } else {
                // If no real data, return placeholder with original card names
                return getPlaceholderMetric(for: metricType, period: period)
            }
        }
    }
    
    /// Get the original card titles to maintain consistency
    private func getRealMetricTitle(_ type: HealthMetricType) -> String {
        switch type {
        case .restingHeartRate: return "Heart Rate"
        case .steps: return "Steps"
        case .activeEnergyBurned: return "Active Energy"
        case .sleepHours: return "Sleep"
        case .vo2Max: return "Cardio (VO2)"
        case .bodyMass: return "Weight"
        default: return type.displayName
        }
    }
    
    /// Get placeholder metric when real data is not available
    private func getPlaceholderMetric(for type: HealthMetricType, period: ImpactDataPoint.PeriodType) -> DashboardMetric {
        switch type {
        case .restingHeartRate:
            return DashboardMetric(
                icon: "heart",
                iconColor: .red,
                title: "Heart Rate",
                value: "--",
                unit: "BPM",
                status: "No data",
                statusColor: .gray,
                timestamp: "--"
            )
        case .steps:
            return DashboardMetric(
                icon: "figure.walk",
                iconColor: .blue,
                title: "Steps",
                value: "--",
                unit: "steps",
                status: "No data",
                statusColor: .gray,
                timestamp: "--"
            )
        case .activeEnergyBurned:
            return DashboardMetric(
                icon: "flame.fill",
                iconColor: .orange,
                title: "Active Energy",
                value: "--",
                unit: "kcal",
                status: "No data",
                statusColor: .gray,
                timestamp: "--"
            )
        case .sleepHours:
            return DashboardMetric(
                icon: "moon.fill",
                iconColor: .yellow,
                title: "Sleep",
                value: "--",
                unit: "hours",
                status: "No data",
                statusColor: .gray,
                timestamp: "--"
            )
        case .vo2Max:
            return DashboardMetric(
                icon: "heart.circle.fill",
                iconColor: .blue,
                title: "Cardio (VO2)",
                value: "--",
                unit: "ml/kg/min",
                status: "No data",
                statusColor: .gray,
                timestamp: "--"
            )
        case .bodyMass:
            return DashboardMetric(
                icon: "scalemass.fill",
                iconColor: .purple,
                title: "Weight",
                value: "--",
                unit: "kg",
                status: "No data",
                statusColor: .gray,
                timestamp: "--"
            )
        default:
            return DashboardMetric(
                icon: "chart.bar.fill",
                iconColor: .gray,
                title: type.displayName,
                value: "--",
                unit: "",
                status: "No data",
                statusColor: .gray,
                timestamp: "--"
            )
        }
    }
    
    // MARK: - Real HealthMetric Helper Functions
    
    /// Get icon for a health metric type
    private func getIconForHealthMetric(_ type: HealthMetricType) -> String {
        switch type {
        case .steps: return "figure.walk"
        case .sleepHours: return "moon.fill"
        case .restingHeartRate: return "heart.fill"
        case .activeEnergyBurned: return "flame.fill"
        case .exerciseMinutes: return "figure.run"
        case .vo2Max: return "heart.circle.fill"
        case .bodyMass: return "scalemass.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .oxygenSaturation: return "lungs.fill"
        default: return "chart.bar.fill"
        }
    }
    
    /// Get color for a health metric type
    private func getColorForHealthMetric(_ type: HealthMetricType) -> Color {
        switch type {
        case .steps: return .blue
        case .sleepHours: return .purple
        case .restingHeartRate: return .red
        case .activeEnergyBurned: return .orange
        case .exerciseMinutes: return .green
        case .vo2Max: return .blue
        case .bodyMass: return .gray
        case .heartRateVariability: return .cyan
        case .oxygenSaturation: return .blue
        default: return .gray
        }
    }
    
    /// Get unit display for a health metric
    private func getUnitForHealthMetric(_ type: HealthMetricType) -> String {
        switch type {
        case .steps: return "steps"
        case .sleepHours: return "hours"
        case .restingHeartRate: return "BPM"
        case .activeEnergyBurned: return "kcal"
        case .exerciseMinutes: return "mins"
        case .vo2Max: return "ml/kg/min"
        case .bodyMass: return "kg"
        case .heartRateVariability: return "ms"
        case .oxygenSaturation: return "%"
        default: return ""
        }
    }
    
    /// Get status text for a health metric based on its impact
    private func getStatusForHealthMetric(_ metric: HealthMetric) -> String {
        guard let impact = metric.impactDetails else {
            return "No data"
        }
        
        let impactMinutes = impact.lifespanImpactMinutes
        let absMinutes = abs(impactMinutes)
        let isPositive = impactMinutes >= 0
        let arrow = isPositive ? "↑" : "↓"
        let verb = isPositive ? "added" : "lost"
        
        return "\(arrow) \(String(format: "%.0f", absMinutes)) mins \(verb)"
    }
    
    /// Get status color for a health metric based on its impact
    private func getStatusColorForHealthMetric(_ metric: HealthMetric) -> Color {
        guard let impact = metric.impactDetails else {
            return .gray
        }
        
        return impact.lifespanImpactMinutes >= 0 ? .green : .red
    }
    
    /// Get timestamp for a health metric
    private func getTimestampForHealthMetric(_ metric: HealthMetric) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: metric.date)
    }
    
    // MARK: - Dynamic Metric Helper Functions
    
    /// Get the display name of the top impactful metric
    private func getTopMetricDisplayName() -> String {
        guard let topMetric = filteredMetrics.first else {
            return "Connect Health Data"
        }
        
        let metricName = topMetric.type.displayName
        let isPositive = topMetric.impactDetails?.lifespanImpactMinutes ?? 0 >= 0
        
        if isPositive {
            return "Optimal \(metricName)"
        } else {
            return "Suboptimal \(metricName)"
        }
    }
    
    /// Get the impact text for the top metric
    private func getTopMetricImpactText() -> String {
        guard let topMetric = filteredMetrics.first,
              let impact = topMetric.impactDetails else {
            return "Track this metric to see your impact"
        }
        
        let impactMinutes = abs(impact.lifespanImpactMinutes)
        let isPositive = impact.lifespanImpactMinutes >= 0
        
        if isPositive {
            return "Adding \(String(format: "%.0f", impactMinutes)) minutes"
        } else {
            return "Costing you \(String(format: "%.0f", impactMinutes)) minutes"
        }
    }
    
    /// Get the impact recommendatoin for the top metric
    private func getTopMetricImpactReccomendationText() -> String {
        guard let topMetric = filteredMetrics.first,
              let impact = topMetric.impactDetails else {
            return "Track this metric to see your impact"
        }
        return impact.recommendation
    }
    
    /// Get the color for the top metric impact
    private func getTopMetricImpactColor() -> Color {
        guard let topMetric = filteredMetrics.first,
              let impact = topMetric.impactDetails else {
            return .white.opacity(0.7)
        }
        
        let isPositive = impact.lifespanImpactMinutes >= 0
        return isPositive ? .ampedGreen : .ampedRed
    }
    
    /// Get the icon for the top metric
    private func getTopMetricIcon() -> String {
        guard let topMetric = filteredMetrics.first else {
            return "heart.fill"
        }
        
        switch topMetric.type {
        case .steps: return "figure.walk"
        case .sleepHours: return "moon"
        case .restingHeartRate: return "heart.fill"
        case .activeEnergyBurned: return "flame.fill"
        case .exerciseMinutes: return "figure.run"
        case .vo2Max: return "heart.circle.fill"
        case .bodyMass: return "scalemass.fill"
        default: return "chart.bar.fill"
        }
    }
    
    /// Get the icon color for the top metric
    private func getTopMetricIconColor() -> Color {
        guard let topMetric = filteredMetrics.first else {
            return Color.red
        }
        
        switch topMetric.type {
        case .steps: return .blue
        case .sleepHours: return Color(red:252/255, green:238/255, blue: 33/255) // Keep original yellow for sleep
        case .restingHeartRate: return .red
        case .activeEnergyBurned: return .orange
        case .exerciseMinutes: return .green
        case .vo2Max: return .blue
        case .bodyMass: return .purple
        default: return .gray
        }
    }
    
    // MARK: - Removed duplicate helper functions - now in MetricDetailContentView
    
    /*
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
     
     // MARK: - Chart Helper Functions
     
     /// Get chart data for a specific metric and period
     func getChartDataForMetric(_ metricTitle: String, period: String) -> [ChartDataPoint] {
     switch metricTitle.lowercased() {
     case "sleep":
     return getSleepChartData(for: period)
     case "steps":
     return getStepsChartData(for: period)
     case "heart rate":
     return getHeartRateChartData(for: period)
     case "exercise":
     return getExerciseChartData(for: period)
     case "weight":
     return getWeightChartData(for: period)
     default:
     return getDefaultChartData(for: period)
     }
     }
     
     /// Get X-axis labels for different periods
     func getXAxisLabels(for period: String) -> [String] {
     switch period {
     case "day":
     return ["12 AM", "6 AM", "12 PM", "6 PM", "11 PM"]
     case "month":
     return ["Week 1", "Week 2", "Week 3", "Week 4"]
     case "year":
     return ["Q1", "Q2", "Q3", "Q4"]
     default:
     return ["1", "2", "3", "4", "5"]
     }
     }
     
     /// Get Y-axis labels based on metric type
     func getYAxisLabels(for metricTitle: String) -> [String] {
     switch metricTitle.lowercased() {
     case "sleep":
     return ["9", "7", "5", "3"]
     case "steps":
     return ["15k", "10k", "5k", "0"]
     case "heart rate":
     return ["70", "65", "60", "55"]
     case "exercise":
     return ["60", "40", "20", "0"]
     case "weight":
     return ["75", "70", "65", "60"]
     default:
     return ["100", "75", "50", "25"]
     }
     }
     
     // MARK: - Specific Chart Data Functions
     
     func getSleepChartData(for period: String) -> [ChartDataPoint] {
     switch period {
     case "day":
     return [
     ChartDataPoint(value: 7.2, label: "Mon"),
     ChartDataPoint(value: 8.1, label: "Tue"),
     ChartDataPoint(value: 6.8, label: "Wed"),
     ChartDataPoint(value: 7.5, label: "Thu"),
     ChartDataPoint(value: 8.3, label: "Fri"),
     ChartDataPoint(value: 9.1, label: "Sat"),
     ChartDataPoint(value: 7.8, label: "Sun")
     ]
     case "month":
     return [
     ChartDataPoint(value: 7.5, label: "Week 1"),
     ChartDataPoint(value: 8.0, label: "Week 2"),
     ChartDataPoint(value: 7.2, label: "Week 3"),
     ChartDataPoint(value: 7.8, label: "Week 4")
     ]
     case "year":
     return [
     ChartDataPoint(value: 7.3, label: "Q1"),
     ChartDataPoint(value: 7.8, label: "Q2"),
     ChartDataPoint(value: 8.1, label: "Q3"),
     ChartDataPoint(value: 7.6, label: "Q4")
     ]
     default:
     return []
     }
     }
     
     func getStepsChartData(for period: String) -> [ChartDataPoint] {
     switch period {
     case "day":
     return [
     ChartDataPoint(value: 8500, label: "Mon"),
     ChartDataPoint(value: 12000, label: "Tue"),
     ChartDataPoint(value: 9800, label: "Wed"),
     ChartDataPoint(value: 11500, label: "Thu"),
     ChartDataPoint(value: 13200, label: "Fri"),
     ChartDataPoint(value: 15800, label: "Sat"),
     ChartDataPoint(value: 9200, label: "Sun")
     ]
     case "month":
     return [
     ChartDataPoint(value: 10500, label: "Week 1"),
     ChartDataPoint(value: 12000, label: "Week 2"),
     ChartDataPoint(value: 9800, label: "Week 3"),
     ChartDataPoint(value: 11200, label: "Week 4")
     ]
     case "year":
     return [
     ChartDataPoint(value: 9500, label: "Q1"),
     ChartDataPoint(value: 11200, label: "Q2"),
     ChartDataPoint(value: 12800, label: "Q3"),
     ChartDataPoint(value: 10500, label: "Q4")
     ]
     default:
     return []
     }
     }
     
     func getHeartRateChartData(for period: String) -> [ChartDataPoint] {
     switch period {
     case "day":
     return [
     ChartDataPoint(value: 65, label: "Mon"),
     ChartDataPoint(value: 62, label: "Tue"),
     ChartDataPoint(value: 68, label: "Wed"),
     ChartDataPoint(value: 64, label: "Thu"),
     ChartDataPoint(value: 61, label: "Fri"),
     ChartDataPoint(value: 59, label: "Sat"),
     ChartDataPoint(value: 66, label: "Sun")
     ]
     case "month":
     return [
     ChartDataPoint(value: 66, label: "Week 1"),
     ChartDataPoint(value: 64, label: "Week 2"),
     ChartDataPoint(value: 63, label: "Week 3"),
     ChartDataPoint(value: 62, label: "Week 4")
     ]
     case "year":
     return [
     ChartDataPoint(value: 68, label: "Q1"),
     ChartDataPoint(value: 65, label: "Q2"),
     ChartDataPoint(value: 63, label: "Q3"),
     ChartDataPoint(value: 61, label: "Q4")
     ]
     default:
     return []
     }
     }
     
     func getExerciseChartData(for period: String) -> [ChartDataPoint] {
     switch period {
     case "day":
     return [
     ChartDataPoint(value: 25, label: "Mon"),
     ChartDataPoint(value: 45, label: "Tue"),
     ChartDataPoint(value: 30, label: "Wed"),
     ChartDataPoint(value: 50, label: "Thu"),
     ChartDataPoint(value: 35, label: "Fri"),
     ChartDataPoint(value: 60, label: "Sat"),
     ChartDataPoint(value: 20, label: "Sun")
     ]
     case "month":
     return [
     ChartDataPoint(value: 35, label: "Week 1"),
     ChartDataPoint(value: 42, label: "Week 2"),
     ChartDataPoint(value: 38, label: "Week 3"),
     ChartDataPoint(value: 45, label: "Week 4")
     ]
     case "year":
     return [
     ChartDataPoint(value: 30, label: "Q1"),
     ChartDataPoint(value: 38, label: "Q2"),
     ChartDataPoint(value: 45, label: "Q3"),
     ChartDataPoint(value: 42, label: "Q4")
     ]
     default:
     return []
     }
     }
     
     func getWeightChartData(for period: String) -> [ChartDataPoint] {
     switch period {
     case "day":
     return [
     ChartDataPoint(value: 70.2, label: "Mon"),
     ChartDataPoint(value: 70.1, label: "Tue"),
     ChartDataPoint(value: 69.8, label: "Wed"),
     ChartDataPoint(value: 70.0, label: "Thu"),
     ChartDataPoint(value: 69.9, label: "Fri"),
     ChartDataPoint(value: 70.3, label: "Sat"),
     ChartDataPoint(value: 70.1, label: "Sun")
     ]
     case "month":
     return [
     ChartDataPoint(value: 71.0, label: "Week 1"),
     ChartDataPoint(value: 70.5, label: "Week 2"),
     ChartDataPoint(value: 70.2, label: "Week 3"),
     ChartDataPoint(value: 70.0, label: "Week 4")
     ]
     case "year":
     return [
     ChartDataPoint(value: 72.5, label: "Q1"),
     ChartDataPoint(value: 71.8, label: "Q2"),
     ChartDataPoint(value: 70.5, label: "Q3"),
     ChartDataPoint(value: 70.0, label: "Q4")
     ]
     default:
     return []
     }
     }
     
     func getDefaultChartData(for period: String) -> [ChartDataPoint] {
     switch period {
     case "day":
     return [
     ChartDataPoint(value: 85, label: "Mon"),
     ChartDataPoint(value: 92, label: "Tue"),
     ChartDataPoint(value: 78, label: "Wed"),
     ChartDataPoint(value: 88, label: "Thu"),
     ChartDataPoint(value: 95, label: "Fri"),
     ChartDataPoint(value: 90, label: "Sat"),
     ChartDataPoint(value: 82, label: "Sun")
     ]
     case "month":
     return [
     ChartDataPoint(value: 82, label: "Week 1"),
     ChartDataPoint(value: 88, label: "Week 2"),
     ChartDataPoint(value: 85, label: "Week 3"),
     ChartDataPoint(value: 90, label: "Week 4")
     ]
     case "year":
     return [
     ChartDataPoint(value: 80, label: "Q1"),
     ChartDataPoint(value: 85, label: "Q2"),
     ChartDataPoint(value: 88, label: "Q3"),
     ChartDataPoint(value: 90, label: "Q4")
     ]
     default:
     return []
     }
     }
     */
}

// MARK: - Chart Data Model
struct ChartDataPoint {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
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
//            DashboardView()
        }
    }
}

extension LinearGradient {
    static var customBlueToDarkGray: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#3B77A3"),  // top blue
                Color.black.opacity(0.8),
                Color.black.opacity(0.9)   // bottom gray/black
            ],
            startPoint: .topLeading,     // Blue in top-left
            endPoint: .bottomTrailing    // Dark toward bottom-right
        )
    }
    
    static var dateNavLinearGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#318AFC"),
                Color(hex: "#18EF47").opacity(0.58)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

enum NavigationRoute: Hashable {
    case detailedAnalysis
    case metricDetail(type: HealthMetricType, period: ImpactDataPoint.PeriodType)
    case profile
    case subscription
}
