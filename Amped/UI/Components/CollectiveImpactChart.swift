import SwiftUI
import Charts

// MARK: - Container View for State Management
/// Container that manages the chart state and provides real data
struct CollectiveImpactChartContainer: View {
    @ObservedObject var viewModel: DashboardViewModel
    let selectedPeriod: ImpactDataPoint.PeriodType
    
    // RESTORE INTERACTIVE FUNCTIONALITY: Add state for drag interactions
    @State private var selectedDataPoint: ChartImpactDataPoint?
    @State private var isDragging: Bool = false
    
    var body: some View {
        // CRITICAL FIX: Always use synchronous chart data that matches the headline exactly
        // Remove dependency on async historicalChartData which may be inconsistent
        let chartData = viewModel.generateCollectiveImpactChartData()
        
        CollectiveImpactChart(
            dataPoints: chartData,
            period: selectedPeriod,
            selectedDataPoint: $selectedDataPoint,  // FIXED: Use proper binding
            isDragging: $isDragging                  // FIXED: Use proper binding
        )
        .onAppear {
            // Force chart data generation on appear to ensure fresh data
            _ = viewModel.generateCollectiveImpactChartData()
        }
        .onChange(of: selectedPeriod) { _ in
            // Regenerate chart data when period changes and reset drag state
            selectedDataPoint = nil
            isDragging = false
            _ = viewModel.generateCollectiveImpactChartData()
        }
    }
}

/// Chart that displays collective life impact of all metrics over time instead of individual metric values
/// Rules: Simplicity is KING, Follow Apple's Human Interface Guidelines
struct CollectiveImpactChart: View {
    let dataPoints: [ChartImpactDataPoint]
    let period: ImpactDataPoint.PeriodType
    @Binding var selectedDataPoint: ChartImpactDataPoint?
    @Binding var isDragging: Bool
    
    @State private var dragLocation: CGPoint = .zero
    
    // Determine chart color based on overall impact relative to neutral baseline (Rule: Clear visual feedback)
    private var chartColor: Color {
        let finalImpact = dataPoints.last?.impact ?? 0
        return finalImpact >= 0 ? .ampedGreen : .ampedRed
    }
    
    // Calculate Y-axis range to ensure neutral baseline (0) is visible and symmetrical
    private var yAxisRange: ClosedRange<Double> {
        let values = dataPoints.map { $0.impact }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        
        // Calculate the maximum absolute distance from neutral baseline (0)
        let maxAbsoluteValue = max(abs(minValue), abs(maxValue))
        
        // Add more padding for better visual spacing above and below neutral line
        let padding = max(maxAbsoluteValue * 0.5, 90) // Increased from 30% to 50% and min from 60 to 90 minutes
        let symmetricalRange = maxAbsoluteValue + padding
        
        // Return symmetrical range around neutral baseline (0)
        return (-symmetricalRange)...(symmetricalRange)
    }
    
    // Calculate optimal y-axis tick count for regular increments
    private func getYAxisStride() -> AxisMarkValues {
        let totalRange = yAxisRange.upperBound - yAxisRange.lowerBound
        
        // DEBUG LOG: Track y-axis range calculation
        print("🔍 DEBUG - Y-Axis Range: \(yAxisRange.lowerBound) to \(yAxisRange.upperBound), Total: \(totalRange) minutes")
        
        // Define clean increment options in minutes for optimal readability
        let incrementOptions = [15.0, 30.0, 60.0, 120.0, 180.0, 360.0, 720.0, 1440.0, 2880.0] // 15min to 2 days
        
        // Find the best increment that gives us 4-8 divisions across the range
        var optimalTickCount = 5 // Default fallback
        for increment in incrementOptions {
            let divisions = totalRange / increment
            print("🔍 DEBUG - Testing increment \(increment)min = \(divisions) divisions")
            if divisions >= 4 && divisions <= 8 {
                optimalTickCount = Int(divisions.rounded())
                print("🔍 DEBUG - Selected increment \(increment)min with \(optimalTickCount) ticks")
                break
            }
        }
        
        // Use automatic with calculated optimal count for regular spacing
        return .automatic(desiredCount: optimalTickCount)
    }
    
    // Get gradient colors for area chart based on impact direction
    private func getAreaGradient(for impact: Double) -> LinearGradient {
        let isPositive = impact >= 0
        let baseColor = isPositive ? Color.ampedGreen : Color.ampedRed
        
        return LinearGradient(
            colors: [
                baseColor.opacity(0.3),
                baseColor.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            Chart {
                // Neutral baseline line at zero - represents optimal health habits (Rule: Clear visual targets)
                RuleMark(y: .value("Neutral Baseline", 0))
                    .lineStyle(StrokeStyle(lineWidth: 2.0, dash: [6, 3]))
                    .foregroundStyle(Color.white.opacity(0.6))
                
                ForEach(dataPoints, id: \.id) { point in
                    // Area mark from neutral baseline (0) to the impact value (Rule: Consistent visual language)
                    AreaMark(
                        x: .value("Time", point.date),
                        yStart: .value("Neutral Baseline", 0),
                        yEnd: .value("Collective Impact", point.impact)
                    )
                    .foregroundStyle(getAreaGradient(for: point.impact))
                    
                    // Line showing collective impact trend relative to neutral baseline
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Collective Impact", point.impact)
                    )
                    .foregroundStyle(point.impact >= 0 ? .ampedGreen : .ampedRed)
                    .lineStyle(StrokeStyle(lineWidth: 3.0, lineCap: .round, lineJoin: .round))
                }
                
                // Selected point indicator for interaction
                if let selected = selectedDataPoint {
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(Color.white.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))
                    
                    PointMark(
                        x: .value("Time", selected.date),
                        y: .value("Collective Impact", selected.impact)
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
                AxisMarks(values: getYAxisStride()) { value in
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
            .padding(.top, 40)  // Rules: Reduced from 80 to 40 to better fit on screen
            .overlay(alignment: .topLeading) {
                // Rules: Position legend in the reduced padding area
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.ampedGreen)
                            .frame(width: 8, height: 8)
                        Text("Above optimal health")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.ampedRed)
                            .frame(width: 8, height: 8)
                        Text("Below optimal health")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    HStack(spacing: 6) {
                        Rectangle()
                            .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 1, dash: [4, 2]))
                            .frame(width: 12, height: 2)
                        Text("Research-based optimal")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.leading, 12)
                .padding(.top, 4)  // Rules: Adjusted for reduced padding area
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial.opacity(0.3))
                        .padding(-4)
                )
 
            }
            .overlay(alignment: .topTrailing) {
                // Interactive value display when dragging - Rules: Adjusted for reduced padding
                if isDragging, let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Collective Impact")
                            .style(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatImpactTime(selected.impact))
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
                    .offset(x: max(dragLocation.x - geometry.size.width + 100, -geometry.size.width + 100), y: 50) // Rules: Adjusted for reduced legend padding
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
        // CRITICAL FIX: Use the exact same formatting logic as the headline in DashboardView
        let absMinutes = abs(minutes)
        let sign = minutes >= 0 ? "+" : ""
        
        // Use the same unit conversion constants as DashboardView
        let minutesInHour = 60.0
        let minutesInDay = 1440.0
        let minutesInWeek = 10080.0
        let minutesInMonth = 43200.0
        let minutesInYear = 525600.0
        
        // Years
        if absMinutes >= minutesInYear {
            let years = absMinutes / minutesInYear
            if years >= 1.0 {
                let unit = years == 1.0 ? "year" : "years"
                let valueString = years.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", years) : String(format: "%.1f", years)
                return "\(sign)\(valueString) \(unit)"
            } else {
                return String(format: "%@%.1f year", sign, years)
            }
        }
        
        // Months
        if absMinutes >= minutesInMonth {
            let months = absMinutes / minutesInMonth
            if months >= 1.0 {
                let unit = months == 1.0 ? "month" : "months"
                let valueString = months.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", months) : String(format: "%.1f", months)
                return "\(sign)\(valueString) \(unit)"
            } else {
                return String(format: "%@%.1f month", sign, months)
            }
        }
        
        // Weeks
        if absMinutes >= minutesInWeek {
            let weeks = absMinutes / minutesInWeek
            if weeks >= 1.0 {
                let unit = weeks == 1.0 ? "week" : "weeks"
                let valueString = weeks.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", weeks) : String(format: "%.1f", weeks)
                return "\(sign)\(valueString) \(unit)"
            } else {
                return String(format: "%@%.1f week", sign, weeks)
            }
        }
        
        // Days
        if absMinutes >= minutesInDay {
            let days = absMinutes / minutesInDay
            if days >= 1.0 {
                let unit = days == 1.0 ? "day" : "days"
                let valueString = days.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", days) : String(format: "%.1f", days)
                return "\(sign)\(valueString) \(unit)"
            } else {
                return String(format: "%@%.1f day", sign, days)
            }
        }
        
        // Hours
        if absMinutes >= minutesInHour {
            let hours = absMinutes / minutesInHour
            if hours >= 1.0 {
                let unit = hours == 1.0 ? "hour" : "hours"
                let valueString = hours.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", hours) : String(format: "%.1f", hours)
                return "\(sign)\(valueString) \(unit)"
            } else {
                return String(format: "%@%.1f hour", sign, hours)
            }
        }
        
        // Minutes
        return String(format: "%@%.0f minutes", sign, absMinutes)
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

// MARK: - Preview
struct CollectiveImpactChart_Previews: PreviewProvider {
    static var previews: some View {
        let sampleData = [
            ChartImpactDataPoint(date: Date().addingTimeInterval(-3600 * 6), impact: -120, value: 0),
            ChartImpactDataPoint(date: Date().addingTimeInterval(-3600 * 4), impact: -80, value: 0),
            ChartImpactDataPoint(date: Date().addingTimeInterval(-3600 * 2), impact: -40, value: 0),
            ChartImpactDataPoint(date: Date(), impact: 20, value: 0)
        ]
        
        CollectiveImpactChart(
            dataPoints: sampleData,
            period: .day,
            selectedDataPoint: .constant(nil),
            isDragging: .constant(false)
        )
        .frame(height: 220)
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
} 