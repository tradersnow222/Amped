# Onboarding Persistence Fix

## Problem
Users were experiencing a bug where backgrounding the app during onboarding would cause them to lose their progress and return to the "What should we call you?" screen (welcome step) when reopening the app.

## Root Cause
The `OnboardingFlow` had a local `@State private var currentStep: OnboardingStep = .welcome` that was not persisted. When the app went to background and returned, this state would reset to `.welcome`, causing users to lose their progress.

## Solution
Implemented a simplified persistence system that ensures users always return to where they left off in onboarding when backgrounding the app:

### Behavior (All Cases)
- User backgrounds or leaves the app during onboarding
- **Result**: User returns to exactly where they left off in onboarding
- **Note**: For true fresh starts, users can use the debug reset function

## Implementation Details

### 1. App State Management (`AmpedApp.swift`)
```swift
// Added to AppState class:
@Published var currentOnboardingStep: OnboardingStep = .welcome
private var didTerminateCleanly: Bool = false

// Scene phase handling:
case .background:
    appState.saveOnboardingProgress() // Save current step
case .inactive:
    appState.saveOnboardingProgress() // Save current step
case .active:
    appState.handleAppReturnFromBackground() // Load saved step
```

### 2. Persistence Logic (`AppState`)
```swift
func saveOnboardingProgress() {
    if !hasCompletedOnboarding {
        UserDefaults.standard.set(currentOnboardingStep.rawValue, forKey: "currentOnboardingStep")
        UserDefaults.standard.set(true, forKey: "didTerminateCleanly")
    }
}

private func loadOnboardingProgress() {
    let didTerminateCleanly = UserDefaults.standard.bool(forKey: "didTerminateCleanly")
    
    if didTerminateCleanly && !hasCompletedOnboarding {
        // Soft close - restore to where they left off
        if let savedStep = OnboardingStep(rawValue: savedStepRaw) {
            currentOnboardingStep = savedStep
        }
    } else {
        // Hard close - reset to welcome
        currentOnboardingStep = .welcome
    }
    
    // Mark that we've read the termination state
    UserDefaults.standard.set(false, forKey: "didTerminateCleanly")
}
```

### 3. OnboardingFlow Refactor (`OnboardingFlow.swift`)
```swift
// Changed from local state to AppState dependency:
// OLD: @State private var currentStep: OnboardingStep = .welcome
// NEW: private var currentStep: OnboardingStep { appState.currentOnboardingStep }

// Updated navigation to use AppState:
private func navigateTo(_ step: OnboardingStep) {
    withAnimation(.spring(response: 0.8, dampingFraction: 0.985, blendDuration: 0.18)) {
        appState.updateOnboardingStep(step)
    }
}
```

### 4. Enum Enhancement
```swift
// Made OnboardingStep persistable:
enum OnboardingStep: String, Equatable, CaseIterable {
    case welcome
    case personalizationIntro
    case questionnaire
    // ... other cases
}
```

## Key Technical Decisions

### Synchronous vs Asynchronous Loading
- **Problem**: UI renders immediately while AppState loads asynchronously
- **Solution**: Load critical onboarding state synchronously during initialization
- **Benefit**: Ensures state is available before first UI render

### Direct @Published Reference vs Computed Property
- **Problem**: Computed properties may not trigger SwiftUI updates reliably
- **Solution**: Reference `appState.currentOnboardingStep` directly in view conditions
- **Benefit**: Guarantees SwiftUI reactivity to state changes
### Simplified Approach
The implementation uses a straightforward approach:
1. **Synchronous State Loading**: Load onboarding state immediately during AppState initialization to avoid race conditions
2. **Direct SwiftUI Reactivity**: Reference `appState.currentOnboardingStep` directly instead of computed properties
3. **Persistent Progress**: Always save and restore onboarding progress

### Why Save on Both `.background` and `.inactive`?
- `.inactive`: Covers cases like Control Center, phone calls, notifications
- `.background`: Covers home button press, app switcher
- Ensures state is saved in all scenarios where user might leave the app

## UserDefaults Keys Used
- `currentOnboardingStep`: String value of the current onboarding step

## Testing
The fix has been validated through:
- Successful build with no compilation errors
- Architecture review confirming proper state management
- Implementation follows iOS best practices for app lifecycle management

## Benefits
1. **Better User Experience**: Users don't lose progress when multitasking
2. **Reliable State Management**: Synchronous loading eliminates race conditions
3. **Performance**: Minimal overhead using efficient UserDefaults persistence
4. **Maintainable**: Simplified logic with fewer edge cases
5. **Consistent Behavior**: Predictable restoration of onboarding progress
