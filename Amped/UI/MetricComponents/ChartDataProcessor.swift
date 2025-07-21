import Foundation

/// Utility for processing chart data with smoothing and outlier detection
final class ChartDataProcessor {
    
    // MARK: - Outlier Detection & Smoothing
    
    /// Apply smoothing and outlier clipping to data points
    static func processDataPoints(
        _ dataPoints: [MetricDataPoint],
        metricType: HealthMetricType,
        smoothingLevel: SmoothingLevel = .light
    ) -> [MetricDataPoint] {
        guard dataPoints.count > 2 else { return dataPoints }
        
        // First, detect and clip outliers
        let clippedData = clipOutliers(dataPoints, metricType: metricType)
        
        // Then apply appropriate smoothing
        switch metricType {
        case .restingHeartRate, .heartRateVariability, .bodyMass, .oxygenSaturation:
            // Apply smoothing for discrete metrics
            return applySmoothing(clippedData, level: smoothingLevel)
            
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            // Cumulative metrics - no smoothing needed
            return clippedData
            
        case .sleepHours:
            // Sleep data - light smoothing only
            return applySmoothing(clippedData, level: .light)
            
        default:
            return clippedData
        }
    }
    
    /// Detect and clip outliers using IQR method
    private static func clipOutliers(
        _ dataPoints: [MetricDataPoint],
        metricType: HealthMetricType
    ) -> [MetricDataPoint] {
        let values = dataPoints.map { $0.value }.sorted()
        guard values.count > 4 else { return dataPoints }
        
        // Calculate Q1, Q3, and IQR
        let q1Index = values.count / 4
        let q3Index = (values.count * 3) / 4
        let q1 = values[q1Index]
        let q3 = values[q3Index]
        let iqr = q3 - q1
        
        // Define outlier bounds (1.5 * IQR is standard)
        let lowerBound = q1 - 1.5 * iqr
        let upperBound = q3 + 1.5 * iqr
        
        // Clip outliers
        return dataPoints.map { point in
            let clippedValue = max(lowerBound, min(upperBound, point.value))
            return MetricDataPoint(
                date: point.date,
                value: clippedValue
            )
        }
    }
    
    /// Apply moving average smoothing
    private static func applySmoothing(
        _ dataPoints: [MetricDataPoint],
        level: SmoothingLevel
    ) -> [MetricDataPoint] {
        guard dataPoints.count > level.windowSize else { return dataPoints }
        
        let sortedPoints = dataPoints.sorted { $0.date < $1.date }
        var smoothedPoints: [MetricDataPoint] = []
        
        for (index, point) in sortedPoints.enumerated() {
            // Calculate window bounds
            let windowStart = max(0, index - level.windowSize / 2)
            let windowEnd = min(sortedPoints.count - 1, index + level.windowSize / 2)
            
            // Calculate weighted average
            var weightedSum = 0.0
            var totalWeight = 0.0
            
            for i in windowStart...windowEnd {
                let distance = abs(i - index)
                let weight = 1.0 / (1.0 + Double(distance) * 0.5) // Distance-based weighting
                weightedSum += sortedPoints[i].value * weight
                totalWeight += weight
            }
            
            let smoothedValue = weightedSum / totalWeight
            
            smoothedPoints.append(MetricDataPoint(
                date: point.date,
                value: smoothedValue
            ))
        }
        
        return smoothedPoints
    }
    
    // MARK: - Aggregation Methods
    
    /// Aggregate data points for different time periods
    static func aggregateDataPoints(
        _ dataPoints: [MetricDataPoint],
        metricType: HealthMetricType,
        period: ImpactDataPoint.PeriodType
    ) -> [MetricDataPoint] {
        guard !dataPoints.isEmpty else { return [] }
        
        switch metricType {
        case .steps, .exerciseMinutes, .activeEnergyBurned:
            // Cumulative metrics - show totals
            return aggregateCumulativeData(dataPoints, period: period)
            
        case .restingHeartRate, .heartRateVariability, .bodyMass, .vo2Max, .oxygenSaturation:
            // Discrete metrics - show averages
            return aggregateDiscreteData(dataPoints, period: period)
            
        case .sleepHours:
            // Sleep - special handling
            return aggregateSleepData(dataPoints, period: period)
            
        default:
            return aggregateDiscreteData(dataPoints, period: period)
        }
    }
    
    /// Aggregate cumulative data (sum per period)
    private static func aggregateCumulativeData(
        _ dataPoints: [MetricDataPoint],
        period: ImpactDataPoint.PeriodType
    ) -> [MetricDataPoint] {
        // Group by appropriate time unit
        let grouped = groupDataByPeriod(dataPoints, period: period)
        
        return grouped.map { (date, points) in
            let total = points.reduce(0) { $0 + $1.value }
            return MetricDataPoint(
                date: date,
                value: total
            )
        }.sorted { $0.date < $1.date }
    }
    
    /// Aggregate discrete data (average per period)
    private static func aggregateDiscreteData(
        _ dataPoints: [MetricDataPoint],
        period: ImpactDataPoint.PeriodType
    ) -> [MetricDataPoint] {
        let grouped = groupDataByPeriod(dataPoints, period: period)
        
        return grouped.map { (date, points) in
            let average = points.reduce(0) { $0 + $1.value } / Double(points.count)
            return MetricDataPoint(
                date: date,
                value: average
            )
        }.sorted { $0.date < $1.date }
    }
    
    /// Special aggregation for sleep data
    private static func aggregateSleepData(
        _ dataPoints: [MetricDataPoint],
        period: ImpactDataPoint.PeriodType
    ) -> [MetricDataPoint] {
        // For sleep, we want daily averages regardless of period
        return aggregateDiscreteData(dataPoints, period: period)
    }
    
    /// Group data points by period
    private static func groupDataByPeriod(
        _ dataPoints: [MetricDataPoint],
        period: ImpactDataPoint.PeriodType
    ) -> [(Date, [MetricDataPoint])] {
        let calendar = Calendar.current
        var grouped: [Date: [MetricDataPoint]] = [:]
        
        for point in dataPoints {
            let key: Date
            
            switch period {
            case .day:
                // Group by hour
                key = calendar.dateInterval(of: .hour, for: point.date)?.start ?? point.date
                
            case .month:
                // Group by day
                key = calendar.startOfDay(for: point.date)
                
            case .year:
                // Group by month
                key = calendar.dateInterval(of: .month, for: point.date)?.start ?? point.date
            }
            
            grouped[key, default: []].append(point)
        }
        
        return grouped.map { ($0.key, $0.value) }
    }
}

// MARK: - Supporting Types

/// Smoothing level for data processing
enum SmoothingLevel {
    case none
    case light
    case moderate
    case heavy
    
    var windowSize: Int {
        switch self {
        case .none: return 1
        case .light: return 3
        case .moderate: return 5
        case .heavy: return 7
        }
    }
} 