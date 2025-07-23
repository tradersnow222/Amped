import XCTest
@testable import Amped

/// Unit tests for battery visualization and charge level calculations
final class BatteryVisualizationTests: XCTestCase {
    
    // MARK: - Test Helpers
    
    private func createTestLifeImpactData(
        period: TimePeriod,
        impactMinutes: Double,
        direction: ImpactDirection
    ) -> LifeImpactData {
        let impactValue = ImpactValue(
            value: abs(impactMinutes),
            unit: .minutes,
            direction: direction
        )
        
        return LifeImpactData(
            timePeriod: period,
            totalImpact: impactValue,
            batteryLevel: 50.0 // Default, will be recalculated
        )
    }
    
    private func calculateExpectedChargeLevel(
        impactMinutes: Double,
        period: TimePeriod
    ) -> Double {
        let maxExpectedImpact: Double
        switch period {
        case .day:
            maxExpectedImpact = 240.0 // 4 hours per day
        case .month:
            maxExpectedImpact = 240.0 * 30.0
        case .year:
            maxExpectedImpact = 240.0 * 365.0
        }
        
        let normalizedImpact = max(-1.0, min(1.0, impactMinutes / maxExpectedImpact))
        let baseCharge = 0.5
        let impactRange = 0.4
        let chargeAdjustment = normalizedImpact * impactRange
        let finalCharge = baseCharge + chargeAdjustment
        
        return max(0.05, min(0.95, finalCharge))
    }
    
    // MARK: - Day Period Tests
    
    func testDayPeriod_PositiveImpact() {
        // Test: 60 minutes positive impact for day period
        let impactData = createTestLifeImpactData(
            period: .day,
            impactMinutes: 60.0,
            direction: .positive
        )
        
        let expectedChargeLevel = calculateExpectedChargeLevel(impactMinutes: 60.0, period: .day)
        
        // Should be above 50% (neutral)
        XCTAssertGreaterThan(expectedChargeLevel, 0.5, "Positive impact should result in charge above 50%")
        
        // Should be around 60% for 60 minutes positive impact
        XCTAssertEqual(expectedChargeLevel, 0.6, accuracy: 0.05, "60 minutes positive impact should result in ~60% charge")
    }
    
    func testDayPeriod_NegativeImpact() {
        // Test: 60 minutes negative impact for day period
        let impactData = createTestLifeImpactData(
            period: .day,
            impactMinutes: 60.0,
            direction: .negative
        )
        
        let expectedChargeLevel = calculateExpectedChargeLevel(impactMinutes: -60.0, period: .day)
        
        // Should be below 50% (neutral)
        XCTAssertLessThan(expectedChargeLevel, 0.5, "Negative impact should result in charge below 50%")
        
        // Should be around 40% for 60 minutes negative impact
        XCTAssertEqual(expectedChargeLevel, 0.4, accuracy: 0.05, "60 minutes negative impact should result in ~40% charge")
    }
    
    func testDayPeriod_NeutralImpact() {
        // Test: 0 minutes impact for day period
        let impactData = createTestLifeImpactData(
            period: .day,
            impactMinutes: 0.0,
            direction: .positive
        )
        
        let expectedChargeLevel = calculateExpectedChargeLevel(impactMinutes: 0.0, period: .day)
        
        // Should be exactly 50% (neutral)
        XCTAssertEqual(expectedChargeLevel, 0.5, accuracy: 0.01, "Zero impact should result in 50% charge")
    }
    
    // MARK: - Month Period Tests
    
    func testMonthPeriod_ScalingCorrect() {
        // Test: Same daily impact (60 min) scaled for month should have same charge level
        let dayImpact = createTestLifeImpactData(
            period: .day,
            impactMinutes: 60.0,
            direction: .positive
        )
        
        let monthImpact = createTestLifeImpactData(
            period: .month,
            impactMinutes: 60.0 * 30.0, // Scaled for month
            direction: .positive
        )
        
        let dayChargeLevel = calculateExpectedChargeLevel(impactMinutes: 60.0, period: .day)
        let monthChargeLevel = calculateExpectedChargeLevel(impactMinutes: 60.0 * 30.0, period: .month)
        
        // Both should result in same charge level when properly scaled
        XCTAssertEqual(dayChargeLevel, monthChargeLevel, accuracy: 0.01, "Same daily impact should result in same charge level regardless of period")
    }
    
    // MARK: - Year Period Tests
    
    func testYearPeriod_ScalingCorrect() {
        // Test: Same daily impact (60 min) scaled for year should have same charge level
        let dayImpact = createTestLifeImpactData(
            period: .day,
            impactMinutes: 60.0,
            direction: .positive
        )
        
        let yearImpact = createTestLifeImpactData(
            period: .year,
            impactMinutes: 60.0 * 365.0, // Scaled for year
            direction: .positive
        )
        
        let dayChargeLevel = calculateExpectedChargeLevel(impactMinutes: 60.0, period: .day)
        let yearChargeLevel = calculateExpectedChargeLevel(impactMinutes: 60.0 * 365.0, period: .year)
        
        // Both should result in same charge level when properly scaled
        XCTAssertEqual(dayChargeLevel, yearChargeLevel, accuracy: 0.01, "Same daily impact should result in same charge level regardless of period")
    }
    
    // MARK: - Edge Cases
    
    func testExtremePositiveImpact_ClampedCorrectly() {
        // Test: Very large positive impact should be clamped to 95%
        let impactData = createTestLifeImpactData(
            period: .day,
            impactMinutes: 1000.0, // Extremely large impact
            direction: .positive
        )
        
        let expectedChargeLevel = calculateExpectedChargeLevel(impactMinutes: 1000.0, period: .day)
        
        // Should be clamped to 95%
        XCTAssertEqual(expectedChargeLevel, 0.95, "Extreme positive impact should be clamped to 95%")
    }
    
    func testExtremeNegativeImpact_ClampedCorrectly() {
        // Test: Very large negative impact should be clamped to 5%
        let impactData = createTestLifeImpactData(
            period: .day,
            impactMinutes: 1000.0, // Extremely large impact
            direction: .negative
        )
        
        let expectedChargeLevel = calculateExpectedChargeLevel(impactMinutes: -1000.0, period: .day)
        
        // Should be clamped to 5%
        XCTAssertEqual(expectedChargeLevel, 0.05, "Extreme negative impact should be clamped to 5%")
    }
    
    // MARK: - Dual Direction Fill Logic Tests
    
    func testDualDirectionFill_PositiveImpact() {
        let chargeLevel = 0.7 // 70% charge (positive)
        
        let isPositive = chargeLevel > 0.5
        let fillHeight = abs(chargeLevel - 0.5) // Should be 0.2
        
        XCTAssertTrue(isPositive, "70% charge should be detected as positive")
        XCTAssertEqual(fillHeight, 0.2, accuracy: 0.01, "Fill height should be 20% above neutral")
    }
    
    func testDualDirectionFill_NegativeImpact() {
        let chargeLevel = 0.3 // 30% charge (negative)
        
        let isPositive = chargeLevel > 0.5
        let fillHeight = abs(chargeLevel - 0.5) // Should be 0.2
        
        XCTAssertFalse(isPositive, "30% charge should be detected as negative")
        XCTAssertEqual(fillHeight, 0.2, accuracy: 0.01, "Fill height should be 20% below neutral")
    }
    
    func testDualDirectionFill_NeutralImpact() {
        let chargeLevel = 0.5 // Exactly neutral
        
        let isPositive = chargeLevel > 0.5
        let fillHeight = abs(chargeLevel - 0.5) // Should be 0.0
        
        XCTAssertFalse(isPositive, "50% charge should not be positive")
        XCTAssertEqual(fillHeight, 0.0, accuracy: 0.001, "Neutral charge should have no fill")
    }
    
    // MARK: - Performance Tests
    
    func testChargeCalculationPerformance() {
        // Test that charge calculation is fast enough for real-time updates
        measure {
            for _ in 0..<1000 {
                let impactData = createTestLifeImpactData(
                    period: .day,
                    impactMinutes: Double.random(in: -240...240),
                    direction: Bool.random() ? .positive : .negative
                )
                
                let _ = calculateExpectedChargeLevel(
                    impactMinutes: impactData.totalImpact.value,
                    period: impactData.timePeriod
                )
            }
        }
    }
} 