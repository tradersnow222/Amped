import Foundation

/// Minimal user profile with anonymous ID for future analytics
struct UserProfile: Codable, Equatable {
    let id: String
    var birthYear: Int?
    var gender: Gender?
    var height: Double?
    var weight: Double?
    var isSubscribed: Bool
    var hasCompletedOnboarding: Bool
    var hasCompletedQuestionnaire: Bool
    var hasGrantedHealthKitPermissions: Bool
    var createdAt: Date
    var lastActive: Date
    
    /// Standard initialization
    init(
        id: String = UUID().uuidString,
        birthYear: Int? = nil,
        gender: Gender? = nil,
        height: Double? = nil,
        weight: Double? = nil,
        isSubscribed: Bool = false,
        hasCompletedOnboarding: Bool = false,
        hasCompletedQuestionnaire: Bool = false,
        hasGrantedHealthKitPermissions: Bool = false,
        createdAt: Date = Date(),
        lastActive: Date = Date()
    ) {
        self.id = id
        self.birthYear = birthYear
        self.gender = gender
        self.height = height
        self.weight = weight
        self.isSubscribed = isSubscribed
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasCompletedQuestionnaire = hasCompletedQuestionnaire
        self.hasGrantedHealthKitPermissions = hasGrantedHealthKitPermissions
        self.createdAt = createdAt
        self.lastActive = lastActive
    }
    
    /// Calculate the user's age in years
    var age: Int? {
        guard let birthYear = birthYear else { return nil }
        
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return currentYear - birthYear
    }
    
    /// Check if user has all required profile data for calculation
    var hasRequiredProfileData: Bool {
        birthYear != nil && gender != nil
    }
    
    /// Gender enum for calculation purposes
    enum Gender: String, Codable, CaseIterable {
        case male
        case female
        case preferNotToSay
        
        var displayName: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            case .preferNotToSay: return "Prefer not to say"
            }
        }
    }
    
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Update profile with questionnaire data
    mutating func updateFromQuestionnaire(birthYear: Int?, gender: Gender?, height: Double?, weight: Double?) {
        self.birthYear = birthYear
        self.gender = gender
        self.height = height
        self.weight = weight
        self.hasCompletedQuestionnaire = true
        self.lastActive = Date()
    }
    
    /// Mark onboarding as completed
    mutating func completeOnboarding() {
        self.hasCompletedOnboarding = true
        self.lastActive = Date()
    }
    
    /// Mark HealthKit permissions as granted
    mutating func grantHealthKitPermissions() {
        self.hasGrantedHealthKitPermissions = true
        self.lastActive = Date()
    }
    
    /// Update subscription status
    mutating func updateSubscriptionStatus(_ isSubscribed: Bool) {
        self.isSubscribed = isSubscribed
        self.lastActive = Date()
    }
} 