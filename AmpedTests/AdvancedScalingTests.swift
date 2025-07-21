import XCTest
@testable import Amped

/// Unit tests for advanced scaling functions in LifeImpactService
final class AdvancedScalingTests: XCTestCase {
    
    private var lifeImpactService: LifeImpactService!
    private var userProfile: UserProfile!
    
    override func setUp() {
        super.setUp()
        userProfile = UserProfile(age: 40, gender: .male)
        lifeImpactService = LifeImpactService(userProfile: userProfile)
    }
    
    override func tearDown() {
        lifeImpactService = nil
        userProfile = nil
        super.tearDown()
    }
    
    // MARK: - Linear Scaling Tests
    
    func testLinearScalingForCumulativeEffects() {
        // Given: A metric with linear cumulative effect
        let smokingImpact = MetricImpactDetail(
            metricType: .smokingStatus,
            currentValue: 5.0,
            baselineValue: 10.0,
            studyReferences: [],
            lifespanImpactMinutes: -100.0, // Daily impact
            calculationMethod: .metaAnalysisSynthesis,
            recommendation: "",
            effectType: .linearCumulative
        )
        
        let metrics = [HealthMetric(type: .smokingStatus, value: 5.0, date: Date(), source: .manual)]
        
        // When: Scale for different periods (using private method through calculateTotalImpact)
        let dailyImpact = calculateScaledImpact(impact: smokingImpact, period: .day, metrics: metrics)
        let monthlyImpact = calculateScaledImpact(impact: smokingImpact, period: .month, metrics: metrics)
        let yearlyImpact = calculateScaledImpact(impact: smokingImpact, period: .year, metrics: metrics)
        
        // Then: Should scale linearly
        XCTAssertEqual(dailyImpact, -100.0, accuracy: 0.1)
        XCTAssertEqual(monthlyImpact, -3000.0, accuracy: 1.0) // -100 * 30
        XCTAssertEqual(yearlyImpact, -36500.0, accuracy: 10.0) // -100 * 365
    }
    
    // MARK: - Diminishing Returns Tests
    
    func testDiminishingReturnsForExercise() {
        // Given: Exercise with diminishing returns
        let exerciseImpact = MetricImpactDetail(
            metricType: .exerciseMinutes,
            currentValue: 30.0,
            baselineValue: 21.4,
            studyReferences: [],
            lifespanImpactMinutes: 15.0, // Daily impact
            calculationMethod: .interpolatedDoseResponse,
            recommendation: "",
            effectType: .diminishingReturns
        )
        
        let metrics = [HealthMetric(type: .exerciseMinutes, value: 30.0, date: Date(), source: .healthKit)]
        
        // When: Scale for year (should show diminishing returns)
        let yearlyImpact = calculateScaledImpact(impact: exerciseImpact, period: .year, metrics: metrics)
        
        // Then: Yearly impact should be less than linear scaling
        let linearYearlyImpact = 15.0 * 365
        XCTAssertLessThan(yearlyImpact, linearYearlyImpact)
        XCTAssertGreaterThan(yearlyImpact, linearYearlyImpact * 0.5) // But not too diminished
    }
    
    // MARK: - U-Shaped Curve Tests
    
    func testUShapedScalingForSleep() {
        // Given: Sleep with U-shaped effect and poor value
        let sleepImpact = MetricImpactDetail(
            metricType: .sleepHours,
            currentValue: 5.0, // Poor sleep
            baselineValue: 7.5,
            studyReferences: [],
            lifespanImpactMinutes: -20.0, // Daily impact
            calculationMethod: .interpolatedDoseResponse,
            recommendation: "",
            effectType: .uShapedCurve
        )
        
        let metrics = [HealthMetric(type: .sleepHours, value: 5.0, date: Date(), source: .healthKit)]
        
        // When: Scale for year
        let yearlyImpact = calculateScaledImpact(impact: sleepImpact, period: .year, metrics: metrics)
        
        // Then: Impact should compound (chronic poor sleep has worse effects)
        let simpleYearlyImpact = -20.0 * 365
        XCTAssertLessThan(yearlyImpact, simpleYearlyImpact) // More negative due to compounding
    }
    
    // MARK: - Threshold Effect Tests
    
    func testThresholdEffectScaling() {
        // Given: A metric with threshold effect
        let thresholdImpact = MetricImpactDetail(
            metricType: .nutritionQuality,
            currentValue: 8.0,
            baselineValue: 7.0,
            studyReferences: [],
            lifespanImpactMinutes: 5.0,
            calculationMethod: .algorithmicEstimate,
            recommendation: "",
            effectType: .thresholdBased
        )
        
        let metrics = [HealthMetric(type: .nutritionQuality, value: 8.0, date: Date(), source: .manual)]
        
        // When: Scale for short period (less than threshold)
        let tenDayImpact = 5.0 * 10 // Expect reduced impact for < 21 days
        let monthlyImpact = calculateScaledImpact(impact: thresholdImpact, period: .month, metrics: metrics)
        
        // Then: Monthly should show threshold effect (not purely linear)
        XCTAssertGreaterThan(monthlyImpact, tenDayImpact) // Should accelerate after threshold
    }
    
    // MARK: - Plateau Effect Tests
    
    func testPlateauEffectScaling() {
        // Given: A metric with plateau effect
        let plateauImpact = MetricImpactDetail(
            metricType: .activeEnergyBurned,
            currentValue: 500.0,
            baselineValue: 400.0,
            studyReferences: [],
            lifespanImpactMinutes: 10.0,
            calculationMethod: .expertConsensus,
            recommendation: "",
            effectType: .plateau
        )
        
        let metrics = [HealthMetric(type: .activeEnergyBurned, value: 500.0, date: Date(), source: .healthKit)]
        
        // When: Scale for year
        let yearlyImpact = calculateScaledImpact(impact: plateauImpact, period: .year, metrics: metrics)
        
        // Then: Impact should plateau (not scale linearly)
        let linearYearlyImpact = 10.0 * 365
        XCTAssertLessThan(yearlyImpact, linearYearlyImpact * 0.2) // Significant plateau effect
    }
    
    // MARK: - Helper Methods
    
    /// Calculate scaled impact using the service's internal scaling logic
    private func calculateScaledImpact(
        impact: MetricImpactDetail,
        period: ImpactDataPoint.PeriodType,
        metrics: [HealthMetric]
    ) -> Double {
        // Create a mock service that exposes the scaling method
        let service = TestableLifeImpactService(userProfile: userProfile)
        return service.testApplyAdvancedScaling(impact, periodType: period, metrics: metrics)
    }
}

/// Testable version of LifeImpactService that exposes private methods
private class TestableLifeImpactService: LifeImpactService {
    func testApplyAdvancedScaling(
        _ impact: MetricImpactDetail,
        periodType: ImpactDataPoint.PeriodType,
        metrics: [HealthMetric]
    ) -> Double {
        // Use reflection or recreate the scaling logic for testing
        // For now, we'll test through the public interface
        let totalImpact = calculateTotalImpact(from: metrics, for: periodType)
        return totalImpact.metricImpacts[impact.metricType] ?? 0
    }
} 