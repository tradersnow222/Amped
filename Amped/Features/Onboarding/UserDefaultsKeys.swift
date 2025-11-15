import Foundation

/// Centralized keys for UserDefaults used across the app
public enum UserDefaultsKeys {
    // Onboarding progress / temp caches
    public static let questionnaireCurrentQuestion = "questionnaire_current_question"
    public static let questionnaireCache = "questionnaire_cache"
    public static let onboardingTempData = "onboarding_temp_data"

    // Legacy/user name key variants observed in code
    public static let userNameLegacy = "userName"

    // Profile and questionnaire keys captured in onboarding flow
    public static let userName = "user_name"
    public static let userGender = "user_gender"
    public static let userDateOfBirth = "user_date_of_birth"
    public static let userHeight = "user_height"
    public static let userWeight = "user_weight"
    public static let userWeightUnit = "user_weight_unit"
    public static let userStressLevel = "user_stress_level"
    public static let userAnxietyLevel = "user_anxiety_level"
    public static let userDietLevel = "user_diet_level"
    public static let userSmokeStats = "user_smoke_stats"
    public static let userAlcoholStats = "user_alcohol_stats"
    public static let userSocialStats = "user_social_stats"
    public static let userBloodPressureStats = "user_blood_pressure_stats"
    public static let userMainReasonStats = "user_main_reason_stats"
    public static let userGoalStats = "user_goal_stats"
    public static let userDeviceSync = "user_device_sync"
}

