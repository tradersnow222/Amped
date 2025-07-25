import Foundation
import OSLog

/// Stores questionnaire response data
struct QuestionnaireData: Codable {
    let deviceTrackingStatus: QuestionnaireViewModel.DeviceTrackingStatus?
    let lifeMotivation: QuestionnaireViewModel.LifeMotivation?
    let nutritionQuality: Double?
    let smokingStatus: Double?
    let alcoholConsumption: Double?
    let socialConnectionsQuality: Double?
    let stressLevel: Double?
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
    
    // MARK: - Initialization
    
    init() {
        // OPTIMIZED: Initialize with minimal main thread work - defer heavy I/O
        // Load critical data first, then async load the rest
        loadUserProfileSync()
        
        // Defer non-critical loading to avoid blocking main thread
        Task { @MainActor in
            await loadDataAsync()
        }
    }
    
    /// Load critical data synchronously for immediate availability
    private func loadUserProfileSync() {
        // Only load the most essential data for immediate use
        if let data = UserDefaults.standard.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.currentUserProfile = profile
            self.hasCompletedQuestionnaire = profile.hasCompletedQuestionnaire
            logger.info("✅ Loaded user profile: Age \(profile.age ?? 0), Gender: \(profile.gender?.rawValue ?? "none")")
        } else {
            logger.warning("⚠️ No user profile found in UserDefaults with key 'user_profile'")
        }
    }
    
    /// Load all remaining data asynchronously
    private func loadDataAsync() async {
        // These can be loaded in background without blocking UI
        await Task.detached(priority: .utility) {
            await self.loadManualMetricsAsync()
            await self.loadQuestionnaireDataAsync()
        }.value
    }
    
    /// Async manual metrics loading
    private func loadManualMetricsAsync() async {
        if let data = UserDefaults.standard.data(forKey: "manual_metrics"),
           let metrics = try? JSONDecoder().decode([ManualMetricInput].self, from: data) {
            await MainActor.run {
                self.manualMetrics = metrics
            }
        }
    }
    
    /// Async questionnaire data loading
    private func loadQuestionnaireDataAsync() async {
        if let data = UserDefaults.standard.data(forKey: "questionnaire_data"),
           let questionnaire = try? JSONDecoder().decode(QuestionnaireData.self, from: data) {
            await MainActor.run {
                self.questionnaireData = questionnaire
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Save questionnaire data and update user profile
    func saveQuestionnaireData(from viewModel: QuestionnaireViewModel) {
        logger.info("💾 Saving questionnaire data to user profile")
        
        // Save user's name to UserDefaults
        UserDefaults.standard.set(viewModel.userName, forKey: "userName")
        
        // Calculate birth year from birthdate
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: viewModel.birthdate)
        
        // Create or update user profile
        let profile = UserProfile(
            id: currentUserProfile?.id ?? UUID().uuidString,
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
        
        // Save to UserDefaults
        saveUserProfile(profile)
        
        // Save questionnaire-specific data
        let questionnaireData = QuestionnaireData(
            deviceTrackingStatus: viewModel.selectedDeviceTrackingStatus,
            lifeMotivation: viewModel.selectedLifeMotivation,
            nutritionQuality: viewModel.selectedNutritionQuality?.nutritionValue,
            smokingStatus: viewModel.selectedSmokingStatus?.smokingValue,
            alcoholConsumption: viewModel.selectedAlcoholFrequency?.alcoholValue,
            socialConnectionsQuality: viewModel.selectedSocialConnectionsQuality?.socialValue,
            stressLevel: viewModel.selectedStressLevel?.stressValue, // User-selected stress level
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