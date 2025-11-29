import SwiftUI
import Combine

struct MetricGridView: View {
    @State private var selectedPeriod: ImpactDataPoint.PeriodType = .day
    @StateObject private var viewModel = DashboardViewModel()
    var onCardTap: ((String, ImpactDataPoint.PeriodType, HealthMetric?) -> Void)? = nil
    var onTapUnlock: (() -> Void)?
    
    @EnvironmentObject var appState: AppState
    
    private struct CardData: Identifiable {
        let id = UUID()
        let type: HealthMetricType
        let healthMetric: HealthMetric?
        let title: String
        let icon: String
        let value: String
        let changeText: String
        let foregroundColor: Color
        let isPositive: Bool
        let unit: String
    }

    private var cards: [CardData] {
        // Target metric order similar to DashboardView
        let targetMetrics: [HealthMetricType] = [.restingHeartRate, .steps, .activeEnergyBurned, .sleepHours, .vo2Max, .bodyMass]

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
            // These map to your existing asset names used by MetricCard (e.g., "heartRateIcon", "stepsIcon", etc.)
            switch type {
            case .restingHeartRate: return "heartRateIcon"
            case .steps: return "stepsIcon"
            case .activeEnergyBurned: return "activityIcon"
            case .sleepHours: return "sleepIcon"
            case .vo2Max: return "cardioIcon"
            case .bodyMass: return "weightIcon"
            default: return "heartRateIcon"
            }
        }
        
        func metricUnit(for type: HealthMetricType) -> String {
            // These map to your existing asset names used by MetricCard (e.g., "heartRateIcon", "stepsIcon", etc.)
            switch type {
            case .restingHeartRate: return "BPM"
            case .steps: return ""
            case .activeEnergyBurned: return "Kcal"
            case .sleepHours: return ""
            case .vo2Max: return ""
            case .bodyMass: return "KG"
            default: return ""
            }
        }

        return targetMetrics.map { metricType in
            if let metric = viewModel.healthMetrics.first(where: { $0.type == metricType }) {
                let minutes = metric.impactDetails?.lifespanImpactMinutes ?? 0
                let isPositive = minutes >= 0
                let changeText = String(format: "%@%.0f mins %@", isPositive ? "↑" : "↓", abs(minutes), isPositive ? "gained" : "lost")
                return CardData(
                    type: metricType,
                    healthMetric: metric,
                    title: title(for: metricType),
                    icon: iconName(for: metricType),
                    value: metric.formattedValue,
                    changeText: changeText,
                    foregroundColor: isPositive ? Color(hex: "#18EF47") : Color(hex: "#F52828"),
                    isPositive: isPositive,
                    unit: metricUnit(for: metricType)
                )
            } else {
                // Placeholder when no data exists
                return CardData(
                    type: metricType,
                    healthMetric: nil,
                    title: title(for: metricType),
                    icon: iconName(for: metricType),
                    value: "--",
                    changeText: "No data",
                    foregroundColor: .gray,
                    isPositive: true,
                    unit: ""
                )
            }
        }
    }
    
    var body: some View {
        ZStack {
//            Color.black.ignoresSafeArea()
//            LinearGradient.customBlueToDarkGray.ignoresSafeArea()
            if !appState.isPremiumUser {
                UnlockSubscriptionView {
                    // Got to subscription
                    onTapUnlock?()
                }
            } else {
                VStack(spacing: 0) {
                    
                    // Header
                    personalizedHeader
                    
                    // Date navigation bar
                    dateNavigationBar
                    
                    ScrollView {
                        
                        // Metrics Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 1) {
                            ForEach(cards) { card in
                                NavigationLink {
                                    if let healthMetric = card.healthMetric {
                                        MetricDetailsView(metric: healthMetric, selectedPeriod: selectedPeriod)
                                    }
                                } label: {
                                    MetricCard(
                                        icon: card.icon,
                                        title: card.title,
                                        value: card.value,
                                        change: card.changeText,
                                        unit: card.unit,
                                        isPositive: card.isPositive,
                                        badge: nil,
                                        foregroundColor: card.foregroundColor,
                                        miniChartMetric: card.healthMetric,
                                        miniChartPeriod: selectedPeriod
                                    )
                                }
                                .disabled(card.healthMetric == nil)
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 100)
                        .background(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(Color.white.opacity(0.08))       // light glass layer
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                                .padding(.horizontal, 12)
                                .padding(.bottom, 90)
                        )
                    }
                }
            }
        }
    }
    
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: false)
            .padding(.top, 10)
    }
    
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
                                .fill(
                                    LinearGradient.dateNavLinearGradient
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
}

struct PeriodButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : Color.gray)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    Group {
                        if isSelected {
                            LinearGradient(
                                colors: [Color(hex: "22D3EE"), Color(hex: "3B82F6")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(Capsule())
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let change: String
    let unit: String
    let isPositive: Bool
    var badge: String? = nil
    let foregroundColor: Color
    
    // NEW: Optional live mini chart inputs (defaults keep existing call sites working)
    var miniChartMetric: HealthMetric? = nil
    var miniChartPeriod: ImpactDataPoint.PeriodType? = nil
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: "#828282").opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    // Icon
                    Image(icon)
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                    
                    Spacer()
                }
                .padding(.bottom, 16)
                
                // Title with badge
                HStack(spacing: 8) {
                    Text(title)
                        .font(.poppins(14))
                        .foregroundColor(Color.white)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.poppins(20, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(hex: "3B82F6"))
                            .clipShape(Capsule())
                    }
                }
                .padding(.bottom, 4)
                
                // Value
                Text(value+" "+unit)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.bottom, 12)
                
                // Change
                Text(change)
                    .font(.poppins(16))
                    .foregroundColor(foregroundColor)
                    .padding(.bottom, 2)
                
                // Chart
                ZStack(alignment: .bottomTrailing) {
                    if let metric = miniChartMetric, let period = miniChartPeriod {
                        MiniMetricSparklineView(
                            metric: metric,
                            period: period,
                            lineColor: foregroundColor
                        )
                        .frame(height: 48)
                    } else {
                        // Graceful fallback placeholder (keeps UI identical)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 1.5)
                            .offset(y: 23) // center-ish baseline
                    }
                }
            }
            .padding(20)
        }
        .frame(height: 220)
        .padding(.bottom, 12)
    }
}

// Live mini sparkline that uses the same data source as the full chart
private struct MiniMetricSparklineView: View {
    let metric: HealthMetric
    let period: ImpactDataPoint.PeriodType
    let lineColor: Color
    
    // IMPORTANT: Use the same view model so data matches full detail view
    @StateObject private var vm: MetricDetailViewModel
    
    init(metric: HealthMetric, period: ImpactDataPoint.PeriodType, lineColor: Color) {
        self.metric = metric
        self.period = period
        self.lineColor = lineColor
        _vm = StateObject(wrappedValue: MetricDetailViewModel(metric: metric, initialPeriod: period))
    }
    
    var body: some View {
        GeometryReader { geo in
            let pts = vm.professionalStyleDataPoints
            let path = sparklinePath(in: geo.size, points: pts)
            
            ZStack(alignment: .topLeading) {
                // Underline / baseline feel similar to previous WaveShape stroke look
                path
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                
                // Colored overlay to make it pop slightly
                path
                    .stroke(lineColor.opacity(0.9), lineWidth: 1.5)
                
                // Trailing dot at the last valid data point (sync with full chart)
                if let lastPoint = lastPointPosition(in: geo.size, points: pts) {
                    Circle()
                        .fill(lineColor)
                        .frame(width: 8, height: 8)
                        .position(x: lastPoint.x, y: lastPoint.y)
                }
            }
        }
        .onAppear {
            vm.loadRealHistoricalData(for: metric, period: period)
        }
        .onChange(of: period) { newPeriod in
            vm.loadRealHistoricalData(for: metric, period: newPeriod)
        }
        .clipped()
    }
    
    private func sparklinePath(in size: CGSize, points: [MetricDataPoint]) -> Path {
        var path = Path()
        guard points.count > 1 else { return path }
        
        // Compute bounds
        let xs = points.map { $0.date.timeIntervalSince1970 }
        let ys = points.map { $0.value }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max(),
              maxX > minX else { return path }
        
        let inset: CGFloat = 2
        let width = size.width - inset * 2
        let height = size.height - inset * 2
        
        // Avoid flat line when min == max
        let yRange = (maxY - minY) == 0 ? 1.0 : (maxY - minY)
        
        func xPos(_ t: TimeInterval) -> CGFloat {
            let p = (t - minX) / (maxX - minX)
            return inset + CGFloat(p) * width
        }
        func yPos(_ v: Double) -> CGFloat {
            let p = (v - minY) / yRange
            // Invert y for drawing
            return inset + height * CGFloat(1.0 - p)
        }
        
        // Move to first
        let first = points.first!
        path.move(to: CGPoint(x: xPos(first.date.timeIntervalSince1970), y: yPos(first.value)))
        
        // Simple line (can be upgraded to smoothing if needed)
        for pt in points.dropFirst() {
            path.addLine(to: CGPoint(x: xPos(pt.date.timeIntervalSince1970), y: yPos(pt.value)))
        }
        
        return path
    }
    
    private func lastPointPosition(in size: CGSize, points: [MetricDataPoint]) -> CGPoint? {
        guard let last = points.last else { return nil }
        let xs = points.map { $0.date.timeIntervalSince1970 }
        let ys = points.map { $0.value }
        guard let minX = xs.min(), let maxX = xs.max(),
              let minY = ys.min(), let maxY = ys.max(),
              maxX > minX else { return nil }
        
        let inset: CGFloat = 2
        let width = size.width - inset * 2
        let height = size.height - inset * 2
        let yRange = (maxY - minY) == 0 ? 1.0 : (maxY - minY)
        
        let xP = (last.date.timeIntervalSince1970 - minX) / (maxX - minX)
        let yP = (last.value - minY) / yRange
        
        let x = inset + CGFloat(xP) * width
        let y = inset + height * CGFloat(1.0 - yP)
        return CGPoint(x: x, y: y)
    }
}

struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.67))
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.2, y: height * 0.6),
            control: CGPoint(x: width * 0.1, y: height * 0.5)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.4, y: height * 0.23),
            control: CGPoint(x: width * 0.3, y: height * 0.6)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.6, y: height * 0.63),
            control: CGPoint(x: width * 0.5, y: height * 0.53)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width * 0.8, y: height * 0.97),
            control: CGPoint(x: width * 0.7, y: height * 0.63)
        )
        
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.5),
            control: CGPoint(x: width * 0.9, y: height * 0.57)
        )
        
        return path
    }
}

#Preview {
    MetricGridView().environmentObject(AppState())
}
