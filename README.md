# Amped - Power Up Your Life

**Tagline:** "Power Up Your Life"

Amped is a comprehensive iOS health metrics app that integrates with Apple HealthKit to track and analyze your health data in real-time. Using scientific research and advanced algorithms, Amped calculates how your daily health habits impact your lifespan, presenting this information through an intuitive battery-themed interface that visualizes your health as energy levels.

## 🔋 Key Features

### Dual Battery Visualization System
- **Life Impact Battery**: Shows short-term health habit impacts (daily, monthly, yearly)
- **Life Projection Battery**: Displays total projected lifespan based on current health data
- **Battery-themed UI**: Familiar battery visualizations with charge levels and power indicators

### Comprehensive Health Tracking
- **HealthKit Integration**: Tracks 9 key health metrics automatically
  - Steps, Exercise Minutes, Sleep Hours
  - Resting Heart Rate, Heart Rate Variability
  - Body Mass, Active Energy Burned
  - VO2 Max, Oxygen Saturation
- **Manual Health Questionnaire**: Collects 5 additional lifestyle metrics
  - Nutrition Quality, Smoking Status, Alcohol Consumption
  - Social Connections Quality, Stress Level

### Scientific Life Impact Calculations
- **Research-Based Algorithms**: Calculates lifespan impact using peer-reviewed studies
- **Real-time Analysis**: Processes health data into actionable insights
- **Impact Visualization**: Shows how each metric affects your total life expectancy
- **Time Period Analysis**: View impacts across different time scales (day/month/year)

### Privacy-First Design
- **On-Device Processing**: All health calculations happen locally
- **No Data Sharing**: Personal health data never leaves your device
- **Sign in with Apple**: Secure, privacy-focused authentication
- **Transparent Permissions**: Clear explanations for health data access

### Subscription Model
- **Free Trial**: 7-day trial for new users
- **Flexible Plans**: Monthly ($9.99/month) and Annual ($39.99/year) options
- **StoreKit Integration**: Native iOS payment processing

## 📱 App Architecture

### Design Pattern
- **MVVM Architecture**: Model-View-ViewModel with SwiftUI
- **Modular Design**: Feature-focused modules under 300 lines each
- **Reactive Programming**: Combine framework for data flow
- **Swift Concurrency**: async/await and Task for performance

### Directory Structure
```
Amped/
├── Core/                    # Core business logic and models
│   ├── Models/             # Health metrics, impact calculations, life projections
│   ├── Extensions/         # UserDefaults and utility extensions
│   └── FeatureFlagManager.swift
├── Features/               # Feature modules organized by domain
│   ├── HealthKit/         # HealthKit integration and data processing
│   ├── LifeImpact/        # Life impact calculation algorithms
│   ├── LifeProjection/    # Life expectancy projection calculations
│   ├── Onboarding/        # User onboarding flow
│   ├── Questionnaire/     # Health questionnaire system
│   ├── Payment/           # Subscription and payment handling
│   ├── Settings/          # App settings and preferences
│   └── UI/                # Dashboard and main interface
├── UI/                    # Shared UI components and design system
│   ├── Components/        # Reusable battery-themed components
│   ├── MetricComponents/  # Health metric visualization components
│   ├── Theme/             # Battery theme and glass effects
│   └── Accessibility/     # VoiceOver and accessibility support
└── Analytics/             # Privacy-focused analytics
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
   - The app uses auto-generated Info.plist
   - Follow instructions in `Amped/Scripts/SETUP.md` to add the build script
   - Required usage descriptions are automatically added

5. **Run on device**
   - HealthKit features require a physical iOS device
   - Simulator can be used for UI development but not health data testing

## 🏥 Health Data Integration

### HealthKit Metrics (9 total)
The app automatically collects these metrics when permissions are granted:

| Metric | Type | Impact Calculation |
|--------|------|-------------------|
| Steps | Activity | Baseline: 7,500 steps/day |
| Exercise Minutes | Activity | Baseline: 30 min/day |
| Sleep Hours | Recovery | Optimal: 7-8 hours/night |
| Resting Heart Rate | Cardiovascular | Age-adjusted baselines |
| Heart Rate Variability | Recovery | Age-adjusted baselines |
| Body Mass | Physical | BMI-based calculations |
| Active Energy Burned | Activity | Baseline: 400 kcal/day |
| VO2 Max | Performance | Age/gender-adjusted |
| Oxygen Saturation | Respiratory | Target: 98-100% |

### Manual Questionnaire (5 metrics)
Users provide additional lifestyle data through an 8-question onboarding flow:

| Question | Scale | Impact Factor |
|----------|-------|---------------|
| Nutrition Quality | 1-10 scale | 20 min/point from baseline |
| Smoking Status | 1-10 scale | 30 min/point from baseline |
| Alcohol Consumption | 1-10 scale | 25 min/point from baseline |
| Social Connections | 1-10 scale | 20 min/point from baseline |
| Stress Level | 1-10 scale | 15 min/point from baseline |

## 🧮 Life Impact Calculations

### Scientific Algorithm Approach
The app uses research-based algorithms to calculate lifespan impact:

```swift
// Example: Steps impact calculation
let baseline = 7500.0 // steps
let stepsImpactPerThousand = 5.0 // minutes per 1000 steps
let difference = userSteps - baseline
let impactMinutes = (difference / 1000.0) * stepsImpactPerThousand
```

### Impact Scaling by Time Period
- **Daily**: Direct daily impact calculation
- **Monthly**: Daily impact × 30 days
- **Yearly**: Daily impact × 365 days

### Life Projection Calculation
```swift
// Baseline life expectancy (demographic-based)
let baselineYears = calculateBaseline(age: userAge, gender: userGender)

// Cumulative impact from all health metrics
let totalImpactMinutes = healthMetrics.reduce(0) { $0 + $1.impactMinutes }

// Convert to years and apply to baseline
let impactYears = totalImpactMinutes / (60 * 24 * 365.25)
let adjustedLifeExpectancy = baselineYears + (impactYears * dampingFactor)
```

## 📊 User Flow

### Onboarding Sequence
1. **Welcome Screen**: App introduction with battery animation
2. **Personalization Intro**: Scientific credibility and "little yesses" approach
3. **Questionnaire**: 8 questions collecting manual health metrics
   - Birthdate and Gender
   - Nutrition, Smoking, Alcohol, Social Connections
   - Device tracking preference
   - Life motivation
4. **Payment Screen**: Subscription options with free trial
5. **Dashboard**: Main app experience with dual battery visualization

### Dashboard Experience
- **Period Selector**: Switch between Day/Month/Year views
- **Life Impact Battery**: Shows current period's health impact
- **Life Projection Battery**: Displays total projected lifespan
- **Health Metrics List**: Individual metric cards with power levels
- **Pull-to-Refresh**: Updates health data from HealthKit
- **Metric Details**: Tap any metric for detailed analysis

## ⚙️ Settings & Customization

### User Preferences
- **Metric System**: Switch between metric (kg, cm) and imperial (lbs, ft)
- **Show Unavailable Metrics**: Display metrics without current data
- **Realtime Countdown**: Live countdown of remaining lifespan
- **Sign-in Popup**: Optional authentication prompts

## 🔬 Scientific Research Foundation

### Study References
The app includes citations to peer-reviewed research for major health impacts:

- **Steps**: "Association of Step Volume and Intensity With All-Cause Mortality" (JAMA Internal Medicine, 2019)
- **Sleep**: "Sleep Duration and All-Cause Mortality" (Sleep, 2010)
- **Exercise**: "Association of Leisure-Time Physical Activity With Risk of Cancer" (JAMA Internal Medicine, 2016)
- **Heart Rate Variability**: Multiple cardiovascular health studies
- **Resting Heart Rate**: "Resting Heart Rate and Risk of Cardiovascular Diseases" (Heart, 2016)

### Impact Calculation Methodology
- **Baseline Comparison**: Each metric compared against research-established baselines
- **Dosage Response**: Linear and non-linear relationships based on study findings
- **Confidence Intervals**: Built-in uncertainty factors for projection calculations
- **Damping Factors**: Prevent unrealistic life extension/reduction projections

## 🔐 Privacy & Security

### Data Protection
- **Local Processing**: All health calculations performed on-device
- **No Health Data Transmission**: Personal health information never sent to servers
- **Anonymous Analytics**: Only opt-in, anonymized usage patterns collected
- **Secure Storage**: All data stored using iOS secure frameworks

### Permissions
- **HealthKit**: Read-only access to selected health metrics
- **Sign in with Apple**: Optional, privacy-focused authentication
- **StoreKit**: For subscription management only

## 🛠 Development Workflow

### Code Organization
- **File Size Limit**: All Swift files kept under 300 lines
- **Single Responsibility**: Each class/struct has one clear purpose
- **Protocol-Based**: Dependency injection through protocols
- **MARK Comments**: Clear code section organization

### Testing Strategy
- **Unit Tests**: Core algorithms and business logic
- **UI Tests**: Critical user flows and onboarding
- **Mock Data**: Consistent testing with simulated HealthKit data
- **Performance Tests**: Battery visualization and calculation performance

### Documentation Standards
- **Swift DocC**: All public APIs documented
- **Architecture Decisions**: Documented in `/Documentation/Architecture/`
- **Algorithm Explanations**: Health impact calculations documented
- **User Flow Diagrams**: Visual documentation of app navigation

## 🎨 Design System

### Battery Theme
- **Visual Metaphor**: Health as energy, metrics as power sources
- **Familiar Icons**: Battery indicators following Apple's design patterns
- **Glass Effects**: Modern glassmorphism with depth and transparency
- **Power Levels**: 5-level system (Critical, Low, Medium, High, Full)

### Color System
- **Primary**: Amped Green (healthy/positive impacts)
- **Secondary**: Amped Silver (neutral elements)
- **Warning**: Amped Yellow (moderate concerns)  
- **Critical**: Amped Red (negative impacts)
- **Time-based**: Morning, Midday, Afternoon, Evening, Night themes

### Accessibility
- **VoiceOver Support**: Full screen reader compatibility
- **Dynamic Type**: Supports all iOS text size preferences
- **Color Contrast**: WCAG compliant contrast ratios
- **Reduced Motion**: Alternative animations when requested

## 📈 Performance Optimization

### Health Data Processing
- **Efficient Queries**: Optimized HealthKit data requests
- **Background Tasks**: Health data updates don't block UI
- **Caching Strategy**: Smart caching for offline operation
- **Memory Management**: Value types and ARC optimization

### UI Performance
- **Lazy Loading**: Health metrics loaded as needed
- **Animation Optimization**: 60fps battery visualizations
- **State Management**: Efficient SwiftUI state handling
- **Image Assets**: Optimized battery and background images

## 🚀 Future Roadmap

### Planned Features
- **Cloud Sync**: Optional iCloud synchronization
- **Apple Watch**: Companion watchOS app
- **Health Trends**: Long-term health pattern analysis
- **Goal Setting**: Personalized health improvement targets
- **Social Features**: Optional health challenge sharing

### Scalability Preparation
- **CloudKit Ready**: Architecture prepared for cloud sync
- **Microservices**: Clear service boundaries for future expansion
- **A/B Testing**: Framework in place for feature experimentation
- **Analytics Pipeline**: Privacy-preserving usage insights

## 📄 License

*License information coming soon*

## 📞 Contact

For questions, support, or feedback, please reach out through the app's settings screen or visit our support documentation.

---

**Amped - Power Up Your Life!** 🔋⚡

*Transform your health data into actionable insights with the power of science and the simplicity of a battery indicator.*
