# Haptic Feedback Implementation

## Overview

Amped uses haptic feedback to enhance the user experience by providing tactile responses to user interactions. This document provides guidelines on how to implement consistent haptic feedback throughout the app.

## Implementation Details

Haptic feedback is implemented through two main components:

1. **HapticFeedback.swift**: A utility class that provides methods for triggering different types of haptic feedback.
2. **ButtonHaptics.swift**: SwiftUI extensions that make it easy to add haptic feedback to buttons and other interactive elements.

## Available Feedback Types

### Basic Feedback Types

- **Light**: Subtle feedback for minor interactions
- **Medium**: Standard feedback for most button presses (default)
- **Heavy**: Stronger feedback for significant actions (like app navigation)

### Notification Feedback Types

- **Success**: For successful operations
- **Warning**: For actions requiring attention
- **Error**: For failed operations or errors

### Selection Feedback

- **Selection**: For selection changes in pickers, menus, etc.

## Usage Guidelines

### Standard Buttons

For most buttons, add the `.hapticFeedback()` modifier:

```swift
Button("Continue") {
    // Action
}
.hapticFeedback()  // Uses medium impact by default
```

### Custom Feedback Intensity

Specify the feedback intensity with the parameter:

```swift
Button("Get Started") {
    // Action
}
.hapticFeedback(.heavy)  // Strong feedback for important buttons
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

## When to Use Haptic Feedback

- **DO** use haptic feedback for all primary user interactions
- **DO** match the intensity to the importance of the action
- **DO** use success/error feedback for operations with clear outcomes
- **DON'T** overuse haptic feedback for minor UI element changes
- **DON'T** use continuous haptic feedback that could become annoying

## Accessibility Considerations

Haptic feedback enhances the experience for most users but is particularly valuable for:

- Users with visual impairments who benefit from additional non-visual feedback
- Users in situations where visual attention is limited
- Users who need confirmation of their actions

Note that haptic feedback relies on device capabilities and user settings. Always ensure your UI provides visual feedback in addition to haptic feedback. 