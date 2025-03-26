//
//  AmpedUITests.swift
//  AmpedUITests
//
//  Created by Matt Snow on 3/23/25.
//

import XCTest

final class AmpedUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
        
        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests.
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /// Test the onboarding flow from welcome screen to dashboard
    func testOnboardingFlow() throws {
        let app = XCUIApplication()
        
        // Welcome screen
        XCTAssertTrue(app.staticTexts["Power Up Your Life"].exists, "Welcome title should be visible")
        app.buttons["Get Started"].tap()
        
        // Personalization screen
        XCTAssertTrue(app.staticTexts["Power Up Your Experience"].exists, "Personalization intro should be visible")
        app.swipeLeft()
        
        // Questionnaire
        XCTAssertTrue(app.staticTexts["Quick Questions"].exists, "Questionnaire title should be visible")
        
        // Iterate through all questions
        while app.buttons["Next"].exists {
            // For each question type, we'll need to provide an answer
            if app.sliders.count > 0 {
                app.sliders.firstMatch.adjust(toNormalizedSliderPosition: 0.5)
            } else if app.segmentedControls.count > 0 {
                app.segmentedControls.buttons.firstMatch.tap()
            } else if app.switches.count > 0 {
                app.switches.firstMatch.tap()
            }
            
            app.buttons["Next"].tap()
        }
        
        // HealthKit permissions
        XCTAssertTrue(app.staticTexts["Health Access"].exists, "HealthKit permission screen should be visible")
        
        // Tap "Allow Health Access" to simulate HealthKit permission grant
        // Note: This won't actually trigger system permission UI in test mode
        app.buttons["Allow Health Access"].tap()
        
        // Sign in with Apple
        XCTAssertTrue(app.staticTexts["Secure Account"].exists, "Sign in screen should be visible")
        
        // Skip sign in for testing
        app.buttons["Skip For Now"].tap()
        
        // Payment screen
        XCTAssertTrue(app.staticTexts["Unlock Full Power"].exists, "Payment screen should be visible")
        
        // Skip payment for testing
        app.buttons["Continue with Free"].tap()
        
        // Verify we reach the dashboard
        XCTAssertTrue(app.navigationBars["Battery Status"].waitForExistence(timeout: 5), 
                     "Should reach the dashboard")
    }
    
    /// Test basic dashboard interactions
    func testDashboardInteractions() throws {
        // Skip to dashboard (would use helper or test mode flag in real app)
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting", "-SkipOnboarding"]
        app.terminate()
        app.launch()
        
        // Verify dashboard components
        XCTAssertTrue(app.navigationBars["Battery Status"].exists, "Dashboard title should be visible")
        
        // Test period selector
        XCTAssertTrue(app.buttons["Day"].exists, "Period selector should be visible")
        app.buttons["Month"].tap()
        app.buttons["Year"].tap()
        app.buttons["Day"].tap()
        
        // Test battery cards exist
        XCTAssertTrue(app.staticTexts["Today's Impact"].exists, "Impact battery should be visible")
        XCTAssertTrue(app.staticTexts["Life Projection"].exists, "Projection battery should be visible")
        
        // Test metric card interaction
        app.scrollViews.firstMatch.swipeUp()
        
        let metricCards = app.descendants(matching: .any).matching(identifier: "MetricCard")
        if metricCards.count > 0 {
            metricCards.firstMatch.tap()
            
            // Verify metric detail screen
            XCTAssertTrue(app.staticTexts["Impact Details"].waitForExistence(timeout: 2), 
                         "Metric detail screen should open")
            
            // Test recommendations section
            XCTAssertTrue(app.staticTexts["Recommendations"].exists, "Recommendations should be visible")
            
            // Go back
            app.buttons["Done"].tap()
        }
    }
    
    /// Test settings screen
    func testSettingsScreen() throws {
        // Skip to dashboard (would use helper or test mode flag in real app)
        let app = XCUIApplication()
        app.launchArguments = ["-UITesting", "-SkipOnboarding"]
        app.terminate()
        app.launch()
        
        // Open settings (this would depend on your actual UI)
        app.buttons["Settings"].tap()
        
        // Verify settings screen
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2), 
                     "Settings screen should open")
        
        // Test toggle interactions
        let toggles = app.switches.allElementsBoundByIndex
        if toggles.count > 0 {
            toggles[0].tap() // Toggle first setting
        }
        
        // Test picker interaction
        let pickers = app.pickers.allElementsBoundByIndex
        if pickers.count > 0 {
            pickers[0].tap()
        }
        
        // Dismiss settings
        app.buttons["Done"].tap()
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
