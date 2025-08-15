## Data Models

### Core Models
- **HealthMetric**: Single health metric with value, impact, and display properties
- **HealthMetricType**: Enumeration of supported health metric types
- **MetricImpactDetail**: Calculated impact details for each metric with effect types
- **ImpactDataPoint**: Historical tracking point for life impact
- **LifeProjection**: Model for total life expectancy projection
- **StudyReference**: Scientific research reference for impact calculations
- **UserProfile**: Comprehensive user profile with subscription and onboarding state
- **ManualMetricInput**: User-provided health data from questionnaire
- **BatteryStreak**: User engagement streak tracking and milestones
- **StreakMilestone**: Achievement milestones for user engagement
- **QuestionnaireData**: Structured questionnaire responses with validation
- **DailyTarget**: Daily targets for health metrics with caching support
- **ChartImpactDataPoint**: Data points for chart visualization
- **TimePeriod**: Enumeration for different time period calculations

### Data Flow
1. **Collection**: HealthKitManager fetches data, HealthDataService processes it
2. **Manual Input**: QuestionnaireManager collects additional user-provided data
3. **Caching**: CacheManager stores data for offline operation with expiration
4. **Calculation**: LifeImpactService analyzes health data against scientific baselines
5. **Interaction Effects**: InteractionEffectEngine calculates complex metric interactions
6. **Projection**: LifeProjectionService calculates total life expectancy
7. **Engagement**: StreakManager tracks user engagement and milestones
8. **Personalization**: RecommendationService provides personalized insights
9. **Presentation**: ViewModels prepare data, Views render it in the UI
10. **Analytics**: Anonymous usage patterns captured (with consent from repeat users only) for feature optimization