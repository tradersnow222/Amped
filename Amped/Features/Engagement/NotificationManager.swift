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
    private var smartNotificationService: SmartNotificationService?
    
    // Notification identifiers
    private enum NotificationID: String {
        case morningMotivation = "morning_motivation"
        case eveningReflection = "evening_reflection"
        case goalAchievement = "goal_achievement"
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
    
    /// Initialize smart notification service with dependencies
    func setupSmartNotifications(
        healthDataService: HealthDataServicing,
        lifeImpactService: LifeImpactService,
        userProfile: UserProfile
    ) {
        self.smartNotificationService = SmartNotificationService(
            healthDataService: healthDataService,
            lifeImpactService: lifeImpactService,
            userProfile: userProfile
        )
        logger.info("🧠 Smart notification service initialized")
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
    
    /// Schedule smart morning motivation with real-time progress and actionable suggestions
    func scheduleSmartMorningMotivation(targetMinutes: Int) {
        guard isEnabled else { return }
        
        // Schedule for 9 AM daily with smart content
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create content that will be dynamically generated when notification fires
        let content = UNMutableNotificationContent()
        content.title = "Loading your personalized update..."
        content.body = "Calculating your progress and recommendations..."
        content.sound = .default
        content.categoryIdentifier = "SMART_ENGAGEMENT"
        
        // Store target minutes in userInfo for dynamic content generation
        content.userInfo = [
            "targetMinutes": targetMinutes,
            "notificationType": "morning"
        ]
        
        let request = UNNotificationRequest(
            identifier: NotificationID.morningMotivation.rawValue,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("🚨 Failed to schedule smart morning notification: \(error)")
            } else {
                self?.logger.info("✅ Smart morning motivation scheduled for \(targetMinutes) minutes target")
            }
        }
    }
    
    /// Schedule immediate goal achievement notification
    func scheduleGoalAchievementNotification(goalMinutes: Int, actualMinutes: Int) {
        guard isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🎉 Goal Achieved!"
        content.body = "Amazing! You've added \(actualMinutes) minutes to your lifespan today (goal: \(goalMinutes))"
        content.sound = .default
        content.categoryIdentifier = "GOAL_ACHIEVEMENT"
        
        // Immediate notification
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: NotificationID.goalAchievement.rawValue + "_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("🚨 Failed to schedule goal achievement notification: \(error)")
            } else {
                self?.logger.info("🎉 Goal achievement notification scheduled: \(actualMinutes)/\(goalMinutes) minutes")
            }
        }
    }
    
    /// Schedule smart evening reflection with day summary
    func scheduleSmartEveningReflection(targetMinutes: Int) {
        guard isEnabled else { return }
        
        // Schedule for 7 PM daily with smart content
        var components = DateComponents()
        components.hour = 19
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let content = UNMutableNotificationContent()
        content.title = "Loading today's summary..."
        content.body = "Calculating your daily impact..."
        content.sound = .default
        content.categoryIdentifier = "SMART_ENGAGEMENT"
        
        content.userInfo = [
            "targetMinutes": targetMinutes,
            "notificationType": "evening"
        ]
        
        let request = UNNotificationRequest(
            identifier: NotificationID.eveningReflection.rawValue,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("🚨 Failed to schedule smart evening notification: \(error)")
            } else {
                self?.logger.info("✅ Smart evening reflection scheduled for \(targetMinutes) minutes target")
            }
        }
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
        // Get user's daily goal from questionnaire data
        if let targetMinutes = getUserDailyGoal() {
            scheduleSmartMorningMotivation(targetMinutes: targetMinutes)
            scheduleSmartEveningReflection(targetMinutes: targetMinutes)
        } else {
            logger.warning("⚠️ No daily goal found, scheduling basic notifications")
            // Fallback to basic notifications if no goal is set
            scheduleSmartMorningMotivation(targetMinutes: 30) // Default 30 minutes
            scheduleSmartEveningReflection(targetMinutes: 30)
        }
    }
    
    /// Get user's daily lifespan gain goal from stored questionnaire data
    private func getUserDailyGoal() -> Int? {
        // Access the stored questionnaire data
        if let data = UserDefaults.standard.data(forKey: "questionnaire_data"),
           let questionnaireData = try? JSONDecoder().decode(QuestionnaireData.self, from: data) {
            return questionnaireData.desiredDailyLifespanGainMinutes
        }
        return nil
    }
    
    /// Schedule smart goal-based notifications (called when user sets/updates their goal)
    func scheduleGoalBasedNotifications(targetMinutes: Int) {
        guard isEnabled else { 
            logger.info("📱 Notifications not enabled, storing goal for later scheduling")
            return 
        }
        
        // Cancel existing notifications and reschedule with new goal
        cancelAllNotifications()
        
        scheduleSmartMorningMotivation(targetMinutes: targetMinutes)
        scheduleSmartEveningReflection(targetMinutes: targetMinutes)
        
        logger.info("✅ Smart goal-based notifications scheduled for \(targetMinutes) minutes daily")
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
        // Check if this is a smart notification that needs dynamic content
        if notification.request.content.categoryIdentifier == "SMART_ENGAGEMENT" {
            Task { [weak self] in
                await self?.updateSmartNotificationContent(notification: notification)
            }
        }
        
        // Show notifications even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    /// Update notification content with smart, real-time data
    private func updateSmartNotificationContent(notification: UNNotification) async {
        guard let smartService = smartNotificationService,
              let targetMinutes = notification.request.content.userInfo["targetMinutes"] as? Int,
              let typeString = notification.request.content.userInfo["notificationType"] as? String else {
            logger.warning("⚠️ Smart notification missing required data")
            return
        }
        
        let notificationType: NotificationType
        switch typeString {
        case "morning": notificationType = .morning
        case "evening": notificationType = .evening
        default: 
            logger.warning("⚠️ Unknown notification type: \(typeString)")
            return
        }
        
        // Generate smart content
        let smartContent = await smartService.generateSmartNotificationContent(
            goalMinutes: targetMinutes,
            notificationType: notificationType
        )
        
        // Create updated notification content
        let content = UNMutableNotificationContent()
        content.title = smartContent.title
        content.body = smartContent.body
        content.sound = .default
        content.categoryIdentifier = "SMART_ENGAGEMENT"
        
        // Update the notification with smart content
        let identifier = notification.request.identifier + "_smart"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await center.add(request)
            logger.info("🧠 Smart notification content updated: \(smartContent.title)")
        } catch {
            logger.error("🚨 Failed to update smart notification: \(error)")
        }
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
