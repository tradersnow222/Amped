import Foundation

// Lightweight extension to support persistence mapping for OnboardingStep
// Keeps serialization/deserialization logic separate from UI flow file.

extension OnboardingStep {
    /// Initialize an OnboardingStep from a saved name string.
    /// Mirrors the `name` computed property used when saving to UserDefaults.
    /// For the `dashboard` case we default subscription to `false` because the
    /// saved name does not contain subscription information.
    init?(rawValue: String) {
        switch rawValue {
        case "welcome": self = .welcome
        case "personalizationIntro": self = .personalizationIntro
        case "beforeAfterTransformation": self = .beforeAfterTransformation
        case "mascotIntroduction": self = .mascotIntroduction
        case "mascotNaming": self = .mascotNaming
        case "genderSelection": self = .genderSelection
        case "ageSelection": self = .ageSelection
        case "heightStats": self = .heightStats
        case "weightStats": self = .weightStats
        case "stressStats": self = .stressStats
        case "anxietyStats": self = .anxietyStats
        case "dietStats": self = .dietStats
        case "smokeStats": self = .smokeStats
        case "alcoholicStats": self = .alcoholicStats
        case "socialConnectionStats": self = .socialConnectionStats
        case "bloodPressureStats": self = .bloodPressureStats
        case "mainReasonStats": self = .mainReasonStats
        case "goalsStats": self = .goalsStats
        case "syncDeviceStats": self = .syncDeviceStats
        case "terms": self = .terms
        case "paywall": self = .paywall
        case "questionnaire": self = .questionnaire
        case "valueProposition": self = .valueProposition
        case "dashboard": self = .dashboard(subscription: false)
        default: return nil
        }
    }
}
