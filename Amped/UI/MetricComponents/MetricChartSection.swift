import Foundation
import SwiftUI
import Charts

/// Visualizes historical data for a health metric (split red/green, zero baseline, soft gradient)
struct MetricChartSection: View {
    // MARK: - Properties
    
    let metricType: HealthMetricType
    let dataPoints: [MetricDataPoint]
    let period: ImpactDataPoint.PeriodType
    var chartHeight: CGFloat = 300

    // Transform source points into chart-ready points relative to a baseline so 0 is the dashed line
    private var baseline: Double {
        baseline(for: metricType, period: period, dataPoints: dataPoints)
    }
    
    private func baseline(for type: HealthMetricType,
                          period: ImpactDataPoint.PeriodType,
                          dataPoints: [MetricDataPoint]) -> Double {
        switch type {
            // Cumulative metrics use period-scaled neutral baselines
        case .steps:
            switch period {
            case .day:   return 100
            case .month: return 1_000      // ~1,000/day * 30
            case .year:  return 3_000     // ~1,000/day * 365
            }
            
        case .exerciseMinutes:
            switch period {
            case .day:   return 5
            case .month: return 50         // 20/day * 30
            case .year:  return 100       // 20/day * 365
            }
            
        case .activeEnergyBurned:
            switch period {
            case .day:   return 400
            case .month: return 12_000      // 400/day * 30
            case .year:  return 146_000     // 400/day * 365
            }
            
        // Average/point-in-time metrics use the same neutral baseline across periods
        case .sleepHours:
            return 7.5
        case .restingHeartRate:
            return 65
        case .heartRateVariability:
            return 40
        case .vo2Max:
            return 40
        case .bodyMass:
            return 70
        case .bloodPressure:
            return 115
        case .stressLevel:
            return 3
        default:
            return 0
        }
        
    }
    
    private var chartData: [ChartDataPoint] {
        dataPoints.map { src in
            let delta = src.value //- baseline
            return ChartDataPoint(date: src.date, value: delta, label: formattedXAxisLabel(for: src.date))
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



/// Visualizes historical data for a health metric
struct MetricChartSection2: View {
    // MARK: - Properties
    
    /// The health metric type
    let metricType: HealthMetricType
    
    /// Historical data points for the metric
    let dataPoints: [MetricDataPoint]
    
    /// Selected time period
    let period: ImpactDataPoint.PeriodType
    
    /// Height of the chart
    var chartHeight: CGFloat = 380
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
//            HStack {
//                Text("Historical Data")
//                    .font(.headline)
//                
//                Spacer()
//                
//                Text(periodText)
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            
            // Chart visualization
            chartView
                .frame(height: chartHeight)
            
//            // Insight text
//            if !dataPoints.isEmpty {
//                HStack(spacing: 6) {
//                    Image(systemName: insightIcon)
//                        .foregroundColor(insightColor)
//                    
//                    Text(insightText)
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.vertical, 8)
//                .padding(.horizontal, 12)
//                .background(
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(insightColor.opacity(0.1))
//                )
//            }
        }
//        .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.cardBackground)
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
//        )
    }
    
    // MARK: - Chart View
    
    @ViewBuilder
    private var chartView: some View {
        if dataPoints.isEmpty {
            // Empty state
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
            // Line chart visualization
            Chart {
                ForEach(dataPoints) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value(metricType.displayName, point.value)
                    )
                    .foregroundStyle(lineGradient)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    
                    // Area gradient below line
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value(metricType.displayName, point.value)
                    )
                    .foregroundStyle(areaGradient)
                    
                    // Data points
                    PointMark(
                        x: .value("Time", point.date),
                        y: .value(metricType.displayName, point.value)
                    )
                    .foregroundStyle(.white)
                    .symbolSize(30)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(Color.secondary)
                        .font(.caption)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisTick()
                        .foregroundStyle(Color.secondary.opacity(0.2))
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(formatYAxisValueWithUnit(doubleValue))
                                .foregroundStyle(Color.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartBackground { chartProxy in
                Color.clear
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Chart Styling
    
    private var lineGradient: LinearGradient {
        LinearGradient(
            colors: [metricType.color, metricType.color.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                metricType.color.opacity(0.3),
                metricType.color.opacity(0.1),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Helper Methods
    
    /// Format time for display (hour)
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date).lowercased()
    }
    
    /// Format date for display
    private func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        
        switch period {
        case .day:
            formatter.dateFormat = "ha"
        case .month:
            formatter.dateFormat = "d"
        case .year:
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date).lowercased()
    }
    
    /// Get period text based on selected period
    private var periodText: String {
        switch period {
        case .day:
            return "Today"
        case .month:
            return "Past 30 Days"
        case .year:
            return "Past 12 Months"
        }
    }
    
    /// Calculate normalized comparison to baseline
    private func normalizedComparisonToBaseline(for value: Double) -> Double? {
        let baseline = metricType.baselineValue
        guard baseline > 0 else { return nil }
        
        let percentDifference = (value - baseline) / baseline
        
        // Apply direction modifier based on whether higher or lower is better
        return percentDifference * (metricType.isHigherBetter ? 1 : -1)
    }
    
    // MARK: - Insight Properties
    
    /// Get insight text based on data trend
    private var insightText: String {
        guard let first = dataPoints.first?.value,
              let last = dataPoints.last?.value,
              dataPoints.count > 1 else {
            return "Not enough data to analyze trends."
        }
        
        let percentChange = ((last - first) / first) * 100
        
        if abs(percentChange) < 5 {
            return "Your \(metricType.name.lowercased()) has remained stable."
        }
        
        let direction = percentChange > 0 ? "increased" : "decreased"
        let qualifier = (percentChange > 0) == metricType.isHigherBetter ? "improved" : "worsened"
        
        return "Your \(metricType.name.lowercased()) has \(direction) by \(String(format: "%.0f", abs(percentChange)))% which has \(qualifier) your energy level."
    }
    
    /// Get insight icon based on data trend
    private var insightIcon: String {
        guard let first = dataPoints.first?.value,
              let last = dataPoints.last?.value,
              dataPoints.count > 1 else {
            return "questionmark.circle"
        }
        
        let improved = ((last > first) == metricType.isHigherBetter)
        
        if improved {
            return "arrow.up.right.circle.fill"
        } else {
            return "arrow.down.right.circle.fill"
        }
    }
    
    /// Get insight color based on data trend
    private var insightColor: Color {
        guard let first = dataPoints.first?.value,
              let last = dataPoints.last?.value,
              dataPoints.count > 1 else {
            return .gray
        }
        
        let improved = ((last > first) == metricType.isHigherBetter)
        
        if improved {
            return .green
        } else {
            return .red
        }
    }
    
    /// Format Y-axis values with appropriate units for chart display
    private func formatYAxisValueWithUnit(_ value: Double) -> String {
        switch metricType {
        case .steps:
            return formatLargeNumber(value)
        case .exerciseMinutes:
            return "\(Int(value))"
        case .sleepHours:
            return String(format: "%.1f", value)
        case .heartRateVariability:
            return "\(Int(value))"
        case .restingHeartRate:
            return "\(Int(value))"
        case .bodyMass:
            let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
            let displayValue = useMetric ? value : value * 2.20462
            return String(format: "%.0f", displayValue)
        case .activeEnergyBurned:
            return "\(Int(value))"
        case .vo2Max:
            return String(format: "%.1f", value)
        case .oxygenSaturation:
            return String(format: "%.0f", value)
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel, .bloodPressure:
            return String(format: "%.1f", value)
        }
    }
    
    /// Format large numbers with appropriate abbreviations (K, M, etc.)
    private func formatLargeNumber(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1fK", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
}
