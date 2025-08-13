# Personalization Features

This document outlines the strategic personalization implemented throughout the Amped app onboarding flow and main screens.

## Overview

Following the principle "Simplicity is KING," personalization is used strategically only where it has maximum impact, avoiding overuse of the user's name.

## Implementation Details

### Core Components

1. **UserProfile Model**: Extended to include `firstName` field for secure on-device storage
2. **PersonalizationUtils**: Utility class providing context-aware personalized messaging
3. **Name Collection**: User's first name is collected during the questionnaire and stored securely

### Personalization Touchpoints

#### 1. Onboarding Flow

- **ValuePropositionView**: After name collection, displays personalized value proposition
- **PaymentView**: Personalized headline for maximum conversion impact

#### 2. Main Dashboard

- **Personalized Header**: Dynamic greeting based on time of day with user's name
- **Context-Aware Subtitles**: Page-specific subtitles that change based on current screen

#### 3. Achievement System

- **Milestone Celebrations**: Personalized congratulation messages for streak achievements
- **Progress Notifications**: Smart usage of name for motivation and encouragement

### Technical Implementation

#### PersonalizationUtils Functions

- `userFirstName(from:)`: Retrieves user's name from UserProfile or UserDefaults fallback
- `contextualMessage(firstName:context:)`: Returns appropriate message based on context
- Context types include: welcome, valueProposition, payment, dashboardGreeting, motivation, achievement, progress

#### Strategic Usage Guidelines

1. **High-Impact Moments**: Use personalization during conversion-critical moments (payment, onboarding completion)
2. **Welcome/Greeting**: Time-based greetings that feel natural and warm
3. **Achievement Recognition**: Celebrate user milestones with personalized congratulations
4. **Fallback Gracefully**: Always provide non-personalized alternatives when name is unavailable

### Privacy & Storage

- Names are stored locally on device only
- No transmission to external servers
- Secure storage in UserDefaults and UserProfile
- User can update name in settings if needed

### User Experience Benefits

1. **Increased Engagement**: Personalized greetings create emotional connection
2. **Higher Conversion**: Strategic use in payment flow improves subscription rates
3. **Motivation**: Personal achievement messages encourage continued app usage
4. **Professional Feel**: Thoughtful personalization without being overwhelming

## Usage Examples

```swift
// Dashboard greeting
PersonalizationUtils.contextualMessage(
    firstName: userProfile.firstName,
    context: .dashboardGreeting
)
// Result: "Good morning, Sarah" or "Your Life Battery Today"

// Achievement celebration
PersonalizationUtils.contextualMessage(
    firstName: userProfile.firstName,
    context: .achievement("7-Day Streak")
)
// Result: "Congratulations, Sarah! 7-Day Streak" or "Great job! 7-Day Streak"

// Payment conversion
PersonalizationUtils.contextualMessage(
    firstName: userProfile.firstName,
    context: .payment
)
// Result: "Sarah, unlock your full life potential" or "Unlock your full life potential"
```

## Future Enhancements

- Personalized recommendations based on user's name and profile
- Custom notification content with user's name
- Seasonal/contextual greetings
- Personalized insights and health recommendations
