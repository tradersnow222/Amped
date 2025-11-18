import Foundation

struct NotificationPreferences: Codable, Equatable {
    var streakProtectionAlerts: Bool = true
    var personalizedHabitReminders: Bool = true   // Morning smart motivation
    var motivationalBoosts: Bool = false          // Stored preference only
    var dailyCheckInSummary: Bool = true          // Evening reflection
    var healthSyncNotifications: Bool = true      // Stored preference only
    var challengesAndMilestones: Bool = false     // Milestone celebrations
    var weeklyMonthlyReports: Bool = true         // Weekly + monthly scheduling
    var systemAppUpdates: Bool = false            // Stored preference only
    
    private static let key = "NotificationPreferences.v1"
    
    static func load() -> NotificationPreferences {
        if let data = UserDefaults.standard.data(forKey: key),
           let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) {
            return prefs
        }
        return NotificationPreferences()
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
