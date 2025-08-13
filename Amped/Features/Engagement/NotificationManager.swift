import Foundation
import UserNotifications
import OSLog

/// Manages smart, contextual notifications for user engagement
/// Following "Rules: Keep Swift files under 300 lines" guideline
final class NotificationManager: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isEnabled: Bool = false
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "NotificationManager")
    private let center = UNUserNotificationCenter.current()
    
    // Notification identifiers
    private enum NotificationID: String {
        case morningMotivation = "morning_motivation"
        case midDayCheckIn = "midday_checkin"
        case eveningReflection = "evening_reflection"
        case streakProtection = "streak_protection"
        case milestoneReminderr = "milestone_reminder"
        case weeklyProgress = "weekly_progress"
    }
    
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    override init() {
        super.init()
        center.delegate = self
        checkPermissionStatus()
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions with clear value proposition
    func requestPermissions() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            await MainActor.run {
                self.permissionStatus = granted ? .authorized : .denied
                self.isEnabled = granted
            }
            
            if granted {
                logger.info("✅ Notification permissions granted")
                scheduleDefaultNotifications()
            } else {
                logger.info("❌ Notification permissions denied")
            }
            
            return granted
        } catch {
            logger.error("🚨 Error requesting notification permissions: \(error)")
            return false
        }
    }
    
    /// Check current permission status
    func checkPermissionStatus() {
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionStatus = settings.authorizationStatus
                self?.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Smart Notification Scheduling
    
    /// Schedule contextual morning motivation
    func scheduleMorningMotivation() {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Start Strong Today"
        content.body = "Your daily choices add up. Ready to make progress?"
        content.sound = .default
        content.categoryIdentifier = "ENGAGEMENT"
        
        // Schedule for 8 AM daily
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.morningMotivation.rawValue,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("🚨 Failed to schedule morning notification: \(error)")
            } else {
                self?.logger.info("✅ Morning motivation scheduled")
            }
        }
    }
    
    /// Schedule midday check-in
    func scheduleMidDayCheckIn() {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "How's Your Day Going?"
        content.body = "Quick check-in - small actions create big results"
        content.sound = .default
        content.categoryIdentifier = "ENGAGEMENT"
        
        // Schedule for 1 PM daily
        var components = DateComponents()
        components.hour = 13
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.midDayCheckIn.rawValue,
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    /// Schedule evening reflection
    func scheduleEveningReflection() {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Today's Progress"
        content.body = "See how your choices impacted your health today"
        content.sound = .default
        content.categoryIdentifier = "ENGAGEMENT"
        
        // Schedule for 7 PM daily
        var components = DateComponents()
        components.hour = 19
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.eveningReflection.rawValue,
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    /// Schedule streak protection notification
    func scheduleStreakProtection(streakLength: Int) {
        guard isEnabled, streakLength > 0 else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Don't Break The Chain"
        content.body = "Your \(streakLength)-day streak is at risk. One small action keeps it alive!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_PROTECTION"
        
        // Schedule for 9 PM today
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 21
        components.minute = 0
        
        guard let triggerDate = calendar.date(from: components),
              triggerDate > Date() else { return }
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.streakProtection.rawValue,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("🚨 Failed to schedule streak protection: \(error)")
            } else {
                self?.logger.info("🛡️ Streak protection scheduled for \(streakLength) days")
            }
        }
    }
    
    /// Schedule milestone celebration
    func scheduleMilestoneCelebration(milestone: StreakMilestone) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 \(milestone.title)!"
        content.body = milestone.message
        content.sound = .default
        content.categoryIdentifier = "MILESTONE"
        
        // Immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.milestoneReminderr.rawValue,
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    /// Cancel all notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        logger.info("🚫 All notifications cancelled")
    }
    
    /// Cancel specific notification type
    private func cancelNotification(_ type: NotificationID) {
        center.removePendingNotificationRequests(withIdentifiers: [type.rawValue])
        logger.info("🚫 Cancelled \(type.rawValue) notifications")
    }
    
    // MARK: - Default Setup
    
    private func scheduleDefaultNotifications() {
        scheduleMorningMotivation()
        scheduleMidDayCheckIn()
        scheduleEveningReflection()
    }
    
    // MARK: - Observers Setup
    
    func setupStreakObservers() {
        // Listen for streak protection needs
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StreakNeedsProtection"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let userInfo = notification.userInfo,
               let streakLength = userInfo["streakLength"] as? Int {
                self?.scheduleStreakProtection(streakLength: streakLength)
            }
        }
        
        // Listen for milestone achievements
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("StreakMilestoneReached"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let userInfo = notification.userInfo,
               let milestone = userInfo["milestone"] as? StreakMilestone {
                self?.scheduleMilestoneCelebration(milestone: milestone)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifier = response.notification.request.identifier
        logger.info("📱 User tapped notification: \(identifier)")
        
        // Record notification engagement
        NotificationCenter.default.post(
            name: NSNotification.Name("NotificationEngagement"),
            object: nil,
            userInfo: ["notificationId": identifier]
        )
        
        completionHandler()
    }
}
