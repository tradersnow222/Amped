import Foundation
import SwiftUI
import Charts

/// Visualizes historical data for a health metric
struct MetricChartSection: View {
    // MARK: - Properties
    
    let metricType: HealthMetricType
    let dataPoints: [MetricDataPoint]
    let period: ImpactDataPoint.PeriodType
    var chartHeight: CGFloat = 180

    // NEW chart data model
    private var chartData: [ChartDataPoint] {
        dataPoints.map {
            ChartDataPoint(
                date: $0.date,
                value: $0.value,
                label: formattedXAxisLabel(for: $0.date)
            )
        }
    }
    
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
            
            // NEW chart
            chartView
            
            // Insight section
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    
    // MARK: - NEW CHART IMPLEMENTATION
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
        .frame(height: chartHeight) // Apply uniform height to both branches
    }
    
    
    // MARK: - NEW Chart Components
    
    private var yAxisLabelsView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(yAxisValues.reversed(), id: \.self) { value in
                Text(formatYAxisValue(value))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: 35)
    }
    
    private var mainChartView: some View {
        Chart(Array(chartData.enumerated()), id: \.offset) { index, point in
            
            // Main line
            LineMark(
                x: .value("Time", index),
                y: .value("Value", point.value)
            )
            .foregroundStyle(getColorForPoint(point))
            .lineStyle(StrokeStyle(lineWidth: 2.3, lineCap: .round))
            
            // Target line only once
            if index == 0 {
                targetRuleMark
            }
        }
        .chartXAxis {
            AxisMarks(values: xAxisMarkValues) { value in
                if let index = value.as(Int.self), index < chartData.count {
                    AxisValueLabel {
                        Text(chartData[index].label)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                }
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(domain: minYValue...maxYValue)
        .chartPlotStyle { plotArea in
            plotArea.background(plotBackgroundGradient)
        }
    }
    
    
    // MARK: - X Axis
    private var xAxisMarkValues: [Int] {
        let total = chartData.count
        guard total > 0 else { return [] }
        
        let step = max(getXAxisStride(), 1)
        return Array(Swift.stride(from: 0, to: total, by: step))
    }
    
    private func getXAxisStride() -> Int {
        let total = chartData.count
        if total > 12 { return total / 5 }
        if total > 7 { return 2 }
        return 1
    }
    
    
    // MARK: - Target Line
    private var targetRuleMark: some ChartContent {
        RuleMark(y: .value("Target", targetValue))
            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .foregroundStyle(Color.white.opacity(0.25))
    }
    
    
    // MARK: - Background & Border
    private var plotBackgroundGradient: some View {
        LinearGradient(
            colors: [Color.white.opacity(0.03), Color.white.opacity(0.01)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var chartBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.03))
    }
    
    private var chartBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color.white.opacity(0.06), lineWidth: 1)
    }
    
    // MARK: - Y Axis Values
    private var yAxisValues: [Double] {
        let values = chartData.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else { return [0,1,2,3,4] }
        
        let padding = max(abs(minVal), abs(maxVal)) * 0.1
        let min = minVal - padding
        let max = maxVal + padding
        let step = max == min ? 1 : (max - min) / 4
        
        return stride(from: min, through: max, by: step).map { $0 }
    }
    
    private var minYValue: Double {
        let minVal = chartData.map { $0.value }.min() ?? 0
        return minVal - abs(minVal) * 0.1
    }
    
    private var maxYValue: Double {
        let maxVal = chartData.map { $0.value }.max() ?? 1
        return maxVal + abs(maxVal) * 0.1
    }
    
    
    // MARK: - Helpers
    private func formattedXAxisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        
        switch period {
        case .day:
            formatter.dateFormat = "ha"
        case .month:
            formatter.dateFormat = "d"
        case .year:
            formatter.dateFormat = "MMM"
        }
        
        return formatter.string(from: date)
    }
    
    private func formatYAxisValue(_ value: Double) -> String {
        switch metricType {
        case .sleepHours: return String(format: "%.1fh", value)
        case .steps:
            return value >= 1000 ? String(format: "%.0fk", value / 1000) : String(format: "%.0f", value)
        default:
            return String(format: "%.0f", value)
        }
    }
    
    private var targetValue: Double {
        switch metricType {
        case .sleepHours: return 7.5
        case .steps: return 10000
        case .restingHeartRate: return 65
        default:
            let vals = chartData.map { $0.value }
            return vals.reduce(0, +) / Double(max(vals.count, 1))
        }
    }
    
    private func getColorForPoint(_ point: ChartDataPoint) -> Color {
        switch metricType {
        case .sleepHours: return point.value < targetValue ? .red : .green
        case .restingHeartRate: return point.value > targetValue ? .red : .green
        case .steps: return point.value < targetValue ? .red : .green
        default: return point.value < targetValue ? .red : .green
        }
    }
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
    var chartHeight: CGFloat = 180
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Historical Data")
                    .font(.headline)
                
                Spacer()
                
                Text(periodText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Chart visualization
            chartView
                .frame(height: chartHeight)
            
            // Insight text
            if !dataPoints.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: insightIcon)
                        .foregroundColor(insightColor)
                    
                    Text(insightText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(insightColor.opacity(0.1))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1)
        )
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

// MARK: - Data Model

/// Data point for metric history visualization
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
                MetricDataPoint(date: Calendar.current.date(byAdding: .hour, value: -8, to: Date())!, value: 2500),
                MetricDataPoint(date: Calendar.current.date(byAdding: .hour, value: -6, to: Date())!, value: 4200),
                MetricDataPoint(date: Calendar.current.date(byAdding: .hour, value: -4, to: Date())!, value: 5800),
                MetricDataPoint(date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!, value: 7200),
                MetricDataPoint(date: Date(), value: 8500)
            ],
            period: .day
        )
        
        MetricChartSection(
            metricType: .sleepHours,
            dataPoints: [
                MetricDataPoint(date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!, value: 6.2),
                MetricDataPoint(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, value: 7.1),
                MetricDataPoint(date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!, value: 6.8),
                MetricDataPoint(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, value: 7.5),
                MetricDataPoint(date: Date(), value: 7.2)
            ],
            period: .month
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
