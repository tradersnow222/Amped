import SwiftUI
import StoreKit
import OSLog

/// Settings view that exactly matches native iOS Settings design and layout
struct SettingsView: View {
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var showResetConfirmation = false
    @State private var showingHealthDetails = false
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    private let logger = Logger(subsystem: "ai.ampedlife.amped", category: "SettingsView")
    
    private var userName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "Matt Snow"
    }
    
    var body: some View {
        NavigationStack {
            // Main List - completely native iOS Settings approach
            List {
                // User Profile Section - standalone section with clear separation
                Section {
                    NavigationLink {
                        ProfileDetailsView()
                    } label: {
                        HStack(spacing: 12) {
                            // Profile photo - exact iOS Settings size
                            Button {
                                // Future: Handle photo selection
                            } label: {
                                ProfileImageView(size: 60, showBorder: false, showEditIndicator: false)
                            }
                            .buttonStyle(.plain)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(userName)
                                    .font(.title3)
                                    .fontWeight(.regular)
                                    .foregroundColor(.primary)
                                
                                Text("Health metrics, life projection, and app settings")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Main Settings Section - grouped section with clear separation
                Section {
                    // Background App Refresh - matches iOS Settings style
                    NavigationLink {
                        BackgroundRefreshSettingsView()
                    } label: {
                        SettingsRowView(
                            icon: "arrow.clockwise",
                            iconColor: .blue,
                            title: "Background App Refresh"
                        )
                    }
                    
                    // Show Life as Percentage - toggle like Airplane Mode
                    SettingsToggleRowView(
                        icon: "percent",
                        iconColor: .blue,
                        title: "Show Life as Percentage",
                        isOn: $settingsManager.showLifeProjectionAsPercentage
                    )
                    
                    // Use Metric Units - toggle 
                    SettingsToggleRowView(
                        icon: "scalemass",
                        iconColor: .green,
                        title: "Use Metric Units",
                        isOn: $settingsManager.useMetricSystem
                    )
                }
                
                // Additional Settings Section - grouped section with footer
                Section {
                    // Privacy Policy
                    NavigationLink {
                        PrivacyPolicyView()
                    } label: {
                        SettingsRowView(
                            icon: "hand.raised.fill",
                            iconColor: .blue,
                            title: "Privacy Policy"
                        )
                    }
                    
                    // Terms of Service
                    NavigationLink {
                        TermsOfServiceView()
                    } label: {
                        SettingsRowView(
                            icon: "doc.text.fill",
                            iconColor: .blue,
                            title: "Terms of Service"
                        )
                    }
                    
                    // Export Health Data
                    Button {
                        // Future: Implement export functionality
                    } label: {
                        SettingsRowView(
                            icon: "square.and.arrow.up.fill",
                            iconColor: .blue,
                            title: "Export All Health Data",
                            showChevron: false
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Reset All Data (destructive action in red)
                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            // Red icon background for destructive action
                            ZStack {
                                RoundedRectangle(cornerRadius: 5.5)
                                    .fill(Color.red)
                                    .frame(width: 29, height: 29)
                                
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.white)
                            }
                            
                            Text("Reset All Data")
                                .font(.body)
                                .foregroundColor(.red)
                            
                            Spacer()
                        }
                        .padding(.vertical, 1)
                    }
                    .buttonStyle(.plain)
                } footer: {
                    Text("Your data is encrypted on your device and can only be shared with your permission.")
                        .font(.footnote)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search")
        }
        // FINAL FIX: Override the inherited environment from withDeepBackground()
        .preferredColorScheme(nil) // Allow automatic light/dark switching based on system
        .background(Color(.systemGroupedBackground)) // Ensure proper background
        .alert("Reset All Data?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This action cannot be undone. All your health data, settings, and preferences will be permanently deleted.")
        }
    }
    
    private func resetAllData() {
        settingsManager.resetToDefaults()
        QuestionnaireManager().clearAllData()
        NotificationCenter.default.post(
            name: NSNotification.Name("AppDataReset"),
            object: nil
        )
        dismiss()
    }
}

// MARK: - Search Bar (exactly like iOS Settings)

struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color(.systemGray))
                    .font(.system(size: 16, weight: .medium))
                
                TextField("Search", text: $text)
                    .textFieldStyle(.plain)
                    .foregroundColor(.primary)
                
                if !text.isEmpty {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.systemGray))
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(.systemGray5))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Settings Row Components (exactly like iOS Settings)

struct SettingsRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detailText: String?
    let showChevron: Bool
    
    init(icon: String, iconColor: Color, title: String, detailText: String? = nil, showChevron: Bool = true) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.detailText = detailText
        self.showChevron = showChevron
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with background - exactly like iOS Settings
            ZStack {
                RoundedRectangle(cornerRadius: 5.5)
                    .fill(iconColor)
                    .frame(width: 29, height: 29)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let detailText = detailText {
                Text(detailText)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .padding(.vertical, 1)
    }
}

struct SettingsToggleRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with background - exactly like iOS Settings
            ZStack {
                RoundedRectangle(cornerRadius: 5.5)
                    .fill(iconColor)
                    .frame(width: 29, height: 29)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 1)
    }
}


// MARK: - Profile Details View (Comprehensive Editable Profile)

struct ProfileDetailsView: View {
    @StateObject private var viewModel = ProfileDetailsViewModel()
    @State private var showingPhotoPicker = false
    
    var body: some View {
        // ULTRA-FAST: Always show content immediately - no loading state blocking UI
        profileContent
            .navigationTitle("Profile Details")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView()
            }
            .onAppear {
                // ULTRA-FAST: Load data AFTER view appears for smooth UX
                viewModel.loadDataIfNeeded()
            }
    }
    
    @ViewBuilder
    private var profileContent: some View {
        List {
            // Profile Photo Section - No grey background
            HStack {
                Spacer()
                
                Button {
                    showingPhotoPicker = true
                } label: {
                    ProfileImageView(size: 100, showBorder: true, showEditIndicator: true)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.vertical, 30)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            
            // Personal Information Section
            Section("Personal Information") {
                    // First Name
                    HStack {
                        Text("First Name")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditNameView(
                                title: "First Name",
                                currentValue: viewModel.firstName,
                                onSave: { newValue in
                                    viewModel.updateFirstName(newValue)
                                }
                            )
                        } label: {
                            Text(viewModel.firstName.isEmpty ? "Not Set" : viewModel.firstName)
                                .foregroundColor(viewModel.firstName.isEmpty ? .secondary : .secondary)
                        }
                    }
                    
                    // Last Name
                    HStack {
                        Text("Last Name")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditNameView(
                                title: "Last Name",
                                currentValue: viewModel.lastName,
                                onSave: { newValue in
                                    viewModel.updateLastName(newValue)
                                }
                            )
                        } label: {
                            Text(viewModel.lastName.isEmpty ? "Not Set" : viewModel.lastName)
                                .foregroundColor(viewModel.lastName.isEmpty ? .secondary : .secondary)
                        }
                    }
                    
                    // Date of Birth
                    HStack {
                        Text("Date of Birth")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditDatePickerView(
                                currentDate: viewModel.birthDate,
                                onSave: { newDate in
                                    viewModel.updateBirthDate(newDate)
                                }
                            )
                        } label: {
                            Text(viewModel.birthDateDisplay)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Sex
                    HStack {
                        Text("Sex")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditGenderPickerView(
                                currentGender: viewModel.gender,
                                onSave: { newGender in
                                    viewModel.updateGender(newGender)
                                }
                            )
                        } label: {
                            Text(viewModel.genderDisplay)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Health Lifestyle Section
                Section("Health & Lifestyle") {
                    // Nutrition Quality
                    HStack {
                        Text("Nutrition Quality")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditNutritionView(
                                currentValue: viewModel.nutritionQuality,
                                onSave: { newValue in
                                    viewModel.updateNutritionQuality(newValue)
                                }
                            )
                        } label: {
                            Text(viewModel.nutritionDisplay)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Smoking Status
                    HStack {
                        Text("Smoking Status")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditSmokingView(
                                currentValue: viewModel.smokingStatus,
                                onSave: { newValue in
                                    viewModel.updateSmokingStatus(newValue)
                                }
                            )
                        } label: {
                            Text(viewModel.smokingDisplay)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Alcohol Consumption
                    HStack {
                        Text("Alcohol Consumption")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditAlcoholView(
                                currentValue: viewModel.alcoholConsumption,
                                onSave: { newValue in
                                    viewModel.updateAlcoholConsumption(newValue)
                                }
                            )
                        } label: {
                            Text(viewModel.alcoholDisplay)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Social Connections
                    HStack {
                        Text("Social Connections")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditSocialConnectionsView(
                                currentValue: viewModel.socialConnectionsQuality,
                                onSave: { newValue in
                                    viewModel.updateSocialConnections(newValue)
                                }
                            )
                        } label: {
                            Text(viewModel.socialConnectionsDisplay)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Stress Level
                    HStack {
                        Text("Stress Level")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            EditStressLevelView(
                                currentValue: viewModel.stressLevel,
                                onSave: { newValue in
                                    viewModel.updateStressLevel(newValue)
                                }
                            )
                        } label: {
                            Text(viewModel.stressDisplay)
                                .foregroundColor(.secondary)
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Ultra-Fast Profile Details View Model

@MainActor
class ProfileDetailsViewModel: ObservableObject {
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var birthDate: Date = Date()
    @Published var gender: UserProfile.Gender = .male
    @Published var nutritionQuality: Double = 5.0
    @Published var smokingStatus: Double = 10.0  // Never smoker by default
    @Published var alcoholConsumption: Double = 10.0  // Never drink by default
    @Published var socialConnectionsQuality: Double = 5.0
    @Published var stressLevel: Double = 5.0
    @Published var isLoading: Bool = false  // ULTRA-FAST: Start with false, show UI immediately
    
    // ULTRA-FAST: Lazy initialization - only create when actually needed
    private lazy var questionnaireManager = QuestionnaireManager()
    
    // ULTRA-FAST: Cached formatters to prevent recreation
    private static let birthDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    var birthDateDisplay: String {
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        return "\(Self.birthDateFormatter.string(from: birthDate)) (\(age))"
    }
    
    var genderDisplay: String {
        gender.displayName
    }
    
    var nutritionDisplay: String {
        let quality = Int(nutritionQuality)
        switch quality {
        case 1...2: return "Poor (\(quality)/10)"
        case 3...4: return "Fair (\(quality)/10)"
        case 5...6: return "Good (\(quality)/10)"
        case 7...8: return "Very Good (\(quality)/10)"
        case 9...10: return "Excellent (\(quality)/10)"
        default: return "Not Set"
        }
    }
    
    var smokingDisplay: String {
        let status = Int(smokingStatus)
        switch status {
        case 9...10: return "Never"
        case 6...8: return "Former Smoker"
        case 2...5: return "Occasionally"
        case 0...1: return "Daily"
        default: return "Not Set"
        }
    }
    
    var alcoholDisplay: String {
        let consumption = Int(alcoholConsumption)
        switch consumption {
        case 9...10: return "Never"
        case 7...8: return "Rarely"
        case 5...6: return "Occasionally"
        case 3...4: return "Moderate"
        case 1...2: return "Regular"
        case 0: return "Heavy"
        default: return "Not Set"
        }
    }
    
    var socialConnectionsDisplay: String {
        let quality = Int(socialConnectionsQuality)
        switch quality {
        case 1...2: return "Very Limited (\(quality)/10)"
        case 3...4: return "Limited (\(quality)/10)"
        case 5...6: return "Moderate (\(quality)/10)"
        case 7...8: return "Good (\(quality)/10)"
        case 9...10: return "Excellent (\(quality)/10)"
        default: return "Not Set"
        }
    }
    
    var stressDisplay: String {
        let level = Int(stressLevel)
        switch level {
        case 1...2: return "Very Low (\(level)/10)"
        case 3...4: return "Low (\(level)/10)"
        case 5...6: return "Moderate (\(level)/10)"
        case 7...8: return "High (\(level)/10)"
        case 9...10: return "Very High (\(level)/10)"
        default: return "Not Set"
        }
    }
    
    // ULTRA-FAST: Cached data to prevent repeated loading
    private var dataCache: (profile: UserProfile?, questionnaire: QuestionnaireData?)?
    private var isDataLoaded = false
    
    init() {
        // ULTRA-FAST: NO loading in init - show UI immediately
        // Data will be loaded when sheet appears
        setupDefaultValues()
    }
    
    /// ULTRA-FAST: Setup default values immediately without I/O
    private func setupDefaultValues() {
        // Load only the most critical data synchronously from lightweight UserDefaults
        if let userName = UserDefaults.standard.string(forKey: "userName") {
            let components = userName.components(separatedBy: " ")
            self.firstName = components.first ?? ""
            self.lastName = components.dropFirst().joined(separator: " ")
        }
    }
    
    /// ULTRA-FAST: Load data AFTER sheet appears for smooth UX - with caching
    func loadDataIfNeeded() {
        // Prevent multiple loads and use cache if available
        guard !isDataLoaded else { return }
        isDataLoaded = true
        
        // ULTRA-FAST: Load data asynchronously with high priority
        Task(priority: .userInitiated) {
            await loadDataInBackground()
        }
    }
    
    private func loadDataInBackground() async {
        // Use cache if available
        if let cache = dataCache {
            updateUIFromCache(cache)
            return
        }
        
        // All heavy operations in background thread for maximum performance
        let loadedData = await Task.detached(priority: .userInitiated) {
            // Load all data in background thread - no main thread blocking
            var result = (
                profile: UserProfile?.none,
                questionnaire: QuestionnaireData?.none
            )
            
            // OPTIMIZED: Load profile data with error handling
            if let data = UserDefaults.standard.data(forKey: "user_profile") {
                do {
                    result.profile = try JSONDecoder().decode(UserProfile.self, from: data)
                } catch {
                    print("Failed to decode user profile: \(error)")
                }
            }
            
            // OPTIMIZED: Load questionnaire data with error handling
            if let data = UserDefaults.standard.data(forKey: "questionnaire_data") {
                do {
                    result.questionnaire = try JSONDecoder().decode(QuestionnaireData.self, from: data)
                } catch {
                    print("Failed to decode questionnaire data: \(error)")
                }
            }
            
            return result
        }.value
        
        // Cache the loaded data
        dataCache = loadedData
        
        // Update UI on main thread - single batch update for best performance
        updateUIFromCache(loadedData)
    }
    
    /// ULTRA-FAST: Single batch UI update to prevent multiple SwiftUI refreshes
    private func updateUIFromCache(_ cache: (profile: UserProfile?, questionnaire: QuestionnaireData?)) {
        // Process profile data
        if let profile = cache.profile {
            self.gender = profile.gender ?? .male
            
            if let birthYear = profile.birthYear {
                var components = DateComponents()
                components.year = birthYear
                components.month = 1
                components.day = 1
                self.birthDate = Calendar.current.date(from: components) ?? Date()
            }
        }
        
        // Process questionnaire data
        if let questionnaire = cache.questionnaire {
            self.nutritionQuality = questionnaire.nutritionQuality ?? 5.0
            self.smokingStatus = questionnaire.smokingStatus ?? 10.0
            self.alcoholConsumption = questionnaire.alcoholConsumption ?? 10.0
            self.socialConnectionsQuality = questionnaire.socialConnectionsQuality ?? 5.0
            self.stressLevel = questionnaire.stressLevel ?? 5.0
        }
    }
    
    // Update methods that automatically recalculate health impacts
    func updateFirstName(_ newValue: String) {
        firstName = newValue
        updateUserName()
    }
    
    func updateLastName(_ newValue: String) {
        lastName = newValue
        updateUserName()
    }
    
    private func updateUserName() {
        let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        UserDefaults.standard.set(fullName, forKey: "userName")
    }
    
    func updateBirthDate(_ newDate: Date) {
        birthDate = newDate
        updateUserProfile()
    }
    
    func updateGender(_ newGender: UserProfile.Gender) {
        gender = newGender
        updateUserProfile()
    }
    
    func updateNutritionQuality(_ newValue: Double) {
        nutritionQuality = newValue
        updateManualMetrics()
    }
    
    func updateSmokingStatus(_ newValue: Double) {
        smokingStatus = newValue
        updateManualMetrics()
    }
    
    func updateAlcoholConsumption(_ newValue: Double) {
        alcoholConsumption = newValue
        updateManualMetrics()
    }
    
    func updateSocialConnections(_ newValue: Double) {
        socialConnectionsQuality = newValue
        updateManualMetrics()
    }
    
    func updateStressLevel(_ newValue: Double) {
        stressLevel = newValue
        updateManualMetrics()
    }
    
    private func updateUserProfile() {
        // Update the user profile with new birth year and gender
        let birthYear = Calendar.current.component(.year, from: birthDate)
        
        if var profile = questionnaireManager.getCurrentUserProfile() {
            profile.birthYear = birthYear
            profile.gender = gender
            
            // Save updated profile
            do {
                let data = try JSONEncoder().encode(profile)
                UserDefaults.standard.set(data, forKey: "user_profile")
            } catch {
                print("Failed to save updated profile: \(error)")
            }
        }
        
        // Trigger recalculation
        NotificationCenter.default.post(name: NSNotification.Name("ProfileDataUpdated"), object: nil)
    }
    
    private func updateManualMetrics() {
        // Create updated manual metrics
        let currentDate = Date()
        var metrics: [ManualMetricInput] = []
        
        // Add nutrition metric
        metrics.append(ManualMetricInput(
            type: .nutritionQuality,
            value: nutritionQuality,
            date: currentDate,
            notes: "Updated from Profile Details"
        ))
        
        // Add smoking metric
        metrics.append(ManualMetricInput(
            type: .smokingStatus,
            value: smokingStatus,
            date: currentDate,
            notes: "Updated from Profile Details"
        ))
        
        // Add alcohol metric
        metrics.append(ManualMetricInput(
            type: .alcoholConsumption,
            value: alcoholConsumption,
            date: currentDate,
            notes: "Updated from Profile Details"
        ))
        
        // Add social connections metric
        metrics.append(ManualMetricInput(
            type: .socialConnectionsQuality,
            value: socialConnectionsQuality,
            date: currentDate,
            notes: "Updated from Profile Details"
        ))
        
        // Add stress level metric
        metrics.append(ManualMetricInput(
            type: .stressLevel,
            value: stressLevel,
            date: currentDate,
            notes: "Updated from Profile Details"
        ))
        
        // Save updated metrics
        do {
            let data = try JSONEncoder().encode(metrics)
            UserDefaults.standard.set(data, forKey: "manual_metrics")
        } catch {
            print("Failed to save updated manual metrics: \(error)")
        }
        
        // Update questionnaire data as well
        let questionnaireData = QuestionnaireData(
            deviceTrackingStatus: nil,
            lifeMotivation: nil,
            nutritionQuality: nutritionQuality,
            smokingStatus: smokingStatus,
            alcoholConsumption: alcoholConsumption,
            socialConnectionsQuality: socialConnectionsQuality,
            stressLevel: stressLevel,
            savedDate: currentDate
        )
        
        do {
            let data = try JSONEncoder().encode(questionnaireData)
            UserDefaults.standard.set(data, forKey: "questionnaire_data")
        } catch {
            print("Failed to save updated questionnaire data: \(error)")
        }
        
        // Trigger recalculation of health impacts
        NotificationCenter.default.post(name: NSNotification.Name("ManualMetricsUpdated"), object: nil)
    }
}

// MARK: - Picker Views

struct SettingsDatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Birth Date", 
                          selection: $selectedDate, 
                          displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                Spacer()
            }
            .padding()
            .navigationTitle("Date of Birth")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
}

struct SettingsGenderPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGender: UserProfile.Gender = .male
    
    var body: some View {
        NavigationView {
            List {
                ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                    HStack {
                        Text(gender.displayName)
                        Spacer()
                        if selectedGender == gender {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedGender = gender
                        dismiss()
                    }
                }
            }
            .navigationTitle("Sex")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
            }
        }
    }
}

// MARK: - Privacy Views

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.bottom)
                
                Group {
                    Text("Data Collection")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Amped processes all health data locally on your device. We do not collect, store, or transmit your health data to any external servers.")
                        .foregroundColor(.secondary)
                    
                    Text("With your explicit permission, we may collect anonymous usage data to improve the app experience. This data is never linked to your personal identity.")
                        .foregroundColor(.secondary)
                    
                    Text("Analytics")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("If you opt in to analytics, we collect anonymized information about app usage, features used, and performance metrics. You can disable this at any time in settings.")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.primary)
                    .padding(.bottom)
                
                Group {
                    Text("Agreement")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("By using Amped, you agree to these terms of service. The app provides health insights based on scientific research but is not a medical device or a substitute for professional medical advice.")
                        .foregroundColor(.secondary)
                    
                    Text("Limitations of Liability")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Amped is provided \"as is\" without warranties of any kind. We are not liable for any damages arising from your use of the service.")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Editor Views

struct EditNameView: View {
    let title: String
    let currentValue: String
    let onSave: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var textValue: String
    @FocusState private var isTextFieldFocused: Bool
    
    init(title: String, currentValue: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.currentValue = currentValue
        self.onSave = onSave
        self._textValue = State(initialValue: currentValue)
    }
    
    var body: some View {
        // EXACT iOS Settings name editing style - NO Cancel/Save buttons
        List {
            Section {
                TextField(title, text: $textValue)
                    .focused($isTextFieldFocused)
                    .textInputAutocapitalization(.words)
                    .disableAutocorrection(false)  // iOS Settings allows autocorrect for names
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.vertical, 11)  // Exact iOS Settings text field padding
                    .onChange(of: textValue) { newValue in
                        // Auto-save immediately like iOS Settings - no empty check needed
                        onSave(newValue)
                    }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isTextFieldFocused = true
        }
        .onDisappear {
            // Final save when leaving - save whatever is there
            onSave(textValue)
        }
    }
}

struct EditDatePickerView: View {
    let currentDate: Date
    let onSave: (Date) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: Date
    
    init(currentDate: Date, onSave: @escaping (Date) -> Void) {
        self.currentDate = currentDate
        self.onSave = onSave
        self._selectedDate = State(initialValue: currentDate)
    }
    
    var body: some View {
        // Exact iOS Settings style - date picker with auto-save
        List {
            Section {
                DatePicker("Birth Date", 
                          selection: $selectedDate,
                          in: ...Date(),
                          displayedComponents: [.date])
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .onChange(of: selectedDate) { newDate in
                        onSave(newDate)
                    }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Date of Birth")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            // Final save when leaving the view
            onSave(selectedDate)
        }
    }
}

struct EditGenderPickerView: View {
    let currentGender: UserProfile.Gender
    let onSave: (UserProfile.Gender) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGender: UserProfile.Gender
    
    init(currentGender: UserProfile.Gender, onSave: @escaping (UserProfile.Gender) -> Void) {
        self.currentGender = currentGender
        self.onSave = onSave
        self._selectedGender = State(initialValue: currentGender)
    }
    
    var body: some View {
        List {
            Section {
                ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                    HStack {
                        Text(gender.displayName)
                            .font(.body)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedGender == gender {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedGender = gender
                        onSave(gender) // Auto-save immediately like iOS Settings
                        dismiss()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Sex")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditNutritionView: View {
    let currentValue: Double
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedValue: Double
    
    // Use exact same options as questionnaire - only 4 options
    private let nutritionOptions = [
        (value: 10.0, label: "Very Healthy", description: "whole foods, plant-based"),
        (value: 8.0, label: "Mostly Healthy", description: "balanced diet"),
        (value: 3.5, label: "Mixed to Unhealthy", description: "some processed foods"),
        (value: 1.0, label: "Very Unhealthy", description: "fast food, highly processed")
    ]
    
    init(currentValue: Double, onSave: @escaping (Double) -> Void) {
        self.currentValue = currentValue
        self.onSave = onSave
        self._selectedValue = State(initialValue: currentValue)
    }
    
    var body: some View {
        List {
            Section {
                ForEach(nutritionOptions, id: \.value) { option in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.label)
                                .font(.body)
                                .foregroundColor(.primary)
                            if !option.description.isEmpty {
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if selectedValue == option.value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedValue = option.value
                        onSave(option.value) // Auto-save immediately like iOS Settings
                        dismiss()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Nutrition Quality")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditSmokingView: View {
    let currentValue: Double
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedValue: Double
    
    // Use exact same options as questionnaire - only 4 options
    private let smokingOptions = [
        (value: 10.0, label: "Never", description: ""),
        (value: 7.0, label: "Former smoker", description: "quit in the past"),
        (value: 3.0, label: "Occasionally", description: ""),
        (value: 1.0, label: "Daily", description: "")
    ]
    
    init(currentValue: Double, onSave: @escaping (Double) -> Void) {
        self.currentValue = currentValue
        self.onSave = onSave
        self._selectedValue = State(initialValue: currentValue)
    }
    
    var body: some View {
        List {
            Section {
                ForEach(smokingOptions, id: \.value) { option in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.label)
                                .font(.body)
                                .foregroundColor(.primary)
                            if !option.description.isEmpty {
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if selectedValue == option.value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedValue = option.value
                        onSave(option.value) // Auto-save immediately like iOS Settings
                        dismiss()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Smoking Status")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditAlcoholView: View {
    let currentValue: Double
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedValue: Double
    
    // Use exact same options as questionnaire - only 4 options
    private let alcoholOptions = [
        (value: 10.0, label: "Never", description: ""),
        (value: 8.0, label: "Occasionally", description: "weekly or less"),
        (value: 4.0, label: "Several Times", description: "per week"),
        (value: 1.5, label: "Daily or Heavy", description: "one or more daily")
    ]
    
    init(currentValue: Double, onSave: @escaping (Double) -> Void) {
        self.currentValue = currentValue
        self.onSave = onSave
        self._selectedValue = State(initialValue: currentValue)
    }
    
    var body: some View {
        List {
            Section {
                ForEach(alcoholOptions, id: \.value) { option in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.label)
                                .font(.body)
                                .foregroundColor(.primary)
                            if !option.description.isEmpty {
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if selectedValue == option.value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedValue = option.value
                        onSave(option.value) // Auto-save immediately like iOS Settings
                        dismiss()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Alcohol Consumption")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditSocialConnectionsView: View {
    let currentValue: Double
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedValue: Double
    
    // Use exact same options as questionnaire - only 4 options
    private let socialOptions = [
        (value: 10.0, label: "Very Strong", description: "daily interactions"),
        (value: 6.5, label: "Moderate to Good", description: "regular connections"),
        (value: 2.0, label: "Limited", description: "rare interactions"),
        (value: 1.0, label: "Isolated", description: "minimal social contact")
    ]
    
    init(currentValue: Double, onSave: @escaping (Double) -> Void) {
        self.currentValue = currentValue
        self.onSave = onSave
        self._selectedValue = State(initialValue: currentValue)
    }
    
    var body: some View {
        List {
            Section {
                ForEach(socialOptions, id: \.value) { option in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.label)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(option.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedValue == option.value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedValue = option.value
                        onSave(option.value) // Auto-save immediately like iOS Settings
                        dismiss()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Social Connections")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditStressLevelView: View {
    let currentValue: Double
    let onSave: (Double) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedValue: Double
    
    // Use exact same options as questionnaire - only 4 options
    private let stressOptions = [
        (value: 2.0, label: "Very Low", description: "rarely feel stressed"),
        (value: 3.0, label: "Low", description: "occasionally stressed"),
        (value: 6.0, label: "Moderate to High", description: "regular stress"),
        (value: 9.0, label: "Very High", description: "constantly stressed")
    ]
    
    init(currentValue: Double, onSave: @escaping (Double) -> Void) {
        self.currentValue = currentValue
        self.onSave = onSave
        self._selectedValue = State(initialValue: currentValue)
    }
    
    var body: some View {
        List {
            Section {
                ForEach(stressOptions, id: \.value) { option in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(option.label)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text(option.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedValue == option.value {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedValue = option.value
                        onSave(option.value) // Auto-save immediately like iOS Settings
                        dismiss()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Stress Level")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsManager())
}
