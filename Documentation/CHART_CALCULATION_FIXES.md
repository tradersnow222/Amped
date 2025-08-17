# Chart Calculation and Recommendation Fixes

## Date: 8/17/2025

### Issues Fixed

#### 1. Chart Dropping at End (Steps Decreasing)

**Problem**: The steps chart was showing a drop at the end because it was including future hours with no data.

**Root Cause**: In `fetchCumulativeData`, the chart was including all hourly intervals up to the end of the day, including future hours that haven't occurred yet.

**Solution**: 
- Modified `fetchCumulativeData` in `MetricDetailViewModel` to:
  - Skip any data points with timestamps in the future
  - Only process cumulative totals up to the current time
  - Extend the flat line to current time if the last data point is more than an hour old
  - This ensures cumulative metrics like steps never decrease

```swift
// CRITICAL FIX: For day view with cumulative metrics, ensure no future drops
if self.selectedPeriod == .day && (metricType == .steps || metricType == .exerciseMinutes || metricType == .activeEnergyBurned) {
    var runningTotal: Double = 0
    let now = Date()
    
    for dataPoint in tempDataPoints {
        // Skip any data points in the future
        if dataPoint.date > now {
            continue
        }
        
        runningTotal += dataPoint.value
        self.historyData.append(HistoryDataPoint(date: dataPoint.date, value: runningTotal))
    }
    
    // If the last data point is more than an hour old, extend the line to current time
    if let lastDataPoint = self.historyData.last {
        let hoursSinceLastData = now.timeIntervalSince(lastDataPoint.date) / 3600
        if hoursSinceLastData > 1.0 {
            // Add current time with same cumulative value (flat line extension)
            self.historyData.append(HistoryDataPoint(date: now, value: lastDataPoint.value))
        }
    }
}
```

#### 2. Redundant Recommendations

**Problem**: The detail view was showing multiple similar recommendations for steps (e.g., "Daily Walking" and "Increase Movement").

**Root Cause**: The `generateRecommendations` function was adding multiple recommendations that had overlapping content.

**Solution**: 
- Modified `generateRecommendations` to only generate ONE focused recommendation
- Made recommendations context-aware based on metric value:
  - Steps < 5000: "Increase Movement" 
  - Steps 5000-10000: "Daily Walking"
  - Steps > 10000: "Maintain Your Streak"

```swift
private func generateRecommendations(for metric: HealthMetric) {
    recommendations.removeAll()
    
    // CRITICAL FIX: Generate only ONE focused recommendation to avoid redundancy
    var primaryRecommendation: MetricRecommendation?
    
    switch metric.type {
    case .steps:
        // Only show the most relevant recommendation based on current value
        if metric.value < 5000 {
            primaryRecommendation = MetricRecommendation(
                title: "Increase Movement",
                description: "You're below the recommended daily steps..."
            )
        } else if metric.value < 10000 {
            primaryRecommendation = MetricRecommendation(
                title: "Daily Walking",
                description: "You're making progress! Try to reach 10,000 steps..."
            )
        } else {
            primaryRecommendation = MetricRecommendation(
                title: "Maintain Your Streak",
                description: "Excellent work! You're exceeding the daily recommendation..."
            )
        }
    // ...
    }
    
    // Add only the single most relevant recommendation
    if let recommendation = primaryRecommendation {
        recommendations = [recommendation]
    }
}
```

### Files Modified

1. `Amped/Features/UI/ViewModels/MetricDetailViewModel.swift`
   - Fixed `fetchCumulativeData` to prevent future data points
   - Fixed `generateRecommendations` to only show one focused recommendation

### Testing Recommendations

1. **Chart Drop Fix**: 
   - View steps metric in day view
   - Confirm chart never shows a downward trend
   - Verify the line extends flat to current time if no recent data

2. **Recommendation Fix**:
   - Check steps detail view at different values (<5000, 5000-10000, >10000)
   - Verify only one recommendation is shown
   - Confirm recommendation is contextually appropriate

### Impact

These fixes improve the user experience by:
- Showing accurate, non-decreasing cumulative data in charts
- Reducing redundant information in recommendations
- Making the interface cleaner and more focused
- Following the principle "Simplicity is KING" from the app's design philosophy
