import Foundation
import SwiftUI
import Charts

/// Visualizes historical data for a health metric
struct MetricChartSection: View {
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
                .fill(Color(.systemBackground))
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
            // Chart visualization
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Chart grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<4) { i in
                            Divider()
                                .opacity(i == 0 ? 0 : 1) // Hide top line
                                .padding(.bottom, i == 0 ? 0 : geometry.size.height / 4 - 1)
                        }
                    }
                    
                    // Bar chart
                    HStack(alignment: .bottom, spacing: 2) {
                        ForEach(dataPoints) { point in
                            VStack(spacing: 4) {
                                // Bar
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColor(for: point))
                                    .frame(height: calculateBarHeight(point: point, in: geometry.size))
                                
                                // Date label
                                if period == .day {
                                    Text(formatTime(date: point.date))
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(formatDate(date: point.date))
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, 16) // Space for date labels
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate height for a bar based on its value
    private func calculateBarHeight(point: MetricDataPoint, in size: CGSize) -> CGFloat {
        guard let minValue = dataPoints.min(by: { $0.value < $1.value })?.value,
              let maxValue = dataPoints.max(by: { $0.value < $1.value })?.value,
              minValue != maxValue else {
            return size.height / 2
        }
        
        let availableHeight = size.height - 25 // Subtract space for labels
        let valueRange = maxValue - minValue
        let normalized = (point.value - minValue) / valueRange
        return max(15, availableHeight * CGFloat(normalized))
    }
    
    /// Get color for a bar based on metric type and value
    private func barColor(for point: MetricDataPoint) -> Color {
        let baseColor = metricType.color
        
        // Optional: Adjust color based on trend
        if let comparison = normalizedComparisonToBaseline(for: point.value) {
            if comparison > 0.2 {
                return baseColor
            } else if comparison < -0.2 {
                return .red.opacity(0.7)
            } else {
                return baseColor.opacity(0.7)
            }
        }
        
        return baseColor.opacity(0.7)
    }
    
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
        let absoluteChange = last - first
        
        if abs(percentChange) < 5 {
            return "Your \(metricType.name.lowercased()) has been stable."
        }
        
        let direction = percentChange > 0 ? "increased" : "decreased"
        let qualifier = (percentChange > 0) == metricType.isHigherBetter ? "improved" : "declined"
        
        return "Your \(metricType.name.lowercased()) has \(direction) by \(String(format: "%.1f", abs(absoluteChange))) \(metricType.unit) (\(String(format: "%.1f", abs(percentChange)))%), which has \(qualifier) your battery."
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