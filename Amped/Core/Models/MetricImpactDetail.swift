import Foundation

/// Represents calculated impact details for a health metric
struct MetricImpactDetail: Codable, Equatable, Identifiable {
    let id: UUID
    let metricType: HealthMetricType
    let date: Date
    let lifespanImpactMinutes: Double
    let confidencePercentage: Double
    let comparisonToBaseline: ComparisonResult
    let studyReference: StudyReference?
    
    /// Standard initialization
    init(
        id: UUID = UUID(),
        metricType: HealthMetricType,
        date: Date = Date(),
        lifespanImpactMinutes: Double,
        confidencePercentage: Double = 0.95,
        comparisonToBaseline: ComparisonResult = .same,
        studyReference: StudyReference? = nil
    ) {
        self.id = id
        self.metricType = metricType
        self.date = date
        self.lifespanImpactMinutes = lifespanImpactMinutes
        self.confidencePercentage = confidencePercentage
        self.comparisonToBaseline = comparisonToBaseline
        self.studyReference = studyReference
    }
    
    /// Returns the impact in hours
    var lifespanImpactHours: Double {
        lifespanImpactMinutes / 60.0
    }
    
    /// Returns the impact in days
    var lifespanImpactDays: Double {
        lifespanImpactHours / 24.0
    }
    
    /// Returns the formatted impact time (most appropriate unit)
    var formattedImpact: String {
        // For very small impacts (< 1 hour), use minutes
        if abs(lifespanImpactMinutes) < 60 {
            let minutes = Int(abs(lifespanImpactMinutes))
            return "\(lifespanImpactMinutes >= 0 ? "+" : "-")\(minutes) min"
        }
        
        // For medium impacts (< 1 day), use hours
        if abs(lifespanImpactHours) < 24 {
            let hours = abs(lifespanImpactHours)
            return String(format: "\(lifespanImpactHours >= 0 ? "+" : "-")%.1f hrs", hours)
        }
        
        // For large impacts, use days
        let days = abs(lifespanImpactDays)
        return String(format: "\(lifespanImpactDays >= 0 ? "+" : "-")%.1f days", days)
    }
    
    /// Comparison result relative to baseline
    enum ComparisonResult: String, Codable {
        case muchBetter
        case better
        case slightlyBetter
        case nearBaseline
        case same
        case slightlyWorse
        case worse
        case muchWorse
        
        var symbol: String {
            switch self {
            case .muchBetter: return "arrow.up.circle.fill"
            case .better: return "arrow.up"
            case .slightlyBetter: return "arrow.up.right"
            case .nearBaseline, .same: return "arrow.forward"
            case .slightlyWorse: return "arrow.down.right"
            case .worse: return "arrow.down"
            case .muchWorse: return "arrow.down.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .muchBetter: return "Significantly better than baseline"
            case .better: return "Better than baseline"
            case .slightlyBetter: return "Slightly better than baseline"
            case .nearBaseline: return "Near baseline"
            case .same: return "About the same as baseline"
            case .slightlyWorse: return "Slightly worse than baseline"
            case .worse: return "Worse than baseline"
            case .muchWorse: return "Significantly worse than baseline"
            }
        }
        
        var color: String {
            switch self {
            case .muchBetter, .better: return "ampedGreen"
            case .slightlyBetter, .nearBaseline, .same: return "ampedYellow"
            case .slightlyWorse, .worse, .muchWorse: return "ampedRed"
            }
        }
    }
} 