import SwiftUI
import Charts

// MARK: - Chart Data Model
struct ChartDataPoint: Identifiable {
    let id = UUID()
    let value: Double
    let label: String
}

/// Reusable bar chart component for metric detail views
struct MetricBarChart: View {
    // MARK: - Configuration
    let metricTitle: String
    let period: String
    let realChartData: [ChartDataPoint] // Accept real data instead of generating dummy data
    let color: Color
    let isLoading: Bool // Add loading state parameter
    
    // MARK: - State
    @State private var selectedLabel: String?
    
    // MARK: - Body
    var body: some View {
        VStack {
            GeometryReader { containerGeometry in
                ZStack(alignment: .topLeading) {
                    if isLoading {
                        // Loading state with skeleton bars
                        loadingView
                    } else {
                        chartView
                        
                        // Tooltip positioned at center of selected bar
                        if let selectedLabel = selectedLabel,
                           let dataPoint = realChartData.first(where: { $0.label == selectedLabel }) {
                            let barIndex = realChartData.firstIndex(where: { $0.label == selectedLabel }) ?? 0
                            let containerWidth = containerGeometry.size.width
                            let barWidth = containerWidth / CGFloat(realChartData.count)
                            let barCenterX = CGFloat(barIndex) * barWidth + (barWidth / 2)
                            
                            VStack(alignment: .center, spacing: 2) {
                                Text(dataPoint.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(formatAxisValue(dataPoint.value))
                                    .font(.title3.bold())
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                            .shadow(radius: 2)
                            .offset(
                                x: max(10, min(barCenterX - 60, containerWidth - 130)),
                                y: 10
                            )
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                }
            }
            .frame(height: 200) // Back to original height
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                
                // Chart area with skeleton bars
                VStack(spacing: 12) {
                    // Y-axis labels skeleton
                    HStack {
                        VStack(alignment: .trailing, spacing: 8) {
                            ForEach(0..<4, id: \.self) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 30, height: 8)
                                    .shimmerEffect(delay: Double(index) * 0.1)
                            }
                        }
                        .frame(width: 40)
                        
                        // Main chart area
                        VStack(spacing: 8) {
                            // Skeleton bars with two-tone design
                            HStack(alignment: .bottom, spacing: 10) { // Reduced spacing to match tighter X-axis
                                ForEach(0..<6, id: \.self) { index in
                                    VStack(spacing: 0) {
                                        // Upper grey portion (remaining capacity)
                                        RoundedRectangle(cornerRadius: 12) // More rounded corners like remaining space
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(
                                                width: 14, // Thinner bars (14pt width, 26pt gap)
                                                height: getRemainingHeight(for: index)
                                            )
                                            .shimmerEffect(delay: Double(index) * 0.15)
                                        
                                        // Lower yellow portion (data value)
                                        RoundedRectangle(cornerRadius: 12) // More rounded corners like remaining space
                                            .fill(Color.yellow.opacity(0.3))
                                            .frame(
                                                width: 14, // Thinner bars (14pt width, 26pt gap)
                                                height: getRealisticBarHeight(for: index)
                                            )
                                            .shimmerEffect(delay: Double(index) * 0.15)
                                            .pulseEffect(delay: Double(index) * 0.2)
                                    }
                                }
                            }
                            .frame(height: 120) // Back to original height
                            
                            // X-axis labels skeleton
                            HStack(spacing: 8) { // Reduced spacing to match tighter X-axis
                                ForEach(0..<6, id: \.self) { index in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 35, height: 10)
                                        .shimmerEffect(delay: Double(index) * 0.2)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Spacer()
                            .frame(width: 20)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .frame(width: max(300, CGFloat(6) * 50)) // Dynamic width based on expected data points
        }
    }
    
    /// Generate realistic bar heights for loading skeleton
    private func getRealisticBarHeight(for index: Int) -> CGFloat {
        // Create a more realistic distribution of bar heights (data values)
        let heights: [CGFloat] = [50, 70, 45, 80, 55, 65]
        return heights[index % heights.count]
    }
    
    /// Generate remaining height for two-tone skeleton bars
    private func getRemainingHeight(for index: Int) -> CGFloat {
        // Calculate remaining height to complete the bar
        let dataHeight = getRealisticBarHeight(for: index)
        let maxHeight: CGFloat = 100
        return max(0, maxHeight - dataHeight)
    }
    
    
    // MARK: - Chart View (scrollable for long data series)
    private var chartView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Chart {
                ForEach(realChartData) { dataPoint in
                    // Calculate range for two-tone bars - remaining space should fill full grid
                    let maxValue = realChartData.map(\.value).max() ?? dataPoint.value
                    let maxInterval = maxValue < 200 ? maxValue + 50 : maxValue + 1000
                    let remainingValue = maxInterval - dataPoint.value
                    
                    // Data value bar (yellow/lower portion) - fully rounded
                    BarMark(
                        x: .value("Period", dataPoint.label),
                        y: .value("Value", dataPoint.value),
                        width: .ratio(0.35) // Thinner bars (35% width, 65% gap)
                    )
                    .foregroundStyle(Color.yellow)
                    .clipShape(RoundedRectangle(cornerRadius: 12)) // Fully rounded (top and bottom)
                    .opacity(selectedLabel == dataPoint.label ? 1.0 : 0.9)
                    
                    // Remaining capacity bar (dark grey/upper portion) - fully rounded
                    if remainingValue > 0 {
                        BarMark(
                            x: .value("Period", dataPoint.label),
                            y: .value("Remaining", remainingValue),
                            width: .ratio(0.35) // Thinner bars (35% width, 65% gap)
                        )
                        .foregroundStyle(Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 12)) // Fully rounded (top and bottom)
                        .opacity(selectedLabel == dataPoint.label ? 0.8 : 0.6)
                    }
                }
            }
            .chartXAxis {
                xAxisConfiguration
            }
            .chartYAxis {
                yAxisConfiguration
            }
            .frame(width: max(300, CGFloat(realChartData.count) * 35)) // Reduced spacing between data points
            .overlay(
                // Transparent overlay for reliable tap detection with geometry
                GeometryReader { chartGeometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onTapGesture { location in
                            print("🔍 🚨 SCROLLABLE CHART TAP at: \(location)")
                            print("🔍 🚨 Chart has \(realChartData.count) data points")
                            handleScrollableChartTap(at: location, chartWidth: chartGeometry.size.width)
                        }
                }
            )
        }
        .onChange(of: selectedLabel) { _ in
            if selectedLabel != nil {
                // Auto-hide selection after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    selectedLabel = nil
                }
            }
        }
    }
    
    // MARK: - Scrollable Chart Tap Handler
    private func handleScrollableChartTap(at location: CGPoint, chartWidth: CGFloat) {
        print("🔍 🚨 ENTERING scrollable chart tap with location: \(location)")
        print("🔍 🚨 Chart width: \(chartWidth), Data points: \(realChartData.count)")
        
        guard realChartData.count > 0 else { return }
        
        // For scrollable charts, calculate bar width dynamically
        let barWidth = chartWidth / CGFloat(realChartData.count)
        let rawIndex = Int(location.x / barWidth)
        let selectedIndex = max(0, min(rawIndex, realChartData.count - 1))
        
        print("🔍 Bar width: \(barWidth)")
        print("🔍 Raw index: \(rawIndex), Clamped index: \(selectedIndex)")
        
        let selectedPoint = realChartData[selectedIndex]
        selectedLabel = selectedPoint.label
        
        print("🔍 ✅ Selected: \(selectedPoint.label) = \(selectedPoint.value)")
    }
    
    // MARK: - Accurate Tap Handler (using real chart width)
    private func handleAccurateTap(at location: CGPoint, chartWidth: CGFloat) {
        print("🔍 🚨 ENTERING handleAccurateTap with location: \(location)")
        print("🔍 🚨 Using REAL chart width: \(chartWidth)")
        
        guard realChartData.count > 0 else { 
            print("🔍 ❌ No chart data available")
            return 
        }
        
        print("🔍 Chart data count: \(realChartData.count)")
        print("🔍 Chart data labels: \(realChartData.map { $0.label })")
        
        // Use the actual chart width for precise calculation
        let barWidth = chartWidth / CGFloat(realChartData.count)
        let rawIndex = Int(location.x / barWidth)
        
        // Clamp the index to valid range to handle edge cases (especially the last bar)
        let selectedIndex = max(0, min(rawIndex, realChartData.count - 1))
        
        print("🔍 Actual chart width: \(chartWidth)")
        print("🔍 Bar width: \(barWidth)")
        print("🔍 Raw calculated index: \(rawIndex)")
        print("🔍 Clamped index: \(selectedIndex)")
        print("🔍 Valid range: 0 to \(realChartData.count - 1)")
        
        let selectedPoint = realChartData[selectedIndex]
        print("🔍 🚨 SETTING selectedLabel to: \(selectedPoint.label)")
        selectedLabel = selectedPoint.label
        print("🔍 🚨 selectedLabel is now: \(selectedLabel ?? "nil")")
        
        print("🔍 ✅ Selected bar \(selectedIndex): \(selectedPoint.label) = \(selectedPoint.value)")
        
        // Debug: Show where each bar should be
        for (index, dataPoint) in realChartData.enumerated() {
            let barStart = CGFloat(index) * barWidth
            let barEnd = CGFloat(index + 1) * barWidth
            print("🔍 Bar \(index) (\(dataPoint.label)): X range \(barStart) to \(barEnd)")
        }
    }
    
    // MARK: - Simplified Tap Handler (with detailed debugging - backup)
    private func handleSimplifiedTap(at location: CGPoint) {
        print("🔍 🚨 ENTERING handleSimplifiedTap with location: \(location)")
        
        guard realChartData.count > 0 else { 
            print("🔍 ❌ No chart data available")
            return 
        }
        
        print("🔍 Chart data count: \(realChartData.count)")
        print("🔍 Chart data labels: \(realChartData.map { $0.label })")
        
        // Use a reasonable estimate for chart width (will be close enough for tap detection)
        // The exact positioning will be handled by the tooltip calculation using actual geometry
        let estimatedChartWidth: CGFloat = 300
        let barWidth = estimatedChartWidth / CGFloat(realChartData.count)
        let rawIndex = Int(location.x / barWidth)
        
        // Clamp the index to valid range to handle edge cases (especially the last bar)
        let selectedIndex = max(0, min(rawIndex, realChartData.count - 1))
        
        print("🔍 Estimated chart width: \(estimatedChartWidth)")
        print("🔍 Bar width: \(barWidth)")
        print("🔍 Raw calculated index: \(rawIndex)")
        print("🔍 Clamped index: \(selectedIndex)")
        print("🔍 Valid range: 0 to \(realChartData.count - 1)")
        
        if selectedIndex >= 0 && selectedIndex < realChartData.count {
            let selectedPoint = realChartData[selectedIndex]
            print("🔍 🚨 SETTING selectedLabel to: \(selectedPoint.label)")
            selectedLabel = selectedPoint.label
            print("🔍 🚨 selectedLabel is now: \(selectedLabel ?? "nil")")
            
            print("🔍 ✅ Selected bar \(selectedIndex): \(selectedPoint.label) = \(selectedPoint.value)")
            print("🔍 Tooltip will be positioned using actual container geometry")
        } else {
            print("🔍 ❌ Index out of bounds: \(selectedIndex) (valid range: 0-\(realChartData.count-1))")
        }
    }
    
    // MARK: - Position-Based Tap Handler (with actual chart width)
    private func handlePositionBasedTap(at location: CGPoint, chartWidth: CGFloat) {
        guard realChartData.count > 0 else { return }
        
        // Use actual chart width for accurate calculation
        let barWidth = chartWidth / CGFloat(realChartData.count)
        let selectedIndex = Int(location.x / barWidth)
        
        print("🔍 Position-based tap at: \(location)")
        print("🔍 Actual chart width: \(chartWidth)")
        print("🔍 Bar width: \(barWidth)")
        print("🔍 Calculated index: \(selectedIndex)")
        
        if selectedIndex >= 0 && selectedIndex < realChartData.count {
            let selectedPoint = realChartData[selectedIndex]
            selectedLabel = selectedPoint.label
            
            // Calculate where the tooltip should appear
            let barCenterX = CGFloat(selectedIndex) * barWidth + (barWidth / 2)
            print("🔍 ✅ Selected bar \(selectedIndex): \(selectedPoint.label) = \(selectedPoint.value)")
            print("🔍 Bar center will be at X: \(barCenterX)")
        } else {
            print("🔍 ❌ Index out of bounds: \(selectedIndex)")
        }
    }
    
    // MARK: - Direct Tap Handler (Simplified - Backup)
    private func handleDirectTap(at location: CGPoint) {
        guard realChartData.count > 0 else { return }
        
        // For now, just cycle through the data points to test
        // This is a simple approach to verify tap detection is working
        if let currentIndex = realChartData.firstIndex(where: { $0.label == selectedLabel }) {
            let nextIndex = (currentIndex + 1) % realChartData.count
            selectedLabel = realChartData[nextIndex].label
            print("🔍 ✅ Cycling to next: \(realChartData[nextIndex].label)")
        } else {
            // Select first item if nothing is selected
            selectedLabel = realChartData.first?.label
            print("🔍 ✅ Selecting first: \(realChartData.first?.label ?? "none")")
        }
    }
    
    // MARK: - Overlay Tap Handler (Simplified)
    private func handleOverlayTap(at location: CGPoint, geometry: GeometryProxy) {
        guard realChartData.count > 0 else { return }
        
        // Simple calculation assuming chart uses most of the available width
        let chartWidth = geometry.size.width
        let barWidth = chartWidth / CGFloat(realChartData.count)
        let selectedIndex = Int(location.x / barWidth)
        
        print("🔍 Overlay tap at: \(location)")
        print("🔍 Chart width: \(chartWidth), Bar width: \(barWidth)")
        print("🔍 Calculated index: \(selectedIndex)")
        
        if selectedIndex >= 0 && selectedIndex < realChartData.count {
            let selectedPoint = realChartData[selectedIndex]
            selectedLabel = selectedPoint.label
            
            print("🔍 ✅ Selected: \(selectedPoint.label) = \(selectedPoint.value)")
        } else {
            print("🔍 ❌ Index out of bounds: \(selectedIndex)")
        }
    }
    
    // MARK: - Axis Configurations
    private var xAxisConfiguration: some AxisContent {
        AxisMarks { _ in
            // Remove grid lines for cleaner look
            AxisValueLabel()
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    private var yAxisConfiguration: some AxisContent {
        AxisMarks(position: .leading, values: yAxisValues) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [1, 3]))
                .foregroundStyle(.white.opacity(0.15))
            
            AxisValueLabel(anchor: .trailing) {
                Text(formatYAxisValue(value.as(Double.self) ?? 0))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
    
    /// Generate Y-axis values for grid-like appearance
    private var yAxisValues: [Double] {
        guard !realChartData.isEmpty else { 
            // Fallback with reasonable default range
            return [0, 500, 1000, 1500, 2000]
        }
        
        let maxValue = realChartData.map(\.value).max() ?? 1000
        
        // Determine appropriate interval size based on data range
        let intervalSize: Double
        let maxInterval: Double
        
        if maxValue < 200 {
            // For smaller values (< 200), use 50-unit intervals for better granularity
            intervalSize = 50
            maxInterval = maxValue + 50
        } else {
            // For larger values (≥ 200), use 500-unit intervals
            intervalSize = 500
            maxInterval = maxValue + 1000
        }
        
        // Create intervals based on determined size
        let numberOfIntervals = Int(maxInterval / intervalSize)
        
        var intervals: [Double] = []
        for i in 0...numberOfIntervals {
            intervals.append(Double(i) * intervalSize)
        }
        
        return intervals
    }
    
    /// Format Y-axis values for display
    private func formatYAxisValue(_ value: Double) -> String {
        // Determine which intervals to show labels for based on data range
        let maxValue = realChartData.map(\.value).max() ?? 1000
        let shouldShowLabel: Bool
        
        if maxValue < 200 {
            // For smaller values (< 200), show labels at 50-unit intervals
            shouldShowLabel = Int(value) % 50 == 0
        } else {
            // For larger values (≥ 200), show labels at 1000-unit intervals
            shouldShowLabel = Int(value) % 1000 == 0
        }
        
        guard shouldShowLabel else { return "" }
        
        switch metricTitle.lowercased() {
        case "steps":
            if value >= 1000 {
                return String(format: "%.0fK", value / 1000)
            } else {
                return String(format: "%.0f", value)
            }
        case "active energy":
            if value >= 1000 {
                return String(format: "%.0fK", value / 1000)
            } else {
                return String(format: "%.0f", value)
            }
        case "sleep":
            return String(format: "%.0f", value)
        case "heart rate":
            return String(format: "%.0f", value)
        case "cardio (vo2)":
            return String(format: "%.0f", value)
        case "weight":
            return String(format: "%.0f", value)
        default:
            if value >= 1000 {
                return String(format: "%.0fK", value / 1000)
            } else {
                return String(format: "%.0f", value)
            }
        }
    }
    
    
    // MARK: - Private Methods
    
    
    /// Format axis values for display
    private func formatAxisValue(_ value: Double) -> String {
        switch metricTitle.lowercased() {
        case "steps":
            if value >= 1000 {
                return String(format: "%.1fK", value / 1000)
            } else {
                return String(format: "%.0f", value)
            }
        case "active energy":
            return String(format: "%.0f", value)
        case "sleep":
            return String(format: "%.1fh", value)
        case "heart rate":
            return String(format: "%.0f", value)
        case "cardio (vo2)":
            return String(format: "%.1f", value)
        case "weight":
            return String(format: "%.1f", value)
        default:
            return String(format: "%.1f", value)
        }
    }
    
}


// MARK: - Preview
#Preview {
    VStack {
        Text("Steps Chart - Daily View")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
        
        MetricBarChart(
            metricTitle: "Steps",
            period: "day",
            realChartData: [ChartDataPoint(value: 8000, label: "Today (Jan 15)")],
            color: .blue,
            isLoading: false
        )
        .padding()
        
        Text("Steps Chart - Monthly View")
            .font(.headline)
            .foregroundColor(.white)
            .padding()
        
        MetricBarChart(
            metricTitle: "Steps",
            period: "month",
            realChartData: [
                ChartDataPoint(value: 7500, label: "Week 1"),
                ChartDataPoint(value: 8200, label: "Week 2"),
                ChartDataPoint(value: 7800, label: "Week 3"),
                ChartDataPoint(value: 8100, label: "Week 4")
            ],
            color: .blue,
            isLoading: false
        )
        .padding()
    }
    .background(Color.black)
}

// MARK: - Loading Animation Extensions
extension View {
    func shimmerEffect(delay: Double = 0.0) -> some View {
        self
            .overlay(
                ShimmerOverlay(delay: delay)
            )
            .clipped()
    }
    
    func pulseEffect(delay: Double = 0.0) -> some View {
        self
            .overlay(
                PulseOverlay(delay: delay)
            )
    }
}

struct ShimmerOverlay: View {
    let delay: Double
    @State private var isAnimating = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0.0),
                Color.white.opacity(0.4),
                Color.white.opacity(0.0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .rotationEffect(.degrees(30))
        .offset(x: isAnimating ? 300 : -200)
        .animation(
            Animation.linear(duration: 1.8)
                .repeatForever(autoreverses: false)
                .delay(delay),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct PulseOverlay: View {
    let delay: Double
    @State private var isPulsing = false
    
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                    .delay(delay),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct LoadingDotsView: View {
    @State private var animatingDots: [Bool] = [false, false, false]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .scaleEffect(animatingDots[index] ? 1.3 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: animatingDots[index]
                    )
            }
        }
        .onAppear {
            animatingDots = [true, true, true]
        }
    }
}
