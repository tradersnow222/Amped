# Onboarding Persistence Implementation

## Overview

This implementation provides smart onboarding persistence that differentiates between soft close (app backgrounded) vs hard close (app terminated) scenarios, ensuring users are returned to the correct onboarding position.

## Key Components

### 1. OnboardingPersistenceManager (`Amped/Core/OnboardingPersistenceManager.swift`)

**Core Functionality:**
- **Closure Type Detection**: Uses timestamp-based logic with 30-second threshold to determine soft vs hard close
- **Smart Persistence**: Only saves progress during onboarding, clears data on completion
- **Comprehensive Logging**: Detailed logging for debugging and monitoring

**Key Methods:**
- `detectClosureType()` - Determines if last app closure was soft or hard
- `saveOnboardingProgress()` - Saves current step with timestamp
- `loadOnboardingProgress()` - Restores step based on closure type
- `markAppEnteringBackground()` - Marks clean termination for soft close detection

### 2. AppState Integration (`Amped/AmpedApp.swift`)

**Enhanced State Management:**
- **Synchronous Loading**: Critical onboarding state loaded synchronously to prevent race conditions
- **Advanced Restoration**: Uses closure type detection for appropriate restoration logic
- **Lifecycle Integration**: Proper integration with app lifecycle events

**Key Changes:**
- Added `OnboardingPersistenceManager` integration
- Enhanced `loadOnboardingStateSynchronously()` with smart restoration
- Updated `handleAppReturnFromBackground()` for advanced persistence
- Proper lifecycle handling in `handleScenePhaseChange()`

### 3. OnboardingFlow Updates (`Amped/Features/Onboarding/OnboardingFlow.swift`)

**Progress Tracking:**
- **Automatic Saving**: Progress saved on appear/disappear events
- **Smart Navigation**: `updateOnboardingStep()` automatically saves progress
- **Performance Optimized**: Background operations don't block UI

## Behavior Logic

### Soft Close (App Backgrounded)
**Scenario:** User presses home button, switches to another app, or receives a phone call
**Behavior:** User returns to exact onboarding position where they left off
**Detection:** App was cleanly backgrounded, time difference < 30 seconds

### Hard Close (App Terminated)
**Scenario:** User force-quits app, device restarts, or app is terminated by system
**Behavior:** User returns to Welcome screen (fresh start)
**Detection:** App wasn't cleanly terminated OR time difference > 30 seconds

## Implementation Details

### Time-Based Detection Logic

```swift
func detectClosureType() -> ClosureType {
    let currentTimestamp = Date().timeIntervalSince1970
    let lastSaveTimestamp = UserDefaults.standard.double(forKey: lastSaveTimestampKey)
    let wasCleanTermination = UserDefaults.standard.bool(forKey: cleanTerminationKey)
    
    // Fresh launch
    if lastSaveTimestamp == 0 {
        return .hardClose
    }
    
    let timeDifference = currentTimestamp - lastSaveTimestamp
    
    // Hard close if not clean termination AND time > threshold
    if !wasCleanTermination && timeDifference > hardCloseThreshold {
        return .hardClose
    }
    
    return .softClose
}
```

### App Lifecycle Integration

```swift
case .background:
    appState.markAppEnteringBackground()  // Mark clean termination
    appState.saveOnboardingProgress()     // Save current progress
    
case .active:
    appState.handleAppReturnFromBackground()  // Smart restoration
```

### OnboardingFlow Progress Tracking

```swift
.onAppear {
    appState.saveOnboardingProgress()  // Save on appear
}
.onDisappear {
    appState.saveOnboardingProgress()  // Save on disappear
}
```

## Data Storage

**UserDefaults Keys:**
- `currentOnboardingStep` - Current onboarding step
- `onboardingLastSaveTimestamp` - Last save timestamp
- `appLaunchTimestamp` - App launch timestamp
- `appTerminatedCleanly` - Clean termination flag

**Data Cleanup:**
- Progress cleared on onboarding completion
- Related questionnaire data cleared on hard close
- Comprehensive reset available for testing/debugging

## Testing Scenarios

### Test Soft Close Behavior
1. Start onboarding flow
2. Navigate to questionnaire screen
3. Press home button (app goes to background)
4. Wait 5 seconds
5. Return to app
6. **Expected:** User returns to questionnaire screen

### Test Hard Close Behavior
1. Start onboarding flow
2. Navigate to questionnaire screen  
3. Force quit app (swipe up, swipe away app)
4. Wait 35+ seconds
5. Relaunch app
6. **Expected:** User returns to welcome screen (fresh start)

### Test Onboarding Completion
1. Complete entire onboarding flow
2. App backgrounds/terminates at any point
3. Relaunch app
4. **Expected:** User goes directly to dashboard (no onboarding)

## Edge Cases Handled

1. **First Launch**: No saved data → Hard close (fresh start)
2. **Onboarding Complete**: Progress cleared → Dashboard direct
3. **System Restart**: Time gap large → Hard close (fresh start)
4. **Rapid Background/Foreground**: Clean termination → Soft close (restore position)
5. **Force Quit Detection**: No clean termination flag → Hard close
6. **Data Corruption**: Fallback to welcome screen → Safe recovery

## Performance Considerations

- **Synchronous Loading**: Critical state loaded before UI render
- **Background Operations**: Heavy operations moved to background threads
- **Memory Management**: Data cleared after onboarding completion
- **Minimal Overhead**: Lightweight timestamp-based detection

## Logging and Debugging

Comprehensive logging available through OSLog:
- Closure type detection decisions
- Progress save/restore operations
- Timestamp differences for debugging
- Data clearing operations

**Enable logging in Console.app:**
Filter: `subsystem:com.amped.app category:OnboardingPersistence`

## Future Enhancements

1. **User Preferences**: Allow users to disable soft close restoration
2. **Analytics Integration**: Track onboarding drop-off points
3. **A/B Testing**: Test different restoration behaviors
4. **Cloud Sync**: Sync onboarding progress across devices
5. **Advanced Heuristics**: Machine learning for smarter closure detection

## Troubleshooting

**Issue**: User always returns to welcome screen
**Solution**: Check app lifecycle integration, ensure `markAppEnteringBackground()` is called

**Issue**: User stuck in middle of onboarding
**Solution**: Use debug controls to reset onboarding state, check data consistency

**Issue**: Performance impact
**Solution**: Verify synchronous operations are minimal, background tasks not blocking UI

---

*This implementation ensures a seamless user experience while maintaining data consistency and performance standards.*
