# Animation Guidelines

## Overview

Amped uses sophisticated animations to create engaging, performant, and accessible user experiences. This guide covers animation patterns, performance requirements, and implementation standards.

## Animation Philosophy

### Core Principles
- **Purposeful**: Every animation serves a functional purpose
- **Performant**: 60fps target on all supported devices
- **Accessible**: Reduced motion alternatives always provided
- **Delightful**: Enhance user experience without distraction

### Animation Types
1. **Functional**: Battery charging, state transitions
2. **Feedback**: Touch responses, validation confirmations
3. **Guidance**: Onboarding hints, gesture demonstrations
4. **Ambient**: Subtle background effects, theme transitions

## Battery Animations

### Charging/Discharging Effects
```swift
// Battery level animation
withAnimation(.easeInOut(duration: 0.3)) {
    batteryLevel = newLevel
}

// Charging effect with spring
withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
    isCharging = true
}
```

**Performance Requirements**:
- **Duration**: 0.3s for level changes
- **Easing**: .easeInOut for smooth transitions
- **Spring effects**: For organic charging feel

### Power Flow Animation
```swift
// Energy transfer between batteries
withAnimation(.easeInOut(duration: 0.8).delay(0.1)) {
    showEnergyFlow = true
}
```

**Implementation**:
- **Particle effects** for energy transfer
- **Gradient animations** for flow visualization
- **Timing coordination** between source/destination

### Battery State Transitions
```swift
// Power level changes
@State private var powerLevel: PowerLevel = .mediumPower

withAnimation(.easeInOut(duration: 0.4)) {
    powerLevel = newPowerLevel
}
```

**Color Transitions**:
- **Cross-fade** between power level colors
- **Smooth gradients** for intermediate states
- **Accessibility** color alternatives

## Glass Theme Animations

### Blur Transitions
```swift
// Material blur animation
@State private var glassMaterial: Material = .thin

withAnimation(.easeInOut(duration: 0.25)) {
    glassMaterial = .thick
}
```

**Effects**:
- **Blur intensity** changes for focus states
- **Opacity transitions** for depth perception
- **Scale effects** for interactive feedback

### 3D Transformations
```swift
// Card depth animation
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)

// Perspective shift
.rotation3DEffect(
    .degrees(isHovered ? 5 : 0),
    axis: (x: 1, y: 0, z: 0),
    perspective: 0.5
)
```

**3D Guidelines**:
- **Subtle effects**: Maximum 10-degree rotations
- **Performance conscious**: Avoid complex 3D during scrolling
- **Accessibility**: Disable for reduced motion preference

### Glass Card Interactions
```swift
// Touch feedback
.scaleEffect(isPressed ? 0.98 : 1.0)
.opacity(isPressed ? 0.8 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)
```

## Onboarding Animations

### Progress Indicators
```swift
// Progress bar animation
withAnimation(.linear(duration: 0.5)) {
    progress = newProgress
}

// Step completion
withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
    stepCompleted = true
}
```

### Gesture Hints
```swift
// Swipe hint animation
withAnimation(
    Animation.easeInOut(duration: 1.5)
        .repeatForever(autoreverses: true)
) {
    hintOffset = CGSize(width: 20, height: 0)
}
```

**Hint Patterns**:
- **Subtle movement** indicating available gestures
- **Repeating animations** with auto-reverse
- **Fade out** after user interaction

### Question Transitions
```swift
// Question card slide
.transition(.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .move(edge: .leading)
))
.animation(.easeInOut(duration: 0.3), value: currentQuestion)
```

## Dashboard Animations

### Metric Card Loading
```swift
// Staggered card appearance
ForEach(Array(metrics.enumerated()), id: \.offset) { index, metric in
    BatteryMetricCard(metric: metric)
        .transition(.scale.combined(with: .opacity))
        .animation(
            .easeOut(duration: 0.2)
                .delay(Double(index) * 0.05),
            value: metricsLoaded
        )
}
```

### Real-Time Updates
```swift
// Impact change animation
withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
    impactValue = newImpact
}

// Battery level update
withAnimation(.easeInOut(duration: 0.4)) {
    batteryLevel = calculateBatteryLevel(from: newImpact)
}
```

## Performance Standards

### Target Metrics
- **Frame Rate**: 60fps minimum on iPhone 12 and newer
- **Jank Prevention**: No dropped frames during critical animations
- **Memory Usage**: Animations should not cause significant memory spikes
- **Battery Impact**: Minimal power consumption from animations

### Optimization Techniques
```swift
// Use CADisplayLink for complex animations
class AnimationController: ObservableObject {
    private var displayLink: CADisplayLink?
    
    func startAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
}

// Optimize with reduced complexity during scrolling
.drawingGroup() // For complex overlays
.allowsHitTesting(false) // For non-interactive animations
```

### Performance Testing
1. **Instruments profiling** for GPU usage
2. **Frame rate monitoring** during animations
3. **Memory leak detection** for animation cycles
4. **Battery usage analysis** for background animations

## Accessibility Considerations

### Reduced Motion Support
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .easeInOut(duration: 0.3)
}

// Alternative approach for essential animations
var reducedAnimation: Animation {
    reduceMotion ? .linear(duration: 0.1) : .spring(response: 0.5)
}
```

### Alternative Presentations
- **Instant state changes** instead of animated transitions
- **Simple fades** replacing complex movements
- **Static indicators** for continuous animations
- **Audio feedback** as animation alternative

## Animation States

### Battery States
```swift
enum BatteryAnimationState {
    case idle           // Static display
    case charging       // Upward energy flow
    case discharging    // Downward energy flow
    case critical       // Pulsing warning effect
}
```

### Glass States
```swift
enum GlassAnimationState {
    case inactive       // Standard blur level
    case focused        // Enhanced blur depth
    case pressed        // Scale and opacity feedback
    case disabled       // Reduced opacity and blur
}
```

## Common Animation Patterns

### Micro-Interactions
```swift
// Button press feedback
.scaleEffect(isPressed ? 0.95 : 1.0)
.animation(.easeInOut(duration: 0.1), value: isPressed)

// Toggle switch
.rotationEffect(.degrees(isOn ? 0 : 180))
.animation(.spring(response: 0.3), value: isOn)
```

### Page Transitions
```swift
// Onboarding flow navigation
.transition(.asymmetric(
    insertion: .move(edge: .trailing).combined(with: .opacity),
    removal: .move(edge: .leading).combined(with: .opacity)
))
```

### Loading Animations
```swift
// Breathing effect for loading
.scaleEffect(isLoading ? 1.05 : 1.0)
.opacity(isLoading ? 0.7 : 1.0)
.animation(
    Animation.easeInOut(duration: 1.0)
        .repeatWhile(isLoading, autoreverses: true),
    value: isLoading
)
```

## Time-Based Animations

### Theme Transitions
```swift
// Smooth color transitions throughout day
Color.timeBasedBackground
    .animation(.easeInOut(duration: 2.0), value: currentTimeTheme)

// Gradual ambient changes
.hueRotation(.degrees(timeBasedHueShift))
.animation(.linear(duration: 300), value: timeOfDay) // 5-minute cycles
```

### Circadian Rhythm Effects
- **Gradual color shifts** following natural light cycles
- **Subtle brightness** adjustments based on time
- **Animation speed** variations (slower at night)

## Implementation Best Practices

### Animation Lifecycle
```swift
// Proper cleanup
.onAppear {
    startAnimation()
}
.onDisappear {
    stopAnimation()
}
```

### Conditional Animations
```swift
// Smart animation application
.animation(
    viewModel.shouldAnimate ? .spring() : nil,
    value: animatedProperty
)
```

### Interaction Feedback
```swift
// Haptic + visual feedback combination
Button("Action") {
    HapticManager.impact(.medium)
    withAnimation(.spring(response: 0.2)) {
        buttonPressed = true
    }
}
```

## Testing Animations

### Manual Testing
- **Multiple device sizes** (SE, standard, Pro Max)
- **Different performance levels** (iPhone 12 vs iPhone 15)
- **Background/foreground** transitions
- **Memory pressure** scenarios

### Automated Testing
```swift
// Animation completion testing
func testBatteryChargeAnimation() {
    let expectation = XCTestExpectation(description: "Battery animation completes")
    
    withAnimation(.easeInOut(duration: 0.3)) {
        batteryLevel = 1.0
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1.0)
}
```

### Performance Validation
- **Frame rate consistency** during animations
- **Memory usage spikes** detection
- **CPU utilization** monitoring
- **Battery drain** measurement

## Common Issues & Solutions

### Performance Problems
**Issue**: Dropped frames during battery animations
**Solution**: Use `.drawingGroup()` for complex overlays

**Issue**: Memory leaks in repeating animations
**Solution**: Proper cleanup in `.onDisappear`

### Accessibility Issues
**Issue**: Animations too fast for some users
**Solution**: Respect `.accessibilityReduceMotion` preference

**Issue**: Important state changes not announced
**Solution**: Use `UIAccessibility.post()` for critical updates

### Visual Glitches
**Issue**: Animation conflicts between components
**Solution**: Coordinate animations with shared state

**Issue**: Inconsistent timing across features
**Solution**: Centralized animation constants

## Animation Constants

### Standard Durations
```swift
struct AnimationDuration {
    static let microInteraction: Double = 0.1   // Button press
    static let transition: Double = 0.3         // State change
    static let navigation: Double = 0.5         // Screen change
    static let ambient: Double = 2.0            // Background effects
}
```

### Easing Functions
```swift
struct AnimationEasing {
    static let standard = Animation.easeInOut
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let bounce = Animation.spring(response: 0.3, dampingFraction: 0.6)
}
```

This guide ensures consistent, performant, and accessible animations throughout the Amped app while maintaining the battery and glass theme aesthetic.
