import Foundation

/// Detailed impact analysis for a health metric based on peer-reviewed research
struct MetricImpactDetail: Codable, Identifiable, Equatable {
    let id: String
    let metricType: HealthMetricType
    let currentValue: Double
    let baselineValue: Double  // Research-based optimal/reference value
    let variance: Double       // How far from baseline (positive = better, negative = worse)
    
    // Research-backed impact calculations
    let studyReferences: [StudyReference]  // Supporting peer-reviewed studies
    let effectType: HealthEffectType       // How this effect accumulates over time
    let lifespanImpactMinutes: Double      // Daily impact in minutes (can be scaled appropriately)
    let confidenceInterval: ConfidenceInterval? // Statistical confidence in the estimate
    
    // Scientific grounding
    let calculationMethod: CalculationMethod
    let evidenceStrength: EvidenceStrength
    let applicabilityScore: Double  // How well studies apply to current user (0-100)
    
    // User guidance
    let recommendation: String
    let actionability: ActionabilityLevel
    let improvementPotential: Double  // Potential lifespan gain if optimized (minutes/day)
    
    enum CalculationMethod: String, Codable, CaseIterable {
        case directStudyMapping = "Direct Study Mapping"       // Direct from study results
        case interpolatedDoseResponse = "Interpolated Dose-Response"  // Interpolated from dose-response curve
        case metaAnalysisSynthesis = "Meta-Analysis Synthesis"  // Synthesized from multiple studies
        case expertConsensus = "Expert Consensus"             // When direct data unavailable
        case algorithmicEstimate = "Algorithmic Estimate"     // Mathematical modeling
        
        var reliability: Double {
            switch self {
            case .directStudyMapping: return 0.9
            case .metaAnalysisSynthesis: return 0.85
            case .interpolatedDoseResponse: return 0.75
            case .expertConsensus: return 0.6
            case .algorithmicEstimate: return 0.4
            }
        }
    }
    
    enum EvidenceStrength: String, Codable, CaseIterable {
        case strong = "Strong"     // Multiple high-quality studies, consistent results
        case moderate = "Moderate" // Good studies but some limitations
        case limited = "Limited"   // Some evidence but gaps or inconsistencies
        case weak = "Weak"        // Minimal or low-quality evidence
        
        var color: String {
            switch self {
            case .strong: return "ampedGreen"
            case .moderate: return "ampedYellow"
            case .limited: return "ampedYellow"
            case .weak: return "ampedRed"
            }
        }
        
        var score: Double {
            switch self {
            case .strong: return 1.0
            case .moderate: return 0.75
            case .limited: return 0.5
            case .weak: return 0.25
            }
        }
    }
    
    enum ActionabilityLevel: String, Codable, CaseIterable {
        case high = "High"       // User can easily change this metric
        case medium = "Medium"   // Requires effort but achievable
        case low = "Low"        // Difficult to change or not under direct control
        
        var description: String {
            switch self {
            case .high: return "Easy to improve with daily habits"
            case .medium: return "Requires consistent effort to change"
            case .low: return "Challenging to modify directly"
            }
        }
    }
    
    /// Initialize with research-backed calculations
    init(
        id: String = UUID().uuidString,
        metricType: HealthMetricType,
        currentValue: Double,
        baselineValue: Double,
        studyReferences: [StudyReference],
        lifespanImpactMinutes: Double,
        calculationMethod: CalculationMethod,
        recommendation: String,
        improvementPotential: Double? = nil
    ) {
        self.id = id
        self.metricType = metricType
        self.currentValue = currentValue
        self.baselineValue = baselineValue
        self.variance = currentValue - baselineValue
        self.studyReferences = studyReferences
        self.lifespanImpactMinutes = lifespanImpactMinutes
        self.calculationMethod = calculationMethod
        self.recommendation = recommendation
        self.improvementPotential = improvementPotential ?? (lifespanImpactMinutes < 0 ? abs(lifespanImpactMinutes) : 0)
        
        // Derive effect type from primary study
        self.effectType = studyReferences.first?.effectType ?? .linearCumulative
        
        // Calculate evidence strength from studies
        let averageEvidenceScore = studyReferences.isEmpty ? 0 : studyReferences.map(\.evidenceStrength).reduce(0, +) / Double(studyReferences.count)
        if averageEvidenceScore >= 80 {
            self.evidenceStrength = .strong
        } else if averageEvidenceScore >= 60 {
            self.evidenceStrength = .moderate
        } else if averageEvidenceScore >= 40 {
            self.evidenceStrength = .limited
        } else {
            self.evidenceStrength = .weak
        }
        
        // Use confidence interval from primary study
        self.confidenceInterval = studyReferences.first?.confidenceInterval
        
        // Calculate applicability (simplified - would be more complex in real implementation)
        self.applicabilityScore = studyReferences.isEmpty ? 50 :
            studyReferences.map { _ in 80.0 }.reduce(0, +) / Double(studyReferences.count)
        
        // Determine actionability based on metric type
        self.actionability = metricType.actionabilityLevel
    }
    
    /// Get time-period appropriate impact with scientific validity check
    func impactForPeriod(_ periodType: ImpactDataPoint.PeriodType) -> Double {
        // CRITICAL: Only scale if the effect type supports linear scaling
        guard effectType.allowsLinearScaling else {
            // For non-linear effects, return daily impact with a note that longer-term effects
            // require more complex modeling
            return lifespanImpactMinutes
        }
        
        // Apply scaling for linear cumulative effects only
        switch periodType {
        case .day:
            return lifespanImpactMinutes
        case .month:
            return lifespanImpactMinutes * 30.0
        case .year:
            return lifespanImpactMinutes * 365.0
        }
    }
    
    /// Get impact status with research confidence
    var impactStatus: ImpactStatus {
        if lifespanImpactMinutes > 0 {
            return .positive
        } else if lifespanImpactMinutes < 0 {
            return .negative
        } else {
            return .neutral
        }
    }
    
    /// Get formatted description of the scientific basis
    var scientificBasis: String {
        let studyCount = studyReferences.count
        let primaryStudy = studyReferences.first
        
        if studyCount == 0 {
            return "Based on algorithmic estimation (limited evidence)"
        } else if studyCount == 1 {
            return "Based on: \(primaryStudy?.citation ?? "1 peer-reviewed study")"
        } else {
            return "Based on \(studyCount) peer-reviewed studies including: \(primaryStudy?.citation ?? "")"
        }
    }
    
    /// Get reliability score combining evidence and method
    var reliabilityScore: Double {
        let evidenceScore = evidenceStrength.score
        let methodScore = calculationMethod.reliability
        let applicabilityModifier = applicabilityScore / 100.0
        
        return (evidenceScore * 0.5 + methodScore * 0.3 + applicabilityModifier * 0.2)
    }
    
    enum ImpactStatus: String, Codable, CaseIterable {
        case positive = "Positive"
        case neutral = "Neutral"
        case negative = "Negative"
        
        var color: String {
            switch self {
            case .positive: return "ampedGreen"
            case .neutral: return "ampedSilver"
            case .negative: return "ampedRed"
            }
        }
        
        var icon: String {
            switch self {
            case .positive: return "plus.circle.fill"
            case .neutral: return "minus.circle.fill"
            case .negative: return "exclamationmark.triangle.fill"
            }
        }
    }
}

// MARK: - Extensions for Health Metric Types

extension HealthMetricType {
    /// Actionability level for each metric type based on user control
    var actionabilityLevel: MetricImpactDetail.ActionabilityLevel {
        switch self {
        case .steps, .exerciseMinutes, .sleepHours:
            return .high
        case .restingHeartRate, .vo2Max, .bodyMass:
            return .medium
        case .heartRateVariability:
            return .low
        case .alcoholConsumption, .smokingStatus, .stressLevel, .nutritionQuality, .socialConnectionsQuality, .activeEnergyBurned, .oxygenSaturation, .bloodPressure:
            return .medium
        }
    }
}

// MARK: - Formatting Extensions

extension MetricImpactDetail {
    /// Format the impact value for display with appropriate units
    func formattedImpact(for periodType: ImpactDataPoint.PeriodType) -> String {
        let impactMinutes = impactForPeriod(periodType)
        return ImpactDataPoint.formatLifespanImpact(minutes: impactMinutes)
    }
    
    /// Format with confidence interval if available
    var formattedImpactWithConfidence: String {
        let baseImpact = ImpactDataPoint.formatLifespanImpact(minutes: lifespanImpactMinutes)
        if let ci = confidenceInterval {
            return "\(baseImpact) (\(ci.description))"
        }
        return baseImpact
    }
}

