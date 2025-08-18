# Contributing to Amped

## Development Workflow

### Branch Strategy
```bash
main           # Production-ready code
feature/       # New features (feature/battery-animations)
bugfix/        # Bug fixes (bugfix/chart-display-issue)
ui/            # UI/UX improvements (ui/glass-theme-enhancement)
```

### Getting Started
1. **Fork** the repository (if external contributor)
2. **Create branch** from main with descriptive name
3. **Make changes** following coding standards
4. **Test thoroughly** on device and simulator
5. **Submit pull request** with detailed description

## Code Standards

### Swift Guidelines
- **File size limit**: 300 lines maximum
- **MVVM architecture** with clear separation
- **SwiftUI-first** approach with UIKit when necessary
- **Accessibility-first** development

### Naming Conventions
```swift
// Files
BatteryMetricCard.swift
HealthKitPermissionsView.swift

// Types
struct UserProfile
class HealthKitManager
enum HealthMetricType

// Functions
func calculateLifeImpact()
func updateBatteryLevel()
```

### Documentation Requirements
```swift
/// Calculates daily life impact from health metrics
/// - Parameter metrics: Array of current health metrics
/// - Parameter period: Time period for calculation (day/month/year)
/// - Returns: Impact data point with calculated values
func calculateTotalImpact(metrics: [HealthMetric], period: TimePeriod) -> ImpactDataPoint
```

## UI/UX Specific Guidelines

### Design System Compliance
- **Use established colors** from Assets.xcassets
- **Follow dual theme** (Battery + Glass) patterns
- **Implement accessibility** from start
- **Test on multiple devices**

### Critical UI Rules
1. **Questionnaire maximum 4 options** per question
2. **VoiceOver labels** for all interactive elements
3. **Dynamic Type support** for all text
4. **Safe area respect** on all devices

### Animation Standards
- **Performance target**: 60fps on all supported devices
- **Duration guidelines**: 0.3s for micro-interactions, 0.5s for transitions
- **Easing**: Use SwiftUI's built-in easing functions
- **Accessibility**: Provide reduced motion alternatives

## Testing Requirements

### UI Testing Checklist
- [ ] **Multiple screen sizes**: SE, standard, Pro Max
- [ ] **Light and dark mode** compatibility
- [ ] **VoiceOver navigation** works correctly
- [ ] **Dynamic Type scaling** at largest sizes
- [ ] **Landscape orientation** (where supported)
- [ ] **Animation performance** on iPhone 12 or older

### Code Testing
```bash
# Run all tests
⌘+U in Xcode

# Run specific test file
xcodebuild test -scheme Amped -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Manual Testing
1. **Real device testing** for HealthKit integration
2. **Complete user flows** from onboarding to dashboard
3. **Edge cases** like denied permissions
4. **Performance** under various data loads

## Pull Request Process

### PR Requirements
1. **Descriptive title** explaining the change
2. **Clear description** with before/after context
3. **Screenshots/videos** for UI changes
4. **Testing checklist** completed
5. **No merge conflicts** with main branch

### PR Template
```markdown
## Changes Made
Brief description of changes

## Testing Completed
- [ ] Device testing on iPhone
- [ ] Simulator testing
- [ ] VoiceOver testing
- [ ] Dynamic Type testing
- [ ] Performance verification

## Screenshots
[Include before/after screenshots for UI changes]

## Notes
Any additional context or considerations
```

### Review Criteria
- **Code quality** meets project standards
- **UI consistency** with design system
- **Accessibility compliance** verified
- **Performance impact** acceptable
- **Test coverage** adequate

## Common Tasks

### Adding New UI Components
1. **Create in appropriate directory** (`UI/Components/` or `UI/MetricComponents/`)
2. **Follow naming conventions** (descriptive, SwiftUI style)
3. **Implement accessibility** from start
4. **Add SwiftUI preview** for development
5. **Document in design system** if reusable

### Modifying Existing Components
1. **Check all usage locations** before changing interfaces
2. **Maintain backward compatibility** where possible
3. **Update documentation** if behavior changes
4. **Test impact on accessibility**

### Working with Themes
```swift
// Using Glass Theme
.background(Material.thin)
.glassTheme(.regular)

// Using Battery Theme
.foregroundColor(.batteryLevel(for: powerLevel))
.batteryStyle(.horizontal)
```

## File Organization

### UI Component Structure
```
UI/
├── Components/          # Shared reusable components
│   ├── GlassCard.swift
│   ├── BatteryIndicator.swift
│   └── ActionButton.swift
├── MetricComponents/    # Health metric specific UI
│   ├── BatteryMetricCard.swift
│   └── MetricDetailView.swift
└── Theme/              # Design system
    ├── BatteryTheme.swift
    ├── GlassTheme.swift
    └── TextStyles.swift
```

### Feature Component Structure
```
Features/UI/
├── DashboardPages/     # Main app screens
├── ViewModels/         # UI logic and state
└── Components/         # Feature-specific components
```

## Debugging UI Issues

### Common Issues
1. **Layout problems**: Use SwiftUI Inspector
2. **Animation performance**: Profile with Instruments
3. **Accessibility**: Use Accessibility Inspector
4. **Theme issues**: Check time-based color updates

### Debug Tools
- **SwiftUI Inspector**: Runtime view debugging
- **Accessibility Inspector**: VoiceOver testing
- **Instruments**: Performance profiling
- **Console logs**: Use OSLog for structured logging

## Quality Checklist

### Before Submitting
- [ ] **Builds successfully** on clean environment
- [ ] **No compiler warnings** introduced
- [ ] **Accessibility labels** added for new UI
- [ ] **Preview works** without dependencies
- [ ] **Performance acceptable** on target devices
- [ ] **Documentation updated** for significant changes

### UI Specific Checks
- [ ] **Design system compliance** verified
- [ ] **Color accessibility** (contrast ratios)
- [ ] **Touch targets** minimum 44x44 points
- [ ] **Safe area** handling on all devices
- [ ] **State management** follows MVVM pattern

By following these guidelines, you'll ensure your contributions integrate seamlessly with the existing codebase and maintain the high quality standards of the Amped app.
