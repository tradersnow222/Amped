import Foundation

/// Represents a user's engagement streak with the app
/// Following the "Rules: Keep Swift files under 300 lines" guideline
struct BatteryStreak: Codable, Equatable {
    /// Current consecutive days of positive engagement
    let currentStreak: Int
    
    /// User's all-time longest streak
    let longestStreak: Int
    
    /// Date of the last positive engagement
    let lastEngagementDate: Date
    
    /// Whether user has engaged positively today
    let hasEngagedToday: Bool
    
    /// Streak level based on current streak count
    var streakLevel: StreakLevel {
        switch currentStreak {
        case 0: return .starting
        case 1...2: return .building
        case 3...6: return .developing
        case 7...13: return .strong
        case 14...29: return .committed
        case 30...99: return .dedicated
        case 100...: return .legendary
        default: return .starting
        }
    }
    
    /// Whether the streak is at risk (last engagement yesterday or earlier)
    var isAtRisk: Bool {
        let calendar = Calendar.current
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else { return false }
        return lastEngagementDate < calendar.startOfDay(for: yesterday) && !hasEngagedToday
    }
    
    /// Days until streak expires (0 = expires today, -1 = already expired)
    var daysUntilExpiry: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastEngagement = calendar.startOfDay(for: lastEngagementDate)
        
        if hasEngagedToday {
            return 1 // Safe for today, expires tomorrow if no engagement
        }
        
        let daysSinceLastEngagement = calendar.dateComponents([.day], from: lastEngagement, to: today).day ?? 0
        return max(-1, 1 - daysSinceLastEngagement)
    }
    
    /// Create a new streak
    init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastEngagementDate: Date = Date(),
        hasEngagedToday: Bool = false
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = max(longestStreak, currentStreak)
        self.lastEngagementDate = lastEngagementDate
        self.hasEngagedToday = hasEngagedToday
    }
    
    /// Create updated streak after positive engagement
    func withEngagement(on date: Date = Date()) -> BatteryStreak {
        let calendar = Calendar.current
        let engagementDay = calendar.startOfDay(for: date)
        let lastEngagementDay = calendar.startOfDay(for: lastEngagementDate)
        let today = calendar.startOfDay(for: Date())
        
        let isToday = engagementDay == today
        let isConsecutive = engagementDay == calendar.date(byAdding: .day, value: 1, to: lastEngagementDay)
        let isSameDay = engagementDay == lastEngagementDay
        
        if isSameDay {
            // Same day engagement, just update the flag
            return BatteryStreak(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                lastEngagementDate: date,
                hasEngagedToday: isToday
            )
        } else if isConsecutive || (currentStreak == 0 && isToday) {
            // Consecutive day or starting a new streak today
            let newCurrentStreak = currentStreak + 1
            return BatteryStreak(
                currentStreak: newCurrentStreak,
                longestStreak: max(longestStreak, newCurrentStreak),
                lastEngagementDate: date,
                hasEngagedToday: isToday
            )
        } else {
            // Streak broken, start fresh
            return BatteryStreak(
                currentStreak: 1,
                longestStreak: longestStreak,
                lastEngagementDate: date,
                hasEngagedToday: isToday
            )
        }
    }
    
    /// Create updated streak for a new day (resets hasEngagedToday)
    func forNewDay() -> BatteryStreak {
        return BatteryStreak(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastEngagementDate: lastEngagementDate,
            hasEngagedToday: false
        )
    }
}

/// Streak achievement levels with associated messaging
enum StreakLevel: String, CaseIterable, Codable {
    case starting = "starting"
    case building = "building"
    case developing = "developing"
    case strong = "strong"
    case committed = "committed"
    case dedicated = "dedicated"
    case legendary = "legendary"
    
    /// Display name for the streak level
    var displayName: String {
        switch self {
        case .starting: return "Getting Started"
        case .building: return "Building Momentum"
        case .developing: return "Developing Habits"
        case .strong: return "Going Strong"
        case .committed: return "Committed"
        case .dedicated: return "Dedicated"
        case .legendary: return "Legendary"
        }
    }
    
    /// Motivational message for this level
    var motivationalMessage: String {
        switch self {
        case .starting: return "Every expert was once a beginner"
        case .building: return "Momentum is building!"
        case .developing: return "Habits are forming"
        case .strong: return "You're on fire!"
        case .committed: return "Consistency pays off"
        case .dedicated: return "You're truly dedicated"
        case .legendary: return "You're a legend!"
        }
    }
    
    /// Emoji representation
    var emoji: String {
        switch self {
        case .starting: return "🌱"
        case .building: return "🔥"
        case .developing: return "💪"
        case .strong: return "🚀"
        case .committed: return "⭐"
        case .dedicated: return "💎"
        case .legendary: return "👑"
        }
    }
}

/// Milestone achievements for streaks
struct StreakMilestone {
    let day: Int
    let title: String
    let message: String
    let isSpecial: Bool
    
    static let milestones: [StreakMilestone] = [
        StreakMilestone(day: 1, title: "First Step", message: "You started your journey!", isSpecial: false),
        StreakMilestone(day: 3, title: "Building Habits", message: "3 days of consistency!", isSpecial: false),
        StreakMilestone(day: 7, title: "One Week Strong", message: "A full week of healthy choices!", isSpecial: true),
        StreakMilestone(day: 14, title: "Two Weeks!", message: "You're building lasting habits!", isSpecial: false),
        StreakMilestone(day: 21, title: "3 Weeks!", message: "Scientists say habits form around now!", isSpecial: true),
        StreakMilestone(day: 30, title: "One Month!", message: "30 days of dedication! Amazing!", isSpecial: true),
        StreakMilestone(day: 50, title: "50 Days Strong", message: "You're unstoppable!", isSpecial: false),
        StreakMilestone(day: 100, title: "100 Days!", message: "You've reached legendary status!", isSpecial: true),
        StreakMilestone(day: 365, title: "One Full Year!", message: "You're officially a health legend!", isSpecial: true)
    ]
    
    /// Get milestone for a specific day, if it exists
    static func milestone(for day: Int) -> StreakMilestone? {
        return milestones.first { $0.day == day }
    }
}
