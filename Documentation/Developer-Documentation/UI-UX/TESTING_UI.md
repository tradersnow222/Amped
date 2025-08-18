# UI Testing Guide

## Overview

Comprehensive testing strategy for UI/UX components in Amped, covering visual testing, user flow validation, and accessibility compliance.

## Testing Framework

### XCUITest Setup
```swift
import XCTest
@testable import Amped

class AmpedUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
}
```

### SwiftUI Testing
```swift
import SwiftUI
import Testing

@Test func testBatteryViewAccessibility() {
    let batteryView = BatteryView(level: 0.75)
    
    // Test accessibility properties
    #expect(batteryView.accessibilityLabel != nil)
    #expect(batteryView.accessibilityValue != nil)
}
```

## Critical User Flows

### 1. Complete Onboarding Flow
```swift
func testCompleteOnboardingFlow() throws {
    // Welcome screen
    XCTAssertTrue(app.buttons["Get Started"].exists)
    app.buttons["Get Started"].tap()
    
    // Personalization intro
    XCTAssertTrue(app.staticTexts["Power Up Your Experience"].exists)
    app.swipeLeft() // Swipe to begin
    
    // Questionnaire (5 questions)
    for questionIndex in 1...5 {
        // Answer each question
        let firstOption = app.buttons.matching(identifier: "question-option-0").firstMatch
        XCTAssertTrue(firstOption.waitForExistence(timeout: 2))
        firstOption.tap()
        
        // Continue to next question
        if questionIndex < 5 {
            app.swipeLeft()
        }
    }
    
    // HealthKit permissions
    app.buttons["Allow Health Access"].tap()
    
    // Sign in with Apple
    app.buttons["Continue with Apple"].tap()
    
    // Payment screen
    XCTAssertTrue(app.staticTexts["Unlock Full Experience"].exists)
    app.buttons["Start Free Trial"].tap()
    
    // Verify dashboard appears
    XCTAssertTrue(app.staticTexts["Life Impact Battery"].waitForExistence(timeout: 5))
}
```

### 2. Dashboard Navigation
```swift
func testDashboardNavigation() throws {
    // Complete onboarding first
    completeOnboarding()
    
    // Test tab navigation
    app.tabBars.buttons["Dashboard"].tap()
    XCTAssertTrue(app.staticTexts["Life Impact Battery"].exists)
    
    // Test metric card interaction
    let stepsCard = app.buttons.matching(identifier: "metric-card-steps").firstMatch
    XCTAssertTrue(stepsCard.exists)
    stepsCard.tap()
    
    // Verify detail view opens
    XCTAssertTrue(app.navigationBars["Steps Details"].exists)
    
    // Return to dashboard
    app.navigationBars.buttons["Back"].tap()
    XCTAssertTrue(app.staticTexts["Life Impact Battery"].exists)
}
```

### 3. Battery Interaction Testing
```swift
func testBatteryInteractions() throws {
    // Navigate to dashboard
    completeOnboarding()
    
    // Test period selector
    let dayButton = app.buttons["Day"]
    let monthButton = app.buttons["Month"]
    let yearButton = app.buttons["Year"]
    
    // Test period changes
    dayButton.tap()
    XCTAssertTrue(dayButton.isSelected)
    
    monthButton.tap()
    XCTAssertTrue(monthButton.isSelected)
    
    yearButton.tap()
    XCTAssertTrue(yearButton.isSelected)
    
    // Verify battery level updates
    let batteryView = app.otherElements["life-impact-battery"]
    XCTAssertTrue(batteryView.exists)
}
```

## Accessibility Testing

### VoiceOver Navigation Testing
```swift
func testVoiceOverNavigation() throws {
    // Enable VoiceOver simulation
    app.activate()
    
    // Test onboarding accessibility
    let welcomeButton = app.buttons["Get Started"]
    XCTAssertTrue(welcomeButton.exists)
    XCTAssertNotNil(welcomeButton.label)
    
    // Test questionnaire accessibility
    completeOnboarding()
    
    // Verify battery accessibility
    let batteryElement = app.otherElements["life-impact-battery"]
    XCTAssertTrue(batteryElement.exists)
    XCTAssertFalse(batteryElement.label.isEmpty)
}
```

### Dynamic Type Testing
```swift
func testDynamicTypeScaling() throws {
    // Test various content size categories
    let sizeCategories: [UIContentSizeCategory] = [
        .small,
        .medium,
        .large,
        .extraExtraLarge,
        .accessibilityExtraLarge
    ]
    
    for category in sizeCategories {
        // Set content size category
        app.activate()
        // Navigate through app and verify layouts adapt
        testOnboardingWithContentSize(category)
    }
}

private func testOnboardingWithContentSize(_ category: UIContentSizeCategory) {
    // Verify text scales appropriately
    // Verify touch targets remain adequate
    // Verify layout doesn't break
}
```

## Visual Testing

### Screenshot Comparison
```swift
func testVisualRegression() throws {
    // Capture screenshots at key points
    let welcomeScreenshot = app.screenshot()
    let dashboardScreenshot = navigateToDashboard().screenshot()
    
    // Compare against reference images
    // Note: Actual implementation would use visual comparison tools
    XCTAssertNotNil(welcomeScreenshot)
    XCTAssertNotNil(dashboardScreenshot)
}
```

### Theme Testing
```swift
func testTimeBasedThemes() throws {
    // Test theme changes at different times
    let timeThemes = ["morning", "midday", "afternoon", "evening", "night"]
    
    for theme in timeThemes {
        // Simulate time of day
        simulateTimeOfDay(theme)
        
        // Verify theme colors applied
        let backgroundElement = app.otherElements["dashboard-background"]
        XCTAssertTrue(backgroundElement.exists)
        
        // Capture screenshot for visual verification
        let screenshot = app.screenshot()
        XCTAttachment(screenshot: screenshot).lifetime = .keepAlways
    }
}
```

### Battery Animation Testing
```swift
func testBatteryAnimations() throws {
    navigateToDashboard()
    
    // Test battery level changes
    let batteryView = app.otherElements["life-impact-battery"]
    XCTAssertTrue(batteryView.exists)
    
    // Simulate health data changes that would affect battery
    // Verify animation occurs (timing-based testing)
    let expectation = XCTestExpectation(description: "Battery animation completes")
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 2.0)
}
```

## Performance Testing

### Animation Frame Rate
```swift
func testAnimationPerformance() throws {
    // Launch performance measurement
    let launchMetric = XCTOSSignpostMetric.applicationLaunch
    let animationMetric = XCTOSSignpostMetric.custom(subsystem: "com.amped.animations", category: "battery")
    
    let measureOptions = XCTMeasureOptions()
    measureOptions.iterationCount = 5
    
    measure(metrics: [launchMetric, animationMetric], options: measureOptions) {
        app.launch()
        completeOnboarding()
        
        // Trigger battery animations
        let dayButton = app.buttons["Day"]
        dayButton.tap()
        
        let monthButton = app.buttons["Month"]  
        monthButton.tap()
    }
}
```

### Memory Usage
```swift
func testMemoryUsageDuringAnimations() throws {
    let memoryMetric = XCTMemoryMetric()
    let measureOptions = XCTMeasureOptions()
    measureOptions.iterationCount = 3
    
    measure(metrics: [memoryMetric], options: measureOptions) {
        app.launch()
        navigateToDashboard()
        
        // Perform memory-intensive UI operations
        for _ in 0..<10 {
            // Navigate between tabs
            app.tabBars.buttons["Settings"].tap()
            app.tabBars.buttons["Dashboard"].tap()
            
            // Open and close metric details
            app.buttons.matching(identifier: "metric-card").firstMatch.tap()
            app.navigationBars.buttons["Back"].tap()
        }
    }
}
```

## Device-Specific Testing

### Screen Size Testing
```swift
func testMultipleScreenSizes() throws {
    let devices = [
        "iPhone SE (3rd generation)",    // Small screen
        "iPhone 15",                     // Standard screen
        "iPhone 15 Pro Max"              // Large screen
    ]
    
    for device in devices {
        // Test key layouts on each device
        testOnboardingLayout(on: device)
        testDashboardLayout(on: device)
        testMetricDetailLayout(on: device)
    }
}
```

### Orientation Testing
```swift
func testOrientationSupport() throws {
    // Test portrait (primary)
    XCUIDevice.shared.orientation = .portrait
    testDashboardLayout()
    
    // Test landscape (where supported)
    XCUIDevice.shared.orientation = .landscapeLeft
    testDashboardLayout()
    
    // Return to portrait
    XCUIDevice.shared.orientation = .portrait
}
```

## Error State Testing

### Permission Denied States
```swift
func testHealthKitPermissionDenied() throws {
    navigateToHealthKitPermissions()
    
    // Deny permissions
    app.buttons["Deny Access"].tap()
    
    // Verify graceful handling
    XCTAssertTrue(app.staticTexts["Manual Entry Available"].exists)
    XCTAssertTrue(app.buttons["Continue with Manual Entry"].exists)
}
```

### Network Error States
```swift
func testNetworkErrorHandling() throws {
    // Simulate network issues during payment
    navigateToPaymentScreen()
    
    // Attempt payment with network disabled
    app.buttons["Start Free Trial"].tap()
    
    // Verify error handling
    XCTAssertTrue(app.alerts["Network Error"].exists)
    XCTAssertTrue(app.buttons["Retry"].exists)
}
```

## Component-Specific Tests

### Questionnaire Testing
```swift
func testQuestionnaireValidation() throws {
    navigateToQuestionnaire()
    
    // Test maximum 4 options constraint
    let optionButtons = app.buttons.matching(identifier: "question-option")
    XCTAssertLessThanOrEqual(optionButtons.count, 4)
    
    // Test validation feedback
    app.swipeLeft() // Try to continue without answering
    XCTAssertTrue(app.staticTexts["Please select an answer"].exists)
    
    // Answer and verify progression
    optionButtons.firstMatch.tap()
    app.swipeLeft()
    
    // Verify next question appears
    XCTAssertTrue(app.staticTexts["Question 2 of 5"].exists)
}
```

### Chart Interaction Testing
```swift
func testChartInteractions() throws {
    navigateToMetricDetail()
    
    // Test chart exists and is accessible
    let chart = app.otherElements["metric-impact-chart"]
    XCTAssertTrue(chart.exists)
    XCTAssertFalse(chart.label.isEmpty)
    
    // Test period selector on chart
    app.buttons["7 Days"].tap()
    app.buttons["30 Days"].tap()
    
    // Verify chart updates (basic existence check)
    XCTAssertTrue(chart.exists)
}
```

## Manual Testing Checklist

### UI Consistency
- [ ] **Brand colors** consistent across all screens
- [ ] **Typography scaling** works at all Dynamic Type sizes
- [ ] **Glass effects** render properly on all devices
- [ ] **Battery animations** smooth on iPhone 12+
- [ ] **Touch targets** minimum 44x44 points

### User Experience
- [ ] **Onboarding flow** completes without issues
- [ ] **Swipe gestures** work reliably
- [ ] **Loading states** provide clear feedback
- [ ] **Error messages** are helpful and actionable
- [ ] **Navigation** always provides way back

### Performance
- [ ] **App launch** under 3 seconds
- [ ] **Animation smoothness** 60fps during interactions
- [ ] **Memory usage** stable during extended use
- [ ] **Battery drain** minimal during background operation
- [ ] **Responsiveness** immediate feedback for touches

### Accessibility
- [ ] **VoiceOver navigation** logical and complete
- [ ] **Dynamic Type** scaling without layout breaks
- [ ] **Color contrast** meets WCAG AA standards
- [ ] **Reduced motion** alternatives work properly
- [ ] **Voice Control** can access all functions

## Automated UI Test Suite

### Test Organization
```
AmpedUITests/
├── OnboardingUITests.swift      # Complete onboarding flow
├── DashboardUITests.swift       # Dashboard interactions
├── AccessibilityUITests.swift   # VoiceOver and Dynamic Type
├── PerformanceUITests.swift     # Animation and memory tests
└── RegressionUITests.swift      # Visual regression prevention
```

### Test Data Management
```swift
class UITestDataManager {
    static func setupMockHealthData() {
        // Provide consistent test data for UI tests
    }
    
    static func setupEmptyState() {
        // Test empty/error states
    }
    
    static func setupOptimalData() {
        // Test best-case scenarios
    }
}
```

## Platform-Specific Testing

### iPhone SE Testing
- **Compact layout** handling
- **Text truncation** prevention
- **Touch target** accessibility
- **Scroll performance** with limited screen space

### iPhone Pro Max Testing
- **Large screen** utilization
- **Reachability** for top elements
- **Content scaling** appropriately
- **Split view** compatibility (future)

### iPad Considerations (Future)
- **Adaptive layouts** for larger screens
- **Multi-column** layouts where appropriate
- **Pointer interactions** for trackpad support

## Test Scenarios

### Happy Path Testing
1. **Smooth onboarding** with all permissions granted
2. **Active health data** with positive battery levels
3. **Regular usage** patterns with metric improvements
4. **Premium subscription** activation and features

### Edge Case Testing
1. **No health data** available scenarios
2. **Permission denied** states and recovery
3. **Extreme values** (very high/low metrics)
4. **Network connectivity** issues during critical flows

### Stress Testing
1. **Rapid navigation** between screens
2. **Quick gesture** input during animations
3. **Background/foreground** cycling during operations
4. **Memory pressure** scenarios

## Visual Testing Tools

### Screenshot Automation
```swift
func captureKeyScreenshots() {
    let screenshots = [
        ("welcome", app.screenshot()),
        ("questionnaire", navigateToQuestionnaire().screenshot()),
        ("dashboard", navigateToDashboard().screenshot()),
        ("metric-detail", navigateToMetricDetail().screenshot())
    ]
    
    for (name, screenshot) in screenshots {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
```

### Theme Validation
```swift
func testThemeConsistency() {
    let timeThemes = ["morning", "midday", "afternoon", "evening", "night"]
    
    for theme in timeThemes {
        simulateTimeOfDay(theme)
        
        // Capture theme application
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "theme-\(theme)"
        add(attachment)
        
        // Verify color consistency
        verifyThemeColors(for: theme)
    }
}
```

## Performance Benchmarks

### Launch Performance
```swift
func testAppLaunchPerformance() {
    measure(metrics: [XCTApplicationLaunchMetric()]) {
        app.launch()
    }
}
```

### Animation Performance
```swift
func testBatteryAnimationPerformance() {
    navigateToDashboard()
    
    measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
        // Trigger multiple battery animations
        for period in ["Day", "Month", "Year"] {
            app.buttons[period].tap()
            Thread.sleep(forTimeInterval: 0.5) // Wait for animation
        }
    }
}
```

## Component Testing Patterns

### Generic Component Test
```swift
func testComponent<T: View>(_ component: T, expectations: [String]) {
    // Render component in test environment
    let hostingController = UIHostingController(rootView: component)
    
    // Verify basic properties
    XCTAssertNotNil(hostingController.view)
    
    // Test accessibility
    XCTAssertTrue(hostingController.view.isAccessibilityElement)
    
    // Verify expectations
    for expectation in expectations {
        // Custom validation logic
    }
}
```

### Battery Component Testing
```swift
func testBatteryComponent() {
    let batteryView = BatteryView(level: 0.75)
    
    testComponent(batteryView, expectations: [
        "Has accessibility label",
        "Shows correct charge level",
        "Responds to level changes",
        "Provides value announcements"
    ])
}
```

## Continuous Integration

### Automated Test Execution
```bash
# Run UI tests in CI
xcodebuild test \
  -scheme Amped \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -testPlan AmpedUITests
```

### Test Result Reporting
- **Screenshot artifacts** for visual verification
- **Performance metrics** tracking over time
- **Accessibility audit** results
- **Coverage reports** for UI test coverage

## Debugging UI Tests

### Common Issues
1. **Element not found**: Use `.waitForExistence(timeout:)`
2. **Timing issues**: Add appropriate delays for animations
3. **State conflicts**: Ensure clean state between tests
4. **Simulator differences**: Test on multiple simulator versions

### Debug Strategies
```swift
// Element debugging
func debugElement(_ element: XCUIElement) {
    print("Element exists: \(element.exists)")
    print("Element label: \(element.label)")
    print("Element frame: \(element.frame)")
    print("Element type: \(element.elementType)")
}

// Hierarchy debugging
func printUIHierarchy() {
    print(app.debugDescription)
}
```

## Test Data Management

### Mock Health Data
```swift
struct UITestHealthData {
    static let optimal = HealthMetric(
        type: .steps,
        value: 10000,
        unit: "steps",
        date: Date()
    )
    
    static let poor = HealthMetric(
        type: .steps,
        value: 2000,
        unit: "steps", 
        date: Date()
    )
}
```

### Consistent Test State
- **Reset app state** between tests
- **Provide predictable** data scenarios
- **Handle async operations** with proper waiting
- **Clean up** any persistent state

## Quality Gates

### UI Test Requirements
Before merging UI changes:
- [ ] **All UI tests pass** on target devices
- [ ] **Accessibility tests** pass with VoiceOver
- [ ] **Performance benchmarks** within acceptable range
- [ ] **Visual regression** tests show no unexpected changes
- [ ] **Manual testing** completed on physical device

### Coverage Requirements
- **Critical user paths**: 100% test coverage
- **Major components**: Accessibility and visual testing
- **Error scenarios**: Graceful failure handling
- **Performance**: Key animations and transitions

This guide ensures thorough testing of UI/UX components while maintaining performance and accessibility standards.
