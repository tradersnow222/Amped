# Amped - Power Up Your Life

Amped is an iOS health metrics app that integrates with Apple HealthKit to calculate time (lifespan) gained or lost based on scientific research and personal health data. It presents this information with a battery-themed interface that visualizes health as energy levels.

## Key Features

- Real-time health analysis with HealthKit integration
- Personalized questionnaire for additional health metrics
- Life impact calculations based on scientific research
- Total life expectancy projection with dynamic updates
- Dual battery visualization (Impact Battery and Projection Battery)
- Private on-device processing (no data sharing)
- User-friendly insights with actionable recommendations
- Intuitive battery-themed visualization for health metrics
- Frictionless UX designed around the "little yesses" conversion principle

## Screenshots

*Coming soon*

## Requirements

- Xcode 15.0+
- iOS 16.0+
- Apple Developer account (for HealthKit capabilities)

## Setup Instructions

1. Clone the repository
2. Open `Amped.xcodeproj` in Xcode
3. Configure your development team in the Signing & Capabilities section
4. Ensure HealthKit capability is enabled
5. Ensure "Sign in with Apple" capability is enabled
6. Run the app on a physical device (HealthKit features require a device)

### Info.plist Configuration

Amped uses an auto-generated Info.plist approach rather than a physical Info.plist file. This reduces merge conflicts and improves build setting integration. To complete the setup:

1. Follow the instructions in `Amped/Scripts/SETUP.md` to add the Info.plist update script to your build phases
2. The script will automatically add required HealthKit usage descriptions to the generated Info.plist
3. You can view documentation about all Info.plist settings in `Amped/Core/InfoPlistManager.swift`

## Architecture Overview

Amped follows the MVVM (Model-View-ViewModel) architecture pattern and is built entirely with SwiftUI. The app is organized into the following key components:

### Core Services
- **HealthKitManager**: Handles HealthKit permissions and data access
- **HealthDataService**: Processes raw HealthKit data into usable metrics
- **LifeImpactService**: Calculates life impact based on health metrics
- **LifeProjectionService**: Calculates total life expectancy projections

### Key Models
- **HealthMetric**: Single health metric with value, impact, and display properties
- **HealthMetricType**: Enumeration of supported health metric types
- **MetricImpactDetail**: Calculated impact details for each metric
- **ImpactDataPoint**: Historical tracking point for life impact
- **LifeProjection**: Model for total life expectancy projection

### Key UI Components
- **BatteryLifeImpactCard**: Recent impact visualization with battery charge level
- **BatteryLifeProjectionCard**: Total projected life expectancy visualization
- **BatteryMetricCard**: Individual metric card with power level visualization

## Development Workflow

1. The app uses a modular approach with clear separation of concerns
2. All business logic is contained in service classes with protocol-based abstractions
3. UI components are reusable and follow a consistent design system
4. SwiftUI's state management is used for reactive UI updates

## Privacy & Security

- All health data processing happens on-device
- No personal health data is transmitted to external servers
- Authentication is handled via Sign in with Apple
- Clear permission requests explain why health data access is needed

## Contribution Guidelines

Currently, this is an MVP demonstration project. For contribution guidelines, please check back in the future.

## License

*Coming soon*

## Contact

For more information or questions, please reach out to *contact information coming soon*.

---

Amped - Power Up Your Life! 🔋 
