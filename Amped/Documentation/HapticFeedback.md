# Haptic Feedback Implementation

## Overview

Amped uses subtle haptic feedback to enhance the user experience by providing tactile responses to user interactions. Following Apple iOS standards and Steve Jobs design principles of simplicity and elegance, our haptic feedback is refined and purposeful, never overwhelming the user.

## Implementation Details

Haptic feedback is implemented through two main components:

1. **HapticFeedback.swift**: A utility class that provides methods for triggering different types of haptic feedback.
2. **ButtonHaptics.swift**: SwiftUI extensions that make it easy to add haptic feedback to buttons and other interactive elements.

## Available Feedback Types

### Basic Feedback Types (Following Apple iOS Standards)

- **Light**: Subtle feedback for routine interactions, selections, and minor actions (now default)
- **Medium**: Standard feedback for important button presses and confirmations
- **Heavy**: Stronger feedback reserved for significant actions (major completions, purchases)

### Notification Feedback Types

- **Success**: For successful operations
- **Warning**: For actions requiring attention
- **Error**: For failed operations or errors

### Selection Feedback

- **Selection**: For selection changes in pickers, menus, etc.

## Usage Guidelines (Following Apple iOS Standards)

### Routine Buttons (Default - Light Feedback)

For most buttons and routine interactions, add the `.hapticFeedback()` modifier:

```swift
Button("Continue") {
    // Action
}
.hapticFeedback()  // Uses light impact by default (subtle and refined)
```

### Important Actions (Medium Feedback)

For important actions like permissions, authentication, or significant navigation:

```swift
Button("Grant Permissions") {
    // Action
}
.hapticFeedback(.medium)  // Medium feedback for important actions
```

### Major Completions (Heavy Feedback)

Reserve heavy feedback for major completions, purchases, or flow endings:

```swift
Button("Complete Purchase") {
    // Action
}
.hapticFeedback(.heavy)  // Heavy feedback for major actions only
```

### Success/Error Actions

For actions with success/failure outcomes:

```swift
Button("Submit") {
    // Action
}
.successFeedback()  // Use for successful operations

Button("Delete") {
    // Action
}
.errorFeedback()  // Use for destructive or failure actions
```

### Non-Button Elements

For interactive elements that aren't buttons:

```swift
Toggle("Enable Feature", isOn: $isEnabled)
    .withHapticFeedback(.selection)
```

## Onboarding Flow Haptic Strategy

Following Apple iOS standards and Steve Jobs design principles:

### Subtle Routine Interactions (Light Feedback)
- Questionnaire answer buttons
- Back navigation
- Routine selections
- Minor interactions

### Important Progressions (Medium Feedback)
- "Continue" buttons between major sections
- "Get Started" for questionnaire
- HealthKit permissions
- Sign in with Apple

### Major Completions (Heavy Feedback)
- Purchase/subscription actions
- Completing entire onboarding flow
- Major state changes

## When to Use Haptic Feedback

- **DO** use light haptic feedback for routine user interactions
- **DO** match the intensity to the importance of the action
- **DO** use success/error feedback for operations with clear outcomes
- **DO** follow Apple's conservative approach - less is more
- **DON'T** overuse haptic feedback for minor UI element changes
- **DON'T** use heavy feedback for routine button presses
- **DON'T** use continuous haptic feedback that could become annoying

## Steve Jobs Design Principles Applied

- **Simplicity**: Light feedback by default keeps interactions simple and unobtrusive
- **Elegance**: Subtle feedback feels refined rather than mechanical
- **Purposeful**: Each level of feedback has a clear purpose and meaning
- **Intuitive**: Users naturally understand the feedback hierarchy

## Accessibility Considerations

Haptic feedback enhances the experience for most users but is particularly valuable for:

- Users with visual impairments who benefit from additional non-visual feedback
- Users in situations where visual attention is limited
- Users who need confirmation of their actions

Note that haptic feedback relies on device capabilities and user settings. Always ensure your UI provides visual feedback in addition to haptic feedback. 