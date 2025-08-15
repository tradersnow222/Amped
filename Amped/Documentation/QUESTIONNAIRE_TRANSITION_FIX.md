# Questionnaire Transition Logic Investigation & Fix

## Problem Identified
The "What is your first name?" question screen had inconsistent transition logic compared to all questions after the stress question.

## Root Cause Analysis

### Name Question (INCONSISTENT - Before Fix):
```swift
private func proceedToNext() {
    isTextFieldFocused = false
    
    // PROBLEM: Extra async dispatch wrapper
    DispatchQueue.main.async {
        viewModel.userName = localName
        viewModel.proceedToNextQuestion()
    }
}
```

### All Questions After Stress (CONSISTENT - Reference Pattern):
```swift
Button(action: {
    viewModel.selectedStressLevel = stressLevel
    viewModel.proceedToNextQuestion()  // Direct call, no async wrapper
}) {
    FormattedButtonText(...)
}
```

## The Issue
The name question was **double-wrapping** its transition call:
1. `DispatchQueue.main.async` in the view
2. `proceedToNextQuestion()` already handles its own internal async dispatch and animations

This caused timing inconsistencies and potential transition conflicts.

## Fix Applied
Updated the name question's `proceedToNext()` method to match the exact pattern used by all questions after stress:

```swift
private func proceedToNext() {
    // Dismiss keyboard immediately
    isTextFieldFocused = false
    
    // FIXED: Direct call matching other questions
    viewModel.userName = localName
    viewModel.proceedToNextQuestion()
}
```

## Verification Points
All questions now follow the same transition pattern:
- ✅ Stress Level: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Anxiety Level: Direct `viewModel.proceedToNextQuestion()` call  
- ✅ Gender: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Nutrition: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Smoking: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Alcohol: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Social Connections: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Sleep Quality: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Blood Pressure: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Framing Comfort: Direct `viewModel.proceedToNextQuestion()` call
- ✅ Urgency Response: Direct `viewModel.proceedToNextQuestion()` call
- ✅ **Name Question: Now FIXED to match the same pattern**

## Additional Standardization: Category Header Display Logic

**Final Standardization:** After user feedback, standardized the entire questionnaire flow to show category headers consistently for ALL questions, creating a uniform experience.

**Final Implementation:**
```swift
// STANDARDIZED: Category headers for ALL questions
CategoryHeader(category: viewModel.currentQuestionCategory)
```

**Result:** Every question now consistently shows its category header:
- Name & Birthdate questions: Always show "BASICS"  
- All Wellness questions: Always show "WELLNESS"
- All Lifestyle questions: Always show "LIFESTYLE"

This creates a consistent, predictable visual experience throughout the entire questionnaire flow where users always know what category they're currently answering.

## Technical Details
The `QuestionnaireViewModel.proceedToNextQuestion()` method handles:
- Navigation direction setting
- Animation timing with luxury spring (0.8 response, 0.985 damping)
- Internal async dispatch for UI updates
- UserDefaults persistence

The standardized approach ensures:
1. Consistent visual layout across ALL questions
2. No visual interruptions or inconsistencies
3. Clear category context for users at all times
4. Uniform transition behavior throughout the questionnaire

By fixing the transition logic and standardizing the category header display, the entire questionnaire flow now has perfectly consistent behavior and appearance.
