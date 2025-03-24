import XCTest
@testable import Amped

/// Unit tests for the LifeImpactService
final class LifeImpactServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    /// Subject under test
    var lifeImpactService: LifeImpactService!
    
    /// Sample user profile for testing
    var testUserProfile: UserProfile!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        
        // Create a test user profile
        testUserProfile = UserProfile(
            id: "test-user-id",
            birthYear: 1990,
            gender: .male,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true
        )
        
        // Initialize the service with the test profile
        lifeImpactService = LifeImpactService(userProfile: testUserProfile)
    }
    
    override func tearDown() {
        lifeImpactService = nil
        testUserProfile = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Test that positive steps impact results in positive lifespan impact
    func testStepsPositiveImpact() {
        // Given
        let stepsMetric = HealthMetric(
            id: UUID().uuidString,
            type: .steps,
            value: 12000, // Above target value, should be positive
            date: Date()
        )
        
        // When
        let impact = lifeImpactService.calculateImpact(for: stepsMetric)
        
        // Then
        XCTAssertNotNil(impact, "Impact should not be nil")
        XCTAssertGreaterThan(impact.lifespanImpactMinutes, 0, "Steps above target should have positive impact")
        XCTAssertEqual(impact.comparisonToBaseline, .aboveTarget, "Comparison should be above target")
    }
    
    /// Test that negative steps impact results in negative lifespan impact
    func testStepsNegativeImpact() {
        // Given
        let stepsMetric = HealthMetric(
            id: UUID().uuidString,
            type: .steps,
            value: 2000, // Below target value, should be negative
            date: Date()
        )
        
        // When
        let impact = lifeImpactService.calculateImpact(for: stepsMetric)
        
        // Then
        XCTAssertNotNil(impact, "Impact should not be nil")
        XCTAssertLessThan(impact.lifespanImpactMinutes, 0, "Steps below target should have negative impact")
        XCTAssertEqual(impact.comparisonToBaseline, .belowTarget, "Comparison should be below target")
    }
    
    /// Test sleep impact calculation
    func testSleepImpact() {
        // Given
        let sleepMetric = HealthMetric(
            id: UUID().uuidString,
            type: .sleepHours,
            value: 8.0, // Optimal sleep, should be positive
            date: Date()
        )
        
        // When
        let impact = lifeImpactService.calculateImpact(for: sleepMetric)
        
        // Then
        XCTAssertNotNil(impact, "Impact should not be nil")
        XCTAssertGreaterThanOrEqual(impact.lifespanImpactMinutes, 0, "Optimal sleep should have positive impact")
    }
    
    /// Test that extremely low or high sleep has negative impact
    func testExtremesSleepImpact() {
        // Given - very low sleep
        let lowSleepMetric = HealthMetric(
            id: UUID().uuidString,
            type: .sleepHours,
            value: 4.0, // Too little sleep, should be negative
            date: Date()
        )
        
        // Given - very high sleep
        let highSleepMetric = HealthMetric(
            id: UUID().uuidString,
            type: .sleepHours,
            value: 11.0, // Too much sleep, should be negative
            date: Date()
        )
        
        // When
        let lowSleepImpact = lifeImpactService.calculateImpact(for: lowSleepMetric)
        let highSleepImpact = lifeImpactService.calculateImpact(for: highSleepMetric)
        
        // Then
        XCTAssertNotNil(lowSleepImpact, "Impact should not be nil")
        XCTAssertLessThan(lowSleepImpact.lifespanImpactMinutes, 0, "Too little sleep should have negative impact")
        
        XCTAssertNotNil(highSleepImpact, "Impact should not be nil")
        XCTAssertLessThan(highSleepImpact.lifespanImpactMinutes, 0, "Too much sleep should have negative impact")
    }
    
    /// Test that total impact calculation aggregates multiple metrics correctly
    func testTotalImpactCalculation() {
        // Given - collection of metrics with known impacts
        let metrics = [
            HealthMetric(id: "1", type: .steps, value: 12000, date: Date()),
            HealthMetric(id: "2", type: .sleepHours, value: 8.0, date: Date()),
            HealthMetric(id: "3", type: .exerciseMinutes, value: 45, date: Date())
        ]
        
        // Calculate individual impacts for verification
        let stepsImpact = lifeImpactService.calculateImpact(for: metrics[0])
        let sleepImpact = lifeImpactService.calculateImpact(for: metrics[1])
        let exerciseImpact = lifeImpactService.calculateImpact(for: metrics[2])
        
        // When
        let totalImpact = lifeImpactService.calculateTotalImpact(from: metrics, for: .day)
        
        // Then
        XCTAssertNotNil(totalImpact, "Total impact should not be nil")
        
        // Expected total impact (with appropriate scaling for the day period)
        let expectedTotal = stepsImpact.lifespanImpactMinutes + 
                            sleepImpact.lifespanImpactMinutes + 
                            exerciseImpact.lifespanImpactMinutes
        
        // Allow for small rounding differences
        XCTAssertEqual(totalImpact.totalImpactMinutes, expectedTotal, accuracy: 1.0, 
                       "Total impact should be the sum of individual impacts")
    }
    
    /// Test that different period types apply appropriate scaling
    func testPeriodScaling() {
        // Given - same metrics for different period types
        let metrics = [
            HealthMetric(id: "1", type: .steps, value: 10000, date: Date())
        ]
        
        // When
        let dayImpact = lifeImpactService.calculateTotalImpact(from: metrics, for: .day)
        let monthImpact = lifeImpactService.calculateTotalImpact(from: metrics, for: .month)
        let yearImpact = lifeImpactService.calculateTotalImpact(from: metrics, for: .year)
        
        // Then
        XCTAssertNotNil(dayImpact, "Day impact should not be nil")
        XCTAssertNotNil(monthImpact, "Month impact should not be nil")
        XCTAssertNotNil(yearImpact, "Year impact should not be nil")
        
        // Monthly impact should be roughly 30x daily impact
        XCTAssertGreaterThan(monthImpact.totalImpactMinutes, dayImpact.totalImpactMinutes * 25,
                            "Monthly impact should be significantly larger than daily impact")
        
        // Yearly impact should be roughly 12x monthly impact
        XCTAssertGreaterThan(yearImpact.totalImpactMinutes, monthImpact.totalImpactMinutes * 10,
                            "Yearly impact should be significantly larger than monthly impact")
    }
} 