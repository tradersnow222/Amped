import XCTest
@testable import Amped

/// Unit tests for the LifeProjectionService
final class LifeProjectionServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    /// Subject under test
    var lifeProjectionService: LifeProjectionService!
    
    // MARK: - Setup and Teardown
    
    override func setUp() {
        super.setUp()
        lifeProjectionService = LifeProjectionService()
    }
    
    override func tearDown() {
        lifeProjectionService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Test baseline life expectancy calculation
    func testBaselineLifeExpectancy() {
        // Given
        let maleProfile = UserProfile(
            id: "test-male-id",
            birthYear: 1990,
            gender: .male,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true
        )
        
        let femaleProfile = UserProfile(
            id: "test-female-id",
            birthYear: 1990,
            gender: .female,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true
        )
        
        // When
        let maleExpectancy = lifeProjectionService.calculateBaselineLifeExpectancy(for: maleProfile)
        let femaleExpectancy = lifeProjectionService.calculateBaselineLifeExpectancy(for: femaleProfile)
        
        // Then
        XCTAssertGreaterThan(maleExpectancy, 70, "Male life expectancy should be reasonable")
        XCTAssertLessThan(maleExpectancy, 90, "Male life expectancy should be reasonable")
        
        XCTAssertGreaterThan(femaleExpectancy, 75, "Female life expectancy should be reasonable")
        XCTAssertLessThan(femaleExpectancy, 95, "Female life expectancy should be reasonable")
        
        // Females typically have higher life expectancy
        XCTAssertGreaterThan(femaleExpectancy, maleExpectancy, "Female expectancy should be higher than male")
    }
    
    /// Test that positive impacts increase life expectancy
    func testPositiveImpactIncreasesLifeExpectancy() {
        // Given
        let userProfile = UserProfile(
            id: "test-id",
            birthYear: 1990,
            gender: .male,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true
        )
        
        let baselineExpectancy = lifeProjectionService.calculateBaselineLifeExpectancy(for: userProfile)
        let positiveImpactMinutes: Double = 60 * 24 * 365 * 5 // Equivalent to gaining 5 years
        
        // When
        let projection = lifeProjectionService.generateLifeProjection(
            for: userProfile,
            cumulativeImpactMinutes: positiveImpactMinutes
        )
        
        // Then
        XCTAssertNotNil(projection, "Projection should not be nil")
        XCTAssertGreaterThan(projection.projectedLifeExpectancyYears, baselineExpectancy,
                            "Positive impact should increase life expectancy")
        
        // The increase should be approximately the impact in years
        let expectedIncrease = positiveImpactMinutes / (60 * 24 * 365)
        XCTAssertEqual(projection.projectedLifeExpectancyYears, baselineExpectancy + expectedIncrease,
                       accuracy: 0.1, "Projection should add impact years to baseline")
    }
    
    /// Test that negative impacts decrease life expectancy
    func testNegativeImpactDecreasesLifeExpectancy() {
        // Given
        let userProfile = UserProfile(
            id: "test-id",
            birthYear: 1990,
            gender: .male,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true
        )
        
        let baselineExpectancy = lifeProjectionService.calculateBaselineLifeExpectancy(for: userProfile)
        let negativeImpactMinutes: Double = -60 * 24 * 365 * 2 // Equivalent to losing 2 years
        
        // When
        let projection = lifeProjectionService.generateLifeProjection(
            for: userProfile,
            cumulativeImpactMinutes: negativeImpactMinutes
        )
        
        // Then
        XCTAssertNotNil(projection, "Projection should not be nil")
        XCTAssertLessThan(projection.projectedLifeExpectancyYears, baselineExpectancy,
                         "Negative impact should decrease life expectancy")
        
        // The decrease should be approximately the impact in years
        let expectedDecrease = negativeImpactMinutes / (60 * 24 * 365)
        XCTAssertEqual(projection.projectedLifeExpectancyYears, baselineExpectancy + expectedDecrease,
                      accuracy: 0.1, "Projection should subtract impact years from baseline")
    }
    
    /// Test that age calculation is correct
    func testAgeCalculation() {
        // Given
        let birthYear = Calendar.current.component(.year, from: Date()) - 30 // 30 years old
        let userProfile = UserProfile(
            id: "test-id",
            birthYear: birthYear,
            gender: .male,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true
        )
        
        // When
        let age = userProfile.age
        
        // Then
        XCTAssertEqual(age, 30, "Age calculation should be correct")
    }
    
    /// Test that percentage of life remaining calculation works correctly
    func testPercentageLifeRemaining() {
        // Given
        let userProfile = UserProfile(
            id: "test-id",
            birthYear: 1990,
            gender: .male,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true
        )
        
        let age = Calendar.current.component(.year, from: Date()) - 1990
        let projection = lifeProjectionService.generateLifeProjection(
            for: userProfile,
            cumulativeImpactMinutes: 0 // No impact, just baseline
        )
        
        // When
        let percentRemaining = projection.percentageLifeRemaining
        
        // Then
        XCTAssertNotNil(percentRemaining, "Percentage life remaining should not be nil")
        
        // Calculate expected percentage
        let expectedPercentage = (projection.projectedLifeExpectancyYears - Double(age)) / projection.projectedLifeExpectancyYears * 100.0
        XCTAssertEqual(percentRemaining, expectedPercentage, accuracy: 1.0,
                       "Percentage remaining calculation should be correct")
        
        // Sanity check - percentage should be between 0 and 100
        XCTAssertGreaterThan(percentRemaining, 0, "Percentage should be positive")
        XCTAssertLessThan(percentRemaining, 100, "Percentage should be less than 100")
    }
    
    /// Test that confidence intervals are calculated correctly
    func testConfidenceIntervals() {
        // Given
        let userProfile = UserProfile(
            id: "test-id",
            birthYear: 1990,
            gender: .male,
            isSubscribed: true,
            hasCompletedOnboarding: true,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: true
        )
        
        // When
        let projection = lifeProjectionService.generateLifeProjection(
            for: userProfile,
            cumulativeImpactMinutes: 0 // No impact, just baseline
        )
        
        // Then
        XCTAssertNotNil(projection, "Projection should not be nil")
        XCTAssertNotNil(projection.confidenceIntervalLow, "Lower confidence interval should not be nil")
        XCTAssertNotNil(projection.confidenceIntervalHigh, "Upper confidence interval should not be nil")
        
        // Confidence intervals should bracket the projected value
        XCTAssertLessThan(projection.confidenceIntervalLow, projection.projectedLifeExpectancyYears,
                         "Lower bound should be less than projection")
        XCTAssertGreaterThan(projection.confidenceIntervalHigh, projection.projectedLifeExpectancyYears,
                            "Upper bound should be greater than projection")
        
        // Interval width should be reasonable (not too narrow or wide)
        let intervalWidth = projection.confidenceIntervalHigh - projection.confidenceIntervalLow
        XCTAssertGreaterThan(intervalWidth, 5, "Confidence interval should have reasonable width")
        XCTAssertLessThan(intervalWidth, 20, "Confidence interval should not be too wide")
    }
} 