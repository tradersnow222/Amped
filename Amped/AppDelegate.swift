// AppDelegate.swift
import UIKit
import OSLog

final class AppDelegate: NSObject, UIApplicationDelegate {
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "AppDelegate")
    
    // Define your quick action identifiers
    enum QuickAction: String {
        case openDashboard = "ai.ampedlife.amped.openDashboard"
        case refreshHealthData = "ai.ampedlife.amped.refreshHealthData"
        case sendFeedback = "ai.ampedlife.amped.sendFeedback"
        
        var title: String {
            switch self {
            case .openDashboard: return "Open Dashboard"
            case .refreshHealthData: return "Refresh Health Data"
            case .sendFeedback: return "Send Feedback"
            }
        }
        
        var icon: UIApplicationShortcutIcon {
            switch self {
            case .openDashboard:
                return UIApplicationShortcutIcon(type: .favorite)
            case .refreshHealthData:
                return UIApplicationShortcutIcon(type: .update)
            case .sendFeedback:
                return UIApplicationShortcutIcon(type: .mail)
            }
        }
    }
    
    // Store a pending quick action when the app is not active so we can handle it when active.
    private var pendingQuickAction: QuickAction?
    private let pendingKey = "PendingQuickActionType"
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        setupQuickActions()
        
        // Handle cold-launch via quick action by deferring until the app is active.
        if let shortcut = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem,
           let action = QuickAction(rawValue: shortcut.type) {
            logger.info("🧊 Cold launch with quick action: \(shortcut.type, privacy: .public). Deferring until active.")
            pendingQuickAction = action
            // Persist so SwiftUI can pick it up even if our notification races
            UserDefaults.standard.set(action.rawValue, forKey: pendingKey)
            return false
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // If we were launched or foregrounded via a quick action, broadcast it now when SwiftUI is ready.
        if let action = pendingQuickAction {
            logger.info("▶️ Handling deferred quick action on become active: \(action.rawValue, privacy: .public)")
            // Slight delay to ensure SwiftUI view hierarchy can present sheets
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.postQuickActionNotification(action)
                // Clear persisted pending flag now that we're broadcasting
                UserDefaults.standard.removeObject(forKey: self.pendingKey)
            }
            pendingQuickAction = nil
        }
    }
    
    // Create dynamic quick actions for the Home Screen icon
    private func setupQuickActions() {
        let items: [UIApplicationShortcutItem] = [
            UIApplicationShortcutItem(
                type: QuickAction.openDashboard.rawValue,
                localizedTitle: QuickAction.openDashboard.title,
                localizedSubtitle: "Today's Impact",
                icon: QuickAction.openDashboard.icon,
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickAction.refreshHealthData.rawValue,
                localizedTitle: QuickAction.refreshHealthData.title,
                localizedSubtitle: "Pull latest from Health",
                icon: QuickAction.refreshHealthData.icon,
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: QuickAction.sendFeedback.rawValue,
                localizedTitle: QuickAction.sendFeedback.title,
                localizedSubtitle: "Tell us what you think",
                icon: QuickAction.sendFeedback.icon,
                userInfo: nil
            )
        ]
        UIApplication.shared.shortcutItems = items
        logger.info("🏁 Quick Actions configured: \(items.count) items")
    }
    
    // Handle quick action selection (warm/foreground launch)
    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let handled = handleShortcut(shortcutItem, applicationState: application.applicationState)
        completionHandler(handled)
    }
    
    @discardableResult
    private func handleShortcut(_ shortcutItem: UIApplicationShortcutItem, applicationState: UIApplication.State) -> Bool {
        logger.info("🔖 Quick Action selected: \(shortcutItem.type, privacy: .public) (state: \(String(describing: applicationState.rawValue)))")
        
        guard let action = QuickAction(rawValue: shortcutItem.type) else {
            return false
        }
        
        // Persist immediately so SwiftUI can recover on first render even if our post races
        UserDefaults.standard.set(action.rawValue, forKey: pendingKey)
        
        // If app is not active yet, defer until active to avoid missing the SwiftUI subscriber.
        if applicationState != .active {
            logger.info("⏸️ App not active (state \(applicationState.rawValue)); deferring quick action: \(action.rawValue, privacy: .public)")
            pendingQuickAction = action
            return true
        }
        
        // App is active: broadcast to SwiftUI and clear persisted flag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.postQuickActionNotification(action)
            UserDefaults.standard.removeObject(forKey: self.pendingKey)
        }
        return true
    }
    
    private func postQuickActionNotification(_ action: QuickAction) {
        logger.info("📣 Posting QuickActionSelected: \(action.rawValue, privacy: .public)")
        NotificationCenter.default.post(
            name: NSNotification.Name("QuickActionSelected"),
            object: nil,
            userInfo: ["type": action.rawValue]
        )
    }
}
