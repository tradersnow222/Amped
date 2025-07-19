import SwiftUI
import OSLog

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
            .background(Color.black.ignoresSafeArea())
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
        case 4..<7: return .mixed
        case 2..<4: return .mostlyUnhealthy
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
        case 1..<3: return .daily
        case 0..<1: return .heavy
        default: return nil
        }
    }
    
    private func mapValueToSocial(_ value: Double) -> QuestionnaireViewModel.SocialConnectionsQuality? {
        switch value {
        case 9...10: return .veryStrong
        case 7..<9: return .good
        case 4..<7: return .moderate
        case 2..<4: return .limited
        case 0..<2: return .isolated
        default: return nil
        }
    }
} 