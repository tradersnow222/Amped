import SwiftUI
import OSLog

/// ViewModel for the before/after onboarding screen.
/// Computes current lifespan vs. potential lifespan with Amped using real services.
/// Applied rules: Simplicity is KING; MVVM; dependency injection ready via init defaults; no placeholders.
@MainActor
final class BeforeAfterComparisonViewModel: ObservableObject {
    // Inputs
    private let healthDataService: HealthDataServicing
    private let lifeProjectionService: LifeProjectionService
    private let userProfile: UserProfile
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "BeforeAfterComparisonVM")

    // Outputs
    @Published var currentPercent: CGFloat = 0
    @Published var potentialPercent: CGFloat = 0
    @Published var currentLabel: String = "You today"
    @Published var potentialLabel: String = "In a week"

    init(
        healthDataService: HealthDataServicing? = nil,
        lifeProjectionService: LifeProjectionService = LifeProjectionService(),
        userProfile: UserProfile? = nil
    ) {
        // Load profile synchronously similar to DashboardViewModel to avoid defaults
        if let profile = userProfile ?? BeforeAfterComparisonViewModel.loadUserProfileSynchronously() {
            self.userProfile = profile
        } else {
            let currentYear = Calendar.current.component(.year, from: Date())
            self.userProfile = UserProfile(
                id: UUID().uuidString,
                birthYear: currentYear - 30,
                gender: nil,
                height: nil,
                weight: nil,
                isSubscribed: false,
                hasCompletedOnboarding: false,
                hasCompletedQuestionnaire: false,
                hasGrantedHealthKitPermissions: false,
                createdAt: Date(),
                lastActive: Date()
            )
        }

        let hkManager = HealthKitManager()
        self.healthDataService = healthDataService ?? HealthDataService(healthKitManager: hkManager, userProfile: self.userProfile, questionnaireManager: QuestionnaireManager())
        self.lifeProjectionService = lifeProjectionService
    }

    func load() async {
        do {
            // Fetch period-agnostic best snapshot: use current selected day metrics from service
            let metrics = try await healthDataService.fetchHealthMetricsForPeriod(timePeriod: .day)

            // Current projection
            if let current = lifeProjectionService.calculateLifeProjection(from: metrics, userProfile: userProfile) {
                let percent = current.projectionPercentage(currentUserAge: current.currentAge)
                self.currentPercent = max(0, min(1, percent))
                self.currentLabel = "Your current lifespan"
            }

            // Optimal projection using scientifically optimal metrics
            let optimalMetrics = OptimalMetricsFactory.createScientificallyOptimalMetrics(for: userProfile)
            if let optimal = lifeProjectionService.calculateLifeProjection(from: optimalMetrics, userProfile: userProfile) {
                // Highest possible total % lifespan gain = (optimalRemaining - currentRemaining) / currentRemaining
                // Visual battery percentage reflects fraction of life remaining at optimal
                let percent = optimal.projectionPercentage(currentUserAge: optimal.currentAge)
                self.potentialPercent = max(0, min(1, percent))

                // Compute headline gain percent for subtitle
                if let current = lifeProjectionService.calculateLifeProjection(from: metrics, userProfile: userProfile) {
                    let currentRemaining = max(current.yearsRemaining, 0.1)
                    let optimalRemaining = max(optimal.yearsRemaining, 0.1)
                    let gainPercent = max(0.0, (optimalRemaining - currentRemaining) / currentRemaining)
                    let formatted = Int(round(gainPercent * 100))
                    self.potentialLabel = "Potential with Amped (+\(formatted)% more)"
                } else {
                    self.potentialLabel = "Potential with Amped"
                }
            }
        } catch {
            logger.error("Failed to load before/after projections: \(error.localizedDescription)")
        }
    }

    private static func loadUserProfileSynchronously() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "user_profile") else { return nil }
        return try? JSONDecoder().decode(UserProfile.self, from: data)
    }
}


