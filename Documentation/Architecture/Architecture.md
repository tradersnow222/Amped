# Amped Architecture Overview

## Core Architecture

Amped follows the **MVVM (Model-View-ViewModel)** architecture pattern, implemented with SwiftUI and Combine. This architecture provides a clean separation of concerns, testability, and reactivity.

### Architectural Layers

1. **Models**: Core data structures representing health metrics, impact calculations, and projections
2. **Views**: SwiftUI components that render the UI
3. **ViewModels**: Connect models to views, handle UI logic and data transformations
4. **Services**: Handle business logic, data processing, and external integrations

### Directory Structure

```
Amped/
├── Core/ # Core models and services
│   ├── Models/ # Data models
│   ├── CacheManager.swift # Data persistence
│   └── FeatureFlagManager.swift # Feature flag system
├── Features/ # Feature modules
│   ├── HealthKit/ # HealthKit integration
│   ├── LifeImpact/ # Impact calculations
│   ├── LifeProjection/ # Life expectancy projection
│   ├── Onboarding/ # User onboarding
│   ├── Questionnaire/ # Health questions
│   ├── Payment/ # Subscription handling
│   ├── Settings/ # App settings
│   └── UI/ # Feature-specific UI
├── UI/ # Common UI components
│   ├── Components/ # Shared UI components
│   ├── MetricComponents/ # Metric-specific components
│   ├── Theme/ # Theming system
│   └── Accessibility/ # Accessibility support
└── Analytics/ # Privacy-focused analytics
```

## Key Components

### Core Services

- **HealthKitManager**: Handles HealthKit permissions and data retrieval
- **HealthDataService**: Processes raw HealthKit data into usable metrics
- **LifeImpactService**: Calculates health impact based on scientific research
- **LifeProjectionService**: Projects total life expectancy
- **SettingsManager**: Manages user preferences
- **BatteryThemeManager**: Handles time-based theme changes
- **CacheManager**: Enables offline operation
- **FeatureFlagManager**: Controls feature rollout
- **AnalyticsService**: Privacy-respecting analytics

### Data Flow

1. **Data Collection**:
   - HealthKitManager fetches health data through HealthKit API
   - QuestionnaireManager collects additional self-reported data
   - Both sources flow into HealthDataService

2. **Data Processing**:
   - HealthDataService standardizes and combines data
   - LifeImpactService processes metrics against scientific baselines
   - LifeProjectionService calculates long-term projections

3. **Data Presentation**:
   - ViewModels prepare processed data for display
   - Views render data with battery visualizations
   - User interactions feed back into the system

## State Management

Amped uses SwiftUI's built-in state management combined with Combine:

- **@State**: Local view state
- **@StateObject**: View-owned view model instances
- **@ObservedObject**: References to external observable objects
- **@EnvironmentObject**: Dependency injection for shared services
- **@Published**: Reactive properties that trigger UI updates

## Dependencies and Services Injection

Services are provided through a combination of:

1. **Environment Objects**: Global services like SettingsManager
2. **Initialization Parameters**: Specific services passed to ViewModels
3. **Shared Singletons**: For core services like AnalyticsService

## Offline Support

The app implements a comprehensive caching strategy:

1. **In-Memory Cache**: For fast access to recently used data
2. **Disk Cache**: For persistent storage with automatic expiration
3. **Fallback Mechanisms**: To handle missing data gracefully

## Feature Flag System

A feature flag system enables:

1. **Phased Rollouts**: Gradually release features to users
2. **A/B Testing**: Compare different implementations
3. **Emergency Toggles**: Disable problematic features quickly

## Privacy and Security

1. **On-Device Processing**: All health calculations happen locally
2. **Minimal Data Collection**: Analytics are opt-in and anonymized
3. **Secure Storage**: Sensitive data is stored securely on-device

## Testing Strategy

1. **Unit Tests**: For core algorithms and business logic
2. **UI Tests**: For critical user flows
3. **Test Mocks**: To simulate HealthKit responses

## Accessibility

Comprehensive accessibility support with:

1. **VoiceOver Optimization**: Semantic structure for screen readers
2. **Dynamic Type**: Supporting text size adjustments
3. **Color Contrast**: Ensuring readability
4. **Reduced Motion**: Alternative animations when needed

## Scaling Strategy

The architecture is designed to scale from MVP to millions of users:

1. **Modular Design**: Features can be improved independently
2. **Performance Optimization**: Efficient data processing and UI rendering
3. **Future Cloud Integration**: Prepared for optional cloud synchronization

## Design Decisions

### Why MVVM?

MVVM was chosen because:
- It works well with SwiftUI's declarative paradigm
- It improves testability by separating UI from business logic
- It makes reactive data flow straightforward with Combine

### Why On-Device Processing?

On-device processing was chosen because:
- It maximizes privacy by keeping health data local
- It enables offline functionality
- It reduces backend complexity for the MVP

### Why Feature Modules?

The modular approach enables:
- Parallel development by multiple future team members
- Clear separation of concerns
- Easier long-term maintenance 