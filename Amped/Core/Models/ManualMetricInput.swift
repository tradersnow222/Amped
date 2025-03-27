import Foundation

/// Model for manually entered health metrics from questionnaires
struct ManualMetricInput: Identifiable, Codable, Equatable {
    /// Unique identifier for the metric input
    let id: String
    
    /// The type of health metric
    let type: HealthMetricType
    
    /// The value entered by the user
    let value: Double
    
    /// The date when this metric was recorded
    let date: Date
    
    /// Optional user-provided notes
    let notes: String?
    
    /// Create a new manual metric input
    init(id: String = UUID().uuidString, type: HealthMetricType, value: Double, date: Date = Date(), notes: String? = nil) {
        self.id = id
        self.type = type
        self.value = value
        self.date = date
        self.notes = notes
    }
    
    /// Create a sample for preview and testing
    static func sample(type: HealthMetricType, value: Double) -> ManualMetricInput {
        ManualMetricInput(type: type, value: value)
    }
    
    // MARK: - Sample Data
    
    /// Sample nutrition quality data
    static var mockNutrition: ManualMetricInput {
        ManualMetricInput(type: .nutritionQuality, value: 7)
    }
    
    /// Sample stress level data
    static var mockStress: ManualMetricInput {
        ManualMetricInput(type: .stressLevel, value: 4)
    }
    
    /// Sample smoking status data
    static var mockSmoking: ManualMetricInput {
        ManualMetricInput(type: .smokingStatus, value: 0)
    }
    
    /// Sample alcohol consumption data
    static var mockAlcohol: ManualMetricInput {
        ManualMetricInput(type: .alcoholConsumption, value: 2)
    }
    
    /// Sample social connections data
    static var mockSocialConnections: ManualMetricInput {
        ManualMetricInput(type: .socialConnectionsQuality, value: 8)
    }
    
    /// Convert to a standard HealthMetric
    func toHealthMetric() -> HealthMetric {
        HealthMetric(
            id: id,
            type: type,
            value: value,
            date: date,
            source: .userInput,
            impactDetails: nil
        )
    }
    
    /// Validation function to check if the input value is within expected range
    func isValid() -> Bool {
        switch type {
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