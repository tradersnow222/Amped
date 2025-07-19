import Foundation
import HealthKit
import OSLog

/// Handles app launch optimization by deferring non-critical I/O operations
/// Rules: Minimize main thread blocking during app launch
@MainActor
final class LaunchOptimizer {
    
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "LaunchOptimizer")
    
    /// Singleton instance
    static let shared = LaunchOptimizer()
    
    private init() {}
    
    /// Perform critical initialization tasks that must complete before UI appears
    func performCriticalInitialization() {
        // Only the absolute minimum required for initial UI
        logger.info("🚀 Performing critical initialization")
    }
    
    /// Perform non-critical initialization tasks asynchronously
    func performDeferredInitialization() {
        Task {
            logger.info("⏳ Starting deferred initialization")
            
            // Pre-warm HealthKit if available
            if HKHealthStore.isHealthDataAvailable() {
                await preWarmHealthKit()
            }
            
            // Load user preferences and data
            await loadUserData()
            
            logger.info("✅ Deferred initialization complete")
        }
    }
    
    /// Pre-warm HealthKit to improve permission request performance
    private func preWarmHealthKit() async {
        logger.info("🏥 Pre-warming HealthKit")
        
        // Create store instance to load framework
        _ = HKHealthStore()
        
        // Initialize HealthKitManager on main actor
        await MainActor.run {
            _ = HealthKitManager.shared
        }
    }
    
    /// Load user data from storage
    private func loadUserData() async {
        logger.info("📂 Loading user data")
        
        // This triggers the deferred loading in each manager
        await MainActor.run {
            // Managers are already initialized as StateObjects
            // Their deferred loading will happen automatically
        }
    }
} 