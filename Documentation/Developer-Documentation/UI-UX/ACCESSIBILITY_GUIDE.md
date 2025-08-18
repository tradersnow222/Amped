# Accessibility Guide

## Overview

Amped is built with accessibility as a core principle, supporting users with diverse needs through comprehensive VoiceOver support, Dynamic Type scaling, and inclusive design patterns.

## VoiceOver Implementation

### Essential Properties
```swift
.accessibilityLabel("Battery at 75% charge")
.accessibilityHint("Shows your current health impact level")
.accessibilityValue("Gaining 45 minutes per day")
.accessibilityAddTraits(.isButton) // For interactive elements
```

### Label Guidelines
- **Be descriptive**: "Health impact battery" not just "Battery"
- **Include state**: "Steps goal completed" vs "Steps goal"
- **Avoid redundancy**: Don't repeat visible text exactly
- **Use context**: "Questionnaire progress 3 of 5" not just "3 of 5"

### Hint Guidelines
- **Explain purpose**: "Double tap to view detailed health metrics"
- **Describe outcome**: "Opens exercise recommendations"
- **Keep concise**: Maximum 1-2 sentences
- **Skip obvious**: Don't hint for standard buttons

## Dynamic Type Support

### Text Scaling
All text must scale from **xSmall** to **xxxLarge**:

```swift
Text("Battery Level")
    .font(.headline)  // Automatically scales
    .dynamicTypeSize(.xSmall...(.xxxLarge))  // Set bounds if needed
```

### Layout Adaptation
```swift
@Environment(\.dynamicTypeSize) var dynamicTypeSize

var body: some View {
    if dynamicTypeSize.isAccessibilitySize {
        VStack { /* Vertical layout for large text */ }
    } else {
        HStack { /* Horizontal layout for normal text */ }
    }
}
```

### Touch Target Requirements
- **Minimum size**: 44x44 points for all interactive elements
- **Maintain spacing**: Adequate padding between elements
- **Scale appropriately**: Larger targets for accessibility sizes

## Component Accessibility

### Battery Components
```swift
BatteryView(level: 0.75)
    .accessibilityLabel("Health battery")
    .accessibilityValue("75% charged")
    .accessibilityHint("Represents your current health impact")
    .accessibilityAddTraits(.updatesFrequently)
```

### Metric Cards
```swift
BatteryMetricCard(metric: stepsMetric)
    .accessibilityLabel("Steps today")
    .accessibilityValue("8,547 steps, gaining 12 minutes")
    .accessibilityHint("Tap to view detailed step analysis")
    .accessibilityAddTraits(.isButton)
```

### Charts and Graphs
```swift
MetricChart(data: chartData)
    .accessibilityLabel("Steps trend chart")
    .accessibilityValue("7-day average: 9,200 steps, trending up")
    .accessibilityHint("Chart shows step count over the past week")
    .accessibilityChartDescriptor(chartDescriptor) // iOS 15+
```

### Interactive Elements
```swift
Button("Continue to Dashboard") {
    // Action
}
.accessibilityIdentifier("continue-to-dashboard")
.accessibilityAddTraits(.isButton)
```

## Onboarding Accessibility

### Progress Indicators
```swift
ProgressView(value: currentStep, total: totalSteps)
    .accessibilityLabel("Questionnaire progress")
    .accessibilityValue("\(currentStep) of \(totalSteps) completed")
```

### Questionnaire Questions
```swift
// Question with maximum 4 options (per design system rules)
QuestionView(question: "How often do you exercise?")
    .accessibilityLabel("Exercise frequency question")
    .accessibilityHint("Select from 4 options below")
```

### Form Validation
```swift
if !isValid {
    Text("Please select an answer")
        .foregroundColor(.red)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel("Error: Please select an answer to continue")
}
```

## Navigation Accessibility

### Tab Navigation
```swift
TabView {
    DashboardView()
        .tabItem {
            Image(systemName: "battery.100")
            Text("Dashboard")
        }
        .accessibilityLabel("Dashboard tab")
        .accessibilityHint("View your health batteries and metrics")
}
```

### Modal Presentations
```swift
.sheet(isPresented: $showingDetail) {
    MetricDetailView(metric: selectedMetric)
        .accessibilityAddTraits(.isModal)
}
```

### Navigation Hierarchy
- **Logical order**: Left-to-right, top-to-bottom
- **Skip navigation**: Allow jumping between sections
- **Breadcrumbs**: Clear navigation context

## Testing Accessibility

### VoiceOver Testing Checklist
- [ ] **All elements** have appropriate labels
- [ ] **Navigation order** is logical
- [ ] **State changes** are announced
- [ ] **Dynamic content** updates announced
- [ ] **Error messages** are clear and actionable
- [ ] **Form validation** provides clear feedback

### Testing Process
1. **Enable VoiceOver**: Settings → Accessibility → VoiceOver
2. **Navigate with gestures**: Swipe to move, double-tap to activate
3. **Test all flows**: Complete onboarding to dashboard
4. **Verify announcements**: State changes and updates
5. **Check focus order**: Logical progression through UI

### Accessibility Inspector
Use Xcode's Accessibility Inspector to:
- **Audit accessibility** issues automatically
- **Test VoiceOver** navigation
- **Verify color contrast** ratios
- **Check touch target** sizes

## Color Accessibility

### Contrast Requirements
- **WCAG AA compliance**: 4.5:1 for normal text, 3:1 for large text
- **Never rely on color alone**: Use icons + text combinations
- **Test with filters**: Simulate color blindness

### Battery Color Strategy
```swift
// Good: Color + shape + text
BatteryView(level: 0.75)
    .foregroundColor(.fullPower)  // Green color
    .overlay(Text("75%"))         // Text indicator
    .accessibilityValue("75% charged, good health impact")

// Avoid: Color only indicators
```

## Reduced Motion Support

### Motion Preferences
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var batteryAnimation: Animation? {
    reduceMotion ? nil : .easeInOut(duration: 0.3)
}
```

### Alternative Presentations
- **Static states** instead of animations
- **Instant transitions** vs animated transitions
- **Simple fades** instead of complex transformations

## Error Handling Accessibility

### Error Announcements
```swift
if let errorMessage = viewModel.errorMessage {
    Text(errorMessage)
        .foregroundColor(.red)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityPriority(.high)  // Announce immediately
}
```

### Loading States
```swift
if isLoading {
    ProgressView("Calculating health impact...")
        .accessibilityLabel("Calculating your health impact")
        .accessibilityAddTraits(.updatesFrequently)
}
```

## Common Patterns

### Card Accessibility
```swift
VStack {
    Text("Steps Today")
        .accessibilityAddTraits(.isHeader)
    Text("8,547 steps")
        .accessibilityLabel("8,547 steps completed today")
}
.accessibilityElement(children: .combine)
.accessibilityAddTraits(.isButton)
.accessibilityHint("Tap to view step details and trends")
```

### List Accessibility
```swift
List(metrics) { metric in
    MetricRow(metric: metric)
        .accessibilityLabel("\(metric.name): \(metric.displayValue)")
        .accessibilityHint("Tap to view \(metric.name) details")
}
.accessibilityLabel("Health metrics list")
```

### Modal Accessibility
```swift
NavigationView {
    DetailView()
        .navigationTitle("Metric Details")
        .navigationBarItems(trailing: Button("Done") { dismiss() })
}
.accessibilityAddTraits(.isModal)
```

## Health Data Accessibility

### Metric Announcements
```swift
// Announce significant changes
if significantChange {
    UIAccessibility.post(
        notification: .announcement,
        argument: "Health battery updated to \(newLevel)%"
    )
}
```

### Chart Data Access
```swift
// Provide text alternative for charts
if !chartData.isEmpty {
    Text("Chart shows upward trend over 7 days")
        .accessibilityLabel("Chart summary")
        .accessibilityHidden(false)
}
```

## Accessibility Testing Scenarios

### Real-World Testing
1. **Complete onboarding** with VoiceOver only
2. **Navigate dashboard** using swipe gestures
3. **Access metric details** and return to main view
4. **Change settings** with voice control
5. **Handle errors** like denied permissions

### Edge Cases
- **No health data** available
- **Network connectivity** issues
- **Permission denied** states
- **Loading states** and timeouts

## Best Practices Summary

### Do's
✅ **Test with real users** who use accessibility features
✅ **Design for voice control** from the start  
✅ **Provide multiple ways** to access information
✅ **Use semantic markup** (.isHeader, .isButton)
✅ **Announce important changes** to dynamic content

### Don'ts
❌ **Don't rely on color alone** for information
❌ **Don't use vague labels** like "Button" or "View"
❌ **Don't ignore loading states** and error handling
❌ **Don't assume gestures** work for all users
❌ **Don't forget to test** with real accessibility tools

## Resources

### Apple Documentation
- [Accessibility Programming Guide](https://developer.apple.com/documentation/accessibility)
- [VoiceOver Testing Guide](https://developer.apple.com/documentation/accessibility/supporting_voiceover_in_your_app)
- [Dynamic Type Implementation](https://developer.apple.com/documentation/uikit/text_display_and_fonts/adding_a_custom_font_to_your_app)

### Testing Tools
- **Xcode Accessibility Inspector**
- **iOS Accessibility Shortcut** (triple-click home/side button)
- **Voice Control** for hands-free testing
- **Switch Control** for motor accessibility testing

This guide ensures that all UI/UX improvements maintain and enhance the app's accessibility standards.
