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
            height: viewModel.height > 0 ? viewModel.height : nil,
            weight: viewModel.weight > 0 ? viewModel.weight : nil,
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
        var metrics = convertQuestionnaireToMetrics(from: viewModel)
        
        // If questionnaire included blood pressure category, add mapped systolic
        if let bpCategory = viewModel.selectedBloodPressureCategory {
            let systolic = mapBloodPressureCategoryToSystolic(bpCategory)
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
    
    /// Get current manual metrics for health calculations
    func getCurrentManualMetrics() -> [ManualMetricInput] {
        // Lazy-load from UserDefaults if needed to support fresh instances
        if manualMetrics.isEmpty {
            loadManualMetrics()
        }
        return manualMetrics
    }
    
    /// Get current user profile
    func getCurrentUserProfile() -> UserProfile? {
        // Lazy-load from UserDefaults if needed
        if currentUserProfile == nil {
            loadUserProfile()
        }
        return currentUserProfile
    }
    
    /// Load questionnaire data
    func loadQuestionnaireData() -> QuestionnaireData? {
        if questionnaireData == nil {
            loadQuestionnaireDataFromDefaults()
        }
        return questionnaireData
    }
    
    // MARK: - New: Persist from onboarding defaults
    
    /// Build and persist a profile and manual metrics from values saved during the custom onboarding flow
    /// This allows MetricImpactSheetContent to read real data immediately after onboarding.
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
        
        // Date of birth was saved as "\(date)"; try robust parsing
        let birthYear: Int? = {
            if let dobString = UserDefaults.standard.string(forKey: UserDefaultsKeys.userDateOfBirth) {
                if let date = ISO8601DateFormatter().date(from: dobString) {
                    return Calendar.current.component(.year, from: date)
                }
                // Try a common fallback format
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                if let date = df.date(from: dobString) {
                    return Calendar.current.component(.year, from: date)
                }
                // As a last resort, try to regex the year
                if let year = dobString.prefix(4) as Substring?, let y = Int(year) {
                    return y
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
        
        // 2) Convert saved onboarding answers → manual metrics
        var metrics: [ManualMetricInput] = []
        let now = Date()
        
        // Stress level
        if let stressAny = UserDefaults.standard.object(forKey: UserDefaultsKeys.userStressLevel) {
            if let value = parseNumericOrCategory(stressAny, category: .stressLevel) {
                metrics.append(ManualMetricInput(type: .stressLevel, value: value, date: now, notes: "Onboarding"))
            }
        }
        // Anxiety (we don’t have a separate metric; you may choose to combine into stress or ignore)
        if let anxietyAny = UserDefaults.standard.object(forKey: UserDefaultsKeys.userAnxietyLevel) {
            if let value = parseNumericOrCategory(anxietyAny, category: .stressLevel) {
                // Combine conservatively: average stress/anxiety if both exist
                if let idx = metrics.firstIndex(where: { $0.type == .stressLevel }) {
                    let current = metrics[idx].value
                    let combined = (current + value) / 2.0
                    metrics[idx] = ManualMetricInput(type: .stressLevel, value: combined, date: now, notes: "Onboarding (combined stress/anxiety)")
                } else {
                    metrics.append(ManualMetricInput(type: .stressLevel, value: value, date: now, notes: "Onboarding (from anxiety)"))
                }
            }
        }
        // Nutrition
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userDietLevel) {
            if let value = parseNumericOrCategory(any, category: .nutritionQuality) {
                metrics.append(ManualMetricInput(type: .nutritionQuality, value: value, date: now, notes: "Onboarding"))
            }
        }
        // Smoking
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userSmokeStats) {
            if let value = parseNumericOrCategory(any, category: .smokingStatus) {
                metrics.append(ManualMetricInput(type: .smokingStatus, value: value, date: now, notes: "Onboarding"))
            }
        }
        // Alcohol
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userAlcoholStats) {
            if let value = parseNumericOrCategory(any, category: .alcoholConsumption) {
                metrics.append(ManualMetricInput(type: .alcoholConsumption, value: value, date: now, notes: "Onboarding"))
            }
        }
        // Social connections
        if let any = UserDefaults.standard.object(forKey: UserDefaultsKeys.userSocialStats) {
            if let value = parseNumericOrCategory(any, category: .socialConnectionsQuality) {
                metrics.append(ManualMetricInput(type: .socialConnectionsQuality, value: value, date: now, notes: "Onboarding"))
            }
        }
        // Blood pressure (string category)
        if let bpAny = UserDefaults.standard.object(forKey: UserDefaultsKeys.userBloodPressureStats) {
            if let systolic = parseBloodPressureSystolic(bpAny) {
                metrics.append(ManualMetricInput(type: .bloodPressure, value: systolic, date: now, notes: "Onboarding"))
            }
        }
        
        saveManualMetrics(metrics)
        
        // 3) Save minimal questionnaire data snapshot (optional, derived)
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
    
    // MARK: - Helpers for onboarding parsing/mapping
    
    private enum OnboardingCategory {
        case stressLevel
        case nutritionQuality
        case smokingStatus
        case alcoholConsumption
        case socialConnectionsQuality
    }
    
    /// Try to parse a saved value (Double or String) into a 1–10 score depending on category
    private func parseNumericOrCategory(_ any: Any, category: OnboardingCategory) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String {
            if let direct = Double(s) { return direct }
            let lower = s.lowercased()
            switch category {
            case .stressLevel:
                // map common labels
                if lower.contains("very high") { return 10.0 }
                if lower.contains("high") { return 9.0 }
                if lower.contains("moderate to high") { return 7.0 }
                if lower.contains("moderate") { return 6.0 }
                if lower.contains("low") { return 2.0 }
                if lower.contains("very low") { return 1.0 }
            case .nutritionQuality:
                if lower.contains("very healthy") { return 10.0 }
                if lower.contains("mostly") { return 8.0 }
                if lower.contains("mixed") { return 6.0 }
                if lower.contains("unhealthy") { return 1.0 }
            case .smokingStatus:
                if lower.contains("never") { return 10.0 }
                if lower.contains("former") { return 6.0 }
                if lower.contains("occasion") || lower.contains("some") { return 3.0 }
                if lower.contains("daily") { return 1.0 }
            case .alcoholConsumption:
                if lower.contains("never") { return 10.0 }
                if lower.contains("occasion") { return 7.0 }
                if lower.contains("daily") || lower.contains("heavy") { return 1.5 }
                if lower.contains("several") { return 4.0 }
            case .socialConnectionsQuality:
                if lower.contains("very strong") { return 10.0 }
                if lower.contains("moderate") || lower.contains("good") { return 6.5 }
                if lower.contains("limited") { return 2.0 }
                if lower.contains("isolated") { return 1.0 }
            }
        }
        return nil
    }
    
    private func parseBloodPressureSystolic(_ any: Any) -> Double? {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let s = any as? String {
            // If user selected labels, map them; if they put a number like "125", parse it
            if let direct = Double(s) { return direct }
            let lower = s.lowercased()
            if lower.contains("below 120") || lower.contains("normal") {
                return 115.0
            }
            if lower.contains("120") || lower.contains("elevated") {
                return 125.0
            }
            if lower.contains("130") || lower.contains("80+") || lower.contains("stage") {
                return 135.0
            }
            if lower.contains("don") || lower.contains("know") || lower.contains("unknown") {
                return HealthMetricType.bloodPressure.baselineValue // use baseline if unknown
            }
        }
        return nil
    }
    
    private func mapBloodPressureCategoryToSystolic(_ category: QuestionnaireViewModel.BloodPressureCategory) -> Double {
        switch category {
        case .normal, .low:
            return 115.0
        case .elevatedToStage1, .moderate:
            return 125.0
        case .unknown, .high:
            return HealthMetricType.bloodPressure.baselineValue
        }
    }
}

