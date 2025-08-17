//
//  OnboardingPersistenceTests.swift
//  AmpedTests
//
//  Created by Assistant on 8/17/2025.
//

import XCTest
@testable import Amped

@MainActor
final class OnboardingPersistenceTests: XCTestCase {
    
    var persistenceManager: OnboardingPersistenceManager!
    
    override func setUp() {
        super.setUp()
        persistenceManager = OnboardingPersistenceManager()
        // Clean up any existing data
        persistenceManager.resetAllData()
    }
    
    override func tearDown() {
        // Clean up after each test
        persistenceManager.resetAllData()
        persistenceManager = nil
        super.tearDown()
    }
    
    // MARK: - Fresh Launch Tests
    
    func testFreshLaunchDetection() {
        // Test that a fresh launch (no saved data) is detected as hard close
        let closureType = persistenceManager.detectClosureType()
        XCTAssertEqual(closureType, .hardClose, "Fresh launch should be detected as hard close")
    }
    
    // MARK: - Soft Close Tests
    
    func testSoftCloseDetection() {
        // Simulate app launch and backgrounding
        persistenceManager.markAppLaunchStart()
        persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        persistenceManager.markAppEnteringBackground()
        
        // Simulate immediate return (soft close)
        let closureType = persistenceManager.detectClosureType()
        XCTAssertEqual(closureType, .softClose, "Recent backgrounding should be detected as soft close")
    }
    
    func testSoftCloseRestoration() {
        // Save progress and mark as background
        persistenceManager.markAppLaunchStart()
        persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        persistenceManager.markAppEnteringBackground()
        
        // Load progress for soft close
        let restoredStep = persistenceManager.loadOnboardingProgress(closureType: .softClose)
        XCTAssertEqual(restoredStep, .questionnaire, "Soft close should restore exact step")
    }
    
    // MARK: - Hard Close Tests
    
    func testHardCloseDetection() {
        // Simulate app launch and saving progress
        persistenceManager.markAppLaunchStart()
        persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        // Don't mark as entering background (simulate force quit)
        
        // Wait to simulate time passage (we can't actually wait, so we'll modify the timestamp)
        let futureTimestamp = Date().timeIntervalSince1970 + 60.0 // 1 minute later
        UserDefaults.standard.set(futureTimestamp, forKey: "appLaunchTimestamp")
        
        let closureType = persistenceManager.detectClosureType()
        XCTAssertEqual(closureType, .hardClose, "Force quit with time gap should be detected as hard close")
    }
    
    func testHardCloseRestoration() {
        // Save some progress first
        persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        
        // Load progress for hard close (should return welcome)
        let restoredStep = persistenceManager.loadOnboardingProgress(closureType: .hardClose)
        XCTAssertEqual(restoredStep, .welcome, "Hard close should reset to welcome screen")
    }
    
    // MARK: - Progress Save/Load Tests
    
    func testProgressSaving() {
        // Test that progress is saved correctly
        persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        
        // Verify the data was saved
        let savedStep = UserDefaults.standard.string(forKey: "currentOnboardingStep")
        XCTAssertEqual(savedStep, "questionnaire", "Progress should be saved to UserDefaults")
        
        let timestamp = UserDefaults.standard.double(forKey: "onboardingLastSaveTimestamp")
        XCTAssertGreaterThan(timestamp, 0, "Timestamp should be saved")
    }
    
    func testProgressNotSavedWhenComplete() {
        // Test that progress is not saved when onboarding is complete
        persistenceManager.saveOnboardingProgress(.dashboard, hasCompletedOnboarding: true)
        
        // Verify no data was saved
        let savedStep = UserDefaults.standard.string(forKey: "currentOnboardingStep")
        XCTAssertNil(savedStep, "Progress should not be saved when onboarding is complete")
    }
    
    // MARK: - Data Cleanup Tests
    
    func testDataCleanup() {
        // Save some progress first
        persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        UserDefaults.standard.set("TestUser", forKey: "userName")
        
        // Clear the data
        persistenceManager.clearOnboardingProgress()
        
        // Verify data was cleared
        let savedStep = UserDefaults.standard.string(forKey: "currentOnboardingStep")
        let userName = UserDefaults.standard.string(forKey: "userName")
        
        XCTAssertNil(savedStep, "Onboarding step should be cleared")
        XCTAssertNil(userName, "User name should be cleared")
    }
    
    func testResetAllData() {
        // Save various pieces of data
        persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        persistenceManager.markAppLaunchStart()
        persistenceManager.markAppEnteringBackground()
        
        // Reset all data
        persistenceManager.resetAllData()
        
        // Verify everything was cleared
        let savedStep = UserDefaults.standard.string(forKey: "currentOnboardingStep")
        let timestamp = UserDefaults.standard.double(forKey: "onboardingLastSaveTimestamp")
        let launchTimestamp = UserDefaults.standard.double(forKey: "appLaunchTimestamp")
        let cleanTermination = UserDefaults.standard.bool(forKey: "appTerminatedCleanly")
        
        XCTAssertNil(savedStep, "Step should be cleared")
        XCTAssertEqual(timestamp, 0, "Save timestamp should be cleared")
        XCTAssertEqual(launchTimestamp, 0, "Launch timestamp should be cleared")
        XCTAssertFalse(cleanTermination, "Clean termination flag should be cleared")
    }
    
    // MARK: - Edge Case Tests
    
    func testInvalidStepHandling() {
        // Save an invalid step manually
        UserDefaults.standard.set("invalidStep", forKey: "currentOnboardingStep")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "onboardingLastSaveTimestamp")
        persistenceManager.markAppEnteringBackground()
        
        // Try to load progress
        let restoredStep = persistenceManager.loadOnboardingProgress(closureType: .softClose)
        XCTAssertEqual(restoredStep, .welcome, "Invalid step should default to welcome")
    }
    
    func testMissingDataHandling() {
        // Clear all data and try to restore from soft close
        persistenceManager.resetAllData()
        
        let restoredStep = persistenceManager.loadOnboardingProgress(closureType: .softClose)
        XCTAssertEqual(restoredStep, .welcome, "Missing data should default to welcome")
    }
    
    // MARK: - Performance Tests
    
    func testDetectionPerformance() {
        // Set up some data
        persistenceManager.markAppLaunchStart()
        persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        persistenceManager.markAppEnteringBackground()
        
        // Measure detection performance
        measure {
            _ = persistenceManager.detectClosureType()
        }
    }
    
    func testSavePerformance() {
        // Measure save performance
        measure {
            persistenceManager.saveOnboardingProgress(.questionnaire, hasCompletedOnboarding: false)
        }
    }
}

// MARK: - Integration Tests

@MainActor
final class OnboardingPersistenceIntegrationTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() {
        super.setUp()
        appState = AppState()
        // Reset to clean state
        appState.resetOnboarding()
    }
    
    override func tearDown() {
        appState.resetOnboarding()
        appState = nil
        super.tearDown()
    }
    
    func testAppStateIntegration() {
        // Test that AppState properly integrates with persistence manager
        appState.updateOnboardingStep(.questionnaire)
        
        // Verify the step was saved
        let savedStep = UserDefaults.standard.string(forKey: "currentOnboardingStep")
        XCTAssertEqual(savedStep, "questionnaire", "AppState should save step through persistence manager")
    }
    
    func testOnboardingCompletion() {
        // Set up onboarding in progress
        appState.updateOnboardingStep(.payment)
        
        // Complete onboarding
        appState.completeOnboarding()
        
        // Verify progress was cleared
        let savedStep = UserDefaults.standard.string(forKey: "currentOnboardingStep")
        XCTAssertNil(savedStep, "Progress should be cleared when onboarding completes")
        XCTAssertTrue(appState.hasCompletedOnboarding, "Onboarding should be marked as complete")
    }
    
    func testResetFunctionality() {
        // Set up some state
        appState.updateOnboardingStep(.payment)
        appState.completeOnboarding()
        
        // Reset
        appState.resetOnboarding()
        
        // Verify reset
        XCTAssertFalse(appState.hasCompletedOnboarding, "Onboarding should be reset")
        XCTAssertEqual(appState.currentOnboardingStep, .welcome, "Step should be reset to welcome")
    }
}
