import Foundation
import OSLog
import Combine

/// Manages user engagement streaks and milestone tracking
/// Following "Rules: Keep Swift files under 300 lines" guideline
final class StreakManager: ObservableObject {
    
    // MARK: - Properties
    
    /// Current user's streak data
    @Published private(set) var currentStreak: BatteryStreak = BatteryStreak()
    
    /// Whether user has achieved a new milestone today
    @Published private(set) var newMilestoneToday: StreakMilestone?
    
    /// Last milestone reached (for display purposes)
    @Published private(set) var lastMilestone: StreakMilestone?
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "StreakManager")
    private let userDefaults = UserDefaults.standard
    
    // Storage keys
    private enum StorageKey: String {
        case currentStreak = "user_engagement_streak"
        case lastMilestone = "last_streak_milestone"
        case lastEngagementCheck = "last_engagement_check_date"
    }
    
    // MARK: - Singleton
    
    static let shared = StreakManager()
    
    private init() {
        loadStreakData()
        setupDayChangeObserver()
    }
    
    // MARK: - Public Methods
    
    /// Record positive engagement (user opened app and saw updated data)
    func recordEngagement() {
        let previousStreak = currentStreak
        let updatedStreak = currentStreak.withEngagement()
        
        // Check for new milestone
        if updatedStreak.currentStreak > previousStreak.currentStreak {
            checkForMilestone(day: updatedStreak.currentStreak)
        }
        
        // Update current streak
        currentStreak = updatedStreak
        saveStreakData()
        
        logger.info("📈 Engagement recorded. Streak: \(updatedStreak.currentStreak) days")
        
        // Notify analytics
        NotificationCenter.default.post(
            name: NSNotification.Name("StreakEngagementRecorded"),
            object: nil,
            userInfo: [
                "streakLength": updatedStreak.currentStreak,
                "isNewRecord": updatedStreak.currentStreak == updatedStreak.longestStreak,
                "streakLevel": updatedStreak.streakLevel.rawValue
            ]
        )
    }
    
    /// Check if user needs streak protection reminder
    func needsStreakProtection() -> Bool {
        return currentStreak.currentStreak > 0 && currentStreak.isAtRisk
    }
    
    /// Get contextual message for current streak status
    func getStreakStatusMessage() -> String {
        if currentStreak.currentStreak == 0 {
            return "Ready to start your journey?"
        } else if currentStreak.hasEngagedToday {
            return "Streak active: \(currentStreak.currentStreak) days!"
        } else if currentStreak.isAtRisk {
            return "Don't lose your \(currentStreak.currentStreak)-day streak!"
        } else {
            return "Keep your \(currentStreak.currentStreak)-day streak going!"
        }
    }
    
    /// Get encouragement message based on streak level
    func getEncouragementMessage() -> String {
        let level = currentStreak.streakLevel
        let streakCount = currentStreak.currentStreak
        
        switch level {
        case .starting:
            return "Every healthy choice counts. Start today!"
        case .building:
            return "You're building momentum! Keep it up!"
        case .developing:
            return "Great habits are forming. Stay consistent!"
        case .strong:
            return "You're doing amazing! \(streakCount) days strong!"
        case .committed:
            return "Your commitment is inspiring! \(streakCount) days!"
        case .dedicated:
            return "Incredible dedication! \(streakCount) days of growth!"
        case .legendary:
            return "You're a legend! \(streakCount) days of excellence!"
        }
    }
    
    /// Reset streak (for testing or user request)
    func resetStreak() {
        currentStreak = BatteryStreak()
        newMilestoneToday = nil
        lastMilestone = nil
        saveStreakData()
        logger.info("🔄 Streak reset by user request")
    }
    
    // MARK: - Private Methods
    
    private func loadStreakData() {
        // Load streak data
        if let data = userDefaults.data(forKey: StorageKey.currentStreak.rawValue),
           let streak = try? JSONDecoder().decode(BatteryStreak.self, from: data) {
            currentStreak = streak
        }
        
        // Load last milestone
        if let data = userDefaults.data(forKey: StorageKey.lastMilestone.rawValue),
           let milestone = try? JSONDecoder().decode(StreakMilestone.self, from: data) {
            lastMilestone = milestone
        }
        
        logger.info("📊 Loaded streak data: \(self.currentStreak.currentStreak) days")
    }
    
    private func saveStreakData() {
        // Save streak data
        if let data = try? JSONEncoder().encode(currentStreak) {
            userDefaults.set(data, forKey: StorageKey.currentStreak.rawValue)
        }
        
        // Save last milestone
        if let milestone = lastMilestone,
           let data = try? JSONEncoder().encode(milestone) {
            userDefaults.set(data, forKey: StorageKey.lastMilestone.rawValue)
        }
    }
    
    private func checkForMilestone(day: Int) {
        guard let milestone = StreakMilestone.milestone(for: day) else { return }
        
        // Don't show the same milestone twice
        if lastMilestone?.day != day {
            newMilestoneToday = milestone
            lastMilestone = milestone
            
            logger.info("🏆 New milestone reached: \(milestone.title) (Day \(day))")
            
            // Notify for celebration UI
            NotificationCenter.default.post(
                name: NSNotification.Name("StreakMilestoneReached"),
                object: nil,
                userInfo: [
                    "milestone": milestone,
                    "day": day,
                    "isSpecial": milestone.isSpecial
                ]
            )
        }
    }
    
    private func setupDayChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleDayChange()
        }
    }
    
    private func handleDayChange() {
        logger.info("📅 Day changed, updating streak status")
        
        // Update streak for new day
        currentStreak = currentStreak.forNewDay()
        
        // Clear daily milestone if it's a new day
        if !Calendar.current.isDateInToday(lastMilestone?.day != nil ? Date() : Date.distantPast) {
            newMilestoneToday = nil
        }
        
        saveStreakData()
        
        // If streak is at risk, schedule protection notification
        if needsStreakProtection() {
            scheduleStreakProtectionNotification()
        }
    }
    
    private func scheduleStreakProtectionNotification() {
        // This will be implemented when we create the NotificationManager
        logger.info("🚨 Streak at risk, scheduling protection notification")
        
        NotificationCenter.default.post(
            name: NSNotification.Name("StreakNeedsProtection"),
            object: nil,
            userInfo: [
                "streakLength": currentStreak.currentStreak,
                "daysUntilExpiry": currentStreak.daysUntilExpiry
            ]
        )
    }
}

// MARK: - StreakMilestone Codable Extension

extension StreakMilestone: Codable {
    enum CodingKeys: String, CodingKey {
        case day, title, message, isSpecial
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        day = try container.decode(Int.self, forKey: .day)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        isSpecial = try container.decode(Bool.self, forKey: .isSpecial)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(day, forKey: .day)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encode(isSpecial, forKey: .isSpecial)
    }
}
