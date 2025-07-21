import XCTest
@testable import Amped

/// Unit tests for InteractionEffectEngine
final class InteractionEffectEngineTests: XCTestCase {
    
    private var engine: InteractionEffectEngine!
    private var userProfile: UserProfile!
    
    override func setUp() {
        super.setUp()
        engine = InteractionEffectEngine()
        userProfile = UserProfile(age: 40, gender: .male)
    }
    
    override func tearDown() {
        engine = nil
        userProfile = nil
        super.tearDown()
    }
    
    // MARK: - Sleep-Exercise Synergy Tests
    
    func testSleepExerciseSynergyDetected() {
        // Given: Good sleep and exercise
        let sleepMetric = HealthMetric(type: .sleepHours, value: 7.5, date: Date(), source: .healthKit)
        let exerciseMetric = HealthMetric(type: .exerciseMinutes, value: 30, date: Date(), source: .healthKit)
        
        let sleepImpact = MetricImpactDetail(
            metricType: .sleepHours,
            currentValue: 7.5,
            baselineValue: 7.5,
            studyReferences: [],
            lifespanImpactMinutes: 10.0,
            calculationMethod: .interpolatedDoseResponse,
            recommendation: ""
        )
        
        let exerciseImpact = MetricImpactDetail(
            metricType: .exerciseMinutes,
            currentValue: 30,
            baselineValue: 21.4,
            studyReferences: [],
            lifespanImpactMinutes: 15.0,
            calculationMethod: .interpolatedDoseResponse,
            recommendation: ""
        )
        
        // When: Calculate adjusted impacts
        let adjustedImpacts = engine.calculateAdjustedImpacts(
            impacts: [sleepImpact, exerciseImpact],
            metrics: [sleepMetric, exerciseMetric]
        )
        
        // Then: Both impacts should be boosted by 15%
        let adjustedSleep = adjustedImpacts.first { $0.metricType == .sleepHours }
        let adjustedExercise = adjustedImpacts.first { $0.metricType == .exerciseMinutes }
        
        XCTAssertNotNil(adjustedSleep)
        XCTAssertNotNil(adjustedExercise)
        XCTAssertEqual(adjustedSleep?.lifespanImpactMinutes, 11.5, accuracy: 0.1) // 10 * 1.15
        XCTAssertEqual(adjustedExercise?.lifespanImpactMinutes, 17.25, accuracy: 0.1) // 15 * 1.15
    }
    
    func testSleepExerciseSynergyNotDetectedWithPoorSleep() {
        // Given: Poor sleep but good exercise
        let sleepMetric = HealthMetric(type: .sleepHours, value: 5.0, date: Date(), source: .healthKit)
        let exerciseMetric = HealthMetric(type: .exerciseMinutes, value: 30, date: Date(), source: .healthKit)
        
        let impacts = createTestImpacts(for: [sleepMetric, exerciseMetric])
        
        // When: Calculate adjusted impacts
        let adjustedImpacts = engine.calculateAdjustedImpacts(
            impacts: impacts,
            metrics: [sleepMetric, exerciseMetric]
        )
        
        // Then: No synergy boost applied
        XCTAssertEqual(adjustedImpacts[0].lifespanImpactMinutes, impacts[0].lifespanImpactMinutes)
        XCTAssertEqual(adjustedImpacts[1].lifespanImpactMinutes, impacts[1].lifespanImpactMinutes)
    }
    
    // MARK: - Alcohol-HRV Antagonism Tests
    
    func testAlcoholHRVAntagonismDetected() {
        // Given: Alcohol consumption and HRV
        let alcoholMetric = HealthMetric(type: .alcoholConsumption, value: 5.0, date: Date(), source: .manual) // Some drinking
        let hrvMetric = HealthMetric(type: .heartRateVariability, value: 45.0, date: Date(), source: .healthKit)
        
        let hrvImpact = MetricImpactDetail(
            metricType: .heartRateVariability,
            currentValue: 45.0,
            baselineValue: 40.0,
            studyReferences: [],
            lifespanImpactMinutes: 8.0,
            calculationMethod: .expertConsensus,
            recommendation: ""
        )
        
        let alcoholImpact = createTestImpact(for: alcoholMetric)
        
        // When: Calculate adjusted impacts
        let adjustedImpacts = engine.calculateAdjustedImpacts(
            impacts: [alcoholImpact, hrvImpact],
            metrics: [alcoholMetric, hrvMetric]
        )
        
        // Then: HRV benefits should be reduced by 25%
        let adjustedHRV = adjustedImpacts.first { $0.metricType == .heartRateVariability }
        XCTAssertNotNil(adjustedHRV)
        XCTAssertEqual(adjustedHRV?.lifespanImpactMinutes, 6.0, accuracy: 0.1) // 8 * 0.75
    }
    
    // MARK: - Body Mass-Activity Interaction Tests
    
    func testBodyMassReducesActivityBenefits() {
        // Given: High body mass and steps
        let bodyMassMetric = HealthMetric(type: .bodyMass, value: 240.0, date: Date(), source: .healthKit) // 240 lbs
        let stepsMetric = HealthMetric(type: .steps, value: 10000, date: Date(), source: .healthKit)
        
        let stepsImpact = MetricImpactDetail(
            metricType: .steps,
            currentValue: 10000,
            baselineValue: 10000,
            studyReferences: [],
            lifespanImpactMinutes: 20.0,
            calculationMethod: .interpolatedDoseResponse,
            recommendation: ""
        )
        
        let bodyMassImpact = createTestImpact(for: bodyMassMetric)
        
        // When: Calculate adjusted impacts
        let adjustedImpacts = engine.calculateAdjustedImpacts(
            impacts: [bodyMassImpact, stepsImpact],
            metrics: [bodyMassMetric, stepsMetric]
        )
        
        // Then: Steps benefits should be reduced
        let adjustedSteps = adjustedImpacts.first { $0.metricType == .steps }
        XCTAssertNotNil(adjustedSteps)
        XCTAssertLessThan(adjustedSteps!.lifespanImpactMinutes, 20.0) // Reduced from original
    }
    
    // MARK: - Active Interactions Test
    
    func testGetActiveInteractions() {
        // Given: Multiple metrics with synergies
        let metrics = [
            HealthMetric(type: .sleepHours, value: 7.5, date: Date(), source: .healthKit),
            HealthMetric(type: .exerciseMinutes, value: 30, date: Date(), source: .healthKit),
            HealthMetric(type: .alcoholConsumption, value: 5.0, date: Date(), source: .manual),
            HealthMetric(type: .heartRateVariability, value: 45.0, date: Date(), source: .healthKit)
        ]
        
        // When: Get active interactions
        let interactions = engine.getActiveInteractions(for: metrics)
        
        // Then: Should detect both synergy and antagonism
        XCTAssertEqual(interactions.count, 2)
        XCTAssertTrue(interactions.contains { $0.title == "Sleep-Exercise Synergy" })
        XCTAssertTrue(interactions.contains { $0.title == "Alcohol-HRV Impact" })
    }
    
    // MARK: - Helper Methods
    
    private func createTestImpacts(for metrics: [HealthMetric]) -> [MetricImpactDetail] {
        return metrics.map { createTestImpact(for: $0) }
    }
    
    private func createTestImpact(for metric: HealthMetric) -> MetricImpactDetail {
        return MetricImpactDetail(
            metricType: metric.type,
            currentValue: metric.value,
            baselineValue: getBaseline(for: metric.type),
            studyReferences: [],
            lifespanImpactMinutes: 5.0, // Default test impact
            calculationMethod: .algorithmicEstimate,
            recommendation: ""
        )
    }
    
    private func getBaseline(for type: HealthMetricType) -> Double {
        switch type {
        case .sleepHours: return 7.5
        case .exerciseMinutes: return 21.4
        case .alcoholConsumption: return 10.0
        case .heartRateVariability: return 40.0
        case .bodyMass: return 160.0
        case .steps: return 10000.0
        default: return 0.0
        }
    }
} 