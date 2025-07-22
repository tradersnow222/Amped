# Lifespan Calculations Rules

This file documents all calculation logic related to health metrics, lifespan impact, and projections in the Amped iOS app.

## Recent Fixes (2024)

### Phase 4: Recommendation Text & Logic Consistency Fix

**Issues Fixed:**
- ❌ **Inconsistent Text Formatting** → ✅ All recommendations now end with "to add X to your life"
- ❌ **Confusing Period Logic** → ✅ Daily shows additional needed, Month/Year shows total daily targets
- ❌ **Mixed Recommendation Patterns** → ✅ Consistent format across all metric types

**Text Improvements:**
- **Year Recommendations**: Changed from "this year" to "this next year to add X to your life"
- **Month Recommendations**: Changed from "this month" to "this month to add X to your life" 
- **Consistent Endings**: All recommendations now clearly state the life benefit

**Logic Improvements:**
- **Daily Period**: Shows additional amount needed (e.g., "Walk 4,143 more steps today")
- **Month/Year Period**: Shows total daily target (e.g., "Walk 8,743 steps daily this next year")
- **Steps Logic**: For sustained periods, users get total daily step target instead of additional steps
- **Exercise Logic**: Same pattern - additional for daily, total target for month/year
- **Sleep Logic**: Additional hours for daily, total sleep target for sustained periods

**Examples of Fixed Recommendations:**
- Before: "Walk 4,859 steps daily to add 15.0 days this year"
- After: "Walk 8,743 steps daily this next year to add 15.0 days to your life"

**Files Modified:**
- `Amped/Features/UI/RecommendationService.swift`: Updated all recommendation functions for consistency

### Phase 3: Recommendation System Truth Fix

**Issues Fixed:**
- ❌ **Artificial Caps on Recommendations** → ✅ Show actual action needed to reach neutral
- ❌ **Misleading Benefits** → ✅ Show true benefit of reaching 0 impact
- ❌ **Hardcoded Limits** → ✅ Dynamic calculations based on actual deficit

**Root Cause:**
- `calculateRealisticStepTarget` was capping recommendations at 5000 steps (50 min walk)
- `applyRealisticBounds` was limiting benefits to 15 min/day max
- This created confusing recommendations like "Walk 50 min to add 15 min" when user needed more

**Solution:**
- Remove all artificial caps - show the truth
- Calculate exact action needed to reach neutral (0 impact)
- Show the actual benefit of reaching neutral
- Format large walking times appropriately (e.g., "Walk 1h 45min")

**Example Fix:**
- Before: "Walk 50 minutes to add 15 min" (capped and misleading)
- After: "Walk 7,900 steps to add 1 hour 42 minutes" (truthful and motivating with actual step count needed)

**New Recommendation Principles:**
1. **Negative Metrics Priority**: The recommendation should always show the user how much they need to change their metric in order to achieve neutral time (0 impact)
2. **Positive Metrics Enhancement**: If there are no negative metrics to bring up to neutral, then the recommendation should take the lowest positive metric and tell the user how to add 20% to it

**Files Modified:**
- `Amped/Features/UI/RecommendationService.swift`: Removed caps, show true values

### Phase 1: Life Impact Scaling Logic Overhaul

**Issues Fixed:**
- ❌ **U-Shaped Compounding Bug** → ✅ Removed artificial amplification for daily periods in sleep calculations
- ❌ **Logarithmic Scaling Underestimation** → ✅ Fixed diminishing returns formula to maintain logical progression
- ❌ **Inconsistent Daily vs Monthly/Yearly Values** → ✅ Daily impacts no longer artificially inflated beyond true values
- ❌ **Missing Debug Visibility** → ✅ Comprehensive logging for all scaling calculations

**Technical Corrections:**
- **Sleep U-Shaped Effects**: Daily periods now return unmodified daily impact (no 25% amplification)
- **Exercise/Steps Logarithmic**: Monthly uses 85% of linear scaling, Yearly uses 65% (realistic diminishing returns)
- **Threshold Effects**: Daily periods get 30% of full effect (minimal but non-zero single-day impact)
- **Validation**: Added bounds checking and warnings for illogical scaling results

**Mathematical Progression Fixed:**
- Before: Day: -50 min, Month: -1,275 min, Year: -11,850 min (logical progression)
- After: Day: -50 min, Month: -1,275 min, Year: -11,850 min (logical progression)

**Files Modified:**
- `Amped/Features/LifeImpact/LifeImpactService.swift`: Core scaling logic fixes
- `.cursor/rules/lifespan-calculations.mdc`: Documentation updates

### "Today's Focus" Recommendations System Overhaul

**Issues Fixed:**
- ❌ **Hardcoded 20-minute walk recommendations** → ✅ Dynamic action sizing based on actual deficit
- ❌ **Mathematically impossible benefits** (20min walk → 36min life gain) → ✅ Realistic bounds checking (max 15min daily benefit from walking)
- ❌ **Inconsistent period scaling** (daily vs monthly vs yearly) → ✅ Proper period-appropriate calculations
- ❌ **Single action size for all users** → ✅ Personalized recommendations based on current fitness level

**Mathematical Corrections:**
- Daily view: Shows actual daily benefit achievable
- Monthly view: Shows monthly total if action sustained daily (dailyBenefit × 30)
- Yearly view: Shows yearly total if action sustained daily (dailyBenefit × 365)
- Bounds: Steps max 15min/day, Exercise max 20min/day, Sleep max 10min/day

**Files Modified:**
- `Amped/Features/UI/RecommendationService.swift`: Core recommendation logic
- `Amped/UI/Components/ActionableRecommendationsView.swift`: UI integration
- `.cursor/rules/lifespan-calculations.mdc`: Documentation updates

## Time Formatting Guidelines

### Display Rules
1. **Minutes (< 60)**: Display as "X minutes" (e.g., "45 minutes")
   - Singular: "1 minute"
   - Plural: "45 minutes"

2. **Hours (60+ minutes)**: Display as "X hours Y minutes" (e.g., "1 hour 19 minutes")
   - If exactly whole hours, display as "X hours" (e.g., "2 hours")
   - Singular hour: "1 hour 15 minutes"
   - Plural hours: "2 hours 30 minutes"

3. **Days (24+ hours)**: Display as "X.X days" with one decimal place (e.g., "2.5 days")
   - If exactly whole days, display as "X days" (e.g., "3 days")
   - Always use decimal notation for partial days

### Implementation
- Use the `formattedAsTime()` extension for full text display (e.g., "1 hour 19 minutes")
- Use the `formattedAsTimeShort()` extension for compact display (e.g., "1h 19m", "2.5d")
- This formatting applies to ALL time displays throughout the app
- Located in: `Amped/Core/Extensions/TimeFormattingExtensions.swift`

### Examples
- 79 minutes → "1 hour 19 minutes" (full) or "1h 19m" (short)
- 120 minutes → "2 hours" (full) or "2h" (short)
- 1500 minutes → "1 day 1 hour" (full) or "1.0d" (short)
- 3660 minutes → "2.5 days" (full) or "2.5d" (short)

### Special Case: Steps Recommendations
- **Steps metrics**: Show actual step count needed (e.g., "Walk 7,900 steps") instead of time
- **Other metrics**: Continue using time formatting (e.g., "Exercise 1 hour 30 minutes")
- **Benefits**: Always show time format for the benefit portion (e.g., "to add 1 hour 42 minutes")

### Recommendation Ending Format (Updated Phase 4)
- **All recommendations**: End with "to add X to your life" for clear benefit messaging
- **Daily recommendations**: Show additional amount needed (e.g., "Walk 4,143 more steps today to add 1 hour 42 minutes to your life")
- **Sleep daily recommendations**: Use "tonight" instead of "today" (e.g., "Sleep 1 hour more tonight to add 30 minutes to your life")
- **Month recommendations**: Show total daily target (e.g., "Walk 8,743 steps daily this month to add 30 hours to your life")
- **Year recommendations**: Show total daily target (e.g., "Walk 8,743 steps daily this next year to add 15.0 days to your life")

## Core Recommendation Logic

### Recommendation Principles (Updated Phase 3)

```json
{
  "rule_id": "recommendations.core.principles",
  "file": "Amped/Features/UI/RecommendationService.swift",
  "description": "Core principles governing recommendation logic",
  "principles": [
    {
      "priority": 1,
      "rule": "Always show user how much they need to change their metric to achieve neutral time (0 impact)",
      "applies_to": "All negative impact metrics",
      "example": "Steps -1.7h → Walk 7,900 steps to add 1 hour 42 minutes (reach neutral)"
    },
    {
      "priority": 2,
      "rule": "If no negative metrics, take lowest positive metric and show how to add 20% to it",
      "applies_to": "All positive or zero impact metrics",
      "examples": {
        "day": "Walk 15min more today to add 4 min to your life",
        "month": "Walk 15min more daily to add 4 min over the next month", 
        "year": "Walk 15min more daily to add 4 min over the next year"
      }
    }
  ]
}
```

### Recommendation Generation Logic (Fixed Phase 3)

```json
{
  "rule_id": "recommendations.generate.fixed",
  "file": "Amped/Features/UI/RecommendationService.swift",
  "function": "generateRecommendation",
  "description": "Generates truthful, dynamic recommendations without artificial caps",
  "inputs": ["metric", "selectedPeriod"],
  "outputs": ["truthfulRecommendation"],
  "logic": {
    "negative_impact": "Calculate exact action to reach neutral (0 impact)",
         "positive_impact": "Calculate 20% improvement on lowest positive metric, show time benefit over selected period",
    "no_caps": "Show actual time/action needed, no artificial limits",
    "formatting": "Large times shown as 'Xh Ymin' for readability"
  },
  "improvements": [
    "Removed calculateRealisticStepTarget caps (was max 5000 steps)",
    "Removed applyRealisticBounds caps (was max 15min benefit)",
    "Show actual benefit of reaching neutral",
    "Dynamic time formatting for large recommendations"
  ]
}
```

## Individual Metric Impact Calculations

### Steps Impact

```json
{
  "rule_id": "lifeImpact.steps.daily",
  "file": "Amped/Features/LifeImpact/ActivityImpactCalculator.swift",
  "function": "calculateStepsLifeImpact",
  "description": "Calculates daily lifespan impact from steps using J-shaped logarithmic model based on Saint-Maurice et al. (2020) JAMA and Paluch et al. (2022) Lancet Public Health.",
  "inputs": ["currentSteps", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "J-shaped model: <2700 steps: RR=1.6-0.2*(steps/2700); 2700-4000: RR=1.4-0.1*((steps-2700)/1300); 4000-10000: RR=1.3-0.35*log(1+ratio*(e-1)); >10000: diminishing returns"
}
```

### Exercise Minutes Impact

```json
{
  "rule_id": "lifeImpact.exercise.daily",
  "file": "Amped/Features/LifeImpact/ActivityImpactCalculator.swift",
  "function": "calculateExerciseLifeImpact",
  "description": "Calculates exercise impact based on WHO guidelines showing 23% mortality reduction for meeting 150 min/week.",
  "inputs": ["weeklyMinutes", "optimalWeekly", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "0-150 min/week: RR=1-0.23*log(1+min/150*(e-1)); 150-300: RR=0.77-0.12*((min-150)/150); >300: RR=0.65-0.05*min((min-300)/300,1)"
}
```

### Sleep Hours Impact

```json
{
  "rule_id": "lifeImpact.sleep.daily",
  "file": "Amped/Features/LifeImpact/CardiovascularImpactCalculator.swift",
  "function": "calculateSleepLifeImpact",
  "description": "Calculates sleep impact using U-shaped curve model from Jike et al. (2018) Sleep Medicine meta-analysis.",
  "inputs": ["currentSleep", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "U-shaped: 7-8h optimal (RR=1.0+2%/0.5h deviation); <6h: +8% RR/hr deficit; 6-7h: +6% RR/hr; 8-9h: +6% RR/hr excess; >9h: +10% RR/hr"
}
```

### Resting Heart Rate Impact

```json
{
  "rule_id": "lifeImpact.rhr.daily",
  "file": "Amped/Features/LifeImpact/CardiovascularImpactCalculator.swift",
  "function": "calculateRHRLifeImpact",
  "description": "Calculates resting heart rate impact using linear model from Aune et al. (2013) CMAJ meta-analysis.",
  "inputs": ["currentRHR", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Linear: +16% mortality risk per 10 bpm above 60. Daily impact = (RHR-60)/10 * riskFactor * scalingFactor"
}
```

### Heart Rate Variability Impact

```json
{
  "rule_id": "lifeImpact.hrv.daily",
  "file": "Amped/Features/LifeImpact/CardiovascularImpactCalculator.swift",
  "function": "calculateHRVLifeImpact",
  "description": "Calculates HRV impact using expert consensus model with plateau effects.",
  "inputs": ["currentHRV", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Reference 40ms = 0 impact. +17.4 min per 10ms above, -17.4 min per 10ms below, plateau at ±70ms"
}
```

### Alcohol Consumption Impact

```json
{
  "rule_id": "lifeImpact.alcohol.daily",
  "file": "Amped/Features/LifeImpact/LifestyleImpactCalculator.swift",
  "function": "calculateAlcoholLifeImpact",
  "description": "Calculates alcohol impact based on Wood et al. (2018) Lancet meta-analysis of 599,912 current drinkers.",
  "inputs": ["drinksPerDay", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Linear: -17.4 min per drink/day (14g alcohol). Questionnaire scale 1-10 converted to actual drinks"
}
```

### Smoking Status Impact

```json
{
  "rule_id": "lifeImpact.smoking.daily",
  "file": "Amped/Features/LifeImpact/LifestyleImpactCalculator.swift",
  "function": "calculateSmokingLifeImpact",
  "description": "Calculates smoking impact based on extensive mortality research.",
  "inputs": ["smokingStatus", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Scale 1-10: 10=never (-0 min), 8=quit >5y (-3.5 min), 6=quit 1-5y (-17.4 min), 4=occasional (-43.5 min), 1=heavy (-139.2 min)"
}
```

### Stress Level Impact

```json
{
  "rule_id": "lifeImpact.stress.daily",
  "file": "Amped/Features/LifeImpact/LifestyleImpactCalculator.swift",
  "function": "calculateStressLifeImpact",
  "description": "Calculates stress impact based on chronic stress mortality research.",
  "inputs": ["stressLevel", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Linear: 0 impact at level 1, -34.8 min at level 10. Impact = -3.87 * (stressLevel - 1)"
}
```

### Nutrition Quality Impact

```json
{
  "rule_id": "lifeImpact.nutrition.daily",
  "file": "Amped/Features/LifeImpact/LifestyleImpactCalculator.swift",
  "function": "calculateNutritionLifeImpact",
  "description": "Calculates nutrition impact based on diet quality research.",
  "inputs": ["nutritionQuality", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Score <7: linear negative impact up to -6.9 min at score 1; Score 8-10: positive impact up to +3.3 min at score 10"
}
```

### Social Connections Impact

```json
{
  "rule_id": "lifeImpact.socialConnections.daily",
  "file": "Amped/Features/LifeImpact/LifestyleImpactCalculator.swift",
  "function": "calculateSocialConnectionsLifeImpact",
  "description": "Calculates social connections impact based on loneliness mortality research.",
  "inputs": ["socialConnectionsQuality", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Linear: -43.5 min at quality 1 (isolated), 0 min at quality 5, +3.3 min at quality 10"
}
```

### Body Mass Impact

```json
{
  "rule_id": "lifeImpact.bodyMass.daily",
  "file": "Amped/Features/LifeImpact/ActivityImpactCalculator.swift",
  "function": "calculateBodyMassLifeImpact",
  "description": "Calculates body mass impact using linear model.",
  "inputs": ["bodyMass", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Reference 160 lbs. ±17.4 min impact every ±20 lbs (linear)"
}
```

### VO2 Max Impact

```json
{
  "rule_id": "lifeImpact.vo2Max.daily",
  "file": "Amped/Features/LifeImpact/ActivityImpactCalculator.swift",
  "function": "calculateVO2MaxLifeImpact",
  "description": "Calculates VO2 Max impact based on cardiovascular fitness research.",
  "inputs": ["vo2Max", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Reference 40. ±21.8 min per ±5 ml difference, capped at ±87 min"
}
```

### Active Energy Burned Impact

```json
{
  "rule_id": "lifeImpact.activeEnergy.daily",
  "file": "Amped/Features/LifeImpact/ActivityImpactCalculator.swift",
  "function": "calculateActiveEnergyLifeImpact",
  "description": "Calculates active energy impact based on calorie burn.",
  "inputs": ["activeEnergy", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Reference 400 kcal = 0 impact. ±17.4 min per 100 kcal deviation, clamped ±900 kcal"
}
```

### Oxygen Saturation Impact

```json
{
  "rule_id": "lifeImpact.oxygenSaturation.daily",
  "file": "Amped/Features/LifeImpact/ActivityImpactCalculator.swift",
  "function": "calculateOxygenSaturationLifeImpact",
  "description": "Calculates oxygen saturation impact.",
  "inputs": ["oxygenSaturation", "userProfile"],
  "outputs": ["dailyImpactMinutes"],
  "dependencies": ["StudyReferenceProvider"],
  "formula": "Reference 98%. ±8.7 min per ±2% deviation"
}
```

## Aggregated Impact Calculations

### Total Daily Impact

```json
{
  "rule_id": "lifeImpact.total.daily",
  "file": "Amped/Features/LifeImpact/LifeImpactService.swift",
  "function": "calculateTotalImpact",
  "description": "Aggregates individual metric impacts with interaction effects and mortality adjustments.",
  "inputs": ["metrics", "periodType", "userProfile"],
  "outputs": ["ImpactDataPoint"],
  "dependencies": ["InteractionEffectEngine", "BaselineMortalityAdjuster"],
  "steps": [
    "Calculate individual impacts",
    "Apply interaction effects",
    "Apply mortality adjustments",
    "Apply advanced scaling",
    "Weight by evidence quality"
  ]
}
```

### Period Scaling (Updated Phase 1)

```json
{
  "rule_id": "lifeImpact.scaling.period",
  "file": "Amped/Features/LifeImpact/LifeImpactService.swift",
  "function": "applyAdvancedScaling",
  "description": "Scales daily impacts to monthly/yearly based on effect type and behavior patterns with comprehensive debug logging and validation.",
  "inputs": ["impact", "periodType", "metrics"],
  "outputs": ["scaledImpact"],
  "dependencies": ["EffectType"],
  "debug_features": [
    "Logs effect type and daily impact for each metric",
    "Shows scaling calculations step-by-step",
    "Validates logical progression (yearly > monthly > daily)",
    "Warns when scaling seems illogical"
  ],
  "scaling_rules": {
    "linearCumulative": "Simple multiplication (day*30, day*365) - no changes",
    "logarithmic": "FIXED: Diminishing returns with 85% monthly, 65% yearly scaling (was broken log formula)",
    "diminishingReturns": "Same as logarithmic - proper multiplication with diminishing factors",
    "uShapedCurve": "FIXED: Daily periods return unmodified impact (was artificially amplified), monthly/yearly use moderate compounding",
    "thresholdBased": "FIXED: Daily gets 30% effect (was 0%), full scaling after 21-day threshold",
    "exponential": "FIXED: Added 50% bounds checking, 0.1% daily compound with realistic caps",
    "plateau": "FIXED: Daily returns full effect, 20% continuation after 30-day plateau (was 10%)"
  },
  "validation": {
    "expected_minimum_scaling": "Monthly ≥20x daily, Yearly ≥180x daily",
    "warning_threshold": "Logs warning when scaling falls below expected minimums",
    "bounds_checking": "Exponential effects capped at 150% of linear scaling"
  }
}
```

## Interaction Effects

### Sleep-Exercise Synergy

```json
{
  "rule_id": "interaction.sleepExercise",
  "file": "Amped/Features/LifeImpact/InteractionEffectEngine.swift",
  "function": "calculateSleepExerciseSynergy",
  "description": "Calculates synergistic effects between sleep and exercise.",
  "inputs": ["sleepImpact", "exerciseImpact", "metrics"],
  "outputs": ["synergyMultiplier"],
  "dependencies": [],
  "formula": "15% boost (1.15x) when both sleep (7-8h) and exercise (>150min/week) are optimal"
}
```

### Alcohol-HRV Antagonism

```json
{
  "rule_id": "interaction.alcoholHRV",
  "file": "Amped/Features/LifeImpact/InteractionEffectEngine.swift",
  "function": "calculateAlcoholHRVAntagonism",
  "description": "Calculates negative interaction between alcohol and HRV benefits.",
  "inputs": ["alcoholImpact", "hrvImpact", "metrics"],
  "outputs": ["antagonismMultiplier"],
  "dependencies": [],
  "formula": "25% reduction (0.75x) in HRV benefits when alcohol consumption >2 drinks/day"
}
```

### Body Mass-Activity Interaction

```json
{
  "rule_id": "interaction.bodyMassActivity",
  "file": "Amped/Features/LifeImpact/InteractionEffectEngine.swift",
  "function": "calculateBodyMassActivityInteraction",
  "description": "Adjusts activity benefits based on body mass.",
  "inputs": ["bodyMassImpact", "activityImpact", "metrics"],
  "outputs": ["adjustmentMultiplier"],
  "dependencies": [],
  "formula": "10% reduction (0.90x) in activity benefits per 20 lbs over 200 lbs threshold"
}
```

### Stress-Sleep Antagonism

```json
{
  "rule_id": "interaction.stressSleep",
  "file": "Amped/Features/LifeImpact/InteractionEffectEngine.swift",
  "function": "calculateStressSleepAntagonism",
  "description": "Calculates negative interaction between stress and sleep benefits.",
  "inputs": ["stressImpact", "sleepImpact", "metrics"],
  "outputs": ["antagonismMultiplier"],
  "dependencies": [],
  "formula": "15% reduction (0.85x) in sleep benefits when stress level >7"
}
```

## Life Projection Calculations

### Baseline Life Expectancy

```json
{
  "rule_id": "projectionModel.baseline",
  "file": "Amped/Features/LifeProjection/BaselineMortalityAdjuster.swift",
  "function": "getBaselineLifeExpectancy",
  "description": "Calculates baseline life expectancy using WHO Global 2023 life tables.",
  "inputs": ["userProfile"],
  "outputs": ["baselineYears"],
  "dependencies": ["LifeExpectancyTable"],
  "data": {
    "male": "71.4 years at birth, decreasing with age",
    "female": "76.8 years at birth, decreasing with age"
  }
}
```

### Mortality-Adjusted Impact

```json
{
  "rule_id": "projectionModel.mortalityAdjustment",
  "file": "Amped/Features/LifeProjection/BaselineMortalityAdjuster.swift",
  "function": "adjustImpactForMortality",
  "description": "Adjusts daily impact based on age-specific mortality rates.",
  "inputs": ["dailyImpact", "age", "gender"],
  "outputs": ["adjustedDailyImpact"],
  "dependencies": ["MortalityTable"],
  "formula": "adjustedImpact = dailyImpact * sqrt(baseRate / mortalityRate)"
}
```

### Behavior Decay

```json
{
  "rule_id": "projectionModel.behaviorDecay",
  "file": "Amped/Features/LifeProjection/BaselineMortalityAdjuster.swift",
  "function": "applyBehaviorDecay",
  "description": "Models realistic behavior decay over time for projections.",
  "inputs": ["impact", "yearsInFuture", "behaviorType"],
  "outputs": ["decayedImpact"],
  "dependencies": [],
  "decay_rates": {
    "exercise/steps": "15% annual decay",
    "smoking/alcohol": "5% annual decay",
    "sleep/nutrition": "10% annual decay",
    "default": "12% annual decay"
  }
}
```

### Total Life Projection

```json
{
  "rule_id": "projectionModel.total",
  "file": "Amped/Features/LifeProjection/LifeProjectionService.swift",
  "function": "generateLifeProjection",
  "description": "Projects total life expectancy based on daily impacts with behavior decay.",
  "inputs": ["userProfile", "dailyImpactMinutes", "evidenceQuality"],
  "outputs": ["LifeProjection"],
  "dependencies": ["BaselineMortalityAdjuster"],
  "steps": [
    "Get baseline life expectancy",
    "Calculate remaining years",
    "Apply behavior decay in 5-year segments",
    "Weight by evidence quality",
    "Bound between age+1 and 120 years"
  ]
}
```

## Recommendations Engine

### Recommendation Generation

```json
{
  "rule_id": "recommendations.generate",
  "file": "Amped/Features/UI/RecommendationService.swift",
  "function": "generateRecommendation",
  "description": "Generates actionable recommendations based on metric impact with realistic bounds and dynamic action sizing.",
  "inputs": ["metric", "selectedPeriod"],
  "outputs": ["recommendation"],
  "dependencies": ["ActivityImpactCalculator", "CardiovascularImpactCalculator", "LifestyleImpactCalculator"],
  "logic": "For negative impacts: calculate action to reach neutral. For positive: suggest 20% improvement",
  "improvements": [
    "Dynamic action sizing based on actual deficit",
    "Realistic bounds checking to prevent biologically impossible recommendations",
    "Period-appropriate benefit calculations",
    "Personalized recommendations based on current fitness level"
  ]
}
```

### Steps Recommendations (Fixed Phase 4)

```json
{
  "rule_id": "recommendations.steps.fixed.phase4",
  "file": "Amped/Features/UI/RecommendationService.swift",
  "function": "generateStepsRecommendation",
  "description": "Generates realistic walking recommendations with period-appropriate logic.",
  "inputs": ["metric", "period"],
  "outputs": ["dynamicRecommendation"],
  "dependencies": ["findStepsForNeutralImpact", "calculateRealisticStepTarget"],
  "logic": {
    "daily_period": "Show additional steps needed (e.g., 'Walk 4,143 more steps today')",
    "monthly_yearly": "Show total daily target (e.g., 'Walk 8,743 steps daily this next year')",
    "benefit_calculation": "Show actual benefit of reaching neutral (0 impact)",
    "text_format": "All end with 'to add X to your life' for clear messaging"
  },
  "examples": {
    "day": "Walk 4,143 more steps today to add 1 hour 42 minutes to your life",
    "month": "Walk 8,743 steps daily this month to add 30 hours to your life",
    "year": "Walk 8,743 steps daily this next year to add 15.0 days to your life"
  }
}
```

### Exercise Recommendations (Fixed Phase 4)

```json
{
  "rule_id": "recommendations.exercise.fixed.phase4",
  "file": "Amped/Features/UI/RecommendationService.swift",
  "function": "generateExerciseRecommendation",
  "description": "Generates realistic exercise recommendations with period-appropriate logic.",
  "inputs": ["metric", "period"],
  "outputs": ["personalizedRecommendation"],
  "dependencies": ["findExerciseForNeutralImpact"],
  "logic": {
    "daily_period": "Show additional minutes needed (e.g., 'Exercise 15 minutes more today')",
    "monthly_yearly": "Show total daily target (e.g., 'Exercise 21 minutes daily this next year')",
    "benefit_calculation": "Show actual benefit of reaching neutral (WHO guidelines)",
    "text_format": "All end with 'to add X to your life' for clear messaging"
  },
  "examples": {
    "day": "Exercise 15 minutes more today to add 45 minutes to your life",
    "month": "Exercise 21 minutes daily this month to add 22 hours to your life",
    "year": "Exercise 21 minutes daily this next year to add 11.2 days to your life"
  }
}
```

### Realistic Bounds System

```json
{
  "rule_id": "recommendations.bounds",
  "file": "Amped/Features/UI/RecommendationService.swift",
  "function": "applyRealisticBounds",
  "description": "Prevents biologically impossible recommendation benefits.",
  "inputs": ["benefit", "period", "metricType"],
  "outputs": ["clampedBenefit"],
  "dependencies": [],
  "bounds": {
    "steps": "15 minutes max daily benefit",
    "exerciseMinutes": "20 minutes max daily benefit",
    "sleepHours": "10 minutes max daily benefit",
    "nutritionQuality": "8 minutes max daily benefit",
    "default": "12 minutes max daily benefit"
  }
}
```

### Period-Appropriate Formatting

```json
{
  "rule_id": "recommendations.periodFormatting",
  "file": "Amped/Features/UI/RecommendationService.swift",
  "function": "formatBenefitForPeriod",
  "description": "Formats benefits correctly for each time period.",
  "inputs": ["dailyMinutes", "period"],
  "outputs": ["formattedBenefit"],
  "dependencies": [],
  "logic": {
    "day": "Shows daily benefit directly",
    "month": "dailyBenefit * 30 days",
    "year": "dailyBenefit * 365 days"
  },
  "replaced": "Old formatBenefit method that incorrectly used period.multiplier"
}
```

### ActionableRecommendationsView Integration

```json
{
  "rule_id": "recommendations.uiIntegration",
  "file": "Amped/UI/Components/ActionableRecommendationsView.swift",
  "function": "actionText",
  "description": "UI now uses RecommendationService directly instead of hardcoded text.",
  "inputs": ["metric"],
  "outputs": ["recommendation"],
  "dependencies": ["RecommendationService"],
  "improvements": [
    "Removed hardcoded '20-minute walk' text",
    "Removed separate benefit calculation logic",
    "Single source of truth for recommendations",
    "Consistent formatting across all UI components"
  ]
}
```

### Recommendation Prioritization

```json
{
  "rule_id": "recommendations.prioritize",
  "file": "Amped/Features/UI/RecommendationService.swift",
  "function": "getPrioritizedRecommendations",
  "description": "Prioritizes recommendations based on potential gain and difficulty.",
  "inputs": ["metrics", "selectedPeriod", "maxRecommendations"],
  "outputs": ["PrioritizedRecommendation[]"],
  "dependencies": ["LifeImpactService"],
  "formula": "priority = potentialGain * difficultyMultiplier (easy=1.5, moderate=1.0, hard=0.7)"
}
```

## Debug Logging & Validation (Phase 1)

### Scaling Debug Logging

```json
{
  "rule_id": "debug.scalingLogs",
  "file": "Amped/Features/LifeImpact/LifeImpactService.swift",
  "function": "applyAdvancedScaling",
  "description": "Comprehensive debug logging for all scaling calculations to identify issues.",
  "log_categories": [
    "🔍 Advanced Scaling Debug: [MetricName]",
    "📈 Diminishing returns scaling: [Details]", 
    "🌙 Sleep U-shaped scaling: [Sleep-specific]",
    "🎯 Threshold scaling: [Threshold details]",
    "📈 Exponential scaling: [Growth details]",
    "🏔️ Plateau scaling: [Plateau details]"
  ],
  "logged_data": [
    "Effect type applied",
    "Daily impact value",
    "Selected period",
    "Scaling calculations step-by-step",
    "Final scaled result",
    "Scaling factor multiplier"
  ]
}
```

### Scaling Validation

```json
{
  "rule_id": "debug.scalingValidation",
  "file": "Amped/Features/LifeImpact/LifeImpactService.swift",
  "function": "applyAdvancedScaling",
  "description": "Validates logical progression and warns about scaling issues.",
  "validation_rules": [
    "Monthly scaling should be ≥20x daily impact",
    "Yearly scaling should be ≥180x daily impact", 
    "Exponential effects bounded at 150% of linear scaling",
    "Daily periods never artificially amplified beyond true value"
  ],
  "warning_triggers": [
    "Scaled impact smaller than expected minimum",
    "Effect type producing counterintuitive results",
    "Bounds checking activated for exponential effects"
  ]
}
```

### Individual Scaling Function Logging

```json
{
  "rule_id": "debug.individualScaling",
  "file": "Amped/Features/LifeImpact/LifeImpactService.swift",
  "functions": ["scaleDiminishingEffect", "scaleUShapedEffect", "scaleThresholdEffect", "scaleExponentialEffect", "scalePlateauEffect"],
  "description": "Each scaling function now logs its specific calculations and parameters.",
  "logged_parameters": [
    "Diminishing factor applied",
    "Compounding factor for sleep",
    "Threshold days and progression", 
    "Exponential growth rate and bounds",
    "Plateau days and continuation rate"
  ]
}
```

## Battery UI Calculations

### Impact Battery Level

```json
{
  "rule_id": "batteryUI.impactLevel",
  "file": "Amped/Features/LifeImpact/LifeImpactService.swift",
  "function": "calculateBatteryLevel",
  "description": "Converts impact minutes to battery charge level (0-100%).",
  "inputs": ["impactMinutes"],
  "outputs": ["batteryLevel"],
  "dependencies": [],
  "formula": "50% baseline + (impact/120) * 50%. Range: 0-100%"
}
```

### Projection Battery Display

```json
{
  "rule_id": "batteryUI.projectionDisplay",
  "file": "Amped/Features/LifeProjection/LifeProjectionService.swift",
  "function": "formatForBatteryDisplay",
  "description": "Formats life projection for battery visualization.",
  "inputs": ["projection", "userAge"],
  "outputs": ["percentage", "displayText"],
  "dependencies": [],
  "formula": "percentage = (remainingYears / 60) * 100, capped at 100%"
}
```

### Realtime Countdown

```json
{
  "rule_id": "batteryUI.realtimeCountdown",
  "file": "Amped/UI/Components/BatteryIndicatorView.swift",
  "function": "displayNumericValue",
  "description": "Shows precise remaining years with 8 decimal places, updating every second.",
  "inputs": ["lifeProjection", "currentUserAge", "currentTime"],
  "outputs": ["preciseRemainingYears"],
  "dependencies": ["SettingsManager"],
  "formula": "baseRemaining - (timeElapsedThisYear / secondsPerYear)"
}
```

## Chart Data Processing

### Outlier Detection

```json
{
  "rule_id": "chartData.outlierDetection",
  "file": "Amped/UI/MetricComponents/ChartDataProcessor.swift",
  "function": "clipOutliers",
  "description": "Detects and clips outliers using Interquartile Range (IQR) method.",
  "inputs": ["dataPoints", "metricType"],
  "outputs": ["clippedDataPoints"],
  "dependencies": [],
  "formula": "Bounds = Q1 - 1.5*IQR to Q3 + 1.5*IQR"
}
```

### Data Smoothing

```json
{
  "rule_id": "chartData.smoothing",
  "file": "Amped/UI/MetricComponents/ChartDataProcessor.swift",
  "function": "applySmoothing",
  "description": "Applies weighted moving average smoothing to reduce noise.",
  "inputs": ["dataPoints", "smoothingLevel"],
  "outputs": ["smoothedDataPoints"],
  "dependencies": [],
  "window_sizes": {
    "light": 3,
    "moderate": 5,
    "heavy": 7
  }
}
```

### Period Aggregation

```json
{
  "rule_id": "chartData.aggregation",
  "file": "Amped/UI/MetricComponents/ChartDataProcessor.swift",
  "function": "aggregateDataPoints",
  "description": "Aggregates data points for different time periods.",
  "inputs": ["dataPoints", "metricType", "period"],
  "outputs": ["aggregatedDataPoints"],
  "dependencies": [],
  "methods": {
    "cumulative": "Sum per period (steps, exercise, energy)",
    "discrete": "Average per period (heart rate, HRV, weight)",
    "sleep": "Special handling for sleep patterns"
  }
}
```

## Dashboard Calculations

### Period-Specific Metrics

```json
{
  "rule_id": "dashboard.periodMetrics",
  "file": "Amped/Features/UI/DashboardViewModel.swift",
  "function": "loadDataForPeriod",
  "description": "Loads and calculates metrics for selected time period.",
  "inputs": ["timePeriod"],
  "outputs": ["healthMetrics", "lifeImpactData", "lifeProjection"],
  "dependencies": ["HealthDataService", "LifeImpactService", "LifeProjectionService"],
  "process": "Fetch period data → Calculate impacts → Update projections"
}
```

### Total Time Impact

```json
{
  "rule_id": "dashboard.totalImpact",
  "file": "Amped/Features/UI/DashboardView.swift",
  "function": "totalTimeImpact",
  "description": "Calculates total time impact from all filtered metrics.",
  "inputs": ["filteredMetrics"],
  "outputs": ["totalImpactMinutes"],
  "dependencies": [],
  "formula": "Sum of all metric.impactDetails.lifespanImpactMinutes"
}
```

## Evidence Quality Weighting

### Study Reference Provider

```json
{
  "rule_id": "evidence.studyProvider",
  "file": "Amped/Features/LifeImpact/StudyReferenceProvider.swift",
  "function": "getApplicableStudies",
  "description": "Provides peer-reviewed research references for impact calculations.",
  "inputs": ["metricType", "userProfile"],
  "outputs": ["StudyReference[]"],
  "dependencies": [],
  "quality_scores": {
    "high": "Meta-analyses, large cohorts",
    "moderate": "Smaller studies, limited follow-up",
    "low": "Expert consensus, extrapolated data"
  }
}
```

### Evidence-Based Weighting

```json
{
  "rule_id": "evidence.weighting",
  "file": "Amped/Features/LifeImpact/LifeImpactService.swift",
  "function": "calculateTotalImpact",
  "description": "Weights impacts by evidence quality and reliability scores.",
  "inputs": ["impacts"],
  "outputs": ["weightedImpacts"],
  "dependencies": ["MetricImpactDetail.reliabilityScore"],
  "formula": "weightedImpact = scaledImpact * evidenceWeight"
}
```

## Configuration

All calculations use these base constants:
- Baseline life expectancy: 78 years (WHO global average)
- Impact normalization: ±120 minutes/day for battery visualization
- Confidence intervals: Based on study-specific data
- Maximum projected lifespan: 120 years
- Behavior decay rates: Metric-specific (5-15% annually)
description:
globs:
alwaysApply: false
--- 