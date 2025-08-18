import SwiftUI

/// Professional chart statistics: Summary statistics calculated from available data
/// Always computes meaningful statistics regardless of data sparsity
struct ChartSummaryStats {
    let dailyRate: Double        // Daily change rate in minutes
    let weeklyRate: Double       // Weekly change rate (for 3M/Y periods)
    let trend: Double           // Overall trend in minutes
    let highest: Double         // Highest impact value
    let lowest: Double          // Lowest impact value
    let dataPointCount: Int     // Number of available data points
    
    /// Professional behavior: Calculate stats from whatever data exists, never show "no data"
    static func calculate(from dataPoints: [ChartImpactDataPoint], period: ImpactDataPoint.PeriodType) -> ChartSummaryStats {
        guard !dataPoints.isEmpty else {
            // Even with no data, return meaningful zero stats (professional charts never show errors)
            return ChartSummaryStats(
                dailyRate: 0.0,
                weeklyRate: 0.0,
                trend: 0.0,
                highest: 0.0,
                lowest: 0.0,
                dataPointCount: 0
            )
        }
        
        let values = dataPoints.map { $0.impact }
        let highest = values.max() ?? 0.0
        let lowest = values.min() ?? 0.0
        
        // Calculate rate and trend based on available data
        let (dailyRate, weeklyRate, trend) = calculateRatesAndTrend(
            dataPoints: dataPoints, 
            period: period
        )
        
        return ChartSummaryStats(
            dailyRate: dailyRate,
            weeklyRate: weeklyRate,
            trend: trend,
            highest: highest,
            lowest: lowest,
            dataPointCount: dataPoints.count
        )
    }
    
    /// Calculate rates and trends from available data points
    private static func calculateRatesAndTrend(
        dataPoints: [ChartImpactDataPoint], 
        period: ImpactDataPoint.PeriodType
    ) -> (dailyRate: Double, weeklyRate: Double, trend: Double) {
        guard dataPoints.count >= 2 else {
            // Single or no data point - rates are zero (professional behavior with insufficient data)
            return (0.0, 0.0, dataPoints.first?.impact ?? 0.0)
        }
        
        // Sort data points by date to ensure proper calculation
        let sortedPoints = dataPoints.sorted { $0.date < $1.date }
        let firstPoint = sortedPoints.first!
        let lastPoint = sortedPoints.last!
        
        // Calculate time difference in days
        let timeDifferenceSeconds = lastPoint.date.timeIntervalSince(firstPoint.date)
        let timeDifferenceDays = max(timeDifferenceSeconds / (24 * 60 * 60), 0.1) // Minimum 0.1 day
        
        // Calculate impact difference
        let impactDifference = lastPoint.impact - firstPoint.impact
        
        // Calculate daily rate (impact change per day)
        let dailyRate = impactDifference / timeDifferenceDays
        
        // Calculate weekly rate 
        let weeklyRate = dailyRate * 7.0
        
        // Calculate overall trend (total change)
        let trend = impactDifference
        
        return (dailyRate, weeklyRate, trend)
    }
    
    // MARK: - Formatted Display Methods (Professional chart style)
    
    func formattedDailyRate(period: ImpactDataPoint.PeriodType) -> String {
        let rate = period == .year ? weeklyRate : dailyRate
        let unit = period == .year ? "/week" : "/day"
        
        if abs(rate) < 0.1 {
            return "0.0 min\(unit)"
        }
        
        let sign = rate >= 0 ? "+" : ""
        return String(format: "%@%.1f min\(unit)", sign, rate)
    }
    
    func formattedTrend() -> String {
        if abs(trend) < 0.1 {
            return "0.0 min"
        }
        
        let sign = trend >= 0 ? "+" : ""
        return String(format: "%@%.1f min", sign, trend)
    }
    
    func formattedHighest() -> String {
        return String(format: "%.1f min", highest)
    }
    
    func formattedLowest() -> String {
        return String(format: "%.1f min", lowest)
    }
    
    // MARK: - UI Components
    
    /// Professional chart: Summary statistics view that appears below charts
    @ViewBuilder
    func summaryView(period: ImpactDataPoint.PeriodType) -> some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(period == .year ? "Weekly rate" : "Daily rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(formattedDailyRate(period: period))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Trends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(formattedTrend())
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Highest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(formattedHighest())
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Lowest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(formattedLowest())
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}
