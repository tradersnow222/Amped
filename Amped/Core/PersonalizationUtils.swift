import Foundation

/// Utility functions for strategic personalization throughout the app
/// Following the rule: Simplicity is KING - only use names where they have maximal impact
struct PersonalizationUtils {
    
    // MARK: - Name Retrieval
    
    /// Get the user's first name from UserDefaults (single source of truth)
    static var userFirstName: String? {
        return UserDefaults.standard.string(forKey: "userName")?.components(separatedBy: " ").first
    }
    
    /// Get the user's first name from UserDefaults (for consistency with existing API)
    static func userFirstName(from profile: UserProfile?) -> String? {
        return userFirstName
    }
    
    // MARK: - Strategic Personalization Messages
    
    /// Welcome messages for high-impact moments in onboarding
    static func personalizedWelcomeMessage(firstName: String?) -> String {
        guard let name = firstName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Welcome to your personalized life battery experience"
        }
        return "Welcome, \(name)! Let's power up your life together"
    }
    
    /// Value proposition messages for after data collection
    static func personalizedValueMessage(firstName: String?) -> String {
        guard let name = firstName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Your habits directly impact your projected lifespan"
        }
        return "\(name), your habits directly impact your projected lifespan"
    }
    
    /// Payment screen personalization for maximum conversion impact
    static func personalizedPaymentMessage(firstName: String?) -> String {
        guard let name = firstName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Unlock your full life potential"
        }
        return "\(name), unlock your full life potential"
    }
    
    /// Dashboard greeting for returning users
    static func dashboardGreeting(firstName: String?) -> String {
        guard let name = firstName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Your Life Battery Today"
        }
        
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay: String
        
        switch hour {
        case 5..<12:
            timeOfDay = "Good morning"
        case 12..<17:
            timeOfDay = "Good afternoon"
        case 17..<22:
            timeOfDay = "Good evening"
        default:
            timeOfDay = "Hello"
        }
        
        return "\(timeOfDay), \(name)"
    }
    
    /// Achievement congratulation messages
    static func achievementMessage(firstName: String?, achievement: String) -> String {
        guard let name = firstName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Great job! \(achievement)"
        }
        return "Congratulations, \(name)! \(achievement)"
    }
    
    /// Motivation messages for negative impacts
    static func motivationMessage(firstName: String?) -> String {
        guard let name = firstName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "Small changes can make a big difference"
        }
        return "\(name), small changes can make a big difference"
    }
    
    /// Progress encouragement messages
    static func progressMessage(firstName: String?, improvement: String) -> String {
        guard let name = firstName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "You're making progress! \(improvement)"
        }
        return "Keep it up, \(name)! \(improvement)"
    }
    
    // MARK: - Context-Aware Personalization
    
    /// Get appropriate personalized message based on context
    static func contextualMessage(firstName: String?, context: PersonalizationContext) -> String {
        switch context {
        case .welcome:
            return personalizedWelcomeMessage(firstName: firstName)
        case .valueProposition:
            return personalizedValueMessage(firstName: firstName)
        case .payment:
            return personalizedPaymentMessage(firstName: firstName)
        case .dashboardGreeting:
            return dashboardGreeting(firstName: firstName)
        case .motivation:
            return motivationMessage(firstName: firstName)
        case .achievement(let achievement):
            return achievementMessage(firstName: firstName, achievement: achievement)
        case .progress(let improvement):
            return progressMessage(firstName: firstName, improvement: improvement)
        }
    }
}

/// Contexts where personalization has maximum impact
enum PersonalizationContext {
    case welcome
    case valueProposition
    case payment
    case dashboardGreeting
    case motivation
    case achievement(String)
    case progress(String)
}
