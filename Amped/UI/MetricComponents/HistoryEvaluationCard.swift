import SwiftUI

/// A card that evaluates the user's metric history and provides personal, actionable insights
struct HistoryEvaluationCard: View {
    // MARK: - Properties
    
    /// The health metric being evaluated
    let metric: HealthMetric
    
    /// Historical data points for analysis
    let dataPoints: [MetricDataPoint]
    
    /// The current time period being viewed
    let period: ImpactDataPoint.PeriodType
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.ampedGreen.opacity(0.8))
                    .font(.body)
                
                Text("Your Progress")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
            }
            
            // Personal evaluation text
            Text(getPersonalEvaluation())
                .font(.body)
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    /// Generate a personal evaluation based on the metric's history
    private func getPersonalEvaluation() -> String {
        guard !dataPoints.isEmpty else {
            return getNoDataMessage()
        }
        
        let trend = analyzeTrend()
        let variability = analyzeVariability()
        let currentLevel = analyzeCurrentLevel()
        
        return generatePersonalMessage(trend: trend, variability: variability, currentLevel: currentLevel)
    }
    
    /// Analyze the trend in the data (improving, declining, stable)
    private func analyzeTrend() -> TrendType {
        guard dataPoints.count >= 2 else { return .stable }
        
        let recent = dataPoints.suffix(min(3, dataPoints.count))
        let earlier = dataPoints.prefix(min(3, dataPoints.count))
        
        let recentAvg = recent.map { $0.value }.reduce(0, +) / Double(recent.count)
        let earlierAvg = earlier.map { $0.value }.reduce(0, +) / Double(earlier.count)
        
        let percentChange = abs(recentAvg - earlierAvg) / earlierAvg * 100
        
        // Consider it a trend only if change is significant (>5%)
        if percentChange < 5 {
            return .stable
        }
        
        // For different metrics, determine if higher values are better or worse
        let isHigherBetter = isHigherValueBetter(for: metric.type)
        
        if recentAvg > earlierAvg {
            return isHigherBetter ? .improving : .declining
        } else {
            return isHigherBetter ? .declining : .improving
        }
    }
    
    /// Analyze the variability/consistency in the data
    private func analyzeVariability() -> VariabilityType {
        guard dataPoints.count >= 3 else { return .consistent }
        
        let values = dataPoints.map { $0.value }
        let average = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - average, 2) }.reduce(0, +) / Double(values.count)
        let standardDeviation = sqrt(variance)
        let coefficientOfVariation = standardDeviation / average * 100
        
        // Determine variability thresholds based on metric type
        let (lowThreshold, highThreshold) = getVariabilityThresholds(for: metric.type)
        
        if coefficientOfVariation < lowThreshold {
            return .consistent
        } else if coefficientOfVariation > highThreshold {
            return .variable
        } else {
            return .moderate
        }
    }
    
    /// Analyze the current level relative to healthy ranges
    private func analyzeCurrentLevel() -> LevelType {
        let currentValue = metric.value
        let baselineValue = metric.type.baselineValue
        
        // Calculate percentage difference from baseline
        let percentDiff = abs(currentValue - baselineValue) / baselineValue * 100
        
        if percentDiff < 10 {
            return .optimal
        } else if percentDiff < 25 {
            return .good
        } else {
            return .needsImprovement
        }
    }
    
    /// Generate a personal message based on the analysis
    private func generatePersonalMessage(trend: TrendType, variability: VariabilityType, currentLevel: LevelType) -> String {
        let metricName = metric.type.displayName.lowercased()
        let periodName = getPeriodName()
        
        // Start with current level assessment
        var message = getCurrentLevelMessage(currentLevel, metricName: metricName)
        
        // Add trend information
        message += " " + getTrendMessage(trend, metricName: metricName, periodName: periodName)
        
        // Add variability insight if relevant
        if variability == .variable {
            message += " " + getVariabilityMessage(metricName: metricName)
        }
        
        // Add actionable advice
        message += " " + getActionableAdvice(trend: trend, currentLevel: currentLevel, metricName: metricName)
        
        return message
    }
    
    /// Get the current level assessment message
    private func getCurrentLevelMessage(_ level: LevelType, metricName: String) -> String {
        switch level {
        case .optimal:
            return "Your \(metricName) is in a great range right now."
        case .good:
            return "Your \(metricName) is at a good level with some room for improvement."
        case .needsImprovement:
            return "Your \(metricName) has significant room for improvement."
        }
    }
    
    /// Get the trend message
    private func getTrendMessage(_ trend: TrendType, metricName: String, periodName: String) -> String {
        switch trend {
        case .improving:
            return "Over the past \(periodName), you've been making positive changes - keep it up!"
        case .declining:
            return "Over the past \(periodName), there's been some decline, but you can turn this around."
        case .stable:
            return "Your \(metricName) has been fairly consistent over the past \(periodName)."
        }
    }
    
    /// Get the variability message
    private func getVariabilityMessage(metricName: String) -> String {
        return "Your \(metricName) varies quite a bit day to day. Finding more consistency could help you feel better overall."
    }
    
    /// Get actionable advice based on the analysis
    private func getActionableAdvice(trend: TrendType, currentLevel: LevelType, metricName: String) -> String {
        switch (trend, currentLevel) {
        case (.improving, .optimal), (.stable, .optimal):
            return "You're doing great - focus on maintaining these healthy habits that are working for you."
            
        case (.improving, _):
            return "You're heading in the right direction. Small, consistent changes will help you reach your goals."
            
        case (.declining, .needsImprovement):
            return "This is a good time to make some changes. Start with one small improvement you can stick with."
            
        case (.declining, _):
            return "Let's get back on track. Focus on the basics that you know work for your health."
            
        case (.stable, .needsImprovement):
            return "Your \(metricName) is steady but could be better. Try making one small change to see improvement."
            
        case (.stable, .good):
            return "You're consistent, which is great. A small push could help you reach the next level."
        }
    }
    
    /// Get a user-friendly period name
    private func getPeriodName() -> String {
        switch period {
        case .day:
            return "day"
        case .month:
            return "month"
        case .year:
            return "year"
        }
    }
    
    /// Get message when no data is available
    private func getNoDataMessage() -> String {
        return "Once you have more data over time, we'll show you insights about your progress and patterns here."
    }
    
    /// Determine if higher values are better for a given metric type
    private func isHigherValueBetter(for metricType: HealthMetricType) -> Bool {
        switch metricType {
        case .steps, .exerciseMinutes, .sleepHours, .heartRateVariability,
             .nutritionQuality, .socialConnectionsQuality, .activeEnergyBurned,
             .vo2Max, .oxygenSaturation:
            return true
        case .restingHeartRate, .bodyMass, .smokingStatus, .alcoholConsumption, .stressLevel, .bloodPressure:
            return false
        }
    }
    
    /// Get variability thresholds for different metric types
    private func getVariabilityThresholds(for metricType: HealthMetricType) -> (low: Double, high: Double) {
        switch metricType {
        case .steps:
            return (low: 15, high: 40) // Steps can vary quite a bit day to day
        case .sleepHours:
            return (low: 10, high: 25) // Sleep should be fairly consistent
        case .exerciseMinutes:
            return (low: 20, high: 50) // Exercise can vary with schedule
        case .restingHeartRate, .heartRateVariability:
            return (low: 5, high: 15) // Heart metrics should be relatively stable
        case .bodyMass:
            return (low: 2, high: 8) // Weight should be fairly stable
        case .activeEnergyBurned:
            return (low: 15, high: 35) // Can vary with activity level
        case .vo2Max, .oxygenSaturation:
            return (low: 3, high: 10) // Should be quite stable
        case .nutritionQuality, .smokingStatus, .alcoholConsumption,
             .socialConnectionsQuality, .stressLevel, .bloodPressure:
            return (low: 10, high: 30) // Lifestyle factors can vary
        }
    }
}

// MARK: - Supporting Types

/// Represents the trend direction in the data
private enum TrendType {
    case improving
    case declining
    case stable
}

/// Represents the variability level in the data
private enum VariabilityType {
    case consistent
    case moderate
    case variable
}

/// Represents the current level relative to healthy ranges
private enum LevelType {
    case optimal
    case good
    case needsImprovement
} 