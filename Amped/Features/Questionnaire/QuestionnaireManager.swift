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
        setupDefaultState()
    }
    
    private func setupDefaultState() {
        hasCompletedQuestionnaire = UserDefaults.standard.bool(forKey: "hasCompletedQuestionnaire")
        
        if let cache = Self.dataCache, Self.isCacheValid {
            self.currentUserProfile = cache.profile
            self.manualMetrics = cache.metrics
            self.questionnaireData = cache.questionnaire
        }
    }
    
    func loadDataIfNeeded() async {
        if let cache = Self.dataCache, Self.isCacheValid {
            await MainActor.run {
                self.currentUserProfile = cache.profile
                self.manualMetrics = cache.metrics
                self.questionnaireData = cache.questionnaire
            }
            return
        }
        
        guard currentUserProfile == nil else { return }
        
        let loadedData = await Task.detached(priority: .userInitiated) {
            var result: (
                profile: UserProfile?,
                metrics: [ManualMetricInput],
                questionnaire: QuestionnaireData?
            ) = (nil, [], nil)
            
            if let data = UserDefaults.standard.data(forKey: "user_profile") {
                result.profile = try? JSONDecoder().decode(UserProfile.self, from: data)
            }
            if let data = UserDefaults.standard.data(forKey: "manual_metrics") {
                result.metrics = (try? JSONDecoder().decode([ManualMetricInput].self, from: data)) ?? []
            }
            if let data = UserDefaults.standard.data(forKey: "questionnaire_data") {
                result.questionnaire = try? JSONDecoder().decode(QuestionnaireData.self, from: data)
            }
            return result
        }.value
        
        Self.dataCache = loadedData
        Self.isCacheValid = true
        
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
    
    static func invalidateCache() {
        dataCache = nil
        isCacheValid = false
    }
    
    // MARK: - Public Methods
    
    func saveQuestionnaireData(from viewModel: QuestionnaireViewModel) {
        logger.info("💾 Saving questionnaire data to user profile")
        
        UserDefaults.standard.set(viewModel.userName, forKey: "userName")
        
        let birthYear = viewModel.selectedBirthYear
        
        let profile = UserProfile(
            id: currentUserProfile?.id ?? UUID().uuidString,
            firstName: viewModel.userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : viewModel.userName.components(separatedBy: " ").first,
            birthYear: birthYear,
            gender: viewModel.selectedGender,
            height: viewModel.height > 0 ? viewModel.height : nil,
            weight: viewModel.weight > 0 ? viewModel.weight : nil,
            isSubscribed: currentUserProfile?.isSubscribed ?? false,
            hasCompletedOnboarding: currentUserProfile?.hasCompletedOnboarding ?? false,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: currentUserProfile?.hasGrantedHealthKitPermissions ?? false,
            createdAt: currentUserProfile?.createdAt ?? Date(),
            lastActive: Date()
        )
        
        saveUserProfile(profile)
        Self.invalidateCache()
        
        // Keep existing sensitivity/framing/urgency pipeline
        let stress = viewModel.selectedStressLevel?.stressValue
        let anxiety = viewModel.selectedAnxietyLevel?.anxietyValue
        let normalizedStress: Double? = stress.map { min(max(($0 - 2.0) / (10.0 - 2.0) * 10.0, 0.0), 10.0) }
        let normalizedAnxiety: Double? = anxiety.map { 10.0 - $0 }
        let combinedSensitivity: Double? = {
            switch (normalizedStress, normalizedAnxiety) {
            case let (s?, a?): return (s + a) / 2.0
            case let (s?, nil): return s
            case let (nil, a?): return a
            default: return nil
            }
        }()
        
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
            stressLevel: viewModel.selectedStressLevel?.stressValue,
            emotionalSensitivity: combinedSensitivity,
            framingComfortScore: framingScore,
            urgencyResponseScore: urgencyScore,
            bloodPressureCategory: viewModel.selectedBloodPressureCategory,
            savedDate: Date()
        )
        saveQuestionnaireData(questionnaireData)
        
        var metrics = convertQuestionnaireToMetrics(from: viewModel)
        
        if let bpCategory = viewModel.selectedBloodPressureCategory {
            let level = mapBloodPressureCategoryToLevel(bpCategory)
            let systolic = ManualMetricScoring.value(for: .bloodPressure, level: level)
            let metric = ManualMetricInput(
                type: .bloodPressure,
                value: systolic,
                date: Date(),
                notes: "From questionnaire: \(bpCategory.displayName)"
            )
            metrics.append(metric)
            logger.info("🩺 Added blood pressure metric: \(Int(systolic)) mmHg")
        }
        
        saveManualMetrics(metrics)
        
        logger.info("✅ Questionnaire data saved successfully")
        logger.info("📊 Generated \(metrics.count) manual metrics from questionnaire")
        
        hasCompletedQuestionnaire = true
    }
    
    func getCurrentManualMetrics() -> [ManualMetricInput] {
        if manualMetrics.isEmpty {
            loadManualMetrics()
        }
        return manualMetrics
    }
    
    func getCurrentUserProfile() -> UserProfile? {
        if currentUserProfile == nil {
            loadUserProfile()
        }
        return currentUserProfile
    }
    
    func loadQuestionnaireData() -> QuestionnaireData? {
        if questionnaireData == nil {
            loadQuestionnaireDataFromDefaults()
        }
        return questionnaireData
    }
    
    // MARK: - Persist from onboarding defaults (centralized mapping)
    
    func saveOnboardingDataFromDefaults() {
        logger.info("💾 saveOnboardingDataFromDefaults: building profile and manual metrics from UserDefaults keys")
        
        // 1) Build UserProfile
        let existingProfile = getCurrentUserProfile()
        
        let firstName: String? = {
            let name = UserDefaults.standard.string(forKey: UserDefaultsKeys.userName) ??
                       UserDefaults.standard.string(forKey: UserDefaultsKeys.userNameLegacy)
            guard let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
            return trimmed.components(separatedBy: " ").first
        }()
        
        let gender: UserProfile.Gender? = {
            if let raw = UserDefaults.standard.string(forKey: UserDefaultsKeys.userGender),
               let g = UserProfile.Gender(rawValue: raw) {
                return g
            }
            return nil
        }()
        
        let birthYear: Int? = {
            if let dobString = UserDefaults.standard.string(forKey: UserDefaultsKeys.userDateOfBirth) {
                if let date = ISO8601DateFormatter().date(from: dobString) {
                    return Calendar.current.component(.year, from: date)
                }
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                if let date = df.date(from: dobString) {
                    return Calendar.current.component(.year, from: date)
                }
                if let year = Int(dobString.prefix(4)) {
                    return year
                }
            }
            return nil
        }()
        
        let height: Double? = {
            if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userHeight) {
                if let d = any as? Double { return d }
                if let s = any as? String, let d = Double(s) { return d }
            }
            return nil
        }()
        
        let weight: Double? = {
            if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userWeight) {
                if let d = any as? Double { return d }
                if let s = any as? String, let d = Double(s) { return d }
            }
            return nil
        }()
        
        let profile = UserProfile(
            id: existingProfile?.id ?? UUID().uuidString,
            firstName: firstName,
            birthYear: birthYear,
            gender: gender,
            height: height,
            weight: weight,
            isSubscribed: existingProfile?.isSubscribed ?? false,
            hasCompletedOnboarding: existingProfile?.hasCompletedOnboarding ?? false,
            hasCompletedQuestionnaire: true,
            hasGrantedHealthKitPermissions: existingProfile?.hasGrantedHealthKitPermissions ?? false,
            createdAt: existingProfile?.createdAt ?? Date(),
            lastActive: Date()
        )
        saveUserProfile(profile)
        
        // 2) Convert saved onboarding answers → manual metrics using one source of truth
        var metrics: [ManualMetricInput] = []
        let now = Date()
        
        // Stress
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userStressLevel),
           let level = ManualMetricScoring.level(from: "\(any)", for: .stress) {
            let value = ManualMetricScoring.value(for: .stress, level: level)
            metrics.append(ManualMetricInput(type: .stressLevel, value: value, date: now, notes: "Onboarding"))
        }
        // Anxiety (merge into stress average if present)
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userAnxietyLevel),
           let level = ManualMetricScoring.level(from: "\(any)", for: .anxiety) {
            let value = ManualMetricScoring.value(for: .anxiety, level: level)
            if let idx = metrics.firstIndex(where: { $0.type == .stressLevel }) {
                let current = metrics[idx].value
                metrics[idx] = ManualMetricInput(type: .stressLevel, value: (current + value) / 2.0, date: now, notes: "Onboarding (combined stress/anxiety)")
            } else {
                metrics.append(ManualMetricInput(type: .stressLevel, value: value, date: now, notes: "Onboarding (from anxiety)"))
            }
        }
        // Nutrition
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userDietLevel),
           let level = ManualMetricScoring.level(from: "\(any)", for: .nutrition) {
            let value = ManualMetricScoring.value(for: .nutrition, level: level)
            metrics.append(ManualMetricInput(type: .nutritionQuality, value: value, date: now, notes: "Onboarding"))
        }
        // Smoking
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userSmokeStats),
           let level = ManualMetricScoring.level(from: "\(any)", for: .smoking) {
            let value = ManualMetricScoring.value(for: .smoking, level: level)
            metrics.append(ManualMetricInput(type: .smokingStatus, value: value, date: now, notes: "Onboarding"))
        }
        // Alcohol
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userAlcoholStats),
           let level = ManualMetricScoring.level(from: "\(any)", for: .alcohol) {
            let value = ManualMetricScoring.value(for: .alcohol, level: level)
            metrics.append(ManualMetricInput(type: .alcoholConsumption, value: value, date: now, notes: "Onboarding"))
        }
        // Social
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userSocialStats),
           let level = ManualMetricScoring.level(from: "\(any)", for: .social) {
            let value = ManualMetricScoring.value(for: .social, level: level)
            metrics.append(ManualMetricInput(type: .socialConnectionsQuality, value: value, date: now, notes: "Onboarding"))
        }
        // Blood Pressure
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userBloodPressureStats) {
            let s = "\(any)"
            let level = ManualMetricScoring.level(from: s, for: .bloodPressure) ?? .high // treat unknown as .high → baseline
            let systolic = ManualMetricScoring.value(for: .bloodPressure, level: level)
            metrics.append(ManualMetricInput(type: .bloodPressure, value: systolic, date: now, notes: "Onboarding"))
        }
        
        saveManualMetrics(metrics)
        
        // 3) Save minimal questionnaire snapshot (derived)
        let qd = QuestionnaireData(
            deviceTrackingStatus: nil,
            lifeMotivation: nil,
            desiredDailyLifespanGainMinutes: nil,
            nutritionQuality: metrics.first(where: { $0.type == .nutritionQuality })?.value,
            smokingStatus: metrics.first(where: { $0.type == .smokingStatus })?.value,
            alcoholConsumption: metrics.first(where: { $0.type == .alcoholConsumption })?.value,
            socialConnectionsQuality: metrics.first(where: { $0.type == .socialConnectionsQuality })?.value,
            stressLevel: metrics.first(where: { $0.type == .stressLevel })?.value,
            emotionalSensitivity: nil,
            framingComfortScore: nil,
            urgencyResponseScore: nil,
            bloodPressureCategory: nil,
            savedDate: Date()
        )
        saveQuestionnaireData(qd)
        
        // 4) Mark completion and invalidate cache
        markQuestionnaireCompleted()
        Self.invalidateCache()
        
        logger.info("✅ saveOnboardingDataFromDefaults complete: profile + \(metrics.count) metrics saved")
    }
    
    // MARK: - Private Methods
    
    private func convertQuestionnaireToMetrics(from viewModel: QuestionnaireViewModel) -> [ManualMetricInput] {
        var metrics: [ManualMetricInput] = []
        let currentDate = Date()
        
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
            let stressMetric = ManualMetricInput(
                type: .stressLevel,
                value: 5.0,
                date: currentDate,
                notes: "Default value - moderate stress level (questionnaire not completed)"
            )
            metrics.append(stressMetric)
            logger.info("🧠 Added default stress level metric: 5.0/10 (questionnaire not completed)")
        }
        
        return metrics
    }
    
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
    
    func markQuestionnaireCompleted() {
        hasCompletedQuestionnaire = true
        UserDefaults.standard.set(true, forKey: "hasCompletedQuestionnaire")
        logger.info("✅ Questionnaire marked as completed")
    }
    
    // MARK: - BP category mapping to ManualLevel (centralized)
    
    private func mapBloodPressureCategoryToLevel(_ category: QuestionnaireViewModel.BloodPressureCategory) -> ManualLevel {
        switch category {
        case .normal, .low:
            return .low
        case .elevatedToStage1, .moderate:
            return .moderate
        case .unknown, .high:
            return .high
        }
    }
}
