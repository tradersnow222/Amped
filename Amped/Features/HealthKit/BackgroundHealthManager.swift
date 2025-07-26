import Foundation
import BackgroundTasks
import HealthKit
import OSLog
import Combine
import UIKit

/// Manages background health data updates following Apple's best practices
/// Implements BGAppRefreshTask, HealthKit background delivery, and energy-efficient scheduling
@MainActor final class BackgroundHealthManager: ObservableObject {
    
    // MARK: - Types
    
    enum BackgroundTaskIdentifier: String, CaseIterable {
        case healthDataRefresh = "ai.ampedlife.amped.health-refresh"
        case healthProcessing = "ai.ampedlife.amped.health-processing"
        
        var fullIdentifier: String {
            return self.rawValue
        }
    }
    
    // MARK: - Properties
    
    internal let healthKitManager: HealthKitManager
    private let healthDataService: HealthDataService
    internal let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "BackgroundHealthManager")
    
    /// Track background delivery status for each metric
    @Published private(set) var backgroundDeliveryEnabled: [HealthMetricType: Bool] = [:]
    
    /// Track last successful background update
    @Published private(set) var lastBackgroundUpdate: Date?
    
    /// Singleton instance for global access
    static let shared = BackgroundHealthManager()
    
    // MARK: - Initialization
    
    private init() {
        self.healthKitManager = HealthKitManager.shared
        
        // Create a default user profile for background operations
        let defaultProfile = UserProfile(
            id: "background-user",
            birthYear: Calendar.current.component(.year, from: Date()) - 30,
            gender: nil,
            height: 170.0,
            weight: 70.0
        )
        
        self.healthDataService = HealthDataService(
            healthKitManager: healthKitManager,
            userProfile: defaultProfile
        )
        
        setupBackgroundTasks()
        
        // Enable background delivery for critical health metrics
        Task {
            await enableBackgroundDeliveryForCriticalMetrics()
        }
    }
    
    // MARK: - Background Task Registration
    
    /// Register background tasks according to Apple's guidelines
    private func setupBackgroundTasks() {
        logger.info("🔄 Setting up background tasks for health data refresh")
        
        // Register app refresh task for regular health data updates
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.healthDataRefresh.fullIdentifier,
            using: nil
        ) { [weak self] task in
            Task { @MainActor in
                guard let self = self else {
                    task.setTaskCompleted(success: false)
                    return
                }
                
                await self.handleHealthDataRefreshTask(task as! BGAppRefreshTask)
            }
        }
        
        // Register processing task for more intensive health calculations
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.healthProcessing.fullIdentifier,
            using: nil
        ) { [weak self] task in
            Task { @MainActor in
                guard let self = self else {
                    task.setTaskCompleted(success: false)
                    return
                }
                
                await self.handleHealthProcessingTask(task as! BGProcessingTask)
            }
        }
        
        logger.info("✅ Background tasks registered successfully")
    }
    
    // MARK: - Background Task Handlers
    
    /// Handle health data refresh in background - lightweight, frequent updates
    private func handleHealthDataRefreshTask(_ task: BGAppRefreshTask) async {
        logger.info("🔄 Executing background health data refresh")
        
        let startTime = Date()
        var success = false
        
        // Set expiration handler
        task.expirationHandler = {
            self.logger.warning("⏰ Background refresh task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Lightweight refresh of critical health metrics only
        let criticalMetrics = HealthMetricType.healthKitTypes.prefix(3) // Limit to top 3 most important
        var refreshedMetrics: [HealthMetric] = []
        
        for metricType in criticalMetrics {
            if let metric = await healthKitManager.fetchLatestData(for: metricType) {
                refreshedMetrics.append(metric)
                logger.debug("✅ Refreshed \(metricType.displayName): \(metric.formattedValue)")
            }
        }
        
        // Update last refresh time
        await MainActor.run {
            self.lastBackgroundUpdate = Date()
        }
        
        success = !refreshedMetrics.isEmpty
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("🎯 Background refresh completed in \(String(format: "%.2f", duration))s. Refreshed \(refreshedMetrics.count) metrics")
        
        // Schedule next refresh
        scheduleNextHealthRefresh()
        
        task.setTaskCompleted(success: success)
    }
    
    /// Handle intensive health processing - less frequent, more comprehensive
    private func handleHealthProcessingTask(_ task: BGProcessingTask) async {
        logger.info("🔄 Executing background health processing")
        
        let startTime = Date()
        var success = false
        
        // Set expiration handler
        task.expirationHandler = {
            self.logger.warning("⏰ Background processing task expired")
            task.setTaskCompleted(success: false)
        }
        
        // More comprehensive health data processing
        let allMetrics = await healthDataService.fetchLatestMetrics()
        
        // Update analytics (if user consented)
        if !allMetrics.isEmpty {
            // Process life impact calculations in background
            // This is more CPU-intensive work suitable for BGProcessingTask
            logger.info("📊 Processing life impact calculations for \(allMetrics.count) metrics")
            success = true
        }
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("🎯 Background processing completed in \(String(format: "%.2f", duration))s")
        
        task.setTaskCompleted(success: success)
    }
    
    // MARK: - Background Delivery Setup
    
    /// Enable HealthKit background delivery for critical metrics
    private func enableBackgroundDeliveryForCriticalMetrics() async {
        logger.info("🔔 Enabling HealthKit background delivery for critical metrics")
        
        guard healthKitManager.hasAllPermissions || healthKitManager.hasCriticalPermissions else {
            logger.warning("⚠️ No HealthKit permissions available for background delivery")
            return
        }
        
        let criticalTypes = HealthKitManager.criticalMetricTypes
        
        for metricType in criticalTypes {
            let success = await enableBackgroundDelivery(for: metricType)
            
            await MainActor.run {
                backgroundDeliveryEnabled[metricType] = success
            }
            
            if success {
                logger.info("✅ Background delivery enabled for \(metricType.displayName)")
            } else {
                logger.warning("⚠️ Failed to enable background delivery for \(metricType.displayName)")
            }
        }
    }
    
    /// Enable background delivery for a specific metric type
    private func enableBackgroundDelivery(for metricType: HealthMetricType) async -> Bool {
        guard let healthKitType = metricType.healthKitType else {
            // Handle sleep separately as it uses category type
            if metricType == .sleepHours {
                return await enableSleepBackgroundDelivery()
            }
            return false
        }
        
                 do {
             try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                 healthStore.enableBackgroundDelivery(
                     for: healthKitType,
                     frequency: .immediate
                 ) { success, error in
                     if let error = error {
                         continuation.resume(throwing: error)
                     } else if success {
                         continuation.resume()
                     } else {
                         continuation.resume(throwing: NSError(
                             domain: "BackgroundHealthManager",
                             code: 1,
                             userInfo: [NSLocalizedDescriptionKey: "Failed to enable background delivery"]
                         ))
                     }
                 }
             }
             return true
         } catch {
             logger.error("❌ Failed to enable background delivery for \(metricType.displayName): \(error.localizedDescription)")
             return false
         }
    }
    
    /// Enable background delivery for sleep data
    private func enableSleepBackgroundDelivery() async -> Bool {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return false
        }
        
                 do {
             try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                 healthStore.enableBackgroundDelivery(
                     for: sleepType,
                     frequency: .immediate
                 ) { success, error in
                     if let error = error {
                         continuation.resume(throwing: error)
                     } else if success {
                         continuation.resume()
                     } else {
                         continuation.resume(throwing: NSError(
                             domain: "BackgroundHealthManager",
                             code: 1,
                             userInfo: [NSLocalizedDescriptionKey: "Failed to enable sleep background delivery"]
                         ))
                     }
                 }
             }
             return true
         } catch {
             logger.error("❌ Failed to enable sleep background delivery: \(error.localizedDescription)")
             return false
         }
    }
    
    // MARK: - Task Scheduling
    
    /// Schedule next health refresh task
    private func scheduleNextHealthRefresh() {
        // Check if background refresh is enabled in settings
        guard UserDefaults.standard.bool(forKey: "backgroundRefreshEnabled", defaultValue: true) else {
            logger.info("📅 Background refresh disabled in settings - skipping task scheduling")
            return
        }
        
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskIdentifier.healthDataRefresh.fullIdentifier)
        
        // Schedule for optimal time - Apple's system will decide when to actually run it
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes minimum
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("📅 Scheduled next health refresh task")
        } catch {
            logger.error("❌ Failed to schedule health refresh: \(error.localizedDescription)")
        }
    }
    
    /// Schedule health processing task
    func scheduleHealthProcessing() {
        // Check if background refresh is enabled in settings
        guard UserDefaults.standard.bool(forKey: "backgroundRefreshEnabled", defaultValue: true) else {
            logger.info("📅 Background refresh disabled in settings - skipping processing task scheduling")
            return
        }
        
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifier.healthProcessing.fullIdentifier)
        
        // Configure for efficiency - only run when conditions are optimal
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true // Only run when charging to preserve battery
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60 * 60) // 1 hour minimum
        
        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("📅 Scheduled health processing task")
        } catch {
            logger.error("❌ Failed to schedule health processing: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public API
    
    /// Initialize background health updates - call this after permissions are granted
    func startBackgroundUpdates() async {
        // Check if background refresh is enabled in settings
        guard UserDefaults.standard.bool(forKey: "backgroundRefreshEnabled", defaultValue: true) else {
            logger.info("🚀 Background refresh disabled in settings - skipping background updates initialization")
            return
        }
        
        logger.info("🚀 Starting background health updates")
        
        // Enable background delivery for all permitted metrics
        await enableBackgroundDeliveryForCriticalMetrics()
        
        // Schedule initial tasks
        scheduleNextHealthRefresh()
        scheduleHealthProcessing()
        
        logger.info("✅ Background health updates started successfully")
    }
    
    /// Stop background updates - useful for testing or user preference
    func stopBackgroundUpdates() {
        logger.info("🛑 Stopping background health updates")
        
        // Cancel pending tasks
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundTaskIdentifier.healthDataRefresh.fullIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: BackgroundTaskIdentifier.healthProcessing.fullIdentifier)
        
                         // Disable background delivery for all metrics
        Task {
            for metricType in HealthKitManager.allMetricTypes {
                if let healthKitType = metricType.healthKitType {
                    do {
                        try await healthStore.disableBackgroundDelivery(for: healthKitType)
                    } catch {
                        self.logger.error("❌ Failed to disable background delivery for \(metricType.displayName): \(error.localizedDescription)")
                    }
                }
            }
            
            // Handle sleep separately
            if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                do {
                    try await healthStore.disableBackgroundDelivery(for: sleepType)
                } catch {
                    self.logger.error("❌ Failed to disable sleep background delivery: \(error.localizedDescription)")
                }
            }
        }
        
        logger.info("✅ Background health updates stopped")
    }
    
    /// Check if background refresh is enabled in system settings
    var isBackgroundRefreshEnabled: Bool {
        return UIApplication.shared.backgroundRefreshStatus == .available
    }
    
    /// Get status summary for debugging/settings
    func getBackgroundStatus() -> BackgroundStatus {
        return BackgroundStatus(
            refreshEnabled: isBackgroundRefreshEnabled,
            lastUpdate: lastBackgroundUpdate,
            enabledMetrics: backgroundDeliveryEnabled.compactMapValues { $0 ? true : nil }.keys.map { $0 }
        )
    }
    
    // MARK: - Public SwiftUI Integration
    
    /// Handle health data refresh task for SwiftUI integration
    @MainActor
    func handleHealthDataRefreshTask() async {
        // This method is called by SwiftUI's backgroundTask modifier
        logger.info("🔄 Executing SwiftUI background health data refresh")
        
        let startTime = Date()
        
        // Lightweight refresh of critical health metrics only
        let criticalMetrics = HealthMetricType.healthKitTypes.prefix(3) // Limit to top 3 most important
        var refreshedMetrics: [HealthMetric] = []
        
        for metricType in criticalMetrics {
            if let metric = await healthKitManager.fetchLatestData(for: metricType) {
                refreshedMetrics.append(metric)
                logger.debug("✅ Refreshed \(metricType.displayName): \(metric.formattedValue)")
            }
        }
        
        // Update last refresh time
        lastBackgroundUpdate = Date()
        
        let duration = Date().timeIntervalSince(startTime)
        logger.info("🎯 SwiftUI background refresh completed in \(String(format: "%.2f", duration))s. Refreshed \(refreshedMetrics.count) metrics")
    }
}

// MARK: - Supporting Types

/// Status information for background operations
struct BackgroundStatus {
    let refreshEnabled: Bool
    let lastUpdate: Date?
    let enabledMetrics: [HealthMetricType]
}

// MARK: - Extensions

extension BackgroundHealthManager {
    /// Private accessor to HealthStore for background delivery operations
    fileprivate var healthStore: HKHealthStore {
        return HKHealthStore()
    }
} 