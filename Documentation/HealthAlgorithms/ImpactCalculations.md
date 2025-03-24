# Health Impact Calculation Algorithms

## Overview

The Amped app calculates the impact of various health metrics on life expectancy using a research-based approach. This document outlines the algorithms and methodologies used for these calculations.

## Calculation Framework

### Core Principles

1. **Research-Based**: All calculations are based on peer-reviewed scientific research.
2. **Proportional Impact**: Impact is calculated proportionally to the deviation from target values.
3. **Confidence Adjustment**: Greater deviations have confidence adjustments due to extrapolation.
4. **Demographic Customization**: Adjustments are made based on age, gender, and other demographic factors.
5. **Combined Effects**: Multiple metrics are combined with consideration for overlapping effects.

### Impact Flow

The impact calculation follows this process:

1. Compare individual metric value to scientifically established target or baseline
2. Calculate deviation percentage
3. Apply research-based impact factor to calculate minutes gained/lost
4. Adjust for individual demographics
5. Aggregate impacts across metrics with adjustment for interdependence

## Metric-Specific Algorithms

### Steps (Daily Physical Activity)

```swift
if steps >= targetSteps:
    impactMultiplier = min(1.5, 1.0 + (steps - targetSteps) / targetSteps * 0.5)
    impactMinutes = baseImpactMinutes * impactMultiplier
else:
    impactMultiplier = max(0.0, 1.0 - (targetSteps - steps) / targetSteps)
    impactMinutes = baseImpactMinutes * impactMultiplier - baseImpactMinutes
```

**Research Basis**: 
- Each 1,000 steps above sedentary baseline (~5,000) is associated with approximately a 15% decrease in mortality risk, up to ~12,000 steps
- Reference: Lee I-M, et al. (2019). Association of Step Volume and Intensity With All-Cause Mortality in Older Women. JAMA Internal Medicine, 179(8), 1105-1112.

### Sleep Hours

```swift
if sleepHours >= minOptimalSleep && sleepHours <= maxOptimalSleep:
    // Optimal sleep range
    optimalFactor = 1.0 - abs((sleepHours - idealSleep) / (maxOptimalSleep - minOptimalSleep))
    impactMinutes = baseImpactMinutes * optimalFactor
else if sleepHours < minOptimalSleep:
    // Insufficient sleep
    deficitFactor = sleepHours / minOptimalSleep
    impactMinutes = -baseImpactMinutes * (1.0 - deficitFactor)
else:
    // Excessive sleep
    excessFactor = 1.0 + (sleepHours - maxOptimalSleep) / 4.0
    impactMinutes = -baseImpactMinutes * (excessFactor - 1.0)
```

**Research Basis**:
- Both short (<7h) and long (>9h) sleep duration are associated with increased mortality risk
- Optimal sleep range is 7-9 hours for adults
- Reference: Grandner MA, et al. (2010). Sleep duration and mortality: a systematic review and meta-analysis. Journal of Sleep Research, 19(1), 148-158.

### Exercise Minutes

```swift
if exerciseMinutes >= recommendedMinutes:
    impactMultiplier = min(2.0, 1.0 + (exerciseMinutes - recommendedMinutes) / recommendedMinutes)
    impactMinutes = baseImpactMinutes * impactMultiplier
else:
    impactMultiplier = exerciseMinutes / recommendedMinutes
    impactMinutes = baseImpactMinutes * impactMultiplier - baseImpactMinutes
```

**Research Basis**:
- WHO recommends 150 minutes of moderate-intensity activity per week (avg 21.4 min/day)
- Meeting these guidelines is associated with 20-30% reduction in all-cause mortality
- Reference: World Health Organization. (2020). WHO guidelines on physical activity and sedentary behaviour.

### Resting Heart Rate

```swift
if heartRate <= optimalRestingHR:
    impactFactor = min(1.5, 1.0 + (optimalRestingHR - heartRate) / 10.0 * 0.1)
    impactMinutes = baseImpactMinutes * impactFactor
else:
    elevationFactor = (heartRate - optimalRestingHR) / 10.0
    impactMinutes = -baseImpactMinutes * elevationFactor
```

**Research Basis**:
- Each 10 bpm increase in resting heart rate above ~70 bpm is associated with 10-20% increase in mortality risk
- Reference: Aune D, et al. (2017). Resting heart rate and the risk of cardiovascular disease, total cancer, and all-cause mortality - A systematic review and dose-response meta-analysis of prospective studies. Nutrition, Metabolism and Cardiovascular Diseases, 27(6), 504-517.

### VO2 Max (Cardiorespiratory Fitness)

```swift
if vo2Max >= ageAdjustedExcellentVO2Max:
    impactFactor = 1.0 + (vo2Max - ageAdjustedExcellentVO2Max) / 10.0 * 0.2
    impactMinutes = baseImpactMinutes * impactFactor
else if vo2Max >= ageAdjustedAverageVO2Max:
    normalizedPosition = (vo2Max - ageAdjustedAverageVO2Max) / (ageAdjustedExcellentVO2Max - ageAdjustedAverageVO2Max)
    impactMinutes = baseImpactMinutes * normalizedPosition
else:
    deficitFactor = vo2Max / ageAdjustedAverageVO2Max
    impactMinutes = -baseImpactMinutes * (1.0 - deficitFactor)
```

**Research Basis**:
- Higher cardiorespiratory fitness (VO2 max) is strongly associated with lower mortality
- Each 1 MET improvement in fitness is associated with 10-25% reduction in mortality
- Reference: Kodama S, et al. (2009). Cardiorespiratory fitness as a quantitative predictor of all-cause mortality and cardiovascular events in healthy men and women: a meta-analysis. JAMA, 301(19), 2024-2035.

### Nutrition Quality

```swift
// Scale of 1-10, where 10 is optimal nutrition
if nutritionQuality >= 7:
    positionInOptimalRange = (nutritionQuality - 7) / 3.0
    impactMinutes = baseImpactMinutes * (0.7 + positionInOptimalRange * 0.3)
else:
    positionInPoorRange = nutritionQuality / 7.0
    impactMinutes = -baseImpactMinutes * (1.0 - positionInPoorRange)
```

**Research Basis**:
- Higher adherence to healthy dietary patterns (Mediterranean diet, DASH, etc.) is associated with 10-30% reduction in mortality
- Reference: Sofi F, et al. (2014). Mediterranean diet and health status: an updated meta-analysis and a proposal for a literature-based adherence score. Public Health Nutrition, 17(12), 2769-2782.

### Stress Level

```swift
// Scale of 1-10, where 1 is lowest stress
if stressLevel <= 3:
    impactFactor = 1.0 - (stressLevel - 1) / 2.0 * 0.3
    impactMinutes = baseImpactMinutes * impactFactor
else:
    stressFactor = (stressLevel - 3) / 7.0
    impactMinutes = -baseImpactMinutes * stressFactor
```

**Research Basis**:
- Chronic stress is associated with higher mortality through various physiological pathways
- Reference: Cohen S, et al. (2012). Chronic stress, glucocorticoid receptor resistance, inflammation, and disease risk. Proceedings of the National Academy of Sciences, 109(16), 5995-5999.

## Aggregate Impact Calculation

### Daily Impact

```swift
// Initial sum of all impacts
rawImpactSum = sum(all metric impacts)

// Apply interdependence adjustment
adjustedImpact = rawImpactSum * interdependenceAdjustmentFactor

// Daily impact data point
dailyImpact = ImpactDataPoint(
    periodType: .day,
    date: currentDate,
    totalImpactMinutes: adjustedImpact,
    metricContributions: normalizedContributions
)
```

### Period Scaling

```swift
// Scale daily impact to different periods
monthlyImpact = dailyImpact.scaleToPeriod(.month)  // x30
yearlyImpact = dailyImpact.scaleToPeriod(.year)    // x365
```

## Life Expectancy Projection

### Baseline Life Expectancy

```swift
// Based on demographic data
baselineExpectancy = getBaselineLifeExpectancy(gender, birthYear)

// Apply demographic adjustment factors
adjustedBaseline = baselineExpectancy * 
                  ageAdjustmentFactor * 
                  genderAdjustmentFactor
```

### Projection Calculation

```swift
// Convert impact minutes to years
impactYears = cumulativeImpactMinutes / minutesPerYear

// Calculate projected life expectancy
projectedLifeExpectancy = adjustedBaseline + impactYears

// Calculate confidence intervals
confidenceIntervalLow = projectedLifeExpectancy - confidenceRange/2
confidenceIntervalHigh = projectedLifeExpectancy + confidenceRange/2
```

### Percentage Calculation

```swift
// Calculate current age
currentAge = currentYear - birthYear

// Calculate percentage of life remaining
percentageLifeRemaining = (projectedLifeExpectancy - currentAge) / projectedLifeExpectancy * 100
```

## Scientific Research Mapping

Each algorithm is linked to specific scientific studies through the StudyReference model. These references provide the scientific basis for the impact calculations and are displayed to users for transparency.

## Confidence and Limitations

1. **Extrapolation**: Extreme values may be less accurately projected due to extrapolation beyond study ranges
2. **Individual Variation**: Population-level studies may not capture individual genetic or environmental factors
3. **Interdependence**: Health factors interact in complex ways that may not be fully captured
4. **Temporal Effects**: Long-term impacts may differ from short-term projections

## Future Improvements

1. **Personalized Factors**: Incorporate more personalized genetic and environmental factors
2. **Longitudinal Data**: Improve algorithms based on the user's own trend data over time
3. **Machine Learning**: Apply ML techniques to refine impact predictions based on aggregated anonymous data
4. **Additional Metrics**: Incorporate more health metrics as research evolves 