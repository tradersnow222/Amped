import Foundation

/// Represents a peer-reviewed scientific study used for health impact calculations
struct StudyReference: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    let authors: [String]
    let journal: String
    let year: Int
    let doi: String?
    let pmid: String? // PubMed ID
    let studyType: StudyType
    let sampleSize: Int
    let followUpYears: Double?
    let effectType: HealthEffectType
    let methodology: StudyMethodology
    let qualityScore: StudyQuality // Study quality assessment
    
    // Calculation-specific properties
    let baselineValue: Double? // Control group baseline
    let interventionValue: Double? // Intervention/exposure value
    let mortalityReduction: Double? // Mortality reduction percentage
    let lifeYearsGained: Double? // Life years gained/lost
    let confidenceInterval: ConfidenceInterval?
    let applicablePopulation: PopulationCriteria
    
    // Data extraction notes
    let extractionNotes: String?
    let limitationsNotes: String?
    
    enum StudyType: String, Codable, CaseIterable {
        case metaAnalysis = "Meta-Analysis"
        case systematicReview = "Systematic Review"
        case cohortStudy = "Cohort Study"
        case randomizedControlledTrial = "RCT"
        case prospectiveCohort = "Prospective Cohort"
    }
    
    enum StudyQuality: String, Codable, CaseIterable {
        case high = "High"    // Grade A: Meta-analyses, high-quality RCTs
        case moderate = "Moderate"  // Grade B: Well-designed cohort studies
        case low = "Low"      // Grade C: Case-control, cross-sectional
    }
}

/// Defines how health effects accumulate over time based on scientific evidence
enum HealthEffectType: String, Codable, CaseIterable {
    case linearCumulative = "Linear Cumulative"     // Effects add up linearly (e.g., smoking)
    case thresholdBased = "Threshold Based"         // Effects only after sustained exposure
    case diminishingReturns = "Diminishing Returns" // Benefits plateau (e.g., exercise)
    case uShapedCurve = "U-Shaped Curve"           // Optimal range with risks on both ends (e.g., sleep)
    case logarithmic = "Logarithmic"               // Benefits decrease as exposure increases
    case exponential = "Exponential"               // Effects compound over time
    case plateau = "Plateau"                       // Maximum benefit reached quickly
    
    /// Whether simple time-period multiplication is scientifically valid
    var allowsLinearScaling: Bool {
        switch self {
        case .linearCumulative:
            return true
        case .thresholdBased, .diminishingReturns, .uShapedCurve, .logarithmic, .exponential, .plateau:
            return false
        }
    }
}

/// Study methodology details for transparency
struct StudyMethodology: Codable, Equatable {
    let exposureAssessment: String  // How exposure was measured
    let outcomeAssessment: String   // How outcomes were measured
    let adjustmentFactors: [String] // Confounders adjusted for
    let exclusionCriteria: [String] // Who was excluded
    let statisticalMethod: String   // Statistical approach used
}

/// Confidence interval for effect estimates
struct ConfidenceInterval: Codable, Equatable {
    let level: Double      // e.g., 95.0 for 95% CI
    let lowerBound: Double
    let upperBound: Double
    
    var description: String {
        return "\(Int(level))% CI: [\(String(format: "%.2f", lowerBound)), \(String(format: "%.2f", upperBound))]"
    }
}

/// Population criteria for study applicability
struct PopulationCriteria: Codable, Equatable {
    let ageRange: AgeRange?
    let gender: Gender?
    let healthStatus: [String] // e.g., ["healthy adults", "no chronic disease"]
    let geographicRegion: [String] // e.g., ["North America", "Europe"]
    let ethnicGroups: [String]?
    
    enum Gender: String, Codable, CaseIterable, Equatable {
        case male = "Male"
        case female = "Female"
        case all = "All"
    }
    
    struct AgeRange: Codable, Equatable {
        let min: Int
        let max: Int
        
        var description: String {
            return "\(min)-\(max) years"
        }
    }
}

// ResearchInstitute is defined in ResearchInstitute.swift

extension StudyReference {
    /// Create a formatted citation for display
    var citation: String {
        let authorList = authors.prefix(3).joined(separator: ", ")
        let etAl = authors.count > 3 ? " et al." : ""
        return "\(authorList)\(etAl) (\(year)). \(journal)."
    }
    
    /// Create a short citation for compact display
    var shortCitation: String {
        let firstAuthor = authors.first ?? "Unknown"
        return "\(firstAuthor) (\(year))"
    }
    
    /// Check if study is applicable to a given user profile
    func isApplicable(to userProfile: UserProfile) -> Bool {
        // Check age range
        if let ageRange = applicablePopulation.ageRange {
            let userAge = userProfile.age ?? 30 // Default age if not provided
            if userAge < ageRange.min || userAge > ageRange.max {
                return false
            }
        }
        
        // Check gender
        if let studyGender = applicablePopulation.gender,
           studyGender != .all,
           studyGender.rawValue.lowercased() != userProfile.gender?.rawValue.lowercased() {
            return false
        }
        
        return true
    }
    
    /// Get the strength of evidence score
    var evidenceStrength: Double {
        var score = 0.0
        
        // Study type scoring
        switch studyType {
        case .metaAnalysis: score += 40
        case .systematicReview: score += 35
        case .randomizedControlledTrial: score += 30
        case .prospectiveCohort: score += 25
        case .cohortStudy: score += 20
        }
        
        // Quality scoring
        switch qualityScore {
        case .high: score += 30
        case .moderate: score += 20
        case .low: score += 10
        }
        
        // Sample size scoring (logarithmic)
        if sampleSize > 0 {
            score += min(20, log10(Double(sampleSize)) * 5)
        }
        
        // Follow-up period scoring
        if let followUp = followUpYears {
            score += min(10, followUp * 2)
        }
        
        return min(100, score)
    }
} 