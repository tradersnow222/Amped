# Developer Setup Guide

## Prerequisites

### Required Software
- **Xcode 15.0+** (latest stable version recommended)
- **macOS 13.0+** (Ventura or later)
- **iOS 16.0+ Simulator** or physical iPhone

### Development Account
- **Apple Developer Account** (for device testing and HealthKit)
- **Sign in with Apple** capability enabled

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/tradersnow222/Amped.git
cd Amped
```

### 2. Open in Xcode
```bash
open Amped.xcodeproj
```

### 3. Configure Build Settings
- **Bundle Identifier**: Update to your team's identifier
- **Development Team**: Select your Apple Developer team
- **Code Signing**: Automatic signing recommended

### 4. Build Script Setup
The project requires a custom build script for HealthKit permissions:

1. In Xcode, select **Amped target** → **Build Phases**
2. Verify "Update Info.plist" script exists after "Copy Bundle Resources"
3. If missing, add new Run Script Phase with:
   ```bash
   "${SRCROOT}/Amped/Scripts/update_infoplist.sh"
   ```

### 5. First Build
```bash
# Clean and build
⌘+Shift+K (Clean)
⌘+B (Build)
```

## Running the App

### Simulator Testing
- Use **iPhone 15** or newer simulator for best results
- Enable **Apple Health** app in simulator
- Note: HealthKit data will be simulated/empty

### Device Testing (Recommended for UI/UX)
- **Physical iPhone required** for real HealthKit data
- iOS 16.0+ required
- Automatic code signing handles provisioning

## Project Structure Overview

```
Amped/
├── Features/           # Feature modules
│   ├── Onboarding/     # Welcome, questionnaire, payments
│   ├── UI/            # Dashboard, metric details
│   └── HealthKit/     # Health data integration
├── UI/                # Shared UI components
│   ├── Components/    # Reusable components
│   ├── MetricComponents/ # Health metric UI
│   └── Theme/         # Design system
└── Core/              # Models and services
```

## Key Files for UI/UX Work

### Main App Flow
- `AmpedApp.swift` - App entry point
- `ContentView.swift` - Main navigation
- `Features/Onboarding/OnboardingFlow.swift` - Complete onboarding

### Core UI Components
- `UI/Components/` - Reusable components
- `UI/MetricComponents/` - Health metric cards
- `UI/Theme/` - Design system and themes

### Feature Views
- `Features/Onboarding/` - Welcome, questionnaire, payment screens
- `Features/UI/` - Dashboard and metric detail views

## Design System

### Themes
- **Battery Theme**: Energy/charge visualizations
- **Glass Theme**: Apple Liquid Glass effects

### Colors
- **Energy Levels**: fullPower, highPower, mediumPower, lowPower, criticalPower
- **Time-Based**: morning, midday, afternoon, evening, night
- **Brand**: ampedGreen, ampedYellow, ampedRed, ampedSilver, ampedDark

### Typography
- Uses structured `AmpedTextStyle` system
- Supports Dynamic Type for accessibility

## Common Development Tasks

### Preview Development
```swift
#Preview {
    YourView()
        .environmentObject(SettingsManager())
        .environmentObject(HealthKitManager())
}
```

### Testing UI Changes
1. Build and run on device/simulator
2. Use Xcode Previews for rapid iteration
3. Test with VoiceOver enabled
4. Verify Dynamic Type scaling

### Debugging UI Issues
1. Use **SwiftUI Inspector** (Xcode debug tools)
2. Check console for layout warnings
3. Use **Accessibility Inspector** for VoiceOver testing

## Troubleshooting

### Build Issues
- **Clean Build Folder** (⌘+Shift+K) and rebuild
- Check script permissions: `chmod +x Amped/Scripts/update_infoplist.sh`
- Verify bundle identifier is unique

### HealthKit Issues
- Ensure HealthKit capability is enabled in target
- Check physical device for real health data
- Reset Health & Privacy settings if needed

### UI/Animation Issues
- Test on multiple device sizes
- Check for Metal/GPU compatibility
- Verify animation performance on older devices

## Getting Help

### Documentation
- See `Documentation/` folder for detailed guides
- Check `.clinerules/` for coding standards
- Review existing component implementations

### Code Style
- Follow Swift naming conventions
- Keep files under 300 lines
- Use MVVM architecture pattern
- Implement accessibility from start

### Testing
- Run existing tests: `⌘+U`
- Add UI tests for new components
- Test on multiple screen sizes
- Verify accessibility compliance
