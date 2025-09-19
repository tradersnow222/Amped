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
    
    // MARK: - State
    @State private var selectedLabel: String?
    
    // MARK: - Body
    var body: some View {
        VStack {
            GeometryReader { containerGeometry in
                ZStack(alignment: .topLeading) {
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
                        
                        // Debug: Show the positioning calculation
                        .onAppear {
                            print("🔍 Tooltip positioning:")
                            print("   - Container width: \(containerWidth)")
                            print("   - Bar width: \(barWidth)")
                            print("   - Bar index: \(barIndex)")
                            print("   - Bar center X: \(barCenterX)")
                            print("   - Final tooltip X: \(max(10, min(barCenterX - 60, containerWidth - 130)))")
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }
    
    // MARK: - Chart View (scrollable for long data series)
    private var chartView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Chart {
                ForEach(realChartData) { dataPoint in
                    BarMark(
                        x: .value("Period", dataPoint.label),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(color)
                    .cornerRadius(3)
                    .opacity(selectedLabel == dataPoint.label ? 1.0 : 0.8)
                }
            }
            .chartXAxis {
                xAxisConfiguration
            }
            .chartYAxis {
                yAxisConfiguration
            }
            .frame(width: max(300, CGFloat(realChartData.count) * 40)) // Dynamic width based on data points
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
            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                .foregroundStyle(.white.opacity(0.1))
            AxisTick(stroke: StrokeStyle(lineWidth: 1))
                .foregroundStyle(.white.opacity(0.3))
            AxisValueLabel()
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
    
    private var yAxisConfiguration: some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                .foregroundStyle(.white.opacity(0.1))
            AxisTick(stroke: StrokeStyle(lineWidth: 1))
                .foregroundStyle(.white.opacity(0.3))
            AxisValueLabel(anchor: .trailing) {
                Text(formatAxisValue(value.as(Double.self) ?? 0))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
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
            color: .blue
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
            color: .blue
        )
        .padding()
    }
    .background(Color.black)
}
