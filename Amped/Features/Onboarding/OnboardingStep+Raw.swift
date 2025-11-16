import Foundation

// Provide a `rawValue` computed property for OnboardingStep to match RawRepresentable-like usage
// This mirrors the existing `name` mapping used for persistence elsewhere in the codebase.

extension OnboardingStep {
    var rawValue: String {
        switch self {
        case .welcome: return "welcome"
        case .personalizationIntro: return "personalizationIntro"
        case .beforeAfterTransformation: return "beforeAfterTransformation"
        case .mascotIntroduction: return "mascotIntroduction"
        case .mascotNaming: return "mascotNaming"
        case .genderSelection: return "genderSelection"
        case .ageSelection: return "ageSelection"
        case .heightStats: return "heightStats"
        case .weightStats: return "weightStats"
        case .stressStats: return "stressStats"
        case .anxietyStats: return "anxietyStats"
        case .dietStats: return "dietStats"
        case .smokeStats: return "smokeStats"
        case .alcoholicStats: return "alcoholicStats"
        case .socialConnectionStats: return "socialConnectionStats"
        case .bloodPressureStats: return "bloodPressureStats"
        case .mainReasonStats: return "mainReasonStats"
        case .goalsStats: return "goalsStats"
        case .syncDeviceStats: return "syncDeviceStats"
        case .terms: return "terms"
        case .paywall: return "paywall"
        case .questionnaire: return "questionnaire"
        case .valueProposition: return "valueProposition"
        case .dashboard: return "dashboard"
        }
    }
}
