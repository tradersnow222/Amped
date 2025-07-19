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
    
    func testLifeImpactScalingAcrossTimePeriods() throws {
        // Create a user profile
        let profile = createUserProfile(
            age: 30,
            gender: .male,
            height: 1.75,
            weight: 70
        )
        
        let service = LifeImpactService(userProfile: profile)
        
        // Create sample metrics with known impacts
        let metrics = [
            HealthMetric(
                id: "1",
                type: .steps,
                value: 5000, // 2500 steps below baseline (7500)
                date: Date(),
                source: .healthKit
            ),
            HealthMetric(
                id: "2",
                type: .sleepHours,
                value: 7.5, // Optimal sleep
                date: Date(),
                source: .healthKit
            )
        ]
        
        // Calculate impacts for different time periods
        let dayImpact = service.calculateTotalImpact(from: metrics, for: .day)
        let monthImpact = service.calculateTotalImpact(from: metrics, for: .month)
        let yearImpact = service.calculateTotalImpact(from: metrics, for: .year)
        
        // Steps: -2500 steps = -12.5 minutes per day
        // Sleep: optimal = +10 minutes per day
        // Total daily impact: -2.5 minutes
        
        // Verify scaling
        XCTAssertEqual(dayImpact.totalImpactMinutes, -2.5, accuracy: 0.1, "Daily impact should be -2.5 minutes")
        XCTAssertEqual(monthImpact.totalImpactMinutes, -75.0, accuracy: 0.1, "Monthly impact should be -75 minutes (30 days)")
        XCTAssertEqual(yearImpact.totalImpactMinutes, -912.5, accuracy: 0.1, "Yearly impact should be -912.5 minutes (365 days)")
        
        // Verify individual metric scaling
        if let stepsImpactDay = dayImpact.metricImpacts[.steps],
           let stepsImpactMonth = monthImpact.metricImpacts[.steps],
           let stepsImpactYear = yearImpact.metricImpacts[.steps] {
            XCTAssertEqual(stepsImpactMonth, stepsImpactDay * 30, accuracy: 0.1, "Monthly steps impact should be 30x daily")
            XCTAssertEqual(stepsImpactYear, stepsImpactDay * 365, accuracy: 0.1, "Yearly steps impact should be 365x daily")
        } else {
            XCTFail("Steps impact not found in results")
        }
    }
    
    func testScalingConsistencyAcrossAllComponents() throws {
        // Test that scaling is applied consistently everywhere in the app
        
        // Create a user profile
        let profile = createUserProfile(age: 30, gender: .male)
        let service = LifeImpactService(userProfile: profile)
        
        // Create sample HealthKit metric (should be scaled)
        let healthKitMetric = HealthMetric(
            id: "1",
            type: .steps,
            value: 5000, // Below baseline
            date: Date(),
            source: .healthKit
        )
        
        // Create sample manual metric (should NOT be scaled)  
        let manualMetric = HealthMetric(
            id: "2",
            type: .smokingStatus,
            value: 3.0, // Poor score
            date: Date(),
            source: .userInput
        )
        
        // Test daily impacts (no scaling)
        let dailyHealthKitImpact = service.calculateImpact(for: healthKitMetric)
        let dailyManualImpact = service.calculateImpact(for: manualMetric)
        
        // Verify daily impacts are reasonable
        XCTAssertLessThan(dailyHealthKitImpact.lifespanImpactMinutes, 0, "Steps below baseline should have negative impact")
        XCTAssertLessThan(dailyManualImpact.lifespanImpactMinutes, 0, "Poor smoking score should have negative impact")
        
        // Test total impact scaling for different periods
        let metrics = [healthKitMetric, manualMetric]
        
        let dayTotal = service.calculateTotalImpact(from: metrics, for: .day)
        let monthTotal = service.calculateTotalImpact(from: metrics, for: .month)
        let yearTotal = service.calculateTotalImpact(from: metrics, for: .year)
        
        // Verify total impact scales properly
        let expectedMonthly = dayTotal.totalImpactMinutes * 30
        let expectedYearly = dayTotal.totalImpactMinutes * 365
        
        XCTAssertEqual(monthTotal.totalImpactMinutes, expectedMonthly, accuracy: 0.1, "Monthly total should be 30x daily")
        XCTAssertEqual(yearTotal.totalImpactMinutes, expectedYearly, accuracy: 1.0, "Yearly total should be 365x daily")
        
        // Test that manual metrics maintain consistent daily impact regardless of period
        // (This would be tested in the UI layer where manual metrics are handled differently)
        
        print("✅ Scaling consistency test passed")
        print("   Daily total: \(dayTotal.totalImpactMinutes) minutes")
        print("   Monthly total: \(monthTotal.totalImpactMinutes) minutes (30x daily)")
        print("   Yearly total: \(yearTotal.totalImpactMinutes) minutes (365x daily)")
    }
    
    // Helper function for creating user profiles
    private func createUserProfile(age: Int, gender: UserProfile.Gender, height: Double? = nil, weight: Double? = nil) -> UserProfile {
        let currentYear = Calendar.current.component(.year, from: Date())
        let birthYear = currentYear - age
        return UserProfile(
            id: "test-user-id",
            birthYear: birthYear,
            gender: gender,
            height: height,
            weight: weight,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true,
            createdAt: Date(),
            lastActive: Date()
        )
    }
} 