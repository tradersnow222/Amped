import Foundation
import OSLog

/// Stores questionnaire response data
struct QuestionnaireData: Codable {
    let deviceTrackingStatus: QuestionnaireViewModel.DeviceTrackingStatus?
    let lifeMotivation: QuestionnaireViewModel.LifeMotivation?
    let desiredDailyLifespanGainMinutes: Int?
    let nutritionQuality: Double?
    let smokingStatus: Double?
    let alcoholConsumption: Double?
    let socialConnectionsQuality: Double?
    let stressLevel: Double?
    let emotionalSensitivity: Double?
    let framingComfortScore: Double?
    let urgencyResponseScore: Double?
    let bloodPressureCategory: QuestionnaireViewModel.BloodPressureCategory?
    let savedDate: Date
}

/// Manages questionnaire data collection, storage, and conversion to health metrics
final class QuestionnaireManager: ObservableObject {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "QuestionnaireManager")
    
    @Published var hasCompletedQuestionnaire: Bool = false
    @Published var currentUserProfile: UserProfile?
    @Published var manualMetrics: [ManualMetricInput] = []
    @Published var questionnaireData: QuestionnaireData?
    
    // ULTRA-FAST: Static cache to prevent repeated loading across instances
    private static var dataCache: (
        profile: UserProfile?,
        metrics: [ManualMetricInput],
        questionnaire: QuestionnaireData?
    )?
    
    private static var isCacheValid = false
    
    // MARK: - ULTRA-FAST Initialization
    
    init() {
        // ULTRA-FAST: ZERO main thread blocking - only set basic defaults
        // All data loading is deferred until actually needed
        setupDefaultState()
    }
    
    /// ULTRA-FAST: Setup only essential defaults without any I/O
    private func setupDefaultState() {
        // Only set basic completion state from lightweight UserDefaults check
        hasCompletedQuestionnaire = UserDefaults.standard.bool(forKey: "hasCompletedQuestionnaire")
        
        // Use cached data if available for instant access
        if let cache = Self.dataCache, Self.isCacheValid {
            self.currentUserProfile = cache.profile
            self.manualMetrics = cache.metrics
            self.questionnaireData = cache.questionnaire
        }
    }
    
    /// ULTRA-FAST: Load data on-demand when actually needed (called from ProfileDetailsViewModel)
    func loadDataIfNeeded() async {
        // Use cache if available for instant response
        if let cache = Self.dataCache, Self.isCacheValid {
            await MainActor.run {
                self.currentUserProfile = cache.profile
                self.manualMetrics = cache.metrics
                self.questionnaireData = cache.questionnaire
            }
            return
        }
        
        // Prevent multiple simultaneous loads
        guard currentUserProfile == nil else { return }
        
        // Load all data in background thread for maximum performance
        let loadedData = await Task.detached(priority: .userInitiated) {
            var result: (
                profile: UserProfile?,
                metrics: [ManualMetricInput],
                questionnaire: QuestionnaireData?
            ) = (nil, [], nil)
            
            // OPTIMIZED: Load with error handling
            if let data = UserDefaults.standard.data(forKey: "user_profile") {
                do {
                    result.profile = try JSONDecoder().decode(UserProfile.self, from: data)
                } catch {
                    print("Failed to decode user profile: \(error)")
                }
            }
            
            if let data = UserDefaults.standard.data(forKey: "manual_metrics") {
                do {
                    result.metrics = try JSONDecoder().decode([ManualMetricInput].self, from: data)
                } catch {
                    print("Failed to decode manual metrics: \(error)")
                }
            }
            
            if let data = UserDefaults.standard.data(forKey: "questionnaire_data") {
                do {
                    result.questionnaire = try JSONDecoder().decode(QuestionnaireData.self, from: data)
                } catch {
                    print("Failed to decode questionnaire data: \(error)")
                }
            }
            
            return result
        }.value
        
        // Cache the loaded data for future use
        Self.dataCache = loadedData
        Self.isCacheValid = true
        
        // Update state on main thread in single batch
        await MainActor.run {
            self.currentUserProfile = loadedData.profile
            self.manualMetrics = loadedData.metrics
            self.questionnaireData = loadedData.questionnaire
            
            if let profile = loadedData.profile {
                self.hasCompletedQuestionnaire = profile.hasCompletedQuestionnaire
                logger.info("✅ Loaded user profile: Age \(profile.age ?? 0), Gender: \(profile.gender?.rawValue ?? "none")")
            }
            
            logger.info("✅ Loaded \(loadedData.metrics.count) manual metrics")
            
            if loadedData.questionnaire != nil {
                logger.info("✅ Loaded questionnaire data")
            }
        }
    }
    
    /// ULTRA-FAST: Invalidate cache when data changes
    static func invalidateCache() {
        dataCache = nil
        isCacheValid = false
    }
    
    // MARK: - Public Methods
    
    /// Save questionnaire data and update user profile
    func saveQuestionnaireData(from viewModel: QuestionnaireViewModel) {
        logger.info("💾 Saving questionnaire data to user profile")
        
        // Save user's name to UserDefaults
        UserDefaults.standard.set(viewModel.userName, forKey: "userName")
        
        // Use the selected birth year directly from the questionnaire
        let birthYear = viewModel.selectedBirthYear
        
        // Create or update user profile
        let profile = UserProfile(
            id: currentUserProfile?.id ?? UUID().uuidString,
            firstName: viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : viewModel.userName.components(separatedBy: " ").first,
            birthYear: birthYear,
            gender: viewModel.selectedGender,
            height: nil, // Not collected in questionnaire yet
            weight: nil, // Not collected in questionnaire yet
            isSubscribed: currentUserProfile?.isSubscribed ?? false,
            hasCompletedOnboarding: currentUserProfile?.hasCompletedOnboarding ?? false,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: currentUserProfile?.hasGrantedHealthKitPermissions ?? false,
            createdAt: currentUserProfile?.createdAt ?? Date(),
            lastActive: Date()
        )
        
        // Save to UserDefaults and invalidate cache
        saveUserProfile(profile)
        Self.invalidateCache()
        
        // Save questionnaire-specific data
        // Derive combined emotional sensitivity from stress + anxiety
        let stress = viewModel.selectedStressLevel?.stressValue // 2..9 where higher worse
        let anxiety = viewModel.selectedAnxietyLevel?.anxietyValue // 1..10 where lower worse
        // Normalize to 0..10 where higher = more sensitive
        let normalizedStress: Double? = stress.map { min(max(($0 - 2.0) / (10.0 - 2.0) * 10.0, 0.0), 10.0) }
        let normalizedAnxiety: Double? = anxiety.map { 10.0 - $0 } // 10 minimal anxiety -> 0 sensitivity
        let combinedSensitivity: Double? = {
            switch (normalizedStress, normalizedAnxiety) {
            case let (s?, a?): return (s + a) / 2.0
            case let (s?, nil): return s
            case let (nil, a?): return a
            default: return nil
            }
        }()

        // Map framing comfort and urgency into numeric cues (higher => prefers gentler framing)
        let framingScore: Double? = viewModel.selectedFramingComfort.map { choice in
            switch choice {
            case .hardTruths: return 2.0
            case .encouragingWins: return 6.0
            case .gainsOnly: return 8.0
            }
        }
        let urgencyScore: Double? = viewModel.selectedUrgencyResponse.map { choice in
            switch choice {
            case .energized: return 2.0
            case .neutral: return 5.0
            case .pressured: return 8.0
            }
        }

        let questionnaireData = QuestionnaireData(
            deviceTrackingStatus: viewModel.selectedDeviceTrackingStatus,
            lifeMotivation: viewModel.selectedLifeMotivation,
            desiredDailyLifespanGainMinutes: viewModel.desiredDailyLifespanGainMinutes,
            nutritionQuality: viewModel.selectedNutritionQuality?.nutritionValue,
            smokingStatus: viewModel.selectedSmokingStatus?.smokingValue,
            alcoholConsumption: viewModel.selectedAlcoholFrequency?.alcoholValue,
            socialConnectionsQuality: viewModel.selectedSocialConnectionsQuality?.socialValue,
            stressLevel: viewModel.selectedStressLevel?.stressValue, // keep for backward compatibility
            emotionalSensitivity: combinedSensitivity,
            framingComfortScore: framingScore,
            urgencyResponseScore: urgencyScore,
            bloodPressureCategory: viewModel.selectedBloodPressureCategory,
            savedDate: Date()
        )
        saveQuestionnaireData(questionnaireData)
        
        // Convert questionnaire answers to manual metrics
        let metrics = convertQuestionnaireToMetrics(from: viewModel)
        saveManualMetrics(metrics)
        
        logger.info("✅ Questionnaire data saved successfully")
        logger.info("📊 Generated \(metrics.count) manual metrics from questionnaire")
        
        hasCompletedQuestionnaire = true
    }
    
    /// Get current manual metrics for health calculations
    func getCurrentManualMetrics() -> [ManualMetricInput] {
        return manualMetrics
    }
    
    /// Get current user profile
    func getCurrentUserProfile() -> UserProfile? {
        return currentUserProfile
    }
    
    /// Load questionnaire data
    func loadQuestionnaireData() -> QuestionnaireData? {
        return questionnaireData
    }
    
    // MARK: - Private Methods
    
    /// Convert questionnaire answers to manual metric inputs
    private func convertQuestionnaireToMetrics(from viewModel: QuestionnaireViewModel) -> [ManualMetricInput] {
        var metrics: [ManualMetricInput] = []
        let currentDate = Date()
        
        // Convert nutrition quality
        if let nutrition = viewModel.selectedNutritionQuality {
            let metric = ManualMetricInput(
                type: .nutritionQuality,
                value: nutrition.nutritionValue,
                date: currentDate,
                notes: "From questionnaire: \(nutrition.displayName)"
            )
            metrics.append(metric)
            logger.info("📋 Added nutrition metric: \(nutrition.nutritionValue)/10")
        }
        
        // Convert smoking status
        if let smoking = viewModel.selectedSmokingStatus {
            let metric = ManualMetricInput(
                type: .smokingStatus,
                value: smoking.smokingValue,
                date: currentDate,
                notes: "From questionnaire: \(smoking.displayName)"
            )
            metrics.append(metric)
            logger.info("🚭 Added smoking metric: \(smoking.smokingValue)/10")
        }
        
        // Convert alcohol consumption
        if let alcohol = viewModel.selectedAlcoholFrequency {
            let metric = ManualMetricInput(
                type: .alcoholConsumption,
                value: alcohol.alcoholValue,
                date: currentDate,
                notes: "From questionnaire: \(alcohol.displayName)"
            )
            metrics.append(metric)
            logger.info("🍷 Added alcohol metric: \(alcohol.alcoholValue)/10")
        }
        
        // Convert social connections
        if let social = viewModel.selectedSocialConnectionsQuality {
            let metric = ManualMetricInput(
                type: .socialConnectionsQuality,
                value: social.socialValue,
                date: currentDate,
                notes: "From questionnaire: \(social.displayName)"
            )
            metrics.append(metric)
            logger.info("👥 Added social connections metric: \(social.socialValue)/10")
        }
        
        // Add stress level from questionnaire
        if let stressLevel = questionnaireData?.stressLevel {
            let stressMetric = ManualMetricInput(
                type: .stressLevel,
                value: stressLevel,
                date: currentDate,
                notes: "From questionnaire: stress level \(Int(stressLevel))/10"
            )
            metrics.append(stressMetric)
            logger.info("🧠 Added stress level metric from questionnaire: \(stressLevel)/10")
        } else {
            // Fallback to default only if no questionnaire data exists
            let stressMetric = ManualMetricInput(
                type: .stressLevel,
                value: 5.0, // Default moderate stress (middle of 1-10 scale)
                date: currentDate,
                notes: "Default value - moderate stress level (questionnaire not completed)"
            )
            metrics.append(stressMetric)
            logger.info("🧠 Added default stress level metric: 5.0/10 (questionnaire not completed)")
        }
        
        return metrics
    }
    
    /// Save user profile to UserDefaults
    private func saveUserProfile(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: "user_profile")
            currentUserProfile = profile
            logger.info("💾 User profile saved to UserDefaults")
        } catch {
            logger.error("❌ Failed to save user profile: \(error.localizedDescription)")
        }
    }
    
    /// Load user profile from UserDefaults
    private func loadUserProfile() {
        guard let data = UserDefaults.standard.data(forKey: "user_profile") else {
            logger.info("📂 No existing user profile found")
            return
        }
        
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            currentUserProfile = profile
            hasCompletedQuestionnaire = profile.hasCompletedQuestionnaire
            logger.info("✅ User profile loaded from UserDefaults")
        } catch {
            logger.error("❌ Failed to load user profile: \(error.localizedDescription)")
        }
    }
    
    /// Save manual metrics to UserDefaults
    private func saveManualMetrics(_ metrics: [ManualMetricInput]) {
        do {
            let data = try JSONEncoder().encode(metrics)
            UserDefaults.standard.set(data, forKey: "manual_metrics")
            manualMetrics = metrics
            logger.info("💾 Manual metrics saved to UserDefaults")
        } catch {
            logger.error("❌ Failed to save manual metrics: \(error.localizedDescription)")
        }
    }
    
    /// Load manual metrics from UserDefaults
    private func loadManualMetrics() {
        guard let data = UserDefaults.standard.data(forKey: "manual_metrics") else {
            logger.info("📂 No existing manual metrics found")
            return
        }
        
        do {
            let metrics = try JSONDecoder().decode([ManualMetricInput].self, from: data)
            manualMetrics = metrics
            logger.info("✅ Loaded \(metrics.count) manual metrics from UserDefaults")
        } catch {
            logger.error("❌ Failed to load manual metrics: \(error.localizedDescription)")
        }
    }
    
    /// Load questionnaire data from UserDefaults
    private func loadQuestionnaireDataFromDefaults() {
        guard let data = UserDefaults.standard.data(forKey: "questionnaire_data") else {
            logger.info("📂 No existing questionnaire data found")
            return
        }
        
        do {
            let questionnaireData = try JSONDecoder().decode(QuestionnaireData.self, from: data)
            self.questionnaireData = questionnaireData
            logger.info("✅ Loaded questionnaire data from UserDefaults")
        } catch {
            logger.error("❌ Failed to load questionnaire data: \(error.localizedDescription)")
        }
    }
    
    /// Save questionnaire data to UserDefaults
    private func saveQuestionnaireData(_ questionnaireData: QuestionnaireData) {
        do {
            let data = try JSONEncoder().encode(questionnaireData)
            UserDefaults.standard.set(data, forKey: "questionnaire_data")
            self.questionnaireData = questionnaireData
            logger.info("💾 Questionnaire data saved to UserDefaults")
        } catch {
            logger.error("❌ Failed to save questionnaire data: \(error.localizedDescription)")
        }
    }
    
    /// Clear all questionnaire data (for testing or reset)
    func clearAllData() {
        UserDefaults.standard.removeObject(forKey: "user_profile")
        UserDefaults.standard.removeObject(forKey: "manual_metrics")
        UserDefaults.standard.removeObject(forKey: "questionnaire_data")
        UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")
        UserDefaults.standard.removeObject(forKey: "userName")
        currentUserProfile = nil
        manualMetrics = []
        questionnaireData = nil
        hasCompletedQuestionnaire = false
        logger.info("🗑️ All questionnaire data cleared")
    }
    
    /// Mark questionnaire as completed
    func markQuestionnaireCompleted() {
        hasCompletedQuestionnaire = true
        UserDefaults.standard.set(true, forKey: "hasCompletedQuestionnaire")
        logger.info("✅ Questionnaire marked as completed")
    }
}
