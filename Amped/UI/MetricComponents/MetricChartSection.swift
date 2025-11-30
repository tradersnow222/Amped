import Foundation
import SwiftUI
import Charts

// Visualizes historical data for a health metric (split red/green, zero baseline, soft gradient)
struct MetricChartSection: View {
    // MARK: - Properties
    
    let metricType: HealthMetricType
    let dataPoints: [MetricDataPoint]
    let period: ImpactDataPoint.PeriodType
    var chartHeight: CGFloat = 300
    
    // Interaction state
    @State private var selectedIndex: Int? = nil
    @State private var lastHapticsIndex: Int? = nil
    
    // NEW chart data model
    // Transform raw values into delta around the period-aware target/baseline so negatives plot below zero (red)
    private var chartData: [ChartDataPoint] {
        let target = metricType.targetValue(for: period) ?? metricType.baselineValue(for: period)
        return dataPoints.map { src in
            let delta: Double
            if metricType.isHigherBetter {
                // Higher is better: under target => negative
                delta = src.value - target
            } else {
                // Lower is better: above target => negative
                delta = target - src.value
            }
            return ChartDataPoint(
                date: src.date,
                value: delta,
                label: formattedXAxisLabel(for: src.date)
            )
        }
    }
    
    // MARK: - Precomputed Y Domain (fixes mutual dependency crash)
    
    private var yDomain: (min: Double, max: Double) {
        let values = chartData.map { $0.value }
        let rawMin = values.min() ?? -1
        let rawMax = values.max() ?? 1
        // Make domain symmetric around zero with padding
        let maxAbs = max(abs(rawMin), abs(rawMax), 1.0)
        let padded = maxAbs * 1.1
        return (-padded, padded)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            chartView
        }
    }
    
    // MARK: - Chart
    
    private var chartView: some View {
        Group {
            if chartData.isEmpty {
                VStack {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No historical data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        yAxisLabelsView
                        mainChartView
                    }
                    .padding(16)
                    .background(chartBackground)
                    .overlay(chartBorder)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: chartHeight)
    }
    
    // MARK: - Custom Y Axis Labels (left side, stacked)
    
    private var yAxisLabelsView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(yTicks.reversed(), id: \.self) { v in
                Text(formatYAxisTick(v))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxHeight: .infinity, alignment: .center)
            }
        }
        .frame(width: 42)
    }
    
    // MARK: - Main Chart
    
    private var mainChartView: some View {
        let segments = splitSegmentsBySign(chartData)
        
        return Chart {
            // Negative area
            ForEach(segments.neg) { seg in
                ForEach(Array(seg.points.enumerated()), id: \.offset) { _, p in
                    AreaMark(
                        x: .value("Time", idxGlobal(of: p)),
                        yStart: .value("Zero", 0.0),
                        yEnd: .value("Delta", p.value)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [Color.red.opacity(0.35), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }
            }
            
            // Positive area
            ForEach(segments.pos) { seg in
                ForEach(Array(seg.points.enumerated()), id: \.offset) { _, p in
                    AreaMark(
                        x: .value("Time", idxGlobal(of: p)),
                        yStart: .value("Zero", 0.0),
                        yEnd: .value("Delta", p.value)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [Color.green.opacity(0.35), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                }
            }
            
            // Negative line
            ForEach(segments.neg) { seg in
                ForEach(Array(seg.points.enumerated()), id: \.offset) { _, p in
                    LineMark(
                        x: .value("Time", idxGlobal(of: p)),
                        y: .value("Delta", p.value)
                    )
                    .foregroundStyle(Color.red)
                    .lineStyle(StrokeStyle(lineWidth: 2.3, lineCap: .round))
                }
            }
            
            // Positive line
            ForEach(segments.pos) { seg in
                ForEach(Array(seg.points.enumerated()), id: \.offset) { _, p in
                    LineMark(
                        x: .value("Time", idxGlobal(of: p)),
                        y: .value("Delta", p.value)
                    )
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 2.3, lineCap: .round))
                }
            }
            
            // Zero baseline (dashed)
            RuleMark(y: .value("Zero", 0.0))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(Color.white.opacity(0.35))
            
            // Selection crosshair + marker + annotation
            if let idx = selectedIndex, idx >= 0, idx < chartData.count {
                let point = chartData[idx]
                
                RuleMark(x: .value("Selected", idx))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                
                PointMark(
                    x: .value("Selected", idx),
                    y: .value("Delta", point.value)
                )
                .symbolSize(64)
                .foregroundStyle(point.value >= 0 ? Color.green : Color.red)
                .annotation(position: .top, alignment: .leading) {
                    selectionCallout(forIndex: idx)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisMarkValues) { value in
                if let idx = value.as(Int.self), idx < chartData.count {
                    AxisValueLabel {
                        Text(chartData[idx].label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    AxisGridLine().foregroundStyle(Color.clear)
                    AxisTick().foregroundStyle(Color.clear)
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: yDomain.min...yDomain.max)
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.015)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        // Interactive overlay to select nearest point by drag/tap
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateSelection(at: value.location, in: geo, proxy: proxy)
                            }
                            .onEnded { _ in
                                // Keep last selection; double-tap clears
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.easeOut(duration: 0.15)) {
                            selectedIndex = nil
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selectedIndex)
    }
    
    // MARK: - X Axis
    
    private var xAxisMarkValues: [Int] {
        let total = chartData.count
        guard total > 0 else { return [] }
        let step = max(xStride(for: total), 1)
        return Array(stride(from: 0, to: total, by: step))
    }
    
    private func xStride(for total: Int) -> Int {
        switch period {
        case .day:
            if total > 16 { return max(total / 6, 1) }
            if total > 8 { return 2 }
            return 1
        case .month:
            if total > 24 { return max(total / 8, 1) }
            if total > 12 { return 3 }
            return 2
        case .year:
            return max(total / 6, 1)
        }
    }
    
    // MARK: - Y Ticks
    
    private var yTicks: [Double] {
        let minV = yDomain.min
        let maxV = yDomain.max
        let steps = 7 // 3 above, 0, 3 below
        guard steps > 1 else { return [0] }
        let strideVal = (maxV - minV) / Double(steps - 1)
        return (0..<steps).map { i in minV + Double(i) * strideVal }
    }
    
    private func formatYAxisTick(_ value: Double) -> String {
        // For sleep: show hours/minutes like +2.3hr, +50min, -1.7hr
        switch metricType {
        case .sleepHours:
            let hours = value
            let absHours = abs(hours)
            if absHours < (1.0 / 12.0) { // <5 min ~ show 0
                return "0"
            } else if absHours < 1.0 {
                let minutes = absHours * 60.0
                let sign = value >= 0 ? "+" : "−"
                return "\(sign)\(Int(round(minutes)))min"
            } else {
                let sign = value >= 0 ? "+" : "−"
                return String(format: "\(sign)%.1fhr", absHours)
            }
        case .steps:
            let sign = value >= 0 ? "+" : "−"
            let absVal = abs(value)
            if absVal >= 1000 {
                return String(format: "\(sign)%.1fk", absVal / 1000)
            } else {
                return "\(sign)\(Int(absVal))"
            }
        default:
            let sign = value >= 0 ? "+" : "−"
            if abs(value) < 1 {
                return "0"
            }
            if abs(value) >= 1000 {
                return String(format: "\(sign)%.1fk", abs(value) / 1000)
            } else {
                return String(format: "\(sign)%.0f", abs(value))
            }
        }
    }
    
    // MARK: - Background & Border
    
    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.03))
    }
    
    private var chartBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
    }
    
    // MARK: - Helpers
    
    private func formattedXAxisLabel(for date: Date) -> String {
        let f = DateFormatter()
        switch period {
        case .day:   f.dateFormat = "ha"
        case .month: f.dateFormat = "d"
        case .year:  f.dateFormat = "MMM"
        }
        return f.string(from: date)
    }
    
    // Split the series into contiguous positive/negative segments for separate styling
    private struct Segment: Identifiable {
        let id = UUID()
        let points: [ChartDataPoint]
        let isPositive: Bool
    }
    
    private func splitSegmentsBySign(_ points: [ChartDataPoint]) -> (pos: [Segment], neg: [Segment]) {
        guard !points.isEmpty else { return ([], []) }
        var pos: [Segment] = []
        var neg: [Segment] = []
        
        var current: [ChartDataPoint] = []
        var currentSign: Bool = points[0].value >= 0
        
        for (i, p) in points.enumerated() {
            if i > 0 {
                let prev = points[i - 1]
                if (prev.value < 0 && p.value > 0) || (prev.value > 0 && p.value < 0) {
                    if let cross = interpolateZeroCrossing(p1: prev, p2: p) {
                        current.append(cross)
                        if currentSign {
                            pos.append(Segment(points: current, isPositive: true))
                        } else {
                            neg.append(Segment(points: current, isPositive: false))
                        }
                        current = [cross]
                        currentSign.toggle()
                    }
                }
            }
            if (p.value >= 0) == currentSign || current.isEmpty {
                current.append(p)
            } else {
                if currentSign {
                    pos.append(Segment(points: current, isPositive: true))
                } else {
                    neg.append(Segment(points: current, isPositive: false))
                }
                current = [p]
                currentSign = p.value >= 0
            }
        }
        if !current.isEmpty {
            if currentSign {
                pos.append(Segment(points: current, isPositive: true))
            } else {
                neg.append(Segment(points: current, isPositive: false))
            }
        }
        return (pos, neg)
    }
    
    private func interpolateZeroCrossing(p1: ChartDataPoint, p2: ChartDataPoint) -> ChartDataPoint? {
        let y1 = p1.value
        let y2 = p2.value
        let dy = y2 - y1
        guard dy != 0 else { return nil }
        
        let t = -y1 / dy
        let dt = p2.date.timeIntervalSince(p1.date)
        let crossDate = p1.date.addingTimeInterval(dt * t)
        return ChartDataPoint(date: crossDate, value: 0.0, label: formattedXAxisLabel(for: crossDate))
    }
    
    private func idxGlobal(of point: ChartDataPoint) -> Int {
        if let idx = chartData.firstIndex(where: { $0.date == point.date && $0.value == point.value }) {
            return idx
        }
        let nearest = chartData.enumerated().min {
            abs($0.element.date.timeIntervalSince(point.date)) < abs($1.element.date.timeIntervalSince(point.date))
        }
        return nearest?.offset ?? 0
    }
    
    // MARK: - Interaction helpers
    
    private func updateSelection(at location: CGPoint, in geo: GeometryProxy, proxy: ChartProxy) {
        // Resolve the plot area frame from the anchor
        let plotFrame: CGRect = geo[proxy.plotAreaFrame]
        
        // Ensure the location is inside the plot area
        guard plotFrame.contains(location) else {
            return
        }
        
        // Convert to plot-area-local X
        let xInPlot = location.x - plotFrame.origin.x
        
        // Resolve x value (Int index) from the proxy
        if let value = proxy.value(atX: xInPlot, as: Int.self) {
            let clamped = max(0, min(value, chartData.count - 1))
            setSelectedIndex(clamped)
        } else if let valueDouble = proxy.value(atX: xInPlot, as: Double.self) {
            let rounded = Int(round(valueDouble))
            let clamped = max(0, min(rounded, chartData.count - 1))
            setSelectedIndex(clamped)
        }
    }
    
    private func setSelectedIndex(_ idx: Int) {
        if selectedIndex != idx {
            selectedIndex = idx
            // Light haptic when moving to a new point
            if lastHapticsIndex != idx {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                lastHapticsIndex = idx
            }
        }
    }
    
    @ViewBuilder
    private func selectionCallout(forIndex idx: Int) -> some View {
        let delta = chartData[idx].value
        // Recover original value from source array (same order)
        let originalValue = (idx < dataPoints.count) ? dataPoints[idx].value : nil
        let titleText = chartData[idx].label
        let isPositive = delta >= 0
        
        VStack(alignment: .leading, spacing: 4) {
            Text(titleText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
            
            // Value lines
            if let v = originalValue {
                Text(originalFormatted(v))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text("Δ \(formatYAxisTick(delta))")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isPositive ? Color.green : Color.red)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black.opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func originalFormatted(_ value: Double) -> String {
        switch metricType {
        case .sleepHours:
            // Show hours with one decimal
            return String(format: "%.1f hr", value)
        case .steps:
            let int = Int(round(value))
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            return (formatter.string(from: NSNumber(value: int)) ?? "\(int)") + " steps"
        case .activeEnergyBurned:
            return String(format: "%.0f kcal", value)
        case .exerciseMinutes:
            return String(format: "%.0f min", value)
        case .restingHeartRate:
            return String(format: "%.0f BPM", value)
        case .heartRateVariability:
            return String(format: "%.0f ms", value)
        case .vo2Max:
            return String(format: "%.0f ml/kg/min", value)
        case .oxygenSaturation:
            return String(format: "%.0f%%", value)
        case .bodyMass:
            return String(format: "%.1f kg", value)
        default:
            // Generic numeric
            if abs(value) >= 1000 {
                return String(format: "%.1fk", value / 1000.0)
            } else if abs(value) >= 1 {
                return String(format: "%.0f", value)
            } else {
                return String(format: "%.2f", value)
            }
        }
    }
}

// MARK: - Data Model used by MetricChartSection

struct MetricDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview {
    VStack {
        MetricChartSection(
            metricType: .steps,
            dataPoints: [
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!, value: 8500),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, value: 9200),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, value: 7800),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, value: 7300),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, value: 9800),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, value: 11200),
                MetricDataPoint(date: Date(), value: 10500)
            ],
            period: .year
        )
        
        MetricChartSection(
            metricType: .sleepHours,
            dataPoints: [
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -6, to: Date())!, value: 6.3),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -5, to: Date())!, value: 6.8),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -4, to: Date())!, value: 6.2),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -3, to: Date())!, value: 6.4),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!, value: 7.1),
                MetricDataPoint(date: Calendar.current.date(byAdding: .month, value: -1, to: Date())!, value: 7.6),
                MetricDataPoint(date: Date(), value: 7.4)
            ],
            period: .year
        )
        
        MetricChartSection(
            metricType: .restingHeartRate,
            dataPoints: [],
            period: .day
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
