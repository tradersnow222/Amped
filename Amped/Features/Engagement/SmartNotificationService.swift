import Foundation
import UserNotifications
import OSLog
import HealthKit

/// Smart notification service that provides goal progress and time-sensitive action recommendations
final class SmartNotificationService: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "SmartNotificationService")
    private let healthDataService: HealthDataServicing
    private let lifeImpactService: LifeImpactService
    private let userProfile: UserProfile
    
    // MARK: - Initialization
    
    init(
        healthDataService: HealthDataServicing,
        lifeImpactService: LifeImpactService,
        userProfile: UserProfile
    ) {
        self.healthDataService = healthDataService
        self.lifeImpactService = lifeImpactService
        self.userProfile = userProfile
    }
    
    // MARK: - Smart Notification Content Generation
    
    /// Generate smart notification content with current progress and time-sensitive actions
    func generateSmartNotificationContent(goalMinutes: Int, notificationType: NotificationType) async -> NotificationContent {
        logger.info("🧠 Generating smart notification for \(notificationType.rawValue) with goal: \(goalMinutes) minutes")
        
        // Get current progress toward goal
        let currentProgress = await getCurrentProgressTowardGoal()
        let remainingMinutes = max(0, goalMinutes - Int(currentProgress.totalImpactMinutes))
        
        // Get time-sensitive action recommendations
        let actionRecommendations = getTimeSensitiveActions(
            currentHour: Calendar.current.component(.hour, from: Date()),
            remainingMinutes: remainingMinutes,
            currentProgress: currentProgress
        )
        
        // Generate notification content based on type
        switch notificationType {
        case .morning:
            return generateMorningNotification(
                goalMinutes: goalMinutes,
                currentProgress: currentProgress,
                actions: actionRecommendations
            )
        case .evening:
            return generateEveningNotification(
                goalMinutes: goalMinutes,
                currentProgress: currentProgress,
                actions: actionRecommendations
            )
        }
    }
    
    // MARK: - Progress Tracking
    
    /// Get current progress toward daily goal
    private func getCurrentProgressTowardGoal() async -> ProgressSummary {
        // Fetch today's metrics
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let todaysMetrics = await healthDataService.fetchMetrics(from: startOfDay, to: endOfDay)
        
        // Calculate total impact from today's metrics
        var totalImpactMinutes: Double = 0
        var positiveImpactMinutes: Double = 0
        var negativeImpactMinutes: Double = 0
        var topContributors: [(metric: HealthMetric, impact: Double)] = []
        
        for metric in todaysMetrics {
            if let impactDetails = metric.impactDetails {
                let impact = impactDetails.lifespanImpactMinutes
                totalImpactMinutes += impact
                
                if impact > 0 {
                    positiveImpactMinutes += impact
                } else {
                    negativeImpactMinutes += impact
                }
                
                topContributors.append((metric: metric, impact: impact))
            }
        }
        
        // Sort by absolute impact for top contributors
        topContributors.sort { abs($0.impact) > abs($1.impact) }
        
        logger.info("📊 Current progress: \(String(format: "%.1f", totalImpactMinutes)) total minutes (\(String(format: "%.1f", positiveImpactMinutes)) positive, \(String(format: "%.1f", negativeImpactMinutes)) negative)")
        
        return ProgressSummary(
            totalImpactMinutes: totalImpactMinutes,
            positiveImpactMinutes: positiveImpactMinutes,
            negativeImpactMinutes: negativeImpactMinutes,
            topContributors: Array(topContributors.prefix(3)),
            totalMetrics: todaysMetrics.count
        )
    }
    
    // MARK: - Time-Sensitive Action Recommendations
    
    /// Get actionable recommendations based on current time and progress
    private func getTimeSensitiveActions(currentHour: Int, remainingMinutes: Int, currentProgress: ProgressSummary) -> [ActionRecommendation] {
        var actions: [ActionRecommendation] = []
        
        switch currentHour {
        case 6...18: // Morning through afternoon
            actions.append(contentsOf: getMorningActions(remainingMinutes: remainingMinutes))
        default: // Evening and night
            actions.append(contentsOf: getEveningActions(remainingMinutes: remainingMinutes))
        }
        
        // Prioritize actions based on impact potential and current deficits
        return prioritizeActions(actions, currentProgress: currentProgress)
    }
    
    private func getMorningActions(remainingMinutes: Int) -> [ActionRecommendation] {
        return [
            ActionRecommendation(
                action: "Take a 10-minute walk to increase your lifespan by 8 minutes",
                estimatedImpact: 8,
                category: .movement,
                timeRequired: 10
            ),
            ActionRecommendation(
                action: "Do 5 minutes of stretching to increase your lifespan by 3 minutes",
                estimatedImpact: 3,
                category: .movement,
                timeRequired: 5
            ),
            ActionRecommendation(
                action: "Eat a healthy breakfast to increase your lifespan by 5 minutes",
                estimatedImpact: 5,
                category: .nutrition,
                timeRequired: 15
            ),
            ActionRecommendation(
                action: "Take deep breaths for 2 minutes to increase your lifespan by 2 minutes",
                estimatedImpact: 2,
                category: .stress,
                timeRequired: 2
            )
        ]
    }
    

    
    private func getEveningActions(remainingMinutes: Int) -> [ActionRecommendation] {
        return [
            ActionRecommendation(
                action: "Go for an evening walk to increase your lifespan by 10 minutes",
                estimatedImpact: 10,
                category: .movement,
                timeRequired: 20
            ),
            ActionRecommendation(
                action: "Cook a healthy dinner to increase your lifespan by 7 minutes",
                estimatedImpact: 7,
                category: .nutrition,
                timeRequired: 30
            ),
            ActionRecommendation(
                action: "Wind down with light stretching to increase your lifespan by 4 minutes",
                estimatedImpact: 4,
                category: .movement,
                timeRequired: 10
            ),
            ActionRecommendation(
                action: "Get 7-8 hours of quality sleep tonight to increase your lifespan by 20 minutes",
                estimatedImpact: 20,
                category: .sleep,
                timeRequired: 0
            ),
            ActionRecommendation(
                action: "Put devices away 1 hour before bed to increase your lifespan by 5 minutes",
                estimatedImpact: 5,
                category: .sleep,
                timeRequired: 0
            )
        ]
    }
    
    private func prioritizeActions(_ actions: [ActionRecommendation], currentProgress: ProgressSummary) -> [ActionRecommendation] {
        // Sort by impact potential and feasibility
        return actions.sorted { action1, action2 in
            let efficiency1 = Double(action1.estimatedImpact) / Double(max(1, action1.timeRequired))
            let efficiency2 = Double(action2.estimatedImpact) / Double(max(1, action2.timeRequired))
            return efficiency1 > efficiency2
        }
    }
    
    // MARK: - Notification Content Generation
    
    private func generateMorningNotification(
        goalMinutes: Int,
        currentProgress: ProgressSummary,
        actions: [ActionRecommendation]
    ) -> NotificationContent {
        let topAction = actions.first
        
        let title = "Start Strong Today"
        let body: String
        
        if let action = topAction {
            body = "Goal: +\(goalMinutes) min today. Try: \(action.action) (+\(action.estimatedImpact) min)"
        } else {
            body = "Ready to add \(goalMinutes) minutes to your life today?"
        }
        
        return NotificationContent(title: title, body: body, actions: Array(actions.prefix(2)))
    }
    

    
    private func generateEveningNotification(
        goalMinutes: Int,
        currentProgress: ProgressSummary,
        actions: [ActionRecommendation]
    ) -> NotificationContent {
        let progressMinutes = Int(currentProgress.totalImpactMinutes)
        let topAction = actions.first
        
        let title: String
        let body: String
        
        if progressMinutes >= goalMinutes {
            title = "Goal Achieved! 🌟"
            body = "Amazing! You added +\(progressMinutes) minutes today (goal: \(goalMinutes))"
        } else if progressMinutes > goalMinutes / 2 {
            title = "So Close!"
            if let action = topAction {
                body = "At +\(progressMinutes)/\(goalMinutes) min. Last push: \(action.action)"
            } else {
                body = "You're at +\(progressMinutes) of \(goalMinutes) minutes. Almost there!"
            }
        } else {
            title = "Tomorrow's a New Day"
            body = "Today: +\(progressMinutes)/\(goalMinutes) min. Rest well for tomorrow!"
        }
        
        return NotificationContent(title: title, body: body, actions: Array(actions.prefix(1)))
    }
}

// MARK: - Supporting Types

enum NotificationType: String {
    case morning = "morning"
    case evening = "evening"
}

struct NotificationContent {
    let title: String
    let body: String
    let actions: [ActionRecommendation]
}

struct ProgressSummary {
    let totalImpactMinutes: Double
    let positiveImpactMinutes: Double
    let negativeImpactMinutes: Double
    let topContributors: [(metric: HealthMetric, impact: Double)]
    let totalMetrics: Int
}

struct ActionRecommendation {
    let action: String
    let estimatedImpact: Int // Minutes of life impact
    let category: ActionCategory
    let timeRequired: Int // Minutes to complete
}

enum ActionCategory {
    case movement
    case nutrition
    case sleep
    case stress
    case social
}
