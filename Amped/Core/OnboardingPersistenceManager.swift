//
//  OnboardingPersistenceManager.swift
//  Amped
//
//  Created by Assistant on 8/17/2025.
//

import SwiftUI
import Foundation
import OSLog

/// Manages onboarding persistence with soft close vs hard close detection
@MainActor
final class OnboardingPersistenceManager: ObservableObject {
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.app", 
                               category: "OnboardingPersistence")
    
    // UserDefaults keys
    private let currentStepKey = "currentOnboardingStep"
    private let lastSaveTimestampKey = "onboardingLastSaveTimestamp"
    private let appLaunchTimestampKey = "appLaunchTimestamp"
    private let cleanTerminationKey = "appTerminatedCleanly"
    private let sessionStartKey = "onboardingSessionStart"
    
    // Time threshold for determining hard vs soft close (30 seconds)
    private let hardCloseThreshold: TimeInterval = 30.0
    
    // MARK: - Public Methods
    
    /// Detect if the app was soft closed (backgrounded) or hard closed (terminated)
    /// - Returns: true if soft close, false if hard close
    func detectClosureType() -> ClosureType {
        let currentTimestamp = Date().timeIntervalSince1970
        let lastSaveTimestamp = UserDefaults.standard.double(forKey: lastSaveTimestampKey)
        let wasCleanTermination = UserDefaults.standard.bool(forKey: cleanTerminationKey)
        
        // DEBUG: Always log the detection details
        print("🔍 CLOSURE DEBUG:")
        print("   currentTimestamp: \(currentTimestamp)")
        print("   lastSaveTimestamp: \(lastSaveTimestamp)")
        print("   wasCleanTermination: \(wasCleanTermination)")
        print("   hardCloseThreshold: \(hardCloseThreshold)")
        
        // If no previous save timestamp, this is a fresh launch
        if lastSaveTimestamp == 0 {
            print("   RESULT: Fresh app launch -> HARD CLOSE")
            logger.info("Fresh app launch detected")
            return .hardClose
        }
        
        let timeDifference = currentTimestamp - lastSaveTimestamp
        print("   timeDifference: \(timeDifference) seconds")
        
        // FIXED LOGIC: Hard close detection with reasonable threshold
        // 1. If app wasn't cleanly terminated (force quit) -> always hard close
        // 2. If app was cleanly terminated but time > 5 seconds -> hard close  
        // 3. If app was cleanly terminated and time < 5 seconds -> soft close
        
        if !wasCleanTermination {
            print("   RESULT: No clean termination -> HARD CLOSE")
            logger.info("Hard close detected - app was force quit (no clean termination)")
            return .hardClose
        }
        
        if timeDifference > 5.0 {
            print("   RESULT: Long time gap (\(timeDifference)s) -> HARD CLOSE")
            logger.info("Hard close detected - time difference: \(timeDifference) seconds")
            return .hardClose
        }
        
        print("   RESULT: Short time gap (\(timeDifference)s) + clean termination -> SOFT CLOSE")
        logger.info("Soft close detected - restoring onboarding position")
        return .softClose
    }
    
    /// Save onboarding progress for soft close scenarios
    /// - Parameters:
    ///   - step: Current onboarding step
    ///   - hasCompletedOnboarding: Whether onboarding is complete
    func saveOnboardingProgress(_ step: OnboardingStep, hasCompletedOnboarding: Bool) {
        guard !hasCompletedOnboarding else {
            // Don't save progress if onboarding is complete
            clearOnboardingProgress()
            return
        }
        
        let timestamp = Date().timeIntervalSince1970
        
        UserDefaults.standard.set(step.name, forKey: currentStepKey)
        UserDefaults.standard.set(timestamp, forKey: lastSaveTimestampKey)
        UserDefaults.standard.set(false, forKey: cleanTerminationKey) // Will be set to true on clean termination
        
        logger.info("Saved onboarding progress: \(step.name) at \(timestamp)")
    }
    
    /// Load onboarding progress based on closure type
    /// - Parameter closureType: Type of app closure (soft or hard)
    /// - Returns: Onboarding step to restore, or nil if should start fresh
    func loadOnboardingProgress(closureType: ClosureType) -> OnboardingStep? {
        switch closureType {
        case .softClose:
            // Restore exact position for soft close
            if let savedStepRaw = UserDefaults.standard.object(forKey: currentStepKey) as? String,
               let savedStep = OnboardingStep(rawValue: savedStepRaw) {
                logger.info("Restored onboarding progress: \(savedStep.name) (soft close)")
                return savedStep
            }
            logger.warning("No saved onboarding step found for soft close")
            return .welcome
            
        case .hardClose:
            // Reset to welcome for hard close
            logger.info("Starting fresh onboarding (hard close)")
            clearOnboardingProgress()
            return .welcome
        }
    }
    
    /// Mark app as starting (called on app launch)
    func markAppLaunchStart() {
        let timestamp = Date().timeIntervalSince1970
        UserDefaults.standard.set(timestamp, forKey: appLaunchTimestampKey)
        UserDefaults.standard.set(false, forKey: cleanTerminationKey)
        
        logger.info("App launch started at \(timestamp)")
    }
    
    /// Mark app as entering background (soft close)
    func markAppEnteringBackground() {
        UserDefaults.standard.set(true, forKey: cleanTerminationKey)
        logger.info("App entering background - marked as clean termination")
    }
    
    /// Clear all onboarding progress (for hard close or completion)
    func clearOnboardingProgress() {
        UserDefaults.standard.removeObject(forKey: currentStepKey)
        UserDefaults.standard.removeObject(forKey: lastSaveTimestampKey)
        UserDefaults.standard.removeObject(forKey: sessionStartKey)
        
        // Also clear related onboarding data
        UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")
        UserDefaults.standard.removeObject(forKey: "userName")
        
        logger.info("Cleared all onboarding progress")
    }
    
    /// Reset all persistence data (for testing/debugging)
    func resetAllData() {
        clearOnboardingProgress()
        UserDefaults.standard.removeObject(forKey: appLaunchTimestampKey)
        UserDefaults.standard.removeObject(forKey: cleanTerminationKey)
        
        logger.info("Reset all persistence data")
    }
}

// MARK: - Supporting Types

/// Represents the type of app closure
enum ClosureType {
    case softClose  // App was backgrounded but still running
    case hardClose  // App was fully terminated
}
