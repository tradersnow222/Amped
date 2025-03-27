import Foundation
import HealthKit
import OSLog

/// Manages HealthKit permissions
@MainActor final class HealthKitPermissionsManager {
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitPermissionsManager")
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    /// Request authorization for specific HealthKit data types
    func requestAuthorization(for types: [HealthMetricType]) async -> (Bool, [String: Bool]) {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.error("HealthKit is not available on this device")
            return (false, [:])
        }
        
        // Prepare read types set
        var typesToRead = Set<HKObjectType>()
        
        // Log all requested types for clarity
        logger.info("Requesting permissions for the following metric types:")
        
        // Add each requested HealthKit type
        for metricType in types {
            if let healthKitType = metricType.healthKitType {
                typesToRead.insert(healthKitType)
                logger.debug("Requesting permission for: \(metricType.displayName)")
            } else {
                logger.debug("No corresponding HealthKit type for: \(metricType.displayName)")
            }
            
            // Special handling for sleep which uses category type
            if metricType == .sleepHours {
                if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                    typesToRead.insert(sleepType)
                    logger.debug("Requesting permission for sleep analysis")
                } else {
                    logger.warning("Sleep analysis type is not available on this device")
                }
            }
        }
        
        // Request permissions - IMPORTANT: Using empty array for share types
        do {
            logger.info("Requesting HealthKit authorization for \(typesToRead.count) types: \(typesToRead.map { $0.identifier })")
            
            // Request authorization with proper error handling
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            logger.info("HealthKit authorization request completed without throwing errors")

            // DIAGNOSTIC FIX: Force a slight delay to let iOS update its permission state
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            logger.info("Completed delay after permission request")
            
            // Check if direct Health app setting is showing permissions
            try await directHealthAppPermissionCheck()
            
            // Check permissions status immediately without delay
            logger.info("Checking critical permissions status...")
            let (criticalGranted, _) = await checkCriticalPermissionsStatus(criticalTypes: types)
            logger.info("Critical permissions check result: granted=\(criticalGranted)")
            
            // Then check all permissions
            logger.info("Checking all permissions status...")
            let (allGranted, updatedSpecialPermissions) = await checkPermissionsStatus(for: types)
            logger.info("All permissions check result: granted=\(allGranted)")
            
            // Consider the request successful if critical permissions are granted
            // This is a key change - we're being more tolerant of partial permissions
            let isSuccessful = criticalGranted || allGranted
            
            if isSuccessful {
                logger.info("Sufficient HealthKit permissions granted: critical=\(criticalGranted), all=\(allGranted)")
                return (true, updatedSpecialPermissions)
            } else {
                logger.error("Not enough HealthKit permissions were granted: critical=\(criticalGranted), all=\(allGranted)")
                logDeniedPermissions(types: types)
                return (false, updatedSpecialPermissions)
            }
        } catch {
            logger.error("Error requesting HealthKit authorization: \(error.localizedDescription)")
            
            // Enhanced error logging
            if let nsError = error as NSError? {
                logger.error("  Domain: \(nsError.domain), Code: \(nsError.code)")
                if let localizedFailure = nsError.localizedFailureReason {
                    logger.error("  Failure reason: \(localizedFailure)")
                }
                if let localizedRecovery = nsError.localizedRecoverySuggestion {
                    logger.error("  Recovery suggestion: \(localizedRecovery)")
                }
            }
            
            return (false, [:])
        }
    }
    
    /// Check if all required permissions have been granted
    func checkPermissionsStatus(for metricTypes: [HealthMetricType]) async -> (Bool, [String: Bool]) {
        guard HKHealthStore.isHealthDataAvailable() else { 
            logger.warning("HealthKit is not available on this device")
            return (false, [:]) 
        }
        
        logger.debug("Checking permissions status for critical health metrics...")
        var permissionsCount = 0
        var grantedCount = 0
        var deniedPermissions: [String] = []
        
        // Dictionary to hold special permission statuses
        var specialPermissions: [String: Bool] = [:]
        
        // Check status for each critical HealthKit type only
        for metricType in metricTypes {
            if let healthKitType = metricType.healthKitType {
                permissionsCount += 1
                let status = healthStore.authorizationStatus(for: healthKitType)
                logger.debug("Permission status for \(metricType.displayName): \(self.statusToString(status))")
                
                if status == .sharingAuthorized {
                    grantedCount += 1
                    logger.debug("✅ Permission granted for \(metricType.displayName)")
                } else {
                    deniedPermissions.append(metricType.displayName)
                    logger.debug("❌ Permission not granted for \(metricType.displayName): \(status.rawValue)")
                    // Log status details to help with troubleshooting
                    switch status {
                    case .notDetermined:
                        logger.debug("   Status: Not Determined - User has not yet made a choice for \(metricType.displayName)")
                    case .sharingDenied:
                        logger.debug("   Status: Sharing Denied - User explicitly denied access to \(metricType.displayName)")
                    case .sharingAuthorized:
                        // This should not happen based on the condition above
                        logger.debug("   Status: Sharing Authorized - This should not appear in denied list")
                    @unknown default:
                        logger.debug("   Status: Unknown (\(status.rawValue)) for \(metricType.displayName)")
                    }
                }
            }
            
            // Special handling for sleep
            if metricType == .sleepHours {
                if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                    permissionsCount += 1
                    let status = healthStore.authorizationStatus(for: sleepType)
                    logger.debug("Permission status for Sleep Analysis: \(self.statusToString(status))")
                    
                    if status == .sharingAuthorized {
                        grantedCount += 1
                        logger.debug("✅ Permission granted for sleep analysis")
                    } else {
                        // Don't add "Sleep Analysis" separately, as we already track sleepHours
                        // This prevents duplicates in the error message
                        logger.debug("❌ Permission not granted for sleep analysis: \(status.rawValue)")
                        // Log detailed status information for sleep analysis
                        switch status {
                        case .notDetermined:
                            logger.debug("   Status: Not Determined - User has not yet made a choice for sleep analysis")
                        case .sharingDenied:
                            logger.debug("   Status: Sharing Denied - User explicitly denied access to sleep analysis")
                        case .sharingAuthorized:
                            // This should not happen based on the condition above
                            logger.debug("   Status: Sharing Authorized - This should not appear in denied list")
                        @unknown default:
                            logger.debug("   Status: Unknown (\(status.rawValue)) for sleep analysis")
                        }
                    }
                }
            }
        }
        
        // Special handling for weight (bodyMass)
        if let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass),
           metricTypes.contains(.bodyMass) {
            
            let status = healthStore.authorizationStatus(for: bodyMassType)
            logger.debug("Permission status for Weight (bodyMass): \(self.statusToString(status))")
            specialPermissions["weight"] = (status == .sharingAuthorized)
        }
        
        // Report overall status
        let allGranted = grantedCount == permissionsCount && permissionsCount > 0
        
        logger.debug("Permission status summary: \(grantedCount)/\(permissionsCount) granted, all granted = \(allGranted)")
        
        return (allGranted, specialPermissions)
    }
    
    /// Check the status of critical permissions
    func checkCriticalPermissionsStatus(criticalTypes: [HealthMetricType]) async -> (Bool, [String: Bool]) {
        // For MVP, we consider same set of metrics as critical
        return await checkPermissionsStatus(for: criticalTypes)
    }
    
    /// Check for permission access directly via Health store properties
    private func directHealthAppPermissionCheck() async throws {
        logger.info("--- PERFORMING DIRECT HEALTH PERMISSION CHECK ---")
        
        // Try to query recent data for Steps as a test
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            let now = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
            
            // Try to actually query for data to see if we can access it
            do {
                let sampleQuery = HKSampleQuery(sampleType: stepsType, predicate: predicate, limit: 1, sortDescriptors: nil) { (_, results, error) in
                    if let error = error {
                        self.logger.error("Direct query failed: \(error.localizedDescription)")
                    } else if let samples = results, !samples.isEmpty {
                        self.logger.info("IMPORTANT: Direct query successful - can access health data!")
                    } else {
                        self.logger.info("Direct query returned no results (possible no data yet)")
                    }
                }
                healthStore.execute(sampleQuery)
                
                // Try a second method - anchored object query
                let anchoredQuery = HKAnchoredObjectQuery(type: stepsType, predicate: predicate, anchor: nil, limit: 1) { (_, samples, _, _, error) in
                    if let error = error {
                        self.logger.error("Anchored query failed: \(error.localizedDescription)")
                    } else if let samples = samples, !samples.isEmpty {
                        self.logger.info("IMPORTANT: Anchored query successful - can access health data!")
                    } else {
                        self.logger.info("Anchored query returned no results (possible no data yet)")
                    }
                }
                healthStore.execute(anchoredQuery)
            }
        }
        
        logger.info("--- END DIRECT HEALTH PERMISSION CHECK ---")
    }
    
    /// Convert HKAuthorizationStatus to a human-readable string for logging
    private func statusToString(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .sharingDenied:
            return "Sharing Denied"
        case .sharingAuthorized:
            return "Sharing Authorized"
        @unknown default:
            return "Unknown (\(status.rawValue))"
        }
    }
    
    /// Log which permissions were denied
    private func logDeniedPermissions(types: [HealthMetricType]) {
        var deniedPermissions: [String] = []
        
        for metricType in types {
            if let healthKitType = metricType.healthKitType {
                let status = healthStore.authorizationStatus(for: healthKitType)
                if status != .sharingAuthorized {
                    deniedPermissions.append(metricType.displayName)
                }
            }
            
            // Special handling for sleep
            if metricType == .sleepHours {
                if let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
                    let status = healthStore.authorizationStatus(for: sleepType)
                    if status != .sharingAuthorized {
                        deniedPermissions.append("Sleep Analysis")
                    }
                }
            }
        }
        
        if !deniedPermissions.isEmpty {
            logger.warning("Permissions denied for: \(deniedPermissions.joined(separator: ", "))")
        }
    }
} 