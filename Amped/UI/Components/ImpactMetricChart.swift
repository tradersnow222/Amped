import SwiftUI
import Charts

/// Chart that displays cumulative life impact over time instead of raw metric values
/// Rules: Simplicity is KING, Follow Apple's Human Interface Guidelines
struct ImpactMetricChart: View {
    let metricType: HealthMetricType
    let dataPoints: [ChartImpactDataPoint]
    let period: ImpactDataPoint.PeriodType
    @Binding var selectedDataPoint: ChartImpactDataPoint?
    @Binding var isDragging: Bool
    
    @State private var dragLocation: CGPoint = .zero
    
    // Determine chart color based on overall impact (Rule: Clear visual feedback)
    private var chartColor: Color {
        let finalImpact = dataPoints.last?.cumulativeImpactMinutes ?? 0
        return finalImpact >= 0 ? .ampedGreen : .ampedRed
    }
    
    // Calculate Y-axis range to ensure zero is visible
    private var yAxisRange: ClosedRange<Double> {
        let values = dataPoints.map { $0.cumulativeImpactMinutes }
        let minValue = min(0, values.min() ?? 0)
        let maxValue = max(0, values.max() ?? 0)
        
        // Add padding for visual clarity
        let padding = max(abs(maxValue - minValue) * 0.2, 60) // At least 60 minutes padding
        return (minValue - padding)...(maxValue + padding)
    }
    
    var body: some View {
        GeometryReader { geometry in
            Chart {
                // Neutral target line at zero (Rule: Clear visual targets)
                RuleMark(y: .value("Neutral", 0))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 5]))
                    .foregroundStyle(Color.white.opacity(0.3))
                
                ForEach(dataPoints) { point in
                    // Area mark from zero to the line value (Rule: Consistent visual language)
                    AreaMark(
                        x: .value("Time", point.date),
                        yStart: .value("Start", 0),
                        yEnd: .value("Life Impact", point.cumulativeImpactMinutes)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                chartColor.opacity(0.3),
                                chartColor.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line showing cumulative impact trend
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Life Impact", point.cumulativeImpactMinutes)
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                
                // Selected point indicator for interaction
                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value("Life Impact", selected.cumulativeImpactMinutes)
                    )
                    .foregroundStyle(Color.white)
                    .symbolSize(80)
                }
            }
            .chartYScale(domain: yAxisRange)
            .chartXAxis {
                AxisMarks(values: getXAxisStride()) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.1))
                    AxisValueLabel(format: getDateFormatStyle())
                        .foregroundStyle(Color.secondary.opacity(0.7))
                        .font(.caption)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                        .foregroundStyle(Color.secondary.opacity(0.1))
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(formatImpactTime(doubleValue))
                                .foregroundStyle(Color.secondary.opacity(0.7))
                                .font(.caption)
                        }
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                // Interactive value display when dragging
                if isDragging, let selected = selectedDataPoint {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatMetricValue(selected.rawValue))
                            .style(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatImpactTime(selected.cumulativeImpactMinutes))
                            .style(.bodyMedium)
                            .foregroundColor(.white)
                        
                        Text(formatDate(selected.date))
                            .style(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.8))
                    )
                    .offset(x: min(dragLocation.x - 40, geometry.size.width - 100), y: 10)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        dragLocation = value.location
                        isDragging = true
                        
                        // Find nearest data point for interaction
                        if !dataPoints.isEmpty {
                            let xPosition = value.location.x
                            let chartWidth = geometry.size.width
                            
                            // Calculate which data point based on x position
                            let relativeX = xPosition / chartWidth
                            let index = Int(relativeX * CGFloat(dataPoints.count - 1))
                            let clampedIndex = max(0, min(dataPoints.count - 1, index))
                            selectedDataPoint = dataPoints[clampedIndex]
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        selectedDataPoint = nil
                    }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getXAxisStride() -> AxisMarkValues {
        guard !dataPoints.isEmpty else { return .automatic() }
        
        switch period {
        case .day:
            return .stride(by: .hour, count: 4)
        case .month:
            return .stride(by: .day, count: 6)
        case .year:
            return .stride(by: .month, count: 3)
        }
    }
    
    private func getDateFormatStyle() -> Date.FormatStyle {
        switch period {
        case .day:
            return .dateTime.hour(.defaultDigits(amPM: .abbreviated))
        case .month:
            return .dateTime.month(.abbreviated).day()
        case .year:
            return .dateTime.month(.abbreviated)
        }
    }
    
    private func formatImpactTime(_ minutes: Double) -> String {
        // Rule: Clear, human-readable formatting
        let absMinutes = abs(minutes)
        let sign = minutes >= 0 ? "+" : "-"
        
        if absMinutes >= 1440 { // Days
            let days = absMinutes / 1440
            return String(format: "%@%.1f days", sign, days)
        } else if absMinutes >= 60 { // Hours
            let hours = absMinutes / 60
            return String(format: "%@%.1f hrs", sign, hours)
        } else {
            return String(format: "%@%.0f min", sign, absMinutes)
        }
    }
    
    private func formatMetricValue(_ value: Double) -> String {
        switch metricType {
        case .steps:
            return "\(Int(value)) steps"
        case .exerciseMinutes:
            return "\(Int(value)) min"
        case .sleepHours:
            return String(format: "%.1f hrs", value)
        case .heartRateVariability:
            return "\(Int(value)) ms"
        case .restingHeartRate:
            return "\(Int(value)) bpm"
        case .bodyMass:
            let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
            let displayValue = useMetric ? value : value * 2.20462
            return String(format: "%.1f %@", displayValue, useMetric ? "kg" : "lbs")
        case .activeEnergyBurned:
            return "\(Int(value)) cal"
        case .vo2Max:
            return String(format: "%.1f mL/kg/min", value)
        case .oxygenSaturation:
            return String(format: "%.0f%%", value)
        default:
            return String(format: "%.1f", value)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch period {
        case .day:
            formatter.dateFormat = "h:mm a"
        case .month:
            formatter.dateFormat = "MMM d"
        case .year:
            formatter.dateFormat = "MMM yyyy"
        }
        
        return formatter.string(from: date)
    }
} 