import Foundation
import HealthKit
import OSLog
@preconcurrency import Combine

/// Manages sleep-related HealthKit functionality
@MainActor final class HealthKitSleepManager {
    private let healthStore: HKHealthStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "HealthKitSleepManager")
    
    init(healthStore: HKHealthStore) {
        self.healthStore = healthStore
    }
    
    /// Process sleep data which requires special handling
    func processSleepData(from startDate: Date, to endDate: Date) async -> HealthMetric? {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit is not available for sleep processing")
            return nil
        }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.warning("Sleep analysis type is not available")
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictEndDate
        )
        
        do {
            // Execute the query with async/await pattern
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)] // Sort by most recent first
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: samples ?? [])
                }
                
                self.healthStore.execute(query)
            }
            
            // CRITICAL FIX: Instead of summing ALL sleep over 7 days, find the most recent night's sleep
            // Group samples by day and get the most recent complete sleep session
            
            if samples.isEmpty {
                logger.info("No sleep samples found in the specified period")
                return nil
            }
            
            // Find the most recent sleep session (group samples that are close together)
            var recentSleepTime: TimeInterval = 0
            var latestSleepDate: Date = Date.distantPast
            
            // Group samples by calendar day to find the most recent complete sleep
            let calendar = Calendar.current
            var sleepByDate: [Date: TimeInterval] = [:]
            
            for sample in samples {
                guard let categorySample = sample as? HKCategorySample else { continue }
                
                // Count only asleep states
                if categorySample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                   categorySample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue {
                    
                    let sleepTime = categorySample.endDate.timeIntervalSince(categorySample.startDate)
                    let sleepDay = calendar.startOfDay(for: categorySample.endDate)
                    
                    sleepByDate[sleepDay, default: 0] += sleepTime
                    
                    // Track the latest sleep date
                    if categorySample.endDate > latestSleepDate {
                        latestSleepDate = categorySample.endDate
                    }
                }
            }
            
            // Get the most recent day's sleep
            if let mostRecentDay = sleepByDate.keys.max(),
               let mostRecentSleep = sleepByDate[mostRecentDay] {
                recentSleepTime = mostRecentSleep
                logger.info("Found most recent sleep session: \(recentSleepTime / 3600.0) hours on \(mostRecentDay)")
            } else {
                logger.info("No valid sleep data found in samples")
                return nil
            }
            
            // Convert to hours
            let sleepHours = recentSleepTime / 3600.0
            
            // Only create metric if we have valid sleep data (between 1-16 hours is reasonable)
            if sleepHours > 1.0 && sleepHours < 16.0 {
                return HealthMetric(
                    id: UUID().uuidString,
                    type: .sleepHours,
                    value: sleepHours,
                    date: latestSleepDate,
                    source: .healthKit
                )
            } else {
                logger.warning("Invalid sleep duration calculated: \(sleepHours) hours - outside reasonable range")
                return nil
            }
            
        } catch {
            logger.error("Error processing sleep data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Set up an observer for sleep changes
    func observeSleepChanges(onCancellable: @escaping (AnyCancellable) -> Void) -> AnyPublisher<HealthMetric?, Error> {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return Fail(error: NSError(domain: "com.amped.Amped", code: 3, userInfo: [NSLocalizedDescriptionKey: "Sleep analysis type is not available"]))
                .eraseToAnyPublisher()
        }
        
        // Create a subject for sleep updates
        let subject = PassthroughSubject<HealthMetric?, Error>()
        
        // Set up the query to observe sleep changes
        let query = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, completionHandler, error in
            // This closure executes on a background thread
            if let error = error {
                Task { @MainActor in
                    self?.logger.error("Sleep observer query error: \(error.localizedDescription)")
                    subject.send(completion: .failure(error))
                }
                completionHandler()
                return
            }
            
            // When sleep data changes, process the updated data
            Task { [weak self] in
                // Create strong reference to avoid capture issues
                guard let self = self else {
                    completionHandler()
                    return
                }
                
                // Process sleep data on the background
                let sleepMetric = await self.processSleepData(from: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, to: Date())
                
                // Update sleep metrics on the main thread
                await MainActor.run {
                    subject.send(sleepMetric)
                }
                
                completionHandler()
            }
        }
        
        // Execute the query
        healthStore.execute(query)
        
        // Create the cancellable
        let cancellable = AnyCancellable {
            self.healthStore.stop(query)
        }
        
        // Use the callback to store the cancellable
        onCancellable(cancellable)
        
        return subject.eraseToAnyPublisher()
    }
} 