# Lifespan Calculations Documentation

This file documents ALL calculation logic currently implemented in the Amped iOS app as of the current codebase state. Every formula, constant, and algorithm is documented exactly as implemented.

## Overview of Calculation Services

The app uses a modular calculation architecture with these core services:

1. **LifeImpactService** - Main coordinator for all impact calculations
2. **ActivityImpactCalculator** - Physical activity metrics (steps, exercise, body mass, VO2 max, active energy, oxygen saturation)
3. **CardiovascularImpactCalculator** - Cardiovascular metrics (heart rate, HRV, sleep)
4. **LifestyleImpactCalculator** - Lifestyle metrics (alcohol, smoking, stress, nutrition, social connections)
5. **LifeProjectionService** - Life expectancy projections
6. **BaselineMortalityAdjuster** - Mortality and life expectancy tables
7. **InteractionEffectEngine** - Metric interaction effects
8. **HealthDataService** - HealthKit data processing and aggregation
9. **StudyReferenceProvider** - Research references and evidence grading

## Global Constants

All calculations use these baseline constants:

```swift
// From all calculators - Global baseline
private let baselineLifeMinutes = 78.0 * 365.25 * 24 * 60  // 40,996,800 minutes (78 years)

// Battery visualization normalization
private let batteryNormalization = 120.0  // ±120 minutes/day for 0-100% battery range

// Life expectancy bounds
private let maximumProjectedLifespan = 120.0  // Maximum projection in years
private let minimumRemainingYears = 1.0      // Minimum remaining life projection
```

## Individual Metric Calculation Formulas

### Steps Impact (ActivityImpactCalculator)

**SUMMARY RULE**: J-shaped curve with optimal at 10,000 steps. High mortality risk below 2,700 steps (RR=1.6), decreasing logarithmically to 0.90 RR at 12,000 steps, then slight increase above 25,000. Use exact thresholds: <2700, 2700-4000, 4000-10000 (logarithmic), 10000-12000, 12000-20000, 20000-25000, >25000. Convert RR to daily minutes using: (1-RR) × 0.082 × baselineLifeMinutes ÷ (remainingYears × 365.25)

**Research Basis**: Saint-Maurice et al. (2020) JAMA, Paluch et al. (2022) Lancet Public Health

**Formula**: J-shaped logarithmic model with exact thresholds

```swift
func calculateStepsLifeImpact(currentSteps: Double, userProfile: UserProfile) -> Double {
    let steps = max(0, currentSteps)
    let relativeRisk: Double
    
    if steps < 2700 {
        relativeRisk = 1.6 - 0.2 * (steps / 2700)
    } else if steps < 4000 {
        relativeRisk = 1.4 - 0.1 * ((steps - 2700) / (4000 - 2700))
    } else if steps <= 10000 {
        let ratio = (steps - 4000) / (10000 - 4000)
        relativeRisk = 1.3 - 0.35 * log(1 + ratio * (exp(1) - 1))
    } else if steps <= 12000 {
        relativeRisk = 0.95 - 0.05 * ((steps - 10000) / 2000)
    } else if steps <= 20000 {
        relativeRisk = 0.90 + 0.03 * ((steps - 12000) / 8000)
    } else if steps <= 25000 {
        relativeRisk = 0.93 + 0.07 * ((steps - 20000) / 5000)
    } else {
        relativeRisk = 1.00 + 0.15 * min((steps - 25000) / 10000, 1)
    }
    
    // Convert to daily impact
    let riskReduction = 1.0 - relativeRisk
    let impactScaling = 0.082  // From research (3.2 year gain for 50% RR reduction)
    let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
    let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
    let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
    
    return dailyImpact
}
```

**Key Thresholds**:
- Optimal: 10,000 steps (baseline value)
- High risk: < 2,700 steps
- Diminishing returns: > 12,000 steps
- Maximum tracked: 25,000 steps

### Exercise Minutes Impact (ActivityImpactCalculator)

**SUMMARY RULE**: Logarithmic benefits based on weekly minutes. 0 min/week = RR 1.0. 0-150 min/week: logarithmic decrease to RR 0.77 (23% mortality reduction). 150-300 min/week: linear decrease to RR 0.65. >300 min/week: minimal additional benefit (RR 0.60). Convert weekly to daily input. Use scaling factor 0.126 for RR-to-daily-minutes conversion.

**Research Basis**: Zhao et al. (2020) Circulation Research meta-analysis, WHO guidelines

**Formula**: Logarithmic model based on weekly minutes

```swift
func calculateExerciseLifeImpact(weeklyMinutes: Double, optimalWeekly: Double, userProfile: UserProfile) -> Double {
    let wkMin = max(0, weeklyMinutes)
    let relativeRisk: Double
    
    if wkMin <= 0 {
        relativeRisk = 1.0
    } else if wkMin <= 150 {
        relativeRisk = 1 - 0.23 * log(1 + wkMin/150 * (exp(1) - 1))
    } else if wkMin <= 300 {
        relativeRisk = 0.77 - 0.12 * ((wkMin - 150) / 150)
    } else {
        relativeRisk = 0.65 - 0.05 * min((wkMin - 300) / 300, 1)
    }
    
    // Convert to daily impact
    let riskReduction = 1.0 - relativeRisk
    let impactScaling = 0.126  // From research (3.4 year gain for 35% RR reduction)
    let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
    let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
    let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
    
    return dailyImpact
}
```

**Key Values**:
- Optimal: 150 minutes/week (WHO guidelines)
- Maximum benefit: 300 minutes/week
- Impact scaling: 0.126 (23% mortality reduction at 150 min/week)

### Sleep Hours Impact (CardiovascularImpactCalculator)

**SUMMARY RULE**: U-shaped curve with optimal 7-8 hours (RR=1.0). Penalties: <6h = +8% RR per hour deficit, 6-7h = +6% RR per hour, 8-9h = +6% RR per hour excess, >9h = +10% RR per hour. Within optimal band (7-8h): +2% RR per 0.5h deviation from 7.5h center. Use scaling factor 0.05 for RR-to-daily-minutes conversion.

**Research Basis**: Jike et al. (2018) Sleep Medicine meta-analysis

**Formula**: U-shaped curve with penalties for deviation from 7-8 hours

```swift
func calculateSleepLifeImpact(currentSleep: Double, userProfile: UserProfile) -> Double {
    let sleepH = max(3, min(currentSleep, 12))
    let relativeRisk: Double
    
    if sleepH >= 7.0 && sleepH <= 8.0 {
        // Optimal band 7–8 h: +2% RR / 0.5 h deviation
        let deviation = min(abs(sleepH - 7.5), 0.5)
        relativeRisk = 1.0 + (deviation / 0.5) * 0.02
    } else if sleepH < 6.0 {
        // Short <6 h: +8% RR per hr deficit
        let deficit = 6.0 - sleepH
        relativeRisk = 1.0 + deficit * 0.08
    } else if sleepH < 7.0 {
        // Borderline 6–7 h: +6% RR / hr
        let deficit = 7.0 - sleepH
        relativeRisk = 1.0 + deficit * 0.06
    } else if sleepH <= 9.0 {
        // Borderline 8–9 h: +6% RR / hr excess
        let excess = sleepH - 8.0
        relativeRisk = 1.0 + excess * 0.06
    } else {
        // Excess >9 h: +10% RR / hr
        let excess = sleepH - 9.0
        relativeRisk = 1.0 + excess * 0.10
    }
    
    // Convert to daily impact
    let riskReduction = 1.0 - relativeRisk
    let impactScaling = 0.05  // From research
    let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
    let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
    let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
    
    return dailyImpact
}
```

**Key Values**:
- Optimal range: 7.0-8.0 hours (baseline: 7.5)
- Moderate penalties: 6-7h and 8-9h (+6% RR per hour)
- Severe penalties: <6h (+8% RR per hour), >9h (+10% RR per hour)

### Resting Heart Rate Impact (CardiovascularImpactCalculator)

**SUMMARY RULE**: Linear relationship with 60 bpm optimal. +16% mortality risk per 10 bpm above 60. Formula: RR = 1.0 + (bpm-60)/10 × 0.16. Bounds: 40-120 bpm. Use scaling factor 0.05 for RR-to-daily-minutes conversion.

**Research Basis**: Aune et al. (2013) CMAJ meta-analysis

**Formula**: Linear increase in mortality risk

```swift
func calculateRHRLifeImpact(currentRHR: Double, userProfile: UserProfile) -> Double {
    let bpm = max(40, min(currentRHR, 120))
    let reference = 60.0  // Optimal RHR
    
    // Linear risk: +16% per 10 bpm > 60
    let bpmDifference = bpm - reference
    let relativeRisk = 1.0 + (bpmDifference / 10.0) * 0.16
    
    // Convert to daily impact
    let riskReduction = 1.0 - relativeRisk
    let impactScaling = 0.05  // From research
    let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
    let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
    let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
    
    return dailyImpact
}
```

**Key Values**:
- Optimal: 60 bpm (reference point)
- Linear penalty: +16% mortality risk per 10 bpm above 60
- Bounds: 40-120 bpm

### Heart Rate Variability Impact (CardiovascularImpactCalculator)

**SUMMARY RULE**: Linear relationship with 40ms reference point. ±17.4 minutes daily impact per 10ms deviation. Plateau at ±30ms (±52.2 minutes max). Bounds: 10-100ms. Direct minutes calculation, no RR conversion needed.

**Research Basis**: Expert consensus model

**Formula**: Linear with plateau effects

```swift
func calculateHRVLifeImpact(currentHRV: Double, userProfile: UserProfile) -> Double {
    let hrv = max(10, min(currentHRV, 100))
    let reference = 40.0  // Reference HRV
    
    // Calculate deviation from reference
    let hrvDifference = hrv - reference
    
    // Clamp to ±70 ms plateau
    let clampedDifference = max(-30.0, min(hrvDifference, 30.0))
    
    // ±17.4 min per 10 ms deviation
    let dailyImpact = (clampedDifference / 10.0) * 17.4
    
    return dailyImpact
}
```

**Key Values**:
- Reference: 40 ms
- Linear rate: ±17.4 minutes per 10 ms
- Plateau: ±30 ms (±52.2 minutes max impact)

### Alcohol Consumption Impact (LifestyleImpactCalculator)

**SUMMARY RULE**: Convert questionnaire scale (1-10) to actual drinks/day: 10=0, 8=0.25, 6=0.5, 4=1.0, 2=2.5, 0=4.0 drinks. Linear RR: ≤1 drink = +5% RR per drink, >1 drink = 1.05 + (excess×0.15). Clamp 0-5 drinks. Use scaling factor 0.08 for RR-to-daily-minutes conversion.

**Research Basis**: Wood et al. (2018) Lancet meta-analysis

**Formula**: Linear relationship with questionnaire scale conversion

```swift
func calculateAlcoholLifeImpact(drinksPerDay: Double, userProfile: UserProfile) -> Double {
    let drinks = max(0, min(drinksPerDay, 5)) // Clamp to reasonable range
    let relativeRisk: Double
    
    if drinks <= 1.0 {
        // +5% RR per drink up to 1/day
        relativeRisk = 1.0 + (drinks * 0.05)
    } else {
        // Steeper increase above 1 drink/day
        let excessDrinks = drinks - 1.0
        relativeRisk = 1.05 + (excessDrinks * 0.15) // Steeper penalty
    }
    
    // Convert to daily impact
    let riskReduction = 1.0 - relativeRisk
    let impactScaling = 0.08  // From research
    let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
    let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
    let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
    
    return dailyImpact
}

// Questionnaire conversion (scale 1-10 to actual drinks)
func convertQuestionnaireScaleToActualDrinks(questionnaireValue: Double) -> Double {
    switch questionnaireValue {
    case 9...10: return 0.0      // Never drink
    case 7..<9: return 0.25      // Rarely (1 drink/month)
    case 5..<7: return 0.5       // Occasionally (1 drink/week)
    case 3..<5: return 1.0       // Moderate (1 drink/day)
    case 1..<3: return 2.5       // Regular (2-3 drinks/day)
    case 0..<1: return 4.0       // Heavy (4+ drinks/day)
    default: return 0.0
    }
}
```

### Smoking Status Impact (LifestyleImpactCalculator)

**SUMMARY RULE**: Convert questionnaire scale (1-10) to smoking status: 10-9=Never (0), 8-6=Former (1), 5-2=Light (2), 1-0=Heavy (3). Fixed daily penalties: Never=0 min, Former=-116.1 min, Light=-232.2 min, Heavy=-348.3 min. Direct minutes, no RR conversion.

**Research Basis**: Extensive epidemiological studies

**Formula**: Fixed daily penalties by smoking status

```swift
func calculateSmokingLifeImpact(smokingStatus: Double) -> Double {
    let dailyImpact: Double
    
    switch Int(smokingStatus) {
    case 0: dailyImpact = 0.0      // Never smoker
    case 1: dailyImpact = -116.1   // Former smoker
    case 2: dailyImpact = -232.2   // Light smoker (<1 pack/day)
    case 3: dailyImpact = -348.3   // Heavy smoker (≥1 pack/day)
    default: dailyImpact = 0.0
    }
    
    return dailyImpact
}

// Questionnaire conversion (scale 1-10 to smoking status 0-3)
func convertQuestionnaireScaleToSmokingStatus(questionnaireValue: Double) -> Double {
    switch questionnaireValue {
    case 9...10: return 0.0  // Never smoker
    case 6..<9: return 1.0   // Former smoker
    case 2..<6: return 2.0   // Occasionally
    case 0..<2: return 3.0   // Daily heavy
    default: return 0.0
    }
}
```

### Stress Level Impact (LifestyleImpactCalculator)

**SUMMARY RULE**: Graduated risk by stress level (1-10 scale). ≤3=baseline RR 1.0. 3-6: +3% RR per level. 6-8: +5% RR per level. 8-10: +8% RR per level. Use scaling factor 0.04 for RR-to-daily-minutes conversion.

**Research Basis**: Chronic stress mortality research

**Formula**: Graduated risk increases by stress level

```swift
func calculateStressLifeImpact(stressLevel: Double, userProfile: UserProfile) -> Double {
    let level = max(1, min(stressLevel, 10))
    let relativeRisk: Double
    
    if level <= 3.0 {
        // Below optimal: baseline
        relativeRisk = 1.0
    } else if level <= 6.0 {
        // 3-6: Linear RR = 1 + 0.03*(level-3)
        relativeRisk = 1.0 + 0.03 * (level - 3.0)
    } else if level <= 8.0 {
        // 6-8: +0.05 per level
        let baseRisk = 1.0 + 0.03 * 3.0  // Risk at level 6
        relativeRisk = baseRisk + 0.05 * (level - 6.0)
    } else {
        // 8-10: +0.08 per level
        let baseRisk = 1.0 + 0.03 * 3.0 + 0.05 * 2.0  // Risk at level 8
        relativeRisk = baseRisk + 0.08 * (level - 8.0)
    }
    
    // Convert to daily impact
    let riskReduction = 1.0 - relativeRisk
    let impactScaling = 0.04  // From research
    let totalLifeMinChange = baselineLifeMinutes * riskReduction * impactScaling
    let remainingYears = max(1.0, 78.0 - Double(userProfile.age ?? 40))
    let dailyImpact = totalLifeMinChange / (remainingYears * 365.25)
    
    return dailyImpact
}
```

### Nutrition Quality Impact (LifestyleImpactCalculator)

**SUMMARY RULE**: Quality scale 1-10. <7: linear negative impact from 0 at score 7 to -6.9 min at score 1. 7-8: 0 minutes. 8-10: linear positive impact to +3.3 min at score 10. Direct minutes calculation, no RR conversion.

**Research Basis**: Dietary pattern research and Mediterranean diet studies

**Formula**: Corrected realistic nutrition impact values

```swift
func calculateNutritionLifeImpact(nutritionQuality: Double, userProfile: UserProfile) -> Double {
    let quality = max(1, min(nutritionQuality, 10))
    let dailyImpact: Double
    
    if quality < 7.0 {
        // Linear interpolation: score 7 = 0 min, score 1 = -6.9 min
        dailyImpact = (quality - 7.0) * (6.9 / 6.0) // Reduced by factor of 20 from original
    } else if quality <= 10.0 {
        // Score 7-8 stays at 0, score 8-10 gains benefit
        if quality < 8.0 {
            dailyImpact = 0.0
        } else {
            dailyImpact = (quality - 8.0) * (3.3 / 2.0) // Reduced by factor of 20 from original
        }
    } else {
        dailyImpact = 0.0
    }
    
    return dailyImpact
}
```

### Social Connections Impact (LifestyleImpactCalculator)

**SUMMARY RULE**: Quality scale 1-10. Linear relationship: score 1 = -43.5 min (isolated), score 5 = 0 min (neutral), score 10 = +3.3 min (highly connected). Direct minutes calculation, no RR conversion.

**Research Basis**: Loneliness mortality research

**Formula**: Linear relationship with social connection quality

```swift
func calculateSocialConnectionsLifeImpact(socialConnectionsQuality: Double, userProfile: UserProfile) -> Double {
    let quality = max(1, min(socialConnectionsQuality, 10))
    
    // Linear: -43.5 min at quality 1 (isolated), 0 min at quality 5, +3.3 min at quality 10
    let dailyImpact: Double
    if quality <= 5.0 {
        // Linear from -43.5 at 1 to 0 at 5
        dailyImpact = -43.5 + (quality - 1.0) * (43.5 / 4.0)
    } else {
        // Linear from 0 at 5 to +3.3 at 10
        dailyImpact = (quality - 5.0) * (3.3 / 5.0)
    }
    
    return dailyImpact
}
```

### Body Mass Impact (ActivityImpactCalculator)

**SUMMARY RULE**: Linear relationship with 160 lbs reference (≈24.5 BMI). ±17.4 minutes daily impact per ±20 lbs deviation. Bounds: 80-400 lbs. Direct minutes calculation, no RR conversion.

**Research Basis**: BMI mortality studies

**Formula**: Linear impact per weight deviation

```swift
func calculateBodyMassLifeImpact(bodyMass: Double, userProfile: UserProfile) -> Double {
    let mass = max(80, min(bodyMass, 400))  // Bounds: 80-400 lbs
    let reference = 160.0  // Reference weight (≈24.5 BMI)
    
    // Calculate deviation from reference
    let massDifference = mass - reference
    
    // ±17.4 min impact every ±20 lbs (linear)
    let dailyImpact = (massDifference / 20.0) * 17.4
    
    return dailyImpact
}
```

### VO2 Max Impact (ActivityImpactCalculator)

**SUMMARY RULE**: Age/gender-adjusted reference: base 40 ml·kg⁻¹·min⁻¹, -0.4 per year after age 30, females ×0.88. ±21.8 minutes daily impact per ±5 ml deviation. Plateau at ±20 ml (±87 min max). Bounds: 15-80 ml·kg⁻¹·min⁻¹. Direct minutes calculation.

**Research Basis**: Cardiovascular fitness research with age/gender adjustments

**Formula**: Linear with age and gender adjustments

```swift
func calculateVO2MaxLifeImpact(vo2Max: Double, userProfile: UserProfile) -> Double {
    let vo2 = max(15, min(vo2Max, 80))  // Bounds: 15-80 ml·kg⁻¹·min⁻¹
    
    // Age and gender adjusted reference
    let age = Double(userProfile.age ?? 30)
    let gender = userProfile.gender ?? .male
    
    // VO2 max declines ~1% per year after age 30
    let ageDecline = max(0, (age - 30) * 0.4) // 0.4 mL/kg/min per year
    var reference = 40.0 - ageDecline
    
    // Gender adjustment (females typically 10-15% lower)
    if gender == .female {
        reference *= 0.88
    }
    
    // Calculate deviation from reference
    let vo2Difference = vo2 - reference
    
    // Clamp to ±20 (gives ±87 min)
    let clampedDifference = max(-20.0, min(vo2Difference, 20.0))
    
    // ±21.8 min per ±5 ml difference
    let dailyImpact = (clampedDifference / 5.0) * 21.8
    
    return dailyImpact
}
```

### Active Energy Burned Impact (ActivityImpactCalculator)

**SUMMARY RULE**: Linear relationship with 400 kcal reference. ±17.4 minutes daily impact per ±100 kcal deviation. Clamp deviation to ±900 kcal. Bounds: 0-1300 kcal. Direct minutes calculation, no RR conversion.

**Research Basis**: Calorie expenditure research

**Formula**: Linear impact per calorie deviation

```swift
func calculateActiveEnergyLifeImpact(activeEnergy: Double, userProfile: UserProfile) -> Double {
    let energy = max(0, min(activeEnergy, 1300))  // Bounds: 0-1300 kcal
    let reference = 400.0  // Reference calories
    
    // Calculate deviation from reference
    let energyDifference = energy - reference
    
    // Clamp to ±900 kcal
    let clampedDifference = max(-900.0, min(energyDifference, 900.0))
    
    // ±17.4 min per 100 kcal deviation
    let dailyImpact = (clampedDifference / 100.0) * 17.4
    
    return dailyImpact
}
```

### Oxygen Saturation Impact (ActivityImpactCalculator)

**SUMMARY RULE**: Linear relationship with 98% reference. ±8.7 minutes daily impact per ±2% deviation. Bounds: 80-100%. Direct minutes calculation, no RR conversion.

**Research Basis**: Expert consensus

**Formula**: Linear impact per saturation deviation

```swift
func calculateOxygenSaturationLifeImpact(oxygenSaturation: Double, userProfile: UserProfile) -> Double {
    let saturation = max(80, min(oxygenSaturation, 100))  // Bounds: 80-100%
    let reference = 98.0  // Reference saturation
    
    // Calculate deviation from reference
    let saturationDifference = saturation - reference
    
    // ±8.7 min per ±2% deviation
    let dailyImpact = (saturationDifference / 2.0) * 8.7
    
    return dailyImpact
}
```

## Aggregated Impact Calculations

### Total Impact Calculation (LifeImpactService)

**SUMMARY RULE**: 5-step process: (1) Calculate individual daily impacts for each metric, (2) Apply interaction effects (synergies/antagonisms), (3) Apply mortality adjustments (sqrt(baseRate/mortalityRate)), (4) Weight by evidence quality (High=1.0x, Moderate=0.8x, Low=0.6x), (5) Apply simple linear period scaling (Day×1, Month×30, Year×365). Individual metrics are ALWAYS daily averages regardless of period.

The total impact calculation follows this process:

1. **Calculate Individual Impacts**: Each metric gets its daily impact calculated
2. **Apply Interaction Effects**: Synergies and antagonisms between metrics
3. **Apply Mortality Adjustments**: Age and gender-specific adjustments
4. **Weight by Evidence Quality**: Impacts weighted by research reliability
5. **Apply Period Scaling**: Simple linear scaling for time periods

```swift
func calculateTotalImpact(from metrics: [HealthMetric], for periodType: ImpactDataPoint.PeriodType) -> ImpactDataPoint {
    // Step 1: Calculate individual impacts
    var impacts = calculateImpacts(for: metrics)
    
    // Step 2: Apply interaction effects
    impacts = interactionEngine.calculateAdjustedImpacts(impacts: impacts, metrics: metrics)
    
    // Step 3: Apply mortality adjustments
    let age = userProfile.age ?? 30
    let gender = userProfile.gender ?? .male
    impacts = impacts.map { impact in
        let adjustedDailyImpact = mortalityAdjuster.adjustImpactForMortality(
            dailyImpact: impact.lifespanImpactMinutes,
            age: age,
            gender: gender
        )
        // Return new MetricImpactDetail with adjusted impact...
    }
    
    // Step 4: Sum daily impacts with evidence weighting
    var totalDailyImpactMinutes: Double = 0
    var evidenceQualityScore: Double = 0
    
    for impact in impacts {
        let evidenceWeight = impact.reliabilityScore
        let weightedDailyImpact = impact.lifespanImpactMinutes * evidenceWeight
        totalDailyImpactMinutes += weightedDailyImpact
        evidenceQualityScore += evidenceWeight
    }
    
    evidenceQualityScore = impacts.isEmpty ? 0 : evidenceQualityScore / Double(impacts.count)
    
    // Step 5: Apply period scaling (SIMPLE LINEAR)
    let scaledTotalImpact: Double
    switch periodType {
    case .day:
        scaledTotalImpact = totalDailyImpactMinutes
    case .month:
        scaledTotalImpact = totalDailyImpactMinutes * 30.0
    case .year:
        scaledTotalImpact = totalDailyImpactMinutes * 365.0
    }
    
    return ImpactDataPoint(
        date: Date(),
        periodType: periodType,
        totalImpactMinutes: scaledTotalImpact,
        metricImpacts: impactsByType,
        evidenceQualityScore: evidenceQualityScore
    )
}
```

### Battery Level Calculation (LifeImpactService)

**SUMMARY RULE**: Normalize impact to ±1.0 range using ±120 minutes/day. Battery = 50% + (normalizedImpact × 50%). 0 impact = 50% battery, +120 min/day = 100% battery, -120 min/day = 0% battery. Clamp to 0-100% range.

```swift
func calculateBatteryLevel(from impactMinutes: Double) -> Double {
    // Battery level calculation:
    // 50% = baseline (0 impact)
    // 100% = very positive impact (+120 minutes/day)
    // 0% = very negative impact (-120 minutes/day)
    
    let normalizedImpact = impactMinutes / 120.0 // Normalize to ±1.0 range
    let batteryLevel = 50.0 + (normalizedImpact * 50.0) // Convert to 0-100 range
    
    return max(0.0, min(100.0, batteryLevel))
}
```

## Interaction Effects (InteractionEffectEngine)

**SUMMARY RULE**: Apply multiplicative factors to adjust individual metric impacts. Positive synergies >1.0x: Sleep+Exercise (1.15x), Exercise+HRV (1.10x), Nutrition+Exercise (1.12x). Negative antagonisms <1.0x: Alcohol+HRV (0.75x), Alcohol+Sleep (0.80x), Stress+Sleep (0.85x). Body mass reduces activity benefits by 0.90x per 20 lbs over 200 lbs.

### Sleep-Exercise Synergy

```swift
// 15% boost (1.15x) when both sleep (7-8h) and exercise (>150min/week) are optimal
static let sleepExerciseSynergy = 1.15
```

### Alcohol-HRV Antagonism

```swift
// 25% reduction (0.75x) in HRV benefits when alcohol consumption >2 drinks/day
static let alcoholHRVAntagonism = 0.75
```

### Alcohol-Sleep Antagonism

```swift
// 20% reduction (0.80x) in sleep benefits
static let alcoholSleepAntagonism = 0.80
```

### Stress-Sleep Antagonism

```swift
// 15% reduction (0.85x) in sleep benefits when stress level >7
static let stressSleepAntagonism = 0.85
```

### Body Mass-Activity Interaction

```swift
// 10% reduction (0.90x) in activity benefits per 20 lbs over 200 lbs threshold
static let bodyMassActivityThreshold = 200.0 // lbs
static let bodyMassActivityReduction = 0.90   // per 20 lbs over threshold
```

## Life Projection Calculations (LifeProjectionService)

**SUMMARY RULE**: Use WHO 2023 life tables for baseline expectancy by age/gender. Apply behavior decay in 5-year segments using exponential decay (Exercise/Steps=15%, Smoking/Alcohol=5%, Sleep/Nutrition=10%, Default=12% annual). Calculate total impact over remaining years, convert to years (÷525,600 min/year), apply evidence weighting, add to baseline. Bound between age+1 and 120 years.

### Baseline Life Expectancy Tables (BaselineMortalityAdjuster)

**WHO Global 2023 Life Tables**:

```swift
// Life expectancy by age and gender (remaining years)
private struct LifeExpectancyTable {
    static let male: [Int: Double] = [
        0: 71.4, 10: 62.1, 20: 52.3, 30: 42.8, 40: 33.5,
        50: 24.7, 60: 16.8, 70: 10.1, 80: 5.5, 90: 3.0
    ]
    
    static let female: [Int: Double] = [
        0: 76.8, 10: 67.4, 20: 57.5, 30: 47.7, 40: 38.1,
        50: 28.8, 60: 20.1, 70: 12.5, 80: 6.8, 90: 3.5
    ]
}

// Mortality rates per 100,000
private struct MortalityTable {
    static let maleRates: [Int: Double] = [
        0: 4.5, 10: 0.15, 20: 0.75, 30: 1.2, 40: 2.0,
        50: 4.5, 60: 11.0, 70: 25.0, 80: 60.0, 90: 150.0
    ]
    
    static let femaleRates: [Int: Double] = [
        0: 3.8, 10: 0.12, 20: 0.35, 30: 0.7, 40: 1.4,
        50: 3.0, 60: 7.0, 70: 17.0, 80: 45.0, 90: 130.0
    ]
}
```

### Mortality Adjustment Formula

```swift
func adjustImpactForMortality(dailyImpact: Double, age: Int, gender: UserProfile.Gender) -> Double {
    let mortalityRate = getAnnualMortalityRate(age: age, gender: gender)
    
    // Calculate adjustment factor
    let baseRate = 0.001 // 0.1% baseline
    let adjustmentFactor = baseRate / max(mortalityRate, baseRate)
    
    // Apply non-linear adjustment (sqrt for more realistic curve)
    let adjustedImpact = dailyImpact * sqrt(adjustmentFactor)
    
    return adjustedImpact
}
```

### Behavior Decay Rates

```swift
func applyBehaviorDecay(impact: Double, yearsInFuture: Double, behaviorType: HealthMetricType) -> Double {
    let decayRate: Double
    switch behaviorType {
    case .exerciseMinutes, .steps:
        decayRate = 0.15 // 15% annual decay (harder to maintain)
    case .smokingStatus, .alcoholConsumption:
        decayRate = 0.05 // 5% annual decay (addiction patterns)
    case .sleepHours, .nutritionQuality:
        decayRate = 0.10 // 10% annual decay
    default:
        decayRate = 0.12 // 12% default decay
    }
    
    // Exponential decay model
    let decayFactor = exp(-decayRate * yearsInFuture)
    return impact * decayFactor
}
```

### Life Projection Formula

```swift
func generateLifeProjection(for userProfile: UserProfile, dailyImpactMinutes: Double, evidenceQuality: Double) -> LifeProjection {
    // Get baseline life expectancy
    let baselineLifeExpectancy = mortalityAdjuster.getBaselineLifeExpectancy(for: userProfile)
    let userAge = Double(userProfile.age ?? 30)
    let remainingYears = max(1.0, baselineLifeExpectancy - userAge)
    
    // Apply behavior decay over time in 5-year segments
    var totalLifespanImpactMinutes = 0.0
    let yearsPerSegment = 5.0
    var currentYear = 0.0
    
    while currentYear < remainingYears {
        let segmentYears = min(yearsPerSegment, remainingYears - currentYear)
        let segmentDays = segmentYears * 365.25
        
        // Apply decay for this segment using midpoint
        let decayedDailyImpact = applyBehaviorDecayToAggregate(
            dailyImpact: dailyImpactMinutes,
            yearsInFuture: currentYear + segmentYears / 2.0
        )
        
        totalLifespanImpactMinutes += decayedDailyImpact * segmentDays
        currentYear += segmentYears
    }
    
    // Convert total impact minutes to years
    let lifespanImpactYears = totalLifespanImpactMinutes / (365.25 * 24 * 60)
    
    // Apply evidence quality weighting
    let evidenceAdjustedImpact = lifespanImpactYears * evidenceQuality
    
    // Calculate projected lifespan
    let projectedLifespan = baselineLifeExpectancy + evidenceAdjustedImpact
    
    // Bound between age+1 and 120 years
    let boundedProjection = max(userAge + 1, min(120.0, projectedLifespan))
    
    return LifeProjection(
        id: UUID(),
        calculationDate: Date(),
        baselineLifeExpectancyYears: baselineLifeExpectancy,
        adjustedLifeExpectancyYears: boundedProjection,
        confidencePercentage: evidenceQuality,
        confidenceIntervalYears: 2.0
    )
}
```

## HealthKit Data Processing (HealthDataService)

**SUMMARY RULE**: Use HKStatisticsCollectionQuery with proper options. Cumulative metrics (steps, exercise, energy): cumulativeSum, calculate daily totals then average. Status metrics (heart rate, HRV, weight): averageQuantity, extract daily averages then overall average. Include zero days for accurate averages. For daily view: use HKStatisticsQuery with today only. For periods: enumerate statistics over date range matching Apple Health methodology.

### Cumulative Metrics (Steps, Exercise, Active Energy)

Uses `HKStatisticsCollectionQuery` with `cumulativeSum` option:

```swift
// For monthly period: Calculate daily totals and average
collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
    if let sumQuantity = statistics.sumQuantity() {
        let dailyValue = sumQuantity.doubleValue(for: unit)
        dailyValues.append(dailyValue)
        totalSum += dailyValue
    } else {
        dailyValues.append(0.0) // Include zero days for accurate averages
    }
}

// Calculate average daily value exactly like Apple Health
let averageDailyValue = totalSum / Double(totalDays)
```

### Status Metrics (Heart Rate, HRV, Weight)

Uses `HKStatisticsCollectionQuery` with `averageQuantity`:

```swift
// Extract daily averages and calculate overall average
collection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
    if let averageQuantity = statistics.averageQuantity() {
        let dailyAverage = averageQuantity.doubleValue(for: unit)
        dailyAverages.append(dailyAverage)
    }
}

// Calculate overall average
let overallAverage = dailyAverages.reduce(0, +) / Double(dailyAverages.count)
```

### Sleep Processing (HealthKitSleepManager)

Special handling for sleep data using category samples:

```swift
// Query HKCategoryValueSleepAnalysis samples
// Sum all sleep stages for total sleep duration
// Convert to hours for impact calculation
```

## Evidence Quality and Study References

### Study Reference Provider

The app uses real peer-reviewed research with proper citations:

**Steps Research**:
- Saint-Maurice et al. (2020) JAMA - 4,840 participants, 10.1 year follow-up
- Paluch et al. (2022) Lancet Public Health - 47,471 participants, meta-analysis

**Sleep Research**:
- Jike et al. (2018) Sleep Medicine - 3,995,848 participants, meta-analysis

**Exercise Research**:
- Zhao et al. (2020) Circulation Research - 1,737,844 participants, meta-analysis

**Cardiovascular Research**:
- Aune et al. (2013) CMAJ - 463,520 participants, meta-analysis (heart rate)

**Alcohol Research**:
- Wood et al. (2018) Lancet - 599,912 participants, individual-participant data

### Evidence Quality Scoring

```swift
enum EvidenceStrength: String {
    case high = "High" // Meta-analyses, large cohorts
    case moderate = "Moderate" // Smaller studies, limited follow-up  
    case low = "Low" // Expert consensus, extrapolated data
}

// Reliability scores used for weighting
extension MetricImpactDetail {
    var reliabilityScore: Double {
        switch evidenceStrength {
        case .high: return 1.0
        case .moderate: return 0.8
        case .low: return 0.6
        }
    }
}
```

## Configuration and Constants Summary

**Global Settings**:
- Baseline life expectancy: 78 years
- Battery normalization: ±120 minutes/day
- Maximum projection: 120 years
- Confidence interval: ±2 years

**Period Scaling**:
- Day: 1x (no scaling)
- Month: 30x (simple linear)
- Year: 365x (simple linear)

**Evidence Weighting**:
- High quality: 1.0x
- Moderate quality: 0.8x  
- Low quality: 0.6x

**Behavior Decay Rates**:
- Exercise/Steps: 15% annual
- Smoking/Alcohol: 5% annual
- Sleep/Nutrition: 10% annual
- Default: 12% annual

This documentation reflects the exact current state of all calculations in the Amped iOS app as implemented in the codebase.