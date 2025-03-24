import Foundation

/// User-provided health data from questionnaire
struct ManualMetricInput: Identifiable, Codable, Equatable {
    let id: UUID
    let metricType: HealthMetricType
    let value: Double
    let date: Date
    let notes: String?
    
    /// Standard initialization
    init(
        id: UUID = UUID(),
        metricType: HealthMetricType,
        value: Double,
        date: Date = Date(),
        notes: String? = nil
    ) {
        self.id = id
        self.metricType = metricType
        self.value = value
        self.date = date
        self.notes = notes
    }
    
    /// Convert to a standard HealthMetric
    func toHealthMetric() -> HealthMetric {
        HealthMetric(
            id: id,
            type: metricType,
            value: value,
            date: date
        )
    }
    
    /// Validation function to check if the input value is within expected range
    func isValid() -> Bool {
        switch metricType {
        case .nutritionQuality:
            return value >= 0 && value <= 10
        case .stressLevel:
            return value >= 0 && value <= 10
        default:
            // For any non-manual metrics, validate based on reasonable ranges
            // This is just a fallback since manual inputs should be limited to manual metrics
            return value >= 0
        }
    }
    
    static func == (lhs: ManualMetricInput, rhs: ManualMetricInput) -> Bool {
        lhs.id == rhs.id
    }
} 