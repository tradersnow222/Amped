import Foundation
import SwiftUI
import Charts


// MARK: - Data Model used by MetricChartSection

struct MetricDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

#Preview("Metric Chart Testing") {
    ScrollView {
        VStack(spacing: 32) {
            
            // STEPS
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
            .frame(height: 260)
            .padding()
            .background(.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            
            // SLEEP HOURS
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
            .frame(height: 260)
            .padding()
            .background(.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
            
            // EMPTY DATA
            MetricChartSection(
                metricType: .restingHeartRate,
                dataPoints: [],
                period: .day
            )
            .frame(height: 260)
            .padding()
            .background(.black.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}



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
    
    // NEW — selection for line-only chart
    @State private var selectedPoint: ChartDataPoint? = nil
    
    // Determine if this is a manual metric from questionnaire
    private var isManualMetric: Bool {
        switch metricType {
        case .smokingStatus, .alcoholConsumption, .stressLevel, .nutritionQuality, .socialConnectionsQuality:
            return true
        default:
            return false
        }
    }
    
    // Manual metric: whether higher values are better
    private var manualIsHigherBetter: Bool? {
        switch metricType {
        case .smokingStatus: return true        // 10 = never smoked/best
        case .alcoholConsumption: return true   // higher score = healthier intake
        case .stressLevel: return false         // lower is better
        case .nutritionQuality: return true     // higher is better
        case .socialConnectionsQuality: return true // higher is better
        default: return nil
        }
    }
    
    // Manual metric target values (period-agnostic, reflect best-practice targets used elsewhere in the app)
    private func manualTargetValue(for period: ImpactDataPoint.PeriodType) -> Double? {
        switch metricType {
        case .smokingStatus:
            return 10.0 // abstinent / never
        case .alcoholConsumption:
            return 9.0 // very minimal alcohol
        case .stressLevel:
            return 2.0 // very low stress
        case .nutritionQuality:
            return 9.0 // excellent nutrition quality
        case .socialConnectionsQuality:
            return 8.0 // strong social connections
        default:
            return nil
        }
    }
    
    // Fallback target and direction helpers that prioritize manual metric rules
    private var effectiveTarget: Double {
        if let manual = manualTargetValue(for: period) {
            return manual
        }
        // Fall back to metric-provided target/baseline
        return metricType.targetValue(for: period) ?? metricType.baselineValue(for: period)
    }
    
    private var effectiveIsHigherBetter: Bool {
        if let manual = manualIsHigherBetter {
            return manual
        }
        return metricType.isHigherBetter
    }
    
    // NEW chart data model
    // Transform raw values into delta around the period-aware target/baseline so negatives plot below zero (red)
    private var chartData: [ChartDataPoint] {
        let target = effectiveTarget
        let higherBetter = effectiveIsHigherBetter
        return dataPoints.map { src in
            let delta: Double
            if higherBetter {
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
        let segments = splitSegments(chartData)

        return Chart {

            // negative (red)
            ForEach(Array(segments.neg.enumerated()), id: \.offset) { idx, seg in
                SegmentAreaAndLine(segment: seg, color: .red, seriesID: "neg-\(idx)")
            }

            // positive (green)
            ForEach(Array(segments.pos.enumerated()), id: \.offset) { idx, seg in
                SegmentAreaAndLine(segment: seg, color: .green, seriesID: "pos-\(idx)")
            }

            // Zero baseline
            RuleMark(y: .value("Zero", 0))
                .lineStyle(.init(lineWidth: 1, dash: [4, 4]))
                .foregroundStyle(.white.opacity(0.35))

            // Selection
            if let sp = selectedPoint {
                RuleMark(x: .value("Selected", sp.date))
                    .foregroundStyle(.white.opacity(0.4))
                    .lineStyle(.init(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Selected", sp.date),
                    y: .value("Value", sp.value)
                )
                .symbolSize(60)
                .foregroundStyle(sp.value >= 0 ? .green : .red)
                .annotation(position: .top, alignment: .leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sp.label)
                            .font(.system(size: 12, weight: .semibold))
                        Text(formatValue(sp.value))
                            .font(.system(size: 12))
                        Text("Δ \(formatDelta(sp.value))")
                            .foregroundStyle(sp.value >= 0 ? .green : .red)
                            .font(.system(size: 11))
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.75))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let plotFrame = geo[proxy.plotAreaFrame]

                                guard plotFrame.contains(value.location) else {
                                    selectedPoint = nil
                                    return
                                }

                                // Convert tap to X-value inside chart
                                if let date: Date = proxy.value(atX: value.location.x - plotFrame.origin.x) {
                                    // Find closest data point by date
                                    if let nearest = chartData.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }) {
                                        selectedPoint = nearest
                                    }
                                }
                            }
                            .onEnded { _ in }
                    )
                    .onTapGesture(count: 2) {
                        selectedPoint = nil
                    }
            }
        }
        .chartXAxis {
            AxisMarks(
                values: axisTickIndices(period: period).map { chartData[$0].date }
            ) { value in
                
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(formatDate(date, period: period))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    AxisGridLine().foregroundStyle(.clear)
                    AxisTick().foregroundStyle(.clear)
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
    }

    // Draws the shaded area and the line for a single contiguous segment (either all ≥0 or all <0)
    private struct SegmentAreaAndLine: ChartContent {
        let segment: [ChartDataPoint]
        let color: Color
        let seriesID: String

        var body: some ChartContent {
            // Area (y from 0 to value)
            ForEach(segment, id: \.id) { p in
                AreaMark(
                    x: .value("Date", p.date),
                    yStart: .value("Zero", 0.0),
                    yEnd: .value("Delta", p.value),
                    series: .value("seg", seriesID)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    color == .green
                        ? LinearGradient(colors: [Color.green.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Color.red.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
                )
            }

            // Line
            ForEach(segment, id: \.id) { p in
                LineMark(
                    x: .value("Date", p.date),
                    y: .value("Value", p.value),
                    series: .value("seg", seriesID)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(color)
                .lineStyle(.init(lineWidth: 3.2, lineCap: .round))
            }
        }
    }
    
    func formatDate(_ date: Date, period: ImpactDataPoint.PeriodType) -> String {
        let df = DateFormatter()
        df.locale = .current
        
        switch period {
        case .day:   df.dateFormat = "ha"   // 1AM
//        case .week:  df.dateFormat = "E"    // Mon
        case .month: df.dateFormat = "d MMM"    // 1–30
        case .year:  df.dateFormat = "MMM"  // Jan
        }
        
        return df.string(from: date)
    }

    private func axisTickIndices(period: ImpactDataPoint.PeriodType) -> [Int] {
        switch period {
        
        case .day:
            // Hourly → show every 3 hours
            return stride(from: 0, to: chartData.count, by: 3).map { $0 }

//        case .week:
//            // Daily → show every 2 days
//            return stride(from: 0, to: chartData.count, by: 2).map { $0 }

        case .month:
            // Daily → show every 5 days
            return stride(from: 0, to: chartData.count, by: 5).map { $0 }

        case .year:
            // Monthly → show every 2 months
            return stride(from: 0, to: chartData.count, by: 1).map { $0 }
        }
    }


    private func formatValue(_ v: Double) -> String {
        String(format: "%.1f", v)
    }

    private func formatDelta(_ v: Double) -> String {
        if v >= 0 { return "+\(String(format: "%.1f", v))" }
        return "\(String(format: "%.1f", v))"
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
        // For manual metrics, show ±points (scale 1–10)
        if isManualMetric {
            let sign = value >= 0 ? "+" : "−"
            // Show one decimal if fractional, else integer
            if abs(value).truncatingRemainder(dividingBy: 1) == 0 {
                return "\(sign)\(Int(abs(value)))"
            } else {
                return String(format: "\(sign)%.1f", abs(value))
            }
        }
        
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
    
    private func splitSegments(_ points: [ChartDataPoint]) -> (neg: [[ChartDataPoint]], pos: [[ChartDataPoint]]) {
        guard !points.isEmpty else { return ([], []) }

        var current: [ChartDataPoint] = []
        var positive = points[0].value >= 0
        var segmentsPos: [[ChartDataPoint]] = []
        var segmentsNeg: [[ChartDataPoint]] = []

        for i in 0..<points.count {
            let p = points[i]

            if i > 0 {
                let prev = points[i - 1]

                // detect sign change
                if (prev.value >= 0 && p.value < 0) || (prev.value < 0 && p.value >= 0) {
                    if let z = zeroCross(prev, p) {
                        current.append(z)
                        if positive { segmentsPos.append(current) } else { segmentsNeg.append(current) }
                        current = [z]
                    }
                    positive.toggle()
                }
            }

            current.append(p)
        }

        if positive { segmentsPos.append(current) } else { segmentsNeg.append(current) }

        return (segmentsNeg, segmentsPos)
    }

    private func zeroCross(_ p1: ChartDataPoint, _ p2: ChartDataPoint) -> ChartDataPoint? {
        let y1 = p1.value
        let y2 = p2.value
        guard y1 != y2 else { return nil }

        let t = (0 - y1) / (y2 - y1)
        let dt = p2.date.timeIntervalSince(p1.date)
        let d = p1.date.addingTimeInterval(dt * t)

        return ChartDataPoint(date: d, value: 0, label: formattedXAxisLabel(for: d))
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
            // Generic numeric (works well for manual 1–10 scales too)
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





//
//
//
//// Visualizes historical data for a health metric (split red/green, zero baseline, soft gradient)
//struct MetricChartSection2: View {
//    ...
//}
