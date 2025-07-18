# Amped - Power Up Your Life

**Tagline:** "Power Up Your Life"

Amped is a comprehensive iOS health metrics app that integrates with Apple HealthKit to track and analyze your health data in real-time. Using scientific research and advanced algorithms, Amped calculates how your daily health habits impact your lifespan, presenting this information through an intuitive battery-themed interface that visualizes your health as energy levels.

## 🔋 Key Features

### Dual Battery Visualization System
- **Life Impact Battery**: Shows short-term health habit impacts with dynamic charge levels
- **Life Projection Battery**: Displays total projected lifespan with smooth energy flow animations
- **Battery-themed UI**: Familiar battery visualizations with glassmorphism effects and power indicators
- **Interactive Animations**: Smooth charging/discharging animations and energy flow between batteries

### Comprehensive Health Tracking
- **HealthKit Integration**: Tracks key health metrics automatically
  - Steps, Exercise Minutes, Sleep Hours
  - Resting Heart Rate, Heart Rate Variability
  - Body Mass, Active Energy Burned
  - VO2 Max, Oxygen Saturation
- **Enhanced Questionnaire System**: Interactive swipeable interface for lifestyle metrics
  - Birthdate and Gender
  - Nutrition Quality, Smoking Status, Alcohol Consumption
  - Social Connections Quality, Stress Level
  - Device tracking preferences, Life motivation

### Scientific Life Impact Calculations
- **Research-Based Algorithms**: Calculates lifespan impact using peer-reviewed studies
- **Scientific Credibility View**: Transparent display of research sources and methodology
- **Real-time Analysis**: Processes health data into actionable insights
- **Impact Visualization**: Shows how each metric affects your total life expectancy
- **Time Period Analysis**: View impacts across different time scales (day/month/year)

### Privacy-First Design
- **On-Device Processing**: All health calculations happen locally
- **No Data Sharing**: Personal health data never leaves your device
- **Sign in with Apple**: Secure, privacy-focused authentication
- **Transparent Permissions**: Clear explanations for health data access

### Premium Subscription Model
- **Free Trial**: Experience full features before subscribing
- **Flexible Plans**: Monthly and Annual subscription options
- **StoreKit Integration**: Native iOS payment processing with exit offers
- **Processing Overlays**: Smooth payment experience with loading states

## 📱 App Architecture

### Design Pattern
- **MVVM Architecture**: Model-View-ViewModel with SwiftUI
- **Modular Design**: Feature-focused modules under 300 lines each
- **Reactive Programming**: Combine framework for data flow
- **Swift Concurrency**: async/await and Task for performance
- **Dependency Injection**: Protocol-based service architecture

### Directory Structure
```
Amped/
├── Core/                           # Core business logic and models
│   ├── Models/                    # Health metrics, impact calculations, life projections
│   │   ├── HealthMetric.swift
│   │   ├── HealthMetricType.swift
│   │   ├── LifeProjection.swift
│   │   ├── MetricImpactDetail.swift
│   │   └── StudyReference.swift
│   ├── Extensions/                # UserDefaults and utility extensions
│   ├── CacheManager.swift
│   ├── FeatureFlagManager.swift
│   └── InfoPlistManager.swift
├── Features/                      # Feature modules organized by domain
│   ├── HealthKit/                # HealthKit integration and data processing
│   │   ├── HealthKitManager.swift
│   │   ├── HealthKitDataManager.swift
│   │   ├── HealthDataService.swift
│   │   ├── HealthKitPermissionsManager.swift
│   │   └── HealthKitSleepManager.swift
│   ├── LifeImpact/               # Life impact calculation algorithms
│   │   ├── LifeImpactService.swift
│   │   ├── ActivityImpactCalculator.swift
│   │   ├── CardiovascularImpactCalculator.swift
│   │   ├── LifestyleImpactCalculator.swift
│   │   └── StudyReferenceProvider.swift
│   ├── LifeProjection/           # Life expectancy projection calculations
│   │   └── LifeProjectionService.swift
│   ├── Onboarding/               # User onboarding flow
│   │   ├── OnboardingFlow.swift
│   │   ├── OnboardingStepsView.swift
│   │   ├── PersonalizationIntroView.swift
│   │   ├── WelcomeView.swift
│   │   ├── ValuePropositionView.swift
│   │   └── SignInWithAppleView.swift
│   ├── Questionnaire/            # Enhanced questionnaire system
│   │   ├── QuestionnaireView.swift
│   │   ├── QuestionnaireViewModel.swift
│   │   ├── QuestionnaireManager.swift
│   │   ├── QuestionViews.swift
│   │   ├── QuestionnaireGestureHandler.swift
│   │   └── UpdateHealthProfileView.swift
│   ├── Payment/                  # Subscription and payment handling
│   │   ├── PaymentView.swift
│   │   ├── PaymentViewModel.swift
│   │   ├── PaymentComponents.swift
│   │   ├── PricingSection.swift
│   │   ├── ProcessingOverlay.swift
│   │   ├── ExitOfferModal.swift
│   │   ├── SimpleBatteryView.swift
│   │   ├── StoreKitManager.swift
│   │   └── SubscriptionService.swift
│   ├── Settings/                 # App settings and preferences
│   │   ├── SettingsView.swift
│   │   └── SettingsManager.swift
│   └── UI/                       # Dashboard and main interface
│       ├── DashboardView.swift
│       ├── DashboardViewModel.swift
│       ├── DashboardHelpers.swift
│       ├── MetricDetailView.swift
│       ├── MetricDetailSections.swift
│       └── ViewModels/
│           └── MetricDetailViewModel.swift
├── UI/                           # Shared UI components and design system
│   ├── Components/               # Reusable battery-themed components
│   │   ├── BatteryLifeImpactCard.swift
│   │   ├── BatteryLifeProjectionCard.swift
│   │   ├── LifeEnergyFlowBattery.swift
│   │   ├── BatteryIndicatorView.swift
│   │   ├── BatteryAnimations.swift
│   │   ├── SwipeablePageContainer.swift
│   │   ├── ScientificCredibilityView.swift
│   │   ├── PeriodSelector.swift
│   │   ├── PrimaryButtonStyle.swift
│   │   ├── CollapsibleSection.swift
│   │   ├── StyledMetricChart.swift
│   │   ├── OnboardingTransitionModifier.swift
│   │   ├── BackButton.swift
│   │   └── TransparentBackground.swift
│   ├── MetricComponents/         # Health metric visualization components
│   │   ├── BatteryMetricCard.swift
│   │   ├── EnhancedMetricCard.swift
│   │   ├── HealthMetricRow.swift
│   │   ├── HealthMetricsListView.swift
│   │   ├── MetricChartSection.swift
│   │   ├── MetricContextCard.swift
│   │   ├── MetricDetailsView.swift
│   │   └── MetricTipCard.swift
│   ├── Theme/                    # Battery theme and glass effects
│   │   ├── BatteryThemeManager.swift
│   │   ├── GlassThemeManager.swift
│   │   ├── ColorAssets.swift
│   │   ├── TextStyles.swift
│   │   ├── ThemeModifier.swift
│   │   └── BackgroundImageModifier.swift
│   └── Accessibility/            # VoiceOver and accessibility support
│       ├── AccessibilitySupport.swift
│       ├── HapticFeedback.swift
│       └── ButtonHaptics.swift
└── Analytics/                    # Privacy-focused analytics
    └── AnalyticsService.swift
```

## 🚀 Getting Started

### Requirements
- **Xcode 15.0+**
- **iOS 16.0+** target deployment
- **Physical device** (HealthKit requires actual hardware)
- **Apple Developer account** (for HealthKit capabilities)

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/tradersnow222/Amped.git
   cd Amped
   ```

2. **Open in Xcode**
   ```bash
   open Amped.xcodeproj
   ```

3. **Configure capabilities**
   - Select your development team in Signing & Capabilities
   - Ensure HealthKit capability is enabled
   - Ensure "Sign in with Apple" capability is enabled
   - Configure StoreKit for in-app purchases

4. **Set up Info.plist**
   - The app uses auto-generated Info.plist with build scripts
   - Follow instructions in `Amped/Scripts/SETUP.md` to configure build scripts
   - Required HealthKit usage descriptions are automatically added

5. **Run on device**
   - HealthKit features require a physical iOS device
   - Simulator can be used for UI development but not health data testing

## 🏥 Health Data Integration

### HealthKit Metrics
The app automatically collects these metrics when permissions are granted:

| Metric | Type | Impact Calculation |
|--------|------|-------------------|
| Steps | Activity | Research-based baseline comparisons |
| Exercise Minutes | Activity | WHO guidelines integration |
| Sleep Hours | Recovery | Sleep quality impact algorithms |
| Resting Heart Rate | Cardiovascular | Age-adjusted baselines |
| Heart Rate Variability | Recovery | HRV analysis algorithms |
| Body Mass | Physical | BMI-based calculations |
| Active Energy Burned | Activity | Metabolic impact calculations |
| VO2 Max | Performance | Fitness level assessments |
| Oxygen Saturation | Respiratory | Respiratory health indicators |

### Enhanced Questionnaire System
Interactive swipeable interface collecting lifestyle data through an engaging flow:

**Questionnaire Screens:**
1. **Birthdate Collection**: Age-based calculation setup
2. **Gender Selection**: Demographic baseline adjustment
3. **Nutrition Quality**: 1-10 scale dietary assessment
4. **Smoking Status**: Tobacco use impact evaluation
5. **Alcohol Consumption**: Weekly intake assessment
6. **Social Connections**: Social support evaluation
7. **Stress Level**: Stress impact measurement
8. **Life Motivation**: Personal goal setting

**Features:**
- **Swipeable Navigation**: Smooth gesture-based progression
- **Progress Indicators**: Visual feedback on completion
- **Instant Validation**: Real-time input validation
- **Adaptive UI**: Dynamic question presentation

## 🧮 Scientific Foundation & Calculations

### Research Transparency
- **Scientific Credibility View**: New component displaying research sources
- **Study References**: Peer-reviewed research citations for each metric
- **Methodology Transparency**: Clear explanation of calculation approaches
- **Confidence Intervals**: Built-in uncertainty factors

### Life Impact Calculation Algorithm
```swift
// Enhanced impact calculation with research validation
func calculateLifeImpact(for metric: HealthMetric) -> MetricImpactDetail {
    let baseline = studyReferenceProvider.getBaseline(for: metric.type)
    let impactCoefficient = studyReferenceProvider.getImpactCoefficient(for: metric.type)
    
    let difference = metric.value - baseline
    let impactMinutes = difference * impactCoefficient
    
    return MetricImpactDetail(
        metric: metric,
        impactMinutes: impactMinutes,
        studyReference: studyReferenceProvider.getReference(for: metric.type)
    )
}
```

### Impact Calculation Modules
- **ActivityImpactCalculator**: Steps, exercise, active energy calculations
- **CardiovascularImpactCalculator**: Heart rate, HRV, VO2 max analysis
- **LifestyleImpactCalculator**: Questionnaire-based lifestyle impact
- **StudyReferenceProvider**: Research data and baseline management

## 📊 Enhanced User Experience

### Onboarding Flow ("Little Yesses" Approach)
1. **Welcome Screen**: Engaging introduction with battery animations
2. **Personalization Intro**: Scientific credibility and value proposition
3. **Interactive Questionnaire**: Swipeable 8-question flow with progress tracking
4. **HealthKit Permissions**: Clear benefit explanation and permission requests
5. **Sign in with Apple**: Privacy-focused authentication
6. **Payment Screen**: Subscription options with exit offers and processing overlays
7. **Dashboard**: Immediate value display with dual battery visualization

### Dashboard Experience
- **Period Selector**: Dynamic switching between Day/Month/Year views
- **Life Impact Battery**: Real-time health impact visualization
- **Life Projection Battery**: Total lifespan projection with energy flow
- **Enhanced Metric Cards**: Power level indicators and detailed insights
- **Pull-to-Refresh**: Seamless HealthKit data updates
- **Metric Detail Views**: Comprehensive analysis with charts and context
- **Scientific Credibility**: Transparent research source display

### Interactive Features
- **Swipeable Navigation**: Smooth gesture-based interactions
- **Battery Animations**: Dynamic charging/discharging effects
- **Haptic Feedback**: Tactile responses for user actions
- **Glass Effects**: Modern glassmorphism design elements
- **Collapsible Sections**: Organized information display

## ⚙️ Settings & Customization

### User Preferences
- **Metric System**: Switch between metric (kg, cm) and imperial (lbs, ft)
- **Show Unavailable Metrics**: Display metrics without current data
- **Realtime Countdown**: Live countdown of remaining lifespan
- **Sign-in Popup Management**: Control authentication prompts
- **Theme Preferences**: Time-based color schemes
- **Accessibility Options**: VoiceOver and reduced motion support

## 🔬 Scientific Research Integration

### Study Reference System
The app maintains a comprehensive database of peer-reviewed research:

**Research Categories:**
- **Physical Activity**: Steps, exercise duration, and intensity studies
- **Cardiovascular Health**: Heart rate, HRV, and blood pressure research
- **Sleep Science**: Duration, quality, and recovery studies
- **Lifestyle Factors**: Nutrition, smoking, alcohol, and social connections
- **Mental Health**: Stress, social support, and psychological wellbeing

### Research Institutions
- Integration with leading health research organizations
- Regular updates based on latest scientific findings
- Transparent methodology documentation

## �� Privacy & Security

### Data Protection Architecture
- **Local-First Processing**: All health calculations performed on-device
- **Zero Health Data Transmission**: Personal health information never sent to servers
- **Secure Storage**: iOS Keychain and secure frameworks
- **Anonymous Analytics**: Opt-in, anonymized usage patterns only
- **Transparent Permissions**: Clear explanations for all data access requests

### Authentication & Security
- **Sign in with Apple**: Privacy-focused authentication
- **Biometric Security**: TouchID/FaceID support where appropriate
- **Secure Payment Processing**: StoreKit integration with no stored payment data
- **Certificate Pinning**: Secure network communications

## 🛠 Development Workflow

### Code Organization Principles
- **300-Line File Limit**: Strict adherence to modular design
- **Single Responsibility**: Each component has one clear purpose
- **Protocol-Based Architecture**: Dependency injection through interfaces
- **MARK Comments**: Clear code section organization
- **Swift DocC**: Comprehensive API documentation

### Testing Strategy
- **Unit Tests**: Core algorithms and business logic validation
- **UI Tests**: Critical user flows and interaction testing
- **Mock Data Framework**: Consistent testing with simulated HealthKit data
- **Performance Testing**: Battery visualization and calculation optimization
- **Accessibility Testing**: VoiceOver and dynamic type validation

### Quality Assurance
- **Automated Testing**: Comprehensive test suite coverage
- **Code Review Process**: Peer review for all changes
- **Performance Monitoring**: Regular performance audits
- **Accessibility Compliance**: WCAG guideline adherence

## 🎨 Enhanced Design System

### Battery Theme Evolution
- **Visual Metaphor**: Health as energy with sophisticated power indicators
- **Glassmorphism Effects**: Modern depth and transparency
- **Energy Flow Animations**: Dynamic battery-to-battery energy transfer
- **Power Level Hierarchy**: 5-tier system (Critical, Low, Medium, High, Full)
- **Familiar Iconography**: Apple-inspired battery design patterns

### Color System
- **Primary Palette**: Amped Green (positive), Silver (neutral), Yellow (caution), Red (critical)
- **Time-Based Themes**: Morning, Midday, Afternoon, Evening, Night color schemes
- **Dynamic Adaptation**: Color adjustments based on time and user preferences
- **High Contrast Support**: Accessibility-compliant color combinations

### Animation & Interaction
- **Smooth Transitions**: 60fps battery visualizations
- **Gesture Recognition**: Swipe, tap, and long-press interactions
- **Haptic Integration**: Tactile feedback for user actions
- **Reduced Motion Support**: Alternative animations for accessibility

## 📈 Performance Optimization

### Health Data Processing
- **Efficient HealthKit Queries**: Optimized data retrieval with appropriate limits
- **Background Processing**: Health data updates without UI blocking
- **Smart Caching**: Intelligent offline operation support
- **Memory Management**: Value types and automatic reference counting

### UI Performance
- **Lazy Loading**: On-demand health metric loading
- **Animation Optimization**: Hardware-accelerated battery visualizations
- **State Management**: Efficient SwiftUI state handling
- **Asset Optimization**: Compressed images and vector graphics

### Scalability Considerations
- **CloudKit Preparation**: Architecture ready for cloud synchronization
- **Modular Services**: Clean boundaries for future feature expansion
- **Analytics Framework**: Privacy-preserving usage insights
- **A/B Testing Ready**: Framework for feature experimentation

## 🚀 Future Roadmap

### Planned Enhancements
- **Apple Watch Integration**: Companion watchOS app with battery indicators
- **Advanced Analytics**: Long-term health trend analysis
- **Goal Setting System**: Personalized health improvement targets
- **Social Features**: Optional health challenge sharing (privacy-preserving)
- **Health Coaching**: AI-powered personalized recommendations

### Technical Evolution
- **Cloud Synchronization**: Optional iCloud backup and sync
- **Machine Learning**: Personalized health pattern recognition
- **Widget Extensions**: iOS home screen battery widgets
- **Shortcuts Integration**: Siri voice command support
- **HealthKit Expansion**: Additional health metric integrations

## 📊 App Analytics & Insights

### Privacy-Preserving Analytics
- **Opt-in Only**: User consent required for any data collection
- **Anonymous Aggregation**: No personally identifiable information
- **Local Processing**: Analytics computed on-device when possible
- **Transparent Reporting**: Clear disclosure of collected data types

### Performance Monitoring
- **Crash Reporting**: Anonymous crash and error reporting
- **Performance Metrics**: App responsiveness and battery usage
- **Feature Usage**: Understanding which features provide value
- **Conversion Optimization**: Improving onboarding and subscription flows

## 📄 License

This project is proprietary software. All rights reserved.

## 📞 Support & Contact

For questions, support, or feedback:
- **In-App Support**: Available through the settings screen
- **Repository Issues**: GitHub issue tracking for development-related questions
- **Documentation**: Comprehensive guides in `/Documentation/` directory

---

**Amped - Power Up Your Life!** 🔋⚡

*Transform your health data into actionable insights with the power of science, the transparency of research, and the simplicity of a battery indicator.*
