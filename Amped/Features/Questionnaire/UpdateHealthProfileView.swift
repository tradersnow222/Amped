import SwiftUI
import OSLog
import Combine // Added for CombineLatest
import PhotosUI // Added for profile picture functionality

/// View for updating questionnaire responses - Rules: User profile update best practices
struct UpdateHealthProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = UpdateHealthProfileViewModel()
    @State private var showingConfirmation = false
    @State private var hasChanges = false
    
    private let logger = Logger(subsystem: "com.amped.Amped", category: "UpdateHealthProfile")
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with last updated info
                    headerSection
                    
                    // Individual metric update cards
                    nutritionSection
                    smokingSection
                    alcoholSection
                    socialConnectionsSection
                    
                    // Update button
                    updateButton
                        .padding(.top, 16)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Update Health Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if hasChanges {
                            showingConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                    .foregroundColor(.ampedGreen)
                }
            }
            .alert("Discard Changes?", isPresented: $showingConfirmation) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
        }
        .onAppear {
            viewModel.loadCurrentData()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Health Factors")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let lastUpdated = viewModel.lastUpdatedDate {
                Text("Last updated \(lastUpdated, formatter: relativeDateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Text("Life changes? Update your responses to keep your battery calculations accurate.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
    }
    
    // MARK: - Metric Sections
    
    private var nutritionSection: some View {
        MetricUpdateCard(
            title: "Nutrition Quality",
            icon: "fork.knife",
            currentValue: viewModel.selectedNutritionQuality?.displayName ?? "Not set",
            helpText: "How would you rate your overall nutrition and eating habits?"
        ) {
            ForEach(QuestionnaireViewModel.NutritionQuality.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedNutritionQuality = option
                        hasChanges = true
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack {
                        Text(option.displayName)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        if viewModel.selectedNutritionQuality == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ampedGreen)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.selectedNutritionQuality == option ? 
                                  Color.ampedGreen.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var smokingSection: some View {
        MetricUpdateCard(
            title: "Smoking Status",
            icon: "smoke.fill",
            currentValue: viewModel.selectedSmokingStatus?.displayName ?? "Not set",
            helpText: "Have your smoking habits changed?"
        ) {
            ForEach(QuestionnaireViewModel.SmokingStatus.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedSmokingStatus = option
                        hasChanges = true
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack {
                        Text(option.displayName)
                            .foregroundColor(.white)
                        Spacer()
                        if viewModel.selectedSmokingStatus == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ampedGreen)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.selectedSmokingStatus == option ? 
                                  Color.ampedGreen.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var alcoholSection: some View {
        MetricUpdateCard(
            title: "Alcohol Consumption",
            icon: "wineglass",
            currentValue: viewModel.selectedAlcoholFrequency?.displayName ?? "Not set",
            helpText: "How often do you consume alcohol?"
        ) {
            ForEach(QuestionnaireViewModel.AlcoholFrequency.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedAlcoholFrequency = option
                        hasChanges = true
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack {
                        Text(option.displayName)
                            .foregroundColor(.white)
                        Spacer()
                        if viewModel.selectedAlcoholFrequency == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ampedGreen)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.selectedAlcoholFrequency == option ? 
                                  Color.ampedGreen.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                }
            }
        }
    }
    
    private var socialConnectionsSection: some View {
        MetricUpdateCard(
            title: "Social Connections",
            icon: "person.2.fill",
            currentValue: viewModel.selectedSocialConnectionsQuality?.displayName ?? "Not set",
            helpText: "How would you describe your social life and relationships?"
        ) {
            ForEach(QuestionnaireViewModel.SocialConnectionsQuality.allCases, id: \.self) { option in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedSocialConnectionsQuality = option
                        hasChanges = true
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack {
                        Text(option.displayName)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        if viewModel.selectedSocialConnectionsQuality == option {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ampedGreen)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(viewModel.selectedSocialConnectionsQuality == option ? 
                                  Color.ampedGreen.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                }
            }
        }
    }
    
    // MARK: - Update Button
    
    private var updateButton: some View {
        Button {
            Task {
                await viewModel.updateProfile()
                HapticFeedback.success()
                dismiss()
            }
        } label: {
            HStack {
                if viewModel.isUpdating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.8)
                } else {
                    Text("Update Profile")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(hasChanges ? Color.ampedGreen : Color.gray)
            .foregroundColor(.black)
            .cornerRadius(12)
        }
        .disabled(!hasChanges || viewModel.isUpdating)
    }
}

/// Complete profile editor that allows editing ALL questionnaire data
struct CompleteProfileEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CompleteProfileEditorViewModel()
    @State private var showingPhotoPicker = false
    
    private var birthDateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return "\(formatter.string(from: viewModel.birthDate)) (\(viewModel.currentAge))"
    }
    
    var body: some View {
        NavigationView {
            List {
                // Apple Health-style profile photo section
                Section {
                    HStack {
                        Spacer()
                        
                        VStack(spacing: 16) {
                            // Large tappable profile photo
                            Button {
                                showingPhotoPicker = true
                            } label: {
                                ProfileImageView(size: 100, showBorder: true)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Profile photo")
                            .accessibilityHint("Double tap to change profile picture")
                            
                            // Photo picker and remove options
                            VStack(spacing: 8) {
                                PhotosPicker(
                                    selection: $viewModel.selectedPhotoItem,
                                    matching: .images,
                                    photoLibrary: .shared()
                                ) {
                                    Text(viewModel.profileManager.profileImage == nil ? "Add Photo" : "Change Photo")
                                        .font(.subheadline)
                                        .foregroundColor(.accentColor)
                                }
                                
                                if viewModel.profileManager.profileImage != nil {
                                    Button("Remove Photo") {
                                        viewModel.profileManager.removeProfileImage()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.red)
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 20)
                }
                
                // Personal Information Section (Apple Health Style)
                Section {
                    // First Name
                    HStack {
                        Text("First Name")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("First", text: Binding(
                            get: { viewModel.userName.components(separatedBy: " ").first ?? "" },
                            set: { newValue in
                                let lastName = viewModel.userName.components(separatedBy: " ").dropFirst().joined(separator: " ")
                                viewModel.userName = lastName.isEmpty ? newValue : "\(newValue) \(lastName)"
                            }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                    }
                    
                    // Last Name
                    HStack {
                        Text("Last Name")
                            .foregroundColor(.primary)
                        Spacer()
                        TextField("Last", text: Binding(
                            get: { 
                                let components = viewModel.userName.components(separatedBy: " ")
                                return components.count > 1 ? components.dropFirst().joined(separator: " ") : ""
                            },
                            set: { newValue in
                                let firstName = viewModel.userName.components(separatedBy: " ").first ?? ""
                                viewModel.userName = firstName.isEmpty ? newValue : "\(firstName) \(newValue)"
                            }
                        ))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                    }
                    
                    // Date of Birth with Age
                    HStack {
                        Text("Date of Birth")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            DatePickerView(selectedDate: $viewModel.birthDate, validRange: viewModel.validDateRange)
                        } label: {
                            Text(birthDateDisplay)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Sex
                    HStack {
                        Text("Sex")
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink {
                            GenderPickerView(selectedGender: $viewModel.selectedGender)
                        } label: {
                            Text(viewModel.selectedGender?.displayName ?? "Not Set")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Health Factors") {
                    // Stress Level
                    Picker("Stress Level", selection: $viewModel.selectedStressLevel) {
                        Text("Select Level").tag(nil as QuestionnaireViewModel.StressLevel?)
                        ForEach(QuestionnaireViewModel.StressLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level as QuestionnaireViewModel.StressLevel?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Nutrition Quality
                    Picker("Nutrition Quality", selection: $viewModel.selectedNutritionQuality) {
                        Text("Select Quality").tag(nil as QuestionnaireViewModel.NutritionQuality?)
                        ForEach(QuestionnaireViewModel.NutritionQuality.allCases, id: \.self) { nutrition in
                            Text(nutrition.displayName).tag(nutrition as QuestionnaireViewModel.NutritionQuality?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Smoking Status
                    Picker("Smoking Status", selection: $viewModel.selectedSmokingStatus) {
                        Text("Select Status").tag(nil as QuestionnaireViewModel.SmokingStatus?)
                        ForEach(QuestionnaireViewModel.SmokingStatus.allCases, id: \.self) { smoking in
                            Text(smoking.displayName).tag(smoking as QuestionnaireViewModel.SmokingStatus?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Alcohol Consumption
                    Picker("Alcohol Consumption", selection: $viewModel.selectedAlcoholFrequency) {
                        Text("Select Frequency").tag(nil as QuestionnaireViewModel.AlcoholFrequency?)
                        ForEach(QuestionnaireViewModel.AlcoholFrequency.allCases, id: \.self) { alcohol in
                            Text(alcohol.displayName).tag(alcohol as QuestionnaireViewModel.AlcoholFrequency?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Social Connections
                    Picker("Social Connections", selection: $viewModel.selectedSocialConnectionsQuality) {
                        Text("Select Quality").tag(nil as QuestionnaireViewModel.SocialConnectionsQuality?)
                        ForEach(QuestionnaireViewModel.SocialConnectionsQuality.allCases, id: \.self) { social in
                            Text(social.displayName).tag(social as QuestionnaireViewModel.SocialConnectionsQuality?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("Preferences") {
                    // Device Tracking Status
                    Picker("Device Tracking", selection: $viewModel.selectedDeviceTrackingStatus) {
                        Text("Select Option").tag(nil as QuestionnaireViewModel.DeviceTrackingStatus?)
                        ForEach(QuestionnaireViewModel.DeviceTrackingStatus.allCases, id: \.self) { device in
                            Text(device.displayName).tag(device as QuestionnaireViewModel.DeviceTrackingStatus?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Life Motivation
                    Picker("Life Motivation", selection: $viewModel.selectedLifeMotivation) {
                        Text("Select Motivation").tag(nil as QuestionnaireViewModel.LifeMotivation?)
                        ForEach(QuestionnaireViewModel.LifeMotivation.allCases, id: \.self) { motivation in
                            Text(motivation.displayName).tag(motivation as QuestionnaireViewModel.LifeMotivation?)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section {
                    if viewModel.hasChanges {
                        Button {
                            Task {
                                await viewModel.saveChanges()
                                dismiss()
                            }
                        } label: {
                            HStack {
                                if viewModel.isSaving {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .padding(.trailing, 8)
                                }
                                Text(viewModel.isSaving ? "Saving..." : "Save Changes")
                                    .foregroundColor(viewModel.isSaving ? .secondary : .accentColor)
                            }
                        }
                        .disabled(viewModel.isSaving)
                    }
                } footer: {
                    if viewModel.hasChanges {
                        Text("Your health calculations will be updated automatically after saving.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Health Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Profile") {
                        dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        // Future: Enter edit mode
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .onAppear {
                viewModel.loadCurrentData()
            }
        }
    }
}



/// ViewModel for complete profile editor
@MainActor
class CompleteProfileEditorViewModel: ObservableObject {
    // Personal Info
    @Published var userName: String = ""
    @Published var birthDate: Date = Date()
    @Published var selectedGender: UserProfile.Gender?
    
    // Profile Picture - Use centralized manager
    @Published var selectedPhotoItem: PhotosPickerItem?
    let profileManager = ProfileImageManager.shared
    
    // Health Factors
    @Published var selectedStressLevel: QuestionnaireViewModel.StressLevel?
    @Published var selectedNutritionQuality: QuestionnaireViewModel.NutritionQuality?
    @Published var selectedSmokingStatus: QuestionnaireViewModel.SmokingStatus?
    @Published var selectedAlcoholFrequency: QuestionnaireViewModel.AlcoholFrequency?
    @Published var selectedSocialConnectionsQuality: QuestionnaireViewModel.SocialConnectionsQuality?
    
    // Preferences
    @Published var selectedDeviceTrackingStatus: QuestionnaireViewModel.DeviceTrackingStatus?
    @Published var selectedLifeMotivation: QuestionnaireViewModel.LifeMotivation?
    
    // State
    @Published var isSaving = false
    @Published var hasChanges = false
    
    private let questionnaireManager = QuestionnaireManager()
    private let logger = Logger(subsystem: "com.amped.Amped", category: "CompleteProfileEditorViewModel")
    
    // Original values for change detection
    private var originalValues: (
        userName: String,
        birthDate: Date,
        gender: UserProfile.Gender?,
        stressLevel: QuestionnaireViewModel.StressLevel?,
        nutritionQuality: QuestionnaireViewModel.NutritionQuality?,
        smokingStatus: QuestionnaireViewModel.SmokingStatus?,
        alcoholFrequency: QuestionnaireViewModel.AlcoholFrequency?,
        socialConnectionsQuality: QuestionnaireViewModel.SocialConnectionsQuality?,
        deviceTrackingStatus: QuestionnaireViewModel.DeviceTrackingStatus?,
        lifeMotivation: QuestionnaireViewModel.LifeMotivation?
    )?
    
    init() {
        // Set up change detection
        setupChangeDetection()
        // Set up photo picker handling
        setupPhotoPickerHandling()
    }
    
    var currentAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    var validDateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let minDate = calendar.date(byAdding: .year, value: -120, to: Date()) ?? Date()
        let maxDate = calendar.date(byAdding: .year, value: -5, to: Date()) ?? Date()
        return minDate...maxDate
    }
    
    func loadCurrentData() {
        logger.info("📱 Loading complete profile data for editing")
        
        // Load name
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        // Load profile data
        if let profile = questionnaireManager.getCurrentUserProfile() {
            selectedGender = profile.gender
            
            // Convert birth year back to date
            if let birthYear = profile.birthYear {
                var components = DateComponents()
                components.year = birthYear
                components.month = 1
                components.day = 1
                birthDate = Calendar.current.date(from: components) ?? Date()
            }
        }
        
        // Load questionnaire data
        if let data = questionnaireManager.loadQuestionnaireData() {
            selectedStressLevel = mapValueToStressLevel(data.stressLevel)
            selectedDeviceTrackingStatus = data.deviceTrackingStatus
            selectedLifeMotivation = data.lifeMotivation
        }
        
        // Load health factors from manual metrics
        let currentMetrics = questionnaireManager.getCurrentManualMetrics()
        for metric in currentMetrics {
            switch metric.type {
            case .nutritionQuality:
                selectedNutritionQuality = mapValueToNutrition(metric.value)
            case .smokingStatus:
                selectedSmokingStatus = mapValueToSmoking(metric.value)
            case .alcoholConsumption:
                selectedAlcoholFrequency = mapValueToAlcohol(metric.value)
            case .socialConnectionsQuality:
                selectedSocialConnectionsQuality = mapValueToSocial(metric.value)
            case .stressLevel:
                if selectedStressLevel == nil {
                    selectedStressLevel = mapValueToStressLevel(metric.value)
                }
            default:
                break
            }
        }
        
        // Store original values for change detection
        originalValues = (
            userName: userName,
            birthDate: birthDate,
            gender: selectedGender,
            stressLevel: selectedStressLevel,
            nutritionQuality: selectedNutritionQuality,
            smokingStatus: selectedSmokingStatus,
            alcoholFrequency: selectedAlcoholFrequency,
            socialConnectionsQuality: selectedSocialConnectionsQuality,
            deviceTrackingStatus: selectedDeviceTrackingStatus,
            lifeMotivation: selectedLifeMotivation
        )
        
        // Reset change flag
        hasChanges = false
    }
    
    func saveChanges() async {
        isSaving = true
        defer { isSaving = false }
        
        logger.info("💾 Saving complete profile changes")
        
        // Create a temporary questionnaire view model
        let tempViewModel = QuestionnaireViewModel()
        
        // Set all the data
        tempViewModel.userName = userName
        tempViewModel.birthdate = birthDate
        tempViewModel.selectedGender = selectedGender
        tempViewModel.selectedStressLevel = selectedStressLevel
        tempViewModel.selectedNutritionQuality = selectedNutritionQuality
        tempViewModel.selectedSmokingStatus = selectedSmokingStatus
        tempViewModel.selectedAlcoholFrequency = selectedAlcoholFrequency
        tempViewModel.selectedSocialConnectionsQuality = selectedSocialConnectionsQuality
        tempViewModel.selectedDeviceTrackingStatus = selectedDeviceTrackingStatus
        tempViewModel.selectedLifeMotivation = selectedLifeMotivation
        
        // Save through the manager
        questionnaireManager.saveQuestionnaireData(from: tempViewModel)
        
        // Post notification for dashboard to refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("QuestionnaireDataUpdated"),
            object: nil
        )
        
        logger.info("✅ Complete profile updated successfully")
        
        // Update original values
        originalValues = (
            userName: userName,
            birthDate: birthDate,
            gender: selectedGender,
            stressLevel: selectedStressLevel,
            nutritionQuality: selectedNutritionQuality,
            smokingStatus: selectedSmokingStatus,
            alcoholFrequency: selectedAlcoholFrequency,
            socialConnectionsQuality: selectedSocialConnectionsQuality,
            deviceTrackingStatus: selectedDeviceTrackingStatus,
            lifeMotivation: selectedLifeMotivation
        )
        
        hasChanges = false
    }
    
    private func setupChangeDetection() {
        // Monitor all published properties for changes
        Publishers.CombineLatest3(
            $userName,
            $birthDate,
            $selectedGender
        )
        .combineLatest(
            Publishers.CombineLatest4(
                $selectedStressLevel,
                $selectedNutritionQuality,
                $selectedSmokingStatus,
                $selectedAlcoholFrequency
            )
        )
        .combineLatest(
            Publishers.CombineLatest4(
                $selectedSocialConnectionsQuality,
                $selectedDeviceTrackingStatus,
                $selectedLifeMotivation,
                Just(true) // Placeholder to maintain CombineLatest4 structure
            )
        )
        .sink { [weak self] combinedOutput in
            self?.checkForChanges()
        }
        .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func checkForChanges() {
        guard let original = originalValues else {
            hasChanges = false
            return
        }
        
        hasChanges = userName != original.userName ||
                    birthDate != original.birthDate ||
                    selectedGender != original.gender ||
                    selectedStressLevel != original.stressLevel ||
                    selectedNutritionQuality != original.nutritionQuality ||
                    selectedSmokingStatus != original.smokingStatus ||
                    selectedAlcoholFrequency != original.alcoholFrequency ||
                    selectedSocialConnectionsQuality != original.socialConnectionsQuality ||
                    selectedDeviceTrackingStatus != original.deviceTrackingStatus ||
                    selectedLifeMotivation != original.lifeMotivation
    }
    
    // MARK: - Mapping helpers (reuse from UpdateHealthProfileViewModel)
    
    private func mapValueToStressLevel(_ value: Double?) -> QuestionnaireViewModel.StressLevel? {
        guard let value = value else { return nil }
        switch value {
        case 0..<2.5: return .veryLow
        case 2.5..<4.5: return .low
        case 4.5..<7.5: return .moderateToHigh
        case 7.5...10: return .veryHigh
        default: return nil
        }
    }
    
    private func mapValueToNutrition(_ value: Double) -> QuestionnaireViewModel.NutritionQuality? {
        switch value {
        case 9...10: return .veryHealthy
        case 7..<9: return .mostlyHealthy
        case 2..<7: return .mixedToUnhealthy
        case 0..<2: return .veryUnhealthy
        default: return nil
        }
    }
    
    private func mapValueToSmoking(_ value: Double) -> QuestionnaireViewModel.SmokingStatus? {
        switch value {
        case 9...10: return .never
        case 7..<9: return .former
        case 4..<7: return .occasionally
        case 0..<4: return .daily
        default: return nil
        }
    }
    
    private func mapValueToAlcohol(_ value: Double) -> QuestionnaireViewModel.AlcoholFrequency? {
        switch value {
        case 8...10: return .never
        case 6..<8: return .occasionally
        case 4..<6: return .severalTimesWeek
        case 0..<4: return .dailyOrHeavy
        default: return nil
        }
    }
    
    private func mapValueToSocial(_ value: Double) -> QuestionnaireViewModel.SocialConnectionsQuality? {
        switch value {
        case 8...10: return .veryStrong
        case 6..<8: return .moderateToGood
        case 4..<6: return .limited
        case 0..<4: return .isolated
        default: return nil
        }
    }
    
    // MARK: - Photo Picker Handling
    
    private func setupPhotoPickerHandling() {
        // Monitor photo picker selection changes
        $selectedPhotoItem
            .dropFirst() // Skip the initial nil value
            .compactMap { $0 } // Filter out nil values
            .sink { [weak self] photoItem in
                Task { @MainActor in
                    await self?.loadSelectedPhoto(from: photoItem)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func loadSelectedPhoto(from photoItem: PhotosPickerItem) async {
        guard let imageData = try? await photoItem.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: imageData) else {
            logger.error("Failed to load selected photo")
            return
        }
        
        // Use centralized profile manager to save the image - explicitly on main actor
        await MainActor.run {
            profileManager.saveProfileImage(uiImage)
        }
        
        // Post notification to refresh any UI displaying the profile image
        NotificationCenter.default.post(
            name: NSNotification.Name("ProfileImageUpdated"),
            object: nil
        )
        
        logger.info("Profile image updated successfully")
    }
    
 
}

// MARK: - Apple Health Style Picker Views

struct DatePickerView: View {
    @Binding var selectedDate: Date
    let validRange: ClosedRange<Date>
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Birth Date", 
                          selection: $selectedDate, 
                          in: validRange,
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

struct GenderPickerView: View {
    @Binding var selectedGender: UserProfile.Gender?
    @Environment(\.dismiss) private var dismiss
    
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

// MARK: - Supporting Views

/// Reusable card for updating individual metrics
struct MetricUpdateCard<Content: View>: View {
    let title: String
    let icon: String
    let currentValue: String
    let helpText: String
    @ViewBuilder let content: () -> Content
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
                HapticFeedback.selection()
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.ampedGreen)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(currentValue)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(helpText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 38)
                    
                    content()
                        .padding(.leading, 38)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cardBackground)
        )
    }
}

// MARK: - Date Formatter

private let relativeDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.doesRelativeDateFormatting = true
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

// MARK: - View Model

/// View model for updating health profile
class UpdateHealthProfileViewModel: ObservableObject {
    @Published var selectedNutritionQuality: QuestionnaireViewModel.NutritionQuality?
    @Published var selectedSmokingStatus: QuestionnaireViewModel.SmokingStatus?
    @Published var selectedAlcoholFrequency: QuestionnaireViewModel.AlcoholFrequency?
    @Published var selectedSocialConnectionsQuality: QuestionnaireViewModel.SocialConnectionsQuality?
    @Published var lastUpdatedDate: Date?
    @Published var isUpdating = false
    
    private let questionnaireManager = QuestionnaireManager()
    private let logger = Logger(subsystem: "com.amped.Amped", category: "UpdateHealthProfileViewModel")
    
    /// Load current questionnaire data
    func loadCurrentData() {
        logger.info("📱 Loading current questionnaire data for update")
        
        // Load from questionnaire manager
        if let data = questionnaireManager.loadQuestionnaireData() {
            lastUpdatedDate = data.savedDate
        }
        
        // Map current manual metrics to selections
        let currentMetrics = questionnaireManager.getCurrentManualMetrics()
        
        for metric in currentMetrics {
            switch metric.type {
            case .nutritionQuality:
                selectedNutritionQuality = mapValueToNutrition(metric.value)
            case .smokingStatus:
                selectedSmokingStatus = mapValueToSmoking(metric.value)
            case .alcoholConsumption:
                selectedAlcoholFrequency = mapValueToAlcohol(metric.value)
            case .socialConnectionsQuality:
                selectedSocialConnectionsQuality = mapValueToSocial(metric.value)
            default:
                break
            }
        }
    }
    
    /// Update profile with new values
    @MainActor
    func updateProfile() async {
        isUpdating = true
        defer { isUpdating = false }
        
        logger.info("💾 Updating health profile with new values")
        
        // Create a temporary view model to save through the manager
        let tempViewModel = QuestionnaireViewModel()
        
        // Transfer current values
        if let profile = questionnaireManager.getCurrentUserProfile() {
            tempViewModel.birthdate = Calendar.current.date(
                from: DateComponents(year: profile.birthYear)
            ) ?? Date()
            tempViewModel.selectedGender = profile.gender
        }
        
        // Update with new values
        tempViewModel.selectedNutritionQuality = selectedNutritionQuality
        tempViewModel.selectedSmokingStatus = selectedSmokingStatus
        tempViewModel.selectedAlcoholFrequency = selectedAlcoholFrequency
        tempViewModel.selectedSocialConnectionsQuality = selectedSocialConnectionsQuality
        
        // Save through the manager
        questionnaireManager.saveQuestionnaireData(from: tempViewModel)
        
        // Post notification for dashboard to refresh
        NotificationCenter.default.post(
            name: NSNotification.Name("QuestionnaireDataUpdated"),
            object: nil
        )
        
        logger.info("✅ Health profile updated successfully")
    }
    
    // MARK: - Mapping Helpers
    
    private func mapValueToNutrition(_ value: Double) -> QuestionnaireViewModel.NutritionQuality? {
        // Map the 1-10 scale back to enum cases
        switch value {
        case 9...10: return .veryHealthy
        case 7..<9: return .mostlyHealthy
        case 2..<7: return .mixedToUnhealthy
        case 0..<2: return .veryUnhealthy
        default: return nil
        }
    }
    
    private func mapValueToSmoking(_ value: Double) -> QuestionnaireViewModel.SmokingStatus? {
        switch value {
        case 9...10: return .never
        case 6..<9: return .former
        case 2..<6: return .occasionally
        case 0..<2: return .daily
        default: return nil
        }
    }
    
    private func mapValueToAlcohol(_ value: Double) -> QuestionnaireViewModel.AlcoholFrequency? {
        switch value {
        case 9...10: return .never
        case 7..<9: return .occasionally
        case 3..<7: return .severalTimesWeek
        case 0..<3: return .dailyOrHeavy
        default: return nil
        }
    }
    
    private func mapValueToSocial(_ value: Double) -> QuestionnaireViewModel.SocialConnectionsQuality? {
        switch value {
        case 9...10: return .veryStrong
        case 4..<9: return .moderateToGood
        case 2..<4: return .limited
        case 0..<2: return .isolated
        default: return nil
        }
    }
} 