//
//  SignInPopupTests.swift
//  AmpedTests
//
//  Created by Assistant on 8/18/2025.
//

import XCTest
@testable import Amped

/// Tests for Sign in with Apple popup logic and persistence
@MainActor
final class SignInPopupTests: XCTestCase {
    
    var appState: AppState!
    
    override func setUp() async throws {
        // Clear UserDefaults before each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "appLaunchCount")
        defaults.removeObject(forKey: "isAuthenticated")
        defaults.removeObject(forKey: "hasUserPermanentlyDismissedSignIn")
        
        // Create fresh AppState for each test
        appState = AppState()
    }
    
    override func tearDown() async throws {
        appState = nil
        
        // Clean up UserDefaults after each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "appLaunchCount")
        defaults.removeObject(forKey: "isAuthenticated")
        defaults.removeObject(forKey: "hasUserPermanentlyDismissedSignIn")
    }
    
    // MARK: - Sign-In Popup Logic Tests
    
    func testSignInPopupDoesNotShowOnFirstAppLaunch() {
        // Setup: First app launch, onboarding completed
        appState.completeOnboarding()
        appState.incrementAppLaunchCount() // First launch
        
        // Test: Should not show popup on first launch
        let shouldShow = shouldShowSignInPopup()
        XCTAssertFalse(shouldShow, "Sign-in popup should not show on first app launch")
    }
    
    func testSignInPopupShowsOnSecondAppLaunch() {
        // Setup: Second app launch, onboarding completed, not authenticated
        appState.completeOnboarding()
        appState.incrementAppLaunchCount() // First launch
        appState.incrementAppLaunchCount() // Second launch
        
        // Test: Should show popup on second launch
        let shouldShow = shouldShowSignInPopup()
        XCTAssertTrue(shouldShow, "Sign-in popup should show on second app launch")
    }
    
    func testSignInPopupDoesNotShowIfAlreadyAuthenticated() {
        // Setup: Second app launch, onboarding completed, authenticated
        appState.completeOnboarding()
        appState.incrementAppLaunchCount() // First launch
        appState.incrementAppLaunchCount() // Second launch
        appState.setAuthenticated(true)
        
        // Test: Should not show popup if already authenticated
        let shouldShow = shouldShowSignInPopup()
        XCTAssertFalse(shouldShow, "Sign-in popup should not show if user is already authenticated")
    }
    
    func testSignInPopupDoesNotShowIfPermanentlyDismissed() {
        // Setup: Second app launch, onboarding completed, not authenticated, but permanently dismissed
        appState.completeOnboarding()
        appState.incrementAppLaunchCount() // First launch
        appState.incrementAppLaunchCount() // Second launch
        appState.markSignInPermanentlyDismissed()
        
        // Test: Should not show popup if permanently dismissed
        let shouldShow = shouldShowSignInPopup()
        XCTAssertFalse(shouldShow, "Sign-in popup should not show if permanently dismissed")
    }
    
    func testSignInPopupDoesNotShowOnThirdAppLaunch() {
        // Setup: Third app launch, onboarding completed, not authenticated
        appState.completeOnboarding()
        appState.incrementAppLaunchCount() // First launch
        appState.incrementAppLaunchCount() // Second launch
        appState.incrementAppLaunchCount() // Third launch
        
        // Test: Should not show popup on third launch
        let shouldShow = shouldShowSignInPopup()
        XCTAssertFalse(shouldShow, "Sign-in popup should only show on second app launch, not third")
    }
    
    func testSignInPopupDoesNotShowIfOnboardingNotCompleted() {
        // Setup: Second app launch, onboarding NOT completed
        appState.incrementAppLaunchCount() // First launch
        appState.incrementAppLaunchCount() // Second launch
        
        // Test: Should not show popup if onboarding not completed
        let shouldShow = shouldShowSignInPopup()
        XCTAssertFalse(shouldShow, "Sign-in popup should not show if onboarding is not completed")
    }
    
    // MARK: - Authentication State Persistence Tests
    
    func testAuthenticationStatePersists() {
        // Test: Set authenticated and verify it persists
        appState.setAuthenticated(true)
        
        // Verify the state is persisted to UserDefaults
        let isAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        XCTAssertTrue(isAuthenticated, "Authentication state should be persisted to UserDefaults")
        XCTAssertTrue(appState.isAuthenticated, "AppState should reflect authenticated status")
    }
    
    func testAuthenticationAutomaticallyMarksPermanentDismissal() {
        // Test: Authentication should automatically mark popup as permanently dismissed
        appState.setAuthenticated(true)
        
        XCTAssertTrue(appState.hasUserPermanentlyDismissedSignIn, "Authentication should automatically mark sign-in as permanently dismissed")
        
        // Verify it's persisted to UserDefaults
        let isPermanentlyDismissed = UserDefaults.standard.bool(forKey: "hasUserPermanentlyDismissedSignIn")
        XCTAssertTrue(isPermanentlyDismissed, "Permanent dismissal should be persisted to UserDefaults")
    }
    
    func testPermanentDismissalPersists() {
        // Test: Permanent dismissal state persists
        appState.markSignInPermanentlyDismissed()
        
        XCTAssertTrue(appState.hasUserPermanentlyDismissedSignIn, "AppState should reflect permanent dismissal")
        
        // Verify it's persisted to UserDefaults
        let isPermanentlyDismissed = UserDefaults.standard.bool(forKey: "hasUserPermanentlyDismissedSignIn")
        XCTAssertTrue(isPermanentlyDismissed, "Permanent dismissal should be persisted to UserDefaults")
    }
    
    // MARK: - State Loading Tests
    
    func testAuthenticationStateLoadsOnAppStart() {
        // Setup: Set authentication in UserDefaults
        UserDefaults.standard.set(true, forKey: "isAuthenticated")
        UserDefaults.standard.set(true, forKey: "hasUserPermanentlyDismissedSignIn")
        UserDefaults.standard.set(5, forKey: "appLaunchCount")
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        
        // Create new AppState to test loading
        let newAppState = AppState()
        
        // Verify states are loaded correctly
        XCTAssertTrue(newAppState.isAuthenticated, "Authentication state should be loaded from UserDefaults")
        XCTAssertTrue(newAppState.hasUserPermanentlyDismissedSignIn, "Permanent dismissal state should be loaded from UserDefaults")
        XCTAssertEqual(newAppState.appLaunchCount, 5, "App launch count should be loaded from UserDefaults")
        XCTAssertTrue(newAppState.hasCompletedOnboarding, "Onboarding completion should be loaded from UserDefaults")
    }
    
    // MARK: - Helper Methods
    
    /// Helper method that mimics the logic in DashboardView.checkAndShowSignInIfNeeded()
    private func shouldShowSignInPopup() -> Bool {
        return appState.hasCompletedOnboarding && 
               !appState.isAuthenticated && 
               appState.appLaunchCount == 2 && 
               !appState.hasUserPermanentlyDismissedSignIn &&
               !appState.hasShownSignInPopupThisSession
    }
}

// MARK: - Integration Test Documentation

/*
 MANUAL TESTING GUIDE:
 
 To test the Sign in with Apple popup behavior manually:
 
 1. FIRST APP LAUNCH TEST:
    - Delete and reinstall the app
    - Complete the entire onboarding flow
    - Verify NO sign-in popup appears on the dashboard
 
 2. SECOND APP LAUNCH TEST:
    - Force quit the app (swipe up and swipe away)
    - Reopen the app
    - Verify the sign-in popup APPEARS on the dashboard
    - Verify the popup uses the new glass theme styling
 
 3. PERMANENT DISMISSAL TEST:
    - When the popup appears, tap "Maybe later"
    - Force quit and reopen the app multiple times
    - Verify the popup NEVER appears again
 
 4. AUTHENTICATION TEST:
    - Reset the app (delete and reinstall)
    - Complete onboarding, force quit, reopen (popup should appear)
    - Tap "Continue with Apple" and complete authentication
    - Force quit and reopen the app multiple times
    - Verify the popup NEVER appears again
 
 5. THEME VERIFICATION:
    - When the popup appears, verify it has:
      - Glass background with blur effects
      - Consistent spacing and typography with other app cards
      - Apple logo icon in the header
      - Benefits listed with icons
      - Themed "Maybe later" button
      - Smooth animations matching the app's style
 
 Expected Results:
 - Popup shows ONLY on the second app launch
 - Once dismissed (either way), it never shows again
 - All dismissal preferences are persisted across app restarts
 - The popup matches the app's glass theme design system
 */
