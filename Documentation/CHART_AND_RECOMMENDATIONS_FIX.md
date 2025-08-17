# Chart and Recommendations Fix Documentation

## Date: January 17, 2025

### Issues Fixed

#### 1. Chart Showing Downward Trend for Cumulative Metrics
**Problem**: 
- The impact chart for steps was showing a downward trend throughout the day
- As steps increased (e.g., 11 steps → 388 steps), the impact appeared to get worse (more negative)
- This was counterintuitive - users expect to see improvement as they take more steps

**Solution**:
- Modified `impactChartDataPoints` in `MetricDetailViewModel.swift`
- Instead of showing accumulated negative impact, now calculates the actual impact at each step count level
- The chart now correctly shows how impact improves (becomes less negative) as steps increase
- Example: 564 steps might show -2.1 hours lost, but this improves from what it would be with 0 steps

**Technical Details**:
```swift
// OLD: Accumulated impact proportionally (confusing)
let scaledImpact = finalImpactMinutes * progress

// NEW: Calculate actual impact at each value level
let tempMetric = HealthMetric(
    id: UUID().uuidString,
    type: originalMetric.type,
    value: dataPoint.value,  // Use the cumulative value at this time
    date: dataPoint.date,
    source: originalMetric.source
)
let impactDetail = lifeImpactService.calculateImpact(for: tempMetric)
```

#### 2. Redundant Recommendations Display
**Problem**:
- Multiple similar recommendations were appearing for the same metric
- For steps: both "Increase Movement" and "Daily Walking" were shown
- This created visual clutter and confusion

**Solution**:
- Modified `generateRecommendations` in `MetricDetailViewModel.swift`
- Now generates only ONE focused recommendation based on current value
- Logic:
  - < 5,000 steps: "Increase Movement" recommendation
  - 5,000-10,000 steps: "Daily Walking" recommendation  
  - > 10,000 steps: "Maintain Your Streak" recommendation

**Technical Details**:
```swift
// Clear existing and create only one primary recommendation
recommendations.removeAll()
var primaryRecommendation: MetricRecommendation?

// Select the most relevant recommendation based on value
if metric.value < 5000 {
    primaryRecommendation = // "Increase Movement"
} else if metric.value < 10000 {
    primaryRecommendation = // "Daily Walking"
} else {
    primaryRecommendation = // "Maintain Your Streak"
}

// Add only the single most relevant recommendation
if let recommendation = primaryRecommendation {
    recommendations = [recommendation]
}
```

### Impact
- Chart now provides intuitive visual feedback showing improvement as activity increases
- Cleaner UI with focused, actionable recommendations
- Better user understanding of how their activities affect their health impact

### Files Modified
- `Amped/Features/UI/ViewModels/MetricDetailViewModel.swift`

### Testing Notes
- Verify chart shows improvement (less negative impact) as steps increase during the day
- Confirm only one recommendation appears based on current metric value
- Test with different step counts to ensure appropriate recommendation is shown
