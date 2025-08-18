# Component Catalog

## Overview

Visual reference guide for all UI components in the Amped app, organized by feature area and usage patterns.

## Core Components

### Battery Visualization

#### InteractiveBatteryView
**Location**: `UI/Components/InteractiveBatteryView.swift`
**Purpose**: Main life impact battery with time period selection

```swift
InteractiveBatteryView(
    batteryLevel: 0.75,
    period: .day,
    onPeriodChange: { newPeriod in /* handle change */ }
)
```

**Features**:
- Real-time charge level animation
- Touch interactions for period selection (Day/Month/Year)
- Visual feedback for charging/discharging states
- Accessibility support with state announcements

#### BatteryLifeProjectionCard
**Location**: `UI/MetricComponents/BatteryLifeProjectionCard.swift`
**Purpose**: Total life expectancy visualization

```swift
BatteryLifeProjectionCard(
    projection: lifeProjection,
    displayMode: .percentage
)
```

**Features**:
- Dual display modes (years/percentage)
- Confidence interval indicators
- Glass theme integration
- VoiceOver life expectancy announcements

### Metric Display Components

#### BatteryMetricCard
**Location**: `UI/MetricComponents/BatteryMetricCard.swift`
**Purpose**: Individual health metric visualization

```swift
BatteryMetricCard(
    metric: healthMetric,
    powerLevel: .highPower,
    onTap: { /* navigate to detail */ }
)
```

**Features**:
- Power level color coding
- Metric value and impact display
- Glass effect layering
- Touch feedback with haptics

#### MetricDetailView
**Location**: `Features/UI/MetricDetailView.swift`
**Purpose**: Expanded metric information with charts

```swift
MetricDetailView(metric: selectedMetric)
```

**Features**:
- Historical chart visualization
- Contextual tips and insights
- Research reference citations
- Scrollable content with safe area handling

### Glass Theme Components

#### GlassCard
**Location**: `UI/Components/GlassCard.swift`
**Purpose**: Standard card container with blur effects

```swift
GlassCard(material: .regular) {
    // Card content
}
```

**Material Options**:
- `.ultraThin` - Subtle background blur
- `.thin` - Light transparency
- `.regular` - Standard glass effect
- `.thick` - Strong blur effect
- `.prominent` - Maximum blur/opacity

#### GlassButton
**Location**: `UI/Components/GlassButton.swift`
**Purpose**: Interactive button with glass styling

```swift
GlassButton("Continue", material: .thin) {
    // Button action
}
```

## Onboarding Components

### WelcomeView
**Location**: `Features/Onboarding/WelcomeView.swift`
**Purpose**: App introduction screen

**Key Elements**:
- Amped logo with battery animation
- Brand tagline "Power Up Your Life"
- Primary CTA button
- Battery charge animation on load

### PersonalizationIntroView
**Location**: `Features/Onboarding/PersonalizationIntroView.swift`
**Purpose**: Questionnaire introduction

**Key Elements**:
- Battery at 50% with customization message
- Benefit icons with descriptions
- Progress indicator setup
- Swipe gesture hint animation

### QuestionnaireView
**Location**: `Features/Questionnaire/QuestionnaireView.swift`
**Purpose**: Health assessment interface

**Key Elements**:
- Progress indicator (5 questions)
- Question cards with max 4 options
- Gesture-based navigation
- Validation feedback

### HealthKitPermissionsView
**Location**: `Features/HealthKit/HealthKitPermissionsView.swift`
**Purpose**: HealthKit access request

**Key Elements**:
- Permission benefit explanations
- Metric list with descriptions
- Privacy messaging
- Graceful denial handling

### PaymentView
**Location**: `Features/Payment/PaymentView.swift`
**Purpose**: Subscription options

**Key Elements**:
- Feature comparison
- Trial offer highlighting
- Value proposition based on questionnaire
- Secure payment processing

## Dashboard Components

### DashboardView
**Location**: `Features/UI/DashboardView.swift`
**Purpose**: Main app interface

**Layout Structure**:
- Dual battery system at top
- Metric cards in scrollable grid
- Tab navigation at bottom
- Time-based theme integration

### ImpactPageView
**Location**: `Features/UI/DashboardPages/ImpactPageView.swift`
**Purpose**: Life impact battery page

**Key Elements**:
- Interactive battery with period selector
- Real-time impact updates
- Battery level animations
- Accessibility announcements

### ProjectionPageView
**Location**: `Features/UI/DashboardPages/ProjectionPageView.swift`
**Purpose**: Life projection display

**Key Elements**:
- Total life expectancy visualization
- Confidence interval display
- Projection methodology explanation
- Baseline vs adjusted comparison

## Chart Components

### ImpactMetricChart
**Location**: `UI/Components/ImpactMetricChart.swift`
**Purpose**: Historical impact data visualization

```swift
ImpactMetricChart(
    data: chartData,
    metric: healthMetric,
    period: selectedPeriod
)
```

**Features**:
- Renpho-style chart design
- Impact trend visualization
- Interactive data points
- Accessibility chart descriptors

### ChartSummaryStats
**Location**: `UI/Components/ChartSummaryStats.swift`
**Purpose**: Chart data summary display

**Features**:
- Key statistics display
- Trend direction indicators
- Accessible numeric summaries
- Period-based scaling

## Utility Components

### ProgressIndicator
**Location**: `UI/Components/ProgressIndicator.swift`
**Purpose**: Onboarding and loading progress

```swift
ProgressIndicator(
    current: currentStep,
    total: totalSteps,
    style: .circular
)
```

### ActionButton
**Location**: `UI/Components/ActionButton.swift`
**Purpose**: Primary call-to-action styling

```swift
ActionButton("Get Started", style: .primary) {
    // Action
}
```

**Styles**:
- `.primary` - Main CTA with brand colors
- `.secondary` - Secondary actions
- `.glass` - Glass theme integration

### SafariView
**Location**: `UI/Components/SafariView.swift`
**Purpose**: In-app web content display

**Usage**: Privacy policies, research citations, external links

## Shared UI Patterns

### Navigation Patterns
- **Swipe gestures** for onboarding flow
- **Tab navigation** for main app areas
- **Modal presentations** for detail views
- **Back navigation** with clear context

### Loading States
- **Progress indicators** for long operations
- **Skeleton screens** for data loading
- **Error states** with retry options
- **Empty states** with helpful guidance

### Feedback Patterns
- **Haptic feedback** for interactions
- **Visual confirmation** for completed actions
- **Battery charge animations** for positive changes
- **Subtle notifications** for background updates

## Theme Integration

### Time-Based Themes
Components automatically adapt colors based on time of day:
- **Morning**: Soft sunrise tones (6AM-10AM)
- **Midday**: Bright daylight (10AM-2PM)
- **Afternoon**: Warm afternoon (2PM-6PM)
- **Evening**: Golden hour (6PM-10PM)
- **Night**: Deep blues (10PM-6AM)

### Battery Power Levels
Components use consistent power level colors:
- **Full Power**: Green - Optimal health impact
- **High Power**: Light green - Good impact
- **Medium Power**: Yellow - Neutral impact
- **Low Power**: Orange - Poor impact
- **Critical Power**: Red - Very poor impact

## Animation Catalog

### Battery Animations
- **Charging effect**: Smooth fill animation (0.3s)
- **Level changes**: Eased transitions between states
- **Power flow**: Energy transfer between batteries

### Glass Animations
- **Blur transitions**: Depth changes for focus states
- **Scale effects**: Touch feedback and emphasis
- **Opacity changes**: State transitions and reveals

### 3D Transformations
- **Subtle depth**: Card hover and selection states
- **Perspective shifts**: Navigation transitions
- **Rotation effects**: Interactive feedback

## Accessibility Integration

### VoiceOver Support
Every component includes:
- **Descriptive labels** explaining purpose
- **Current values** for dynamic content
- **Interaction hints** for complex gestures
- **State announcements** for changes

### Dynamic Type
All components scale appropriately:
- **Text size adaptation** from xSmall to xxxLarge
- **Layout reflow** for accessibility sizes
- **Touch target scaling** maintaining 44pt minimum

## Usage Guidelines

### Component Selection
- **Reuse existing** components before creating new ones
- **Follow established** patterns for consistency
- **Consider accessibility** from initial design
- **Test performance** on target devices

### Customization
- **Use theme modifiers** rather than hardcoded values
- **Respect design system** color and typography choices
- **Maintain component** interface contracts
- **Document custom** behavior and requirements

### Performance
- **Lazy loading** for expensive components
- **Efficient animations** targeting 60fps
- **Memory conscious** view lifecycle management
- **Background processing** for heavy calculations

This catalog provides a comprehensive reference for all UI components, ensuring consistent implementation and proper usage throughout the app.
