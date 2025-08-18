# Developer Documentation Index

## Quick Start
- **[Developer Setup](../../DEVELOPER_SETUP.md)** - Complete setup instructions and first build
- **[Contributing Guidelines](../../CONTRIBUTING.md)** - Development workflow and standards
- **[Troubleshooting](../../TROUBLESHOOTING.md)** - Common issues and solutions

## UI/UX Development
- **[UI Design System](UI-UX/UI_DESIGN_SYSTEM.md)** - Comprehensive design system guide
- **[Component Catalog](UI-UX/COMPONENT_CATALOG.md)** - Visual reference for all UI components
- **[Accessibility Guide](UI-UX/ACCESSIBILITY_GUIDE.md)** - VoiceOver and accessibility implementation
- **[Animation Guidelines](UI-UX/ANIMATION_GUIDELINES.md)** - Animation standards and patterns
- **[UI Testing Guide](UI-UX/TESTING_UI.md)** - UI testing strategies and tools

## Architecture & Technical
- **[Architecture Overview](../Architecture/Architecture.md)** - System design and patterns
- **[Health Algorithms](../HealthAlgorithms/ImpactCalculations.md)** - Life impact calculation details
- **[Lifespan Calculations](../lifespan-calculations.md)** - Complete calculation documentation

## Project-Specific Guides
- **[Chart Improvements](../RENPHO_STYLE_CHART_IMPROVEMENTS.md)** - Chart visualization enhancements
- **[Metrics Chart UX](../METRICS_CHART_UX_REVIEW.md)** - Chart behavior analysis
- **[Performance Validation](../../Amped/Documentation/PERFORMANCE_VALIDATION_TESTS.md)** - Performance testing strategies

## For UI/UX Developers

### Essential Reading (Start Here)
1. **[Developer Setup](../../DEVELOPER_SETUP.md)** - Get up and running
2. **[UI Design System](UI-UX/UI_DESIGN_SYSTEM.md)** - Understand the design patterns
3. **[Component Catalog](UI-UX/COMPONENT_CATALOG.md)** - See all available components
4. **[Contributing Guidelines](../../CONTRIBUTING.md)** - Follow development standards

### Design System Deep Dive
- **Dual Theme System**: Battery + Glass themes for energy visualization
- **Color System**: Energy levels, time-based themes, brand colors
- **Typography**: Structured text styles with Dynamic Type support
- **Accessibility**: VoiceOver and inclusive design patterns

### Key Constraints
- **Questionnaire Rule**: Maximum 4 options per question (CRITICAL)
- **Performance Target**: 60fps animations on iPhone 12+
- **Accessibility First**: VoiceOver labels required for all interactive elements
- **MVVM Architecture**: Clear separation between UI and business logic

### Quick Reference
```swift
// Basic glass card
GlassCard {
    Text("Content")
        .textStyle(.headline)
}
.glassTheme(.regular)

// Accessible battery display
BatteryView(level: 0.75)
    .accessibilityLabel("Health battery")
    .accessibilityValue("75% charged")
```

## Documentation Organization

```
Documentation/
├── Developer-Documentation/
│   ├── README.md           # This index (start here)
│   └── UI-UX/             # UI/UX specific guides
│       ├── UI_DESIGN_SYSTEM.md
│       ├── COMPONENT_CATALOG.md
│       ├── ACCESSIBILITY_GUIDE.md
│       ├── ANIMATION_GUIDELINES.md
│       └── TESTING_UI.md
├── Architecture/           # Technical architecture
├── HealthAlgorithms/      # Health calculation details
└── [Feature-specific docs] # Chart improvements, UX reviews, etc.
```

## Getting Help

### Internal Resources
1. **Code Examples**: Review existing component implementations
2. **Test Files**: Check `AmpedTests/` for testing patterns
3. **Documentation**: Search this documentation for specific topics

### External Resources
1. **Apple Developer Documentation**: iOS and HealthKit guides
2. **SwiftUI Documentation**: Component and animation references
3. **Accessibility Guidelines**: Apple's accessibility best practices

Start with the **Developer Setup** guide to get your environment configured, then dive into the **UI Design System** to understand the design patterns and constraints.
