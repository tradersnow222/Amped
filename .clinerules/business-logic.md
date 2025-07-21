## Business Logic

### HealthKit Integration
- Request permissions for MVP core metrics only
- Fetch and monitor health data in real-time
- Process raw data into usable metrics with appropriate units
- Handle missing or incomplete data gracefully

### Questionnaire Data Processing
- Store user-provided data securely on device
- Integrate manual inputs with HealthKit data for comprehensive analysis
- Use questionnaire data to fill gaps in HealthKit data
- Allow periodic re-prompting for updated information

### Life Impact Calculations
- Compare user metrics against scientific research baselines
- Calculate impact for each metric type using specialized algorithms
- Aggregate individual impacts into total lifespan effect
- Scale calculations based on selected time period (Day, Month, Year)
- Handle edge cases and data anomalies
- Incorporate both HealthKit and manual metrics in calculations

### Life Projection Calculations
- Calculate baseline life expectancy based on demographic information
- Adjust projection based on cumulative impact of health metrics
- Update projection as new data becomes available
- Present as both absolute value (years) and percentage (%)
- Include confidence interval in calculations

### Time Period Handling
- Support three primary periods (Day, Month, Year) for Life Impact Battery
- Apply appropriate scaling factors to calculations
- Maintain historical data for trending