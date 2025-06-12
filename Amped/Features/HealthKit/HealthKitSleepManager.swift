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
    
    /// Process sleep data for a specific day using Apple Health methodology
    func processSleepData(from startDate: Date, to endDate: Date) async -> HealthMetric? {
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.warning("HealthKit is not available for sleep processing")
            return nil
        }
        
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            logger.warning("Sleep analysis type is not available")
            return nil
        }
        
        // CRITICAL FIX: Calculate sleep for the day being queried (endDate)
        // Apple Health attributes sleep to the day you wake up, using a 3pm cutoff rule
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: endDate)
        
        // Create search range: from 3pm the day before to 3pm on the target day
        // This captures all sleep that should be attributed to the target day
        let threePM = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: targetDay)!
        let searchStartDate = calendar.date(byAdding: .day, value: -1, to: threePM)!
        let searchEndDate = threePM
        
        logger.info("🛏️ Calculating sleep for day: \(targetDay)")
        logger.info("🔍 Searching sleep data from \(searchStartDate) to \(searchEndDate)")
        
        let predicate = HKQuery.predicateForSamples(
            withStart: searchStartDate,
            end: searchEndDate,
            options: .strictStartDate
        )
        
        do {
            // Execute the query with async/await pattern
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    continuation.resume(returning: samples ?? [])
                }
                
                self.healthStore.execute(query)
            }
            
            logger.info("📊 Found \(samples.count) total sleep samples in search range")
            
            if samples.isEmpty {
                logger.info("No sleep samples found in the specified period")
                return nil
            }
            
            // CRITICAL FIX: Use Apple's methodology - filter for all asleep values and apply 3pm rule
            var totalSleepDuration: TimeInterval = 0
            var latestSleepEndDate: Date = Date.distantPast
            var validSleepSamples = 0
            
            for sample in samples {
                guard let categorySample = sample as? HKCategorySample else { continue }
                
                // CRITICAL FIX: Only count actual ASLEEP states, exclude inBed time
                // Apple Health counts only: asleepUnspecified, asleepCore, asleepDeep, asleepREM
                // NOTE: Excluding inBed as it represents time in bed but not necessarily asleep
                let sleepValue = categorySample.value
                if sleepValue == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   sleepValue == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sleepValue == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sleepValue == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    
                    let sleepDuration = categorySample.endDate.timeIntervalSince(categorySample.startDate)
                    
                    // Apply 3pm cutoff rule: if sleep starts after 3pm, it belongs to the next day
                    let sleepStartDay = calendar.startOfDay(for: categorySample.startDate)
                    let threePMOnSleepDay = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: sleepStartDay)!
                    
                    let sleepAttributionDay: Date
                    if categorySample.startDate >= threePMOnSleepDay {
                        // Sleep starts after 3pm, belongs to next day
                        sleepAttributionDay = calendar.date(byAdding: .day, value: 1, to: sleepStartDay)!
                    } else {
                        // Sleep starts before 3pm, belongs to same day
                        sleepAttributionDay = sleepStartDay
                    }
                    
                    // Only count sleep that's attributed to our target day
                    if calendar.isDate(sleepAttributionDay, inSameDayAs: targetDay) {
                        totalSleepDuration += sleepDuration
                        validSleepSamples += 1
                        
                        // Track the latest end date for our metric
                        if categorySample.endDate > latestSleepEndDate {
                            latestSleepEndDate = categorySample.endDate
                        }
                        
                        logger.info("✅ ADDED Sleep Sample: \(String(format: "%.2f", sleepDuration/3600.0))h (\(sleepDuration/60.0) min) from \(categorySample.startDate) to \(categorySample.endDate) - State: \(sleepValue)")
                    } else {
                        logger.debug("⏭️ Skipped sleep sample (wrong day): \(sleepDuration/3600.0) hours attributed to \(sleepAttributionDay) instead of \(targetDay)")
                    }
                } else {
                    // Log excluded sleep states for debugging
                    let sleepDuration = categorySample.endDate.timeIntervalSince(categorySample.startDate)
                    let stateName: String
                    switch sleepValue {
                    case HKCategoryValueSleepAnalysis.inBed.rawValue:
                        stateName = "inBed"
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        stateName = "awake"
                    default:
                        stateName = "unknown(\(sleepValue))"
                    }
                    logger.info("🚫 EXCLUDED Sleep Sample: \(String(format: "%.2f", sleepDuration/3600.0))h (\(sleepDuration/60.0) min) from \(categorySample.startDate) to \(categorySample.endDate) - State: \(stateName)")
                }
            }
            
            logger.info("📈 Total sleep for \(targetDay): \(totalSleepDuration/3600.0) hours from \(validSleepSamples) samples")
            
            // Only create metric if we have valid sleep data
            guard totalSleepDuration > 0 else {
                logger.info("No valid sleep data found for the target day")
                return nil
            }
            
            // Convert to hours
            let sleepHours = totalSleepDuration / 3600.0
            
            // Only create metric if we have reasonable sleep data (between 0.5-16 hours)
            if sleepHours >= 0.5 && sleepHours <= 16.0 {
                return HealthMetric(
                    id: UUID().uuidString,
                    type: .sleepHours,
                    value: sleepHours,
                                         date: latestSleepEndDate == Date.distantPast ? endDate : latestSleepEndDate,
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
            
            // When sleep data changes, process the updated data for today
            Task { [weak self] in
                // Create strong reference to avoid capture issues
                guard let self = self else {
                    completionHandler()
                    return
                }
                
                // Process sleep data for today
                let today = Date()
                let sleepMetric = await self.processSleepData(from: today, to: today)
                
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