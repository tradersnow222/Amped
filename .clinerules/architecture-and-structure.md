## Architecture & Structure

### Design Pattern
- Implement MVVM (Model-View-ViewModel) architecture
- Use SwiftUI's native state management (@State, @StateObject, @EnvironmentObject)
- Incorporate Combine framework for reactive programming
- Implement Swift Concurrency with async/await and Task
- Use dependency injection with protocols for future scalability and testability

### Directory Structure
Amped/
├── Assets.xcassets/ # Asset catalog containing all images and colors
├── Core/ # Core business logic and models
│ ├── Models/ # Core data models (HealthMetric, UserProfile, etc.)
│ ├── Extensions/ # Core Swift extensions
│ ├── CacheManager.swift # Data persistence and offline support
│ ├── FeatureFlagManager.swift # Feature flag system for rollouts
│ ├── LaunchOptimizer.swift # App launch performance optimization
│ ├── ProfileImageManager.swift # User profile image management
│ ├── InfoPlistManager.swift # Info.plist data access
│ └── PersonalizationUtils.swift # User personalization utilities
├── Features/ # Feature modules organized by domain
│ ├── HealthKit/ # HealthKit integration and health data services
│ ├── LifeImpact/ # Life impact calculations and interaction effects
│ ├── LifeProjection/ # Life expectancy projection calculations
│ ├── Onboarding/ # User onboarding flow and components
│ ├── Questionnaire/ # Custom health metric questions and data processing
│ ├── Payment/ # Subscription handling and payment processing
│ ├── Settings/ # App settings and user preferences
│ ├── Engagement/ # User engagement, streaks, and notifications
│ └── UI/ # Feature-specific UI components and view models
├── UI/ # Shared UI components and design system
│ ├── Components/ # Reusable UI components
│ ├── MetricComponents/ # UI components for health metrics
│ ├── Theme/ # Theming system (Battery, Glass, Text styles)
│ └── Accessibility/ # Accessibility support components
├── Analytics/ # Analytics framework (privacy-focused)
├── Documentation/ # Project documentation
│ ├── Architecture/ # Architecture decisions and diagrams
│ ├── HapticFeedback.md # Haptic feedback implementation
│ ├── PersonalizationFeatures.md # Personalization features documentation
│ └── 3D_TRANSFORMATION_SUMMARY.md # 3D transformation effects
├── Scripts/ # Build and utility scripts
├── Preview Content/ # Preview assets for SwiftUI previews
└── AmpedApp.swift # App entry point and main navigation flow

### Project Documentation Structure
README.md # Project overview, setup instructions, contribution guidelines
CHANGELOG.md # Version history and changes
Documentation/
├── Architecture.md # High-level architecture overview
├── CodeStyle.md # Project-specific coding standards
├── Onboarding.md # Developer onboarding guide
├── HealthMetrics.md # Health metrics implementation details
├── LifeImpactModel.md # Life impact calculation documentation
├── LifeProjection.md # Life expectancy projection algorithm
├── Testing.md # Testing strategy and guidelines
├── Images/ # Documentation images and diagrams
└── API/ # API documentation
├── HealthKitManager.md # HealthKit integration documentation
├── LifeImpactService.md # Life impact service documentation
└── etc.


### Core Services
- **HealthKitManager**: Handle HealthKit permissions, data access, and monitoring
- **HealthDataService**: Process raw HealthKit data into usable metrics
- **LifeImpactService**: Calculate life impact based on health metrics with interaction effects
- **LifeProjectionService**: Calculate total life expectancy projections
- **InteractionEffectEngine**: Advanced health metric interaction calculations
- **OnboardingManager**: Manage the onboarding state and flow
- **QuestionnaireManager**: Handle personalized health questions and processing
- **PaymentManager**: Handle subscription and payment processing
- **SettingsManager**: Handle user preferences and app settings
- **BatteryThemeManager**: Implement battery-themed UI management
- **GlassThemeManager**: Implement Apple Liquid Glass themed interface
- **CacheManager**: Handle data persistence and offline operation
- **FeatureFlagManager**: Control feature rollout and A/B testing
- **LaunchOptimizer**: Optimize app launch performance
- **ProfileImageManager**: Centralized user profile image management
- **StreakManager**: Manage user engagement streaks and milestones
- **NotificationManager**: Handle push notifications and engagement
- **RecommendationService**: Provide personalized health recommendations
- **AnalyticsService**: Collect anonymized usage data for product improvement