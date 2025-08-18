# Troubleshooting Guide

## Common Setup Issues

### Xcode Build Errors

#### "Build script not found"
**Symptoms**: Build fails with script execution error
**Solution**:
```bash
# Verify script exists and has execute permissions
ls -la Amped/Scripts/update_infoplist.sh
chmod +x Amped/Scripts/update_infoplist.sh
```

#### "HealthKit entitlement missing"
**Symptoms**: App crashes when accessing HealthKit
**Solution**:
1. Verify `Amped.entitlements` includes HealthKit
2. Check build script runs and adds Info.plist entries
3. Clean build folder and rebuild

#### "Code signing issues"
**Symptoms**: Cannot install on device
**Solution**:
1. Update bundle identifier to unique value
2. Select correct development team
3. Enable "Automatically manage signing"
4. Ensure Apple Developer account is valid

### HealthKit Issues

#### "No health data available"
**Symptoms**: Empty metrics on dashboard
**Solutions**:

**On Simulator**:
- HealthKit data is limited/simulated
- Use physical device for real testing
- Create sample data in Health app if needed

**On Device**:
```swift
// Check HealthKit authorization status
let healthStore = HKHealthStore()
let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
let authStatus = healthStore.authorizationStatus(for: stepType)
print("Authorization status: \(authStatus)")
```

#### "Permission denied"
**Symptoms**: User denied HealthKit access
**Solution**:
1. Guide user to Settings → Privacy → Health → Amped
2. Enable required permissions manually
3. App handles graceful fallback to manual entry

### UI/UX Issues

#### "Battery animation not smooth"
**Symptoms**: Choppy or laggy battery animations
**Diagnosis**:
```swift
// Add performance logging
import OSLog
private let logger = Logger(subsystem: "com.amped.performance", category: "animations")

// In animation code
logger.info("Battery animation started: \(Date())")
withAnimation(.easeInOut(duration: 0.3)) {
    batteryLevel = newLevel
}
logger.info("Battery animation completed: \(Date())")
```

**Solutions**:
1. Test on physical device (not simulator)
2. Check for background processing interference
3. Reduce animation complexity for older devices
4. Use `.drawingGroup()` for complex overlays

#### "Glass theme not rendering"
**Symptoms**: Missing blur effects or transparency
**Solutions**:
1. Verify iOS 16.0+ target deployment
2. Check Material availability on device
3. Test with reduced transparency settings disabled
4. Fallback to solid colors on unsupported devices

#### "VoiceOver not working correctly"
**Symptoms**: Missing or incorrect accessibility labels
**Diagnosis**:
```swift
// Test accessibility in preview
#Preview {
    BatteryView(level: 0.75)
        .accessibilityElement(children: .contain)
        .onAppear {
            print("Accessibility label: \(accessibilityLabel ?? "None")")
        }
}
```

**Solutions**:
1. Add explicit accessibility modifiers
2. Test with Accessibility Inspector
3. Verify element hierarchy and focus order
4. Check for conflicting accessibility traits

### Performance Issues

#### "Slow app launch"
**Symptoms**: App takes >3 seconds to launch
**Diagnosis**:
```swift
// Add launch timing
import OSLog
private let logger = Logger(subsystem: "com.amped.performance", category: "launch")

// In AmpedApp.swift
init() {
    logger.info("App initialization started")
    // Initialization code
    logger.info("App initialization completed")
}
```

**Solutions**:
1. Use LaunchOptimizer for deferred initialization
2. Reduce main thread blocking operations
3. Lazy load expensive components
4. Profile with Instruments Time Profiler

#### "High memory usage"
**Symptoms**: App terminated or warnings in console
**Solutions**:
1. Check for retain cycles in view models
2. Proper cleanup in `.onDisappear`
3. Use weak references for delegates
4. Optimize image loading and caching

### Data Issues

#### "Incorrect impact calculations"
**Symptoms**: Unexpected battery levels or impact values
**Diagnosis**:
```swift
// Add calculation logging
private let logger = Logger(subsystem: "com.amped.calculations", category: "impact")

func calculateLifeImpact() -> Double {
    logger.info("Starting impact calculation with metrics: \(metrics)")
    let result = performCalculation()
    logger.info("Impact calculation result: \(result)")
    return result
}
```

**Solutions**:
1. Verify input data ranges and units
2. Check scientific calculation formulas
3. Validate interaction effects application
4. Test with known good data sets

#### "Cache corruption"
**Symptoms**: Inconsistent data or unexpected resets
**Solutions**:
```swift
// Clear app data for testing
UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)

// Reset HealthKit permissions
// Settings → Privacy & Security → Health → Amped → Delete App
```

## Device-Specific Issues

### iPhone SE (Small Screen)
**Common Issues**:
- Text truncation in metric cards
- Touch targets too small
- Battery visualization crowded

**Solutions**:
- Test with largest Dynamic Type size
- Implement responsive layouts
- Adjust component spacing for small screens

### iPhone Pro Max (Large Screen)
**Common Issues**:
- Excessive whitespace
- Poor reachability for top elements
- Underutilized screen real estate

**Solutions**:
- Implement adaptive layouts
- Consider multi-column designs
- Test single-handed usage patterns

### Older Devices (iPhone 12/13)
**Common Issues**:
- Animation performance
- Glass effects not rendering
- Memory pressure

**Solutions**:
- Reduce animation complexity
- Fallback visual effects
- More aggressive memory management

## Testing Environment Issues

### Simulator Limitations
**HealthKit Data**:
- Limited sample data available
- Background app refresh disabled
- No real sensor data

**Performance**:
- Different performance characteristics
- GPU rendering differences
- Network simulation limitations

**Recommendation**: Always test critical functionality on physical devices

### Xcode Issues
#### "Previews not working"
**Symptoms**: SwiftUI previews fail to load
**Solutions**:
1. Clean DerivedData folder
2. Restart Xcode
3. Check preview dependencies
4. Ensure proper environment objects

#### "Debugger not attaching"
**Solutions**:
1. Clean and rebuild project
2. Restart Xcode and simulator
3. Check code signing configuration
4. Try different simulator device

## Production Issues

### App Store Rejection
**Common Reasons**:
1. Missing HealthKit usage descriptions
2. Accessibility violations
3. Performance issues on review devices
4. UI inconsistencies

**Prevention**:
- Run full test suite before submission
- Test on multiple device types
- Verify all Info.plist entries
- Complete accessibility audit

### User Reports
#### "Battery not updating"
**Investigation Steps**:
1. Check HealthKit permissions granted
2. Verify background app refresh enabled
3. Confirm health data is actively being generated
4. Check calculation service functionality

#### "UI elements too small"
**Investigation Steps**:
1. Verify Dynamic Type implementation
2. Check minimum touch target compliance
3. Test with accessibility settings enabled
4. Consider device-specific adjustments

## Debug Tools

### Logging System
```swift
import OSLog

// Category-based logging
extension Logger {
    static let ui = Logger(subsystem: "com.amped.ui", category: "interface")
    static let performance = Logger(subsystem: "com.amped.performance", category: "metrics")
    static let accessibility = Logger(subsystem: "com.amped.accessibility", category: "voiceover")
}

// Usage in components
Logger.ui.info("Battery view rendered with level: \(batteryLevel)")
```

### Performance Monitoring
```swift
// Add performance markers
import os.signpost

let log = OSLog(subsystem: "com.amped.performance", category: "animations")

os_signpost(.begin, log: log, name: "Battery Animation")
withAnimation(.easeInOut(duration: 0.3)) {
    batteryLevel = newLevel
}
os_signpost(.end, log: log, name: "Battery Animation")
```

### Accessibility Testing
```swift
// Runtime accessibility validation
#if DEBUG
func validateAccessibility() {
    let rootView = UIApplication.shared.windows.first?.rootViewController?.view
    let issues = rootView?.accessibilityElementsAndContainers() ?? []
    
    for element in issues {
        if let accessibilityElement = element as? UIAccessibilityElement {
            assert(!accessibilityElement.accessibilityLabel?.isEmpty ?? true, 
                   "Missing accessibility label")
        }
    }
}
#endif
```

## Emergency Fixes

### Critical Performance Issues
```swift
// Disable expensive animations temporarily
private let emergencyPerformanceMode = true

var batteryAnimation: Animation? {
    emergencyPerformanceMode ? nil : .easeInOut(duration: 0.3)
}
```

### Accessibility Compliance
```swift
// Quick accessibility fixes
.accessibilityLabel("Fallback description")
.accessibilityAddTraits(.isButton)
.accessibilityHint("Tap to interact")
```

### Memory Leaks
```swift
// Break retain cycles
weak var weakSelf = self
closure = { [weak weakSelf] in
    weakSelf?.handleAction()
}
```

## Escalation Path

### Internal Issues
1. **Check Documentation** - Review relevant guides first
2. **Search Codebase** - Look for similar implementations
3. **Test Isolation** - Reproduce in minimal environment
4. **Log Analysis** - Use structured logging for debugging

### External Support
1. **Apple Developer Forums** - For iOS/Xcode specific issues
2. **HealthKit Documentation** - For health data problems
3. **Accessibility Guidelines** - For compliance questions
4. **Performance Best Practices** - For optimization guidance

## Prevention Strategies

### Code Quality
- **Regular code reviews** focusing on performance
- **Automated testing** in CI/CD pipeline
- **Performance monitoring** in development builds
- **Accessibility audits** before releases

### Documentation Maintenance
- **Keep guides updated** with code changes
- **Document known issues** and their solutions
- **Update troubleshooting** based on real issues
- **Review documentation** quarterly for accuracy

This troubleshooting guide helps developers quickly identify and resolve common issues while maintaining the app's quality standards.
