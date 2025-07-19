import SwiftUI
import Charts

/// Beautiful styled chart for displaying metric history with interactive dragging
struct StyledMetricChart: View {
    let metricType: HealthMetricType
    let dataPoints: [MetricDataPoint]
    let period: ImpactDataPoint.PeriodType
    let totalImpact: Double? // Pass in the total impact for the period
    @Binding var selectedDataPoint: MetricDataPoint?
    @Binding var isDragging: Bool
    
    @State private var dragLocation: CGPoint = .zero
    
    // Determine if impact is positive based on metric type and values
    private var isPositiveImpact: Bool {
        // If totalImpact is provided, use it
        if let impact = totalImpact {
            return impact >= 0
        }
        
        // Otherwise, determine based on metric type and data trend
        guard !dataPoints.isEmpty else { return true }
        
        let firstValue = dataPoints.first?.value ?? 0
        let lastValue = dataPoints.last?.value ?? 0
        let trend = lastValue - firstValue
        
        // For different metric types, determine if increasing is good or bad
        switch metricType {
        case .steps, .exerciseMinutes, .sleepHours, .heartRateVariability, 
             .nutritionQuality, .socialConnectionsQuality, .activeEnergyBurned, 
             .vo2Max, .oxygenSaturation:
            // Higher is better
            return trend >= 0
        case .restingHeartRate, .bodyMass, .smokingStatus, .alcoholConsumption, .stressLevel:
            // Lower is better
            return trend <= 0
        }
    }
    
    // Dynamic colors based on impact
    private var chartColor: Color {
        isPositiveImpact ? .ampedGreen : .ampedRed
    }
    
    var body: some View {
        GeometryReader { geometry in
            Chart {
                ForEach(dataPoints) { point in
                    // Area under the line
                    AreaMark(
                        x: .value("Time", point.date),
                        y: .value(metricType.displayName, point.value)
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
                    
                    // Line
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value(metricType.displayName, point.value)
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                }
                
                // Selected point indicator
                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value(metricType.displayName, selected.value)
                    )
                    .foregroundStyle(Color.white)
                    .symbolSize(80)
                }
            }
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
                            Text(formatYAxisValueWithUnit(doubleValue))
                                .foregroundStyle(Color.secondary.opacity(0.7))
                                .font(.caption)
                        }
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                // Value display when dragging
                if isDragging, let selected = selectedDataPoint {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatValueWithUnit(selected.value))
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
                        
                        // Find nearest data point
                        if !dataPoints.isEmpty {
                            let xPosition = value.location.x
                            let chartWidth = geometry.size.width
                            
                            // Calculate which data point index based on x position
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
    
    private func getXAxisStride() -> AxisMarkValues {
        guard !dataPoints.isEmpty else { return .automatic() }
        
        switch period {
        case .day:
            // Show every 4 hours for day view
            return .stride(by: .hour, count: 4)
        case .month:
            // Show every 6 days for month view
            return .stride(by: .day, count: 6)
        case .year:
            // Show every 3 months for year view
            return .stride(by: .month, count: 3)
        }
    }
    
    private func getDateFormatStyle() -> Date.FormatStyle {
        switch period {
        case .day:
            // Show hours like "12 AM", "4 PM", etc
            return .dateTime.hour(.defaultDigits(amPM: .abbreviated))
        case .month:
            // Show days like "Jun 13", "Jun 20", etc
            return .dateTime.month(.abbreviated).day()
        case .year:
            // Show months like "Jan", "Feb", etc
            return .dateTime.month(.abbreviated)
        }
    }
    
    private func getDesiredAxisCount() -> Int {
        switch period {
        case .day:
            return 6
        case .month:
            return 5
        case .year:
            return 4
        }
    }
    
    private func formatValueWithUnit(_ value: Double) -> String {
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
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return String(format: "%.1f score", value)
        }
    }
    
    private func formatValue(_ value: Double) -> String {
        switch metricType {
        case .steps:
            return "\(Int(value))"
        case .exerciseMinutes:
            return "\(Int(value)) min"
        case .sleepHours:
            return String(format: "%.1f hrs", value)
        case .heartRateVariability:
            return "\(Int(value)) ms"
        case .restingHeartRate:
            return "\(Int(value)) bpm"
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
    
    private func getYAxisLabel() -> String {
        switch metricType {
        case .steps:
            return "Steps"
        case .exerciseMinutes:
            return "Minutes"
        case .sleepHours:
            return "Hours"
        case .heartRateVariability:
            return "ms"
        case .restingHeartRate:
            return "bpm"
        case .bodyMass:
            let useMetric = UserDefaults.standard.bool(forKey: "useMetricSystem")
            return useMetric ? "kg" : "lbs"
        case .activeEnergyBurned:
            return "cal"
        case .vo2Max:
            return "mL/kg/min"
        case .oxygenSaturation:
            return "%"
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return "Score"
        }
    }
    
    private func formatYAxisValueWithUnit(_ value: Double) -> String {
        switch metricType {
        case .steps:
            return "\(Int(value))"
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
            let unit = useMetric ? "kg" : "lbs"
            return String(format: "%.0f %@", displayValue, unit)
        case .activeEnergyBurned:
            return "\(Int(value)) cal"
        case .vo2Max:
            return String(format: "%.1f mL/kg/min", value)
        case .oxygenSaturation:
            return String(format: "%.0f%%", value)
        case .nutritionQuality, .smokingStatus, .alcoholConsumption, .socialConnectionsQuality, .stressLevel:
            return String(format: "%.1f", value)
        }
    }
} 