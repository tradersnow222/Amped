# Amped UI Design System

## Overview

Amped uses a sophisticated dual-theme design system that combines battery-inspired energy visualizations with Apple's Liquid Glass aesthetic. This guide covers all UI components, themes, and design patterns.

## Dual Theme System

### Battery Theme
**Purpose**: Visualize health as energy levels
- **Colors**: Energy-based progression (green → yellow → red)
- **Icons**: Horizontal battery segments following Apple patterns
- **Animations**: Charging/discharging effects

### Glass Theme  
**Purpose**: Modern Apple Liquid Glass interface
- **Materials**: Ultra-thin to prominent blur effects
- **Transparency**: Layered depth with backdrop blur
- **Effects**: 3D transformations and visual depth

## Color System

### Energy Level Colors
```swift
fullPower      // Green - Optimal health impact
highPower      // Light green - Good impact  
mediumPower    // Yellow - Neutral/moderate impact
lowPower       // Orange - Poor impact
criticalPower  // Red - Very poor impact
```

### Time-Based Colors
```swift
ampedMorning   // 6AM-10AM - Soft sunrise tones
ampedMidday    // 10AM-2PM - Bright daylight
ampedAfternoon // 2PM-6PM - Warm afternoon
ampedEvening   // 6PM-10PM - Golden hour
ampedNight     // 10PM-6AM - Deep blues
```

### Brand Colors
```swift
ampedGreen     // Primary brand - fully charged state
ampedYellow    // Secondary - medium charge
ampedRed       // Warning - low charge
ampedSilver    // Neutral - metal/chrome effects
ampedDark      // Background - deep contrast
```

## Typography System

### AmpedTextStyle
Structured text styles with consistent weight and sizing:

```swift
.largeTitle    // Main headings, battery percentages
.title         // Section headers
.headline      // Card titles, metric names
.body          // Primary content text
.callout       // Secondary information
.caption       // Fine print, timestamps
```

### Dynamic Type Support
- All text scales with iOS accessibility settings
- Minimum legible sizes maintained
- VoiceOver compatibility built-in

## Core UI Components

### Battery Visualization
**InteractiveBatteryView**
- Real-time battery charge animation
- Touch interactions for time period selection
- Visual feedback for charging/discharging

**BatteryLifeProjectionCard**
- Total life expectancy visualization
- Percentage and absolute time display
- Confidence interval indicators

### Metric Components
**BatteryMetricCard**
- Individual health metric display
- Power level visualization
- Glass effect layering

**MetricDetailView**
- Expanded metric information
- Historical chart visualization
- Contextual tips and insights

### Glass Components
**Material Effects**
```swift
.ultraThin     // Subtle background blur
.thin          // Light transparency
.regular       // Standard glass effect
.thick         // Strong blur effect
.prominent     // Maximum blur/opacity
```

## Layout Patterns

### Dashboard Layout
- **Dual battery system** at top
- **Metric cards** in scrollable grid
- **Navigation tabs** at bottom

### Onboarding Layout
- **Full-screen flows** with progress indicators
- **Swipe gestures** for navigation
- **"Little yesses"** conversion pattern

### Detail Views
- **Hero sections** with large visuals
- **Chart sections** with historical data
- **Action sections** with recommendations

## Animation Guidelines

### Battery Animations
- **Smooth charging** effects (0.3s duration)
- **Energy flow** between batteries
- **Power level** transitions

### Glass Animations
- **Blur transitions** for depth changes
- **Scale effects** for user interactions
- **Opacity fades** for state changes

### 3D Effects
- **Subtle depth** for visual hierarchy
- **Transform animations** for engagement
- **Performance optimized** for smooth 60fps

## Accessibility Standards

### VoiceOver Support
```swift
.accessibilityLabel("Battery at 75% charge")
.accessibilityHint("Shows current health impact")
.accessibilityValue("Gaining 45 minutes per day")
```

### Key Requirements
- **Semantic structure** for screen readers
- **Descriptive labels** for all interactive elements
- **State announcements** for dynamic content
- **Navigation order** logical and intuitive

### Dynamic Type
- Text scales from **xSmall** to **xxxLarge**
- **Minimum touch targets** 44x44 points
- **Layout adapts** to content size changes

## Component Catalog

### Onboarding Components
- `WelcomeView` - App introduction
- `PersonalizationIntroView` - Questionnaire setup
- `QuestionnaireView` - Health assessment
- `HealthKitPermissionsView` - Data access
- `PaymentView` - Subscription options

### Dashboard Components
- `DashboardView` - Main app interface
- `ImpactPageView` - Impact battery visualization
- `ProjectionPageView` - Life projection display
- `MetricGridView` - Health metrics overview

### Shared Components
- `GlassCard` - Standard card with blur effect
- `BatteryIndicator` - Reusable battery display
- `MetricChart` - Historical data visualization
- `ProgressIndicator` - User flow progress
- `ActionButton` - Primary CTA styling

## Design Constraints

### Questionnaire Rules
**CRITICAL**: Maximum 4 options per question
- Prevents user overwhelm
- Ensures consistent UI layout
- Maintains semantic clarity

### Performance Guidelines
- **60fps animations** on all supported devices
- **Efficient blur effects** for glass theme
- **Memory conscious** component lifecycle

### Layout Rules
- **Safe area** respect on all devices
- **Dynamic content** sizing support
- **Landscape orientation** support where appropriate

## Testing UI Changes

### Visual Testing
1. **Multiple device sizes** (SE, standard, Plus/Pro Max)
2. **Light and dark mode** compatibility
3. **Time-based theme** transitions
4. **Animation performance** on older devices

### Accessibility Testing
1. **VoiceOver navigation** flow
2. **Dynamic Type** scaling
3. **Color contrast** ratios
4. **Reduced motion** alternatives

### User Flow Testing
1. **Onboarding completion** rates
2. **Gesture recognition** accuracy
3. **Touch target** accessibility
4. **Error state** handling

## Code Examples

### Basic Glass Card
```swift
GlassCard {
    VStack {
        Text("Health Metric")
            .textStyle(.headline)
        BatteryIndicator(level: 0.75)
    }
}
.glassTheme(.regular)
```

### Accessible Battery Display
```swift
BatteryView(level: batteryLevel)
    .accessibilityLabel("Health battery")
    .accessibilityValue("\(Int(batteryLevel * 100))% charged")
    .accessibilityHint("Shows current health impact level")
```

### Time-Based Theme
```swift
Color.timeBasedBackground
    .animation(.easeInOut(duration: 0.5), value: timeOfDay)
```

This design system ensures consistent, accessible, and performant UI development across the entire app.
