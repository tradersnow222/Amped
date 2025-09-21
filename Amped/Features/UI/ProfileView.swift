import SwiftUI
import Combine
import PhotosUI
import UIKit

// Import required models and view models
// Note: These will be available at runtime from the main app bundle

/// Profile View - User profile and health metrics overview
struct ProfileView: View {
    // MARK: - State Variables
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject private var profileManager = ProfileImageManager.shared
    @StateObject private var questionnaireManager = QuestionnaireManager()
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    // Edit questionnaire metrics states
    @State private var showingNutritionEdit = false
    @State private var showingSmokingEdit = false
    @State private var showingAlcoholEdit = false
    @State private var showingSocialEdit = false
    @State private var showingStressEdit = false
    
    // Edit height and weight states
    @State private var showingHeightEdit = false
    @State private var showingWeightEdit = false
    
    // MARK: - Computed Properties
    private var userProfile: UserProfile {
        viewModel.userProfile
    }
    
    private var displayName: String {
        UserDefaults.standard.string(forKey: "userName") ?? "User"
    }
    
    private var displayAge: Int {
        userProfile.age ?? 0
    }
    
    private var displayGender: String {
        userProfile.gender?.displayName ?? "Not specified"
    }
    
    private var displayBirthYear: String {
        if let birthYear = userProfile.birthYear {
            return "Born: \(birthYear)"
        }
        return "Birth year: Not set"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                personalizedHeader
                
                // Main Content
                ScrollView {
                    VStack(spacing: 16) {
                        // Profile Information Card
                        profileInformationCard
                        
                        // Health Metrics Section
                        healthMetricsSection
                        
                        Spacer(minLength: 100) // Space for bottom navigation
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingEditProfile) {
                EditProfileView(viewModel: viewModel, profileManager: profileManager)
            }
            .onAppear {
                // Load questionnaire data when view appears
                Task {
                    await questionnaireManager.loadDataIfNeeded()
                }
            }
            .sheet(isPresented: $showingNutritionEdit) {
                NutritionEditView(questionnaireManager: questionnaireManager)
            }
            .sheet(isPresented: $showingSmokingEdit) {
                SmokingEditView(questionnaireManager: questionnaireManager)
            }
            .sheet(isPresented: $showingAlcoholEdit) {
                AlcoholEditView(questionnaireManager: questionnaireManager)
            }
            .sheet(isPresented: $showingSocialEdit) {
                SocialConnectionsEditView(questionnaireManager: questionnaireManager)
            }
            .sheet(isPresented: $showingStressEdit) {
                StressLevelEditView(questionnaireManager: questionnaireManager)
            }
            .sheet(isPresented: $showingHeightEdit) {
                HeightEditView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingWeightEdit) {
                WeightEditView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Header Components
    
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: true, userProfile: userProfile)
    }
    
    // MARK: - Profile Information Card
    
    private var profileInformationCard: some View {
        VStack(spacing: 16) {
            HStack {
                // Profile Picture
                ZStack {
                    if let profileImage = profileManager.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                    } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.ampedGreen,.ampedGreen, .ampedYellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                    }
                }
                
                Spacer().frame(width:12)
                
                // Profile Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(displayName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    Text(displayBirthYear)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Age: \(displayAge) • \(displayGender)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                // Edit Button - positioned at bottom right
                        Button(action: {
                            showingEditProfile = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.white)
                        }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
    }
    
    // MARK: - Questionnaire Metric Helpers
    
    private func formatNutritionQuality(_ value: Double?) -> (displayText: String, color: Color) {
        guard let value = value else { return ("Not Set", .gray) }
        
        switch value {
        case 8.0...10.0: return ("Good (\(Int(value))/10)", .green)
        case 5.0..<8.0: return ("Moderate (\(Int(value))/10)", .yellow)
        case 1.0..<5.0: return ("Poor (\(Int(value))/10)", .orange)
        default: return ("Not Set", .gray)
        }
    }
    
    private func formatSmokingStatus(_ value: Double?) -> (displayText: String, color: Color) {
        guard let value = value else { return ("Not Set", .gray) }
        
        switch value {
        case 10.0: return ("Never", .green)
        case 7.0: return ("Former", .yellow)
        case 3.0: return ("Occasionally", .orange)
        case 1.0: return ("Daily", .red)
        default: return ("Not Set", .gray)
        }
    }
    
    private func formatAlcoholConsumption(_ value: Double?) -> (displayText: String, color: Color) {
        guard let value = value else { return ("Not Set", .gray) }
        
        switch value {
        case 8.0...10.0: return ("Never", .green)
        case 4.0..<8.0: return ("Occasionally", .yellow)
        case 1.5..<4.0: return ("Several Times/Week", .orange)
        case 1.0..<1.5: return ("Daily/Heavy", .red)
        default: return ("Not Set", .gray)
        }
    }
    
    private func formatSocialConnections(_ value: Double?) -> (displayText: String, color: Color) {
        guard let value = value else { return ("Not Set", .gray) }
        
        switch value {
        case 8.0...10.0: return ("Strong (\(Int(value))/10)", .green)
        case 5.0..<8.0: return ("Moderate (\(Int(value))/10)", .yellow)
        case 2.0..<5.0: return ("Limited (\(Int(value))/10)", .orange)
        case 1.0..<2.0: return ("Isolated (\(Int(value))/10)", .red)
        default: return ("Not Set", .gray)
        }
    }
    
    private func formatStressLevel(_ value: Double?) -> (displayText: String, color: Color) {
        guard let value = value else { return ("Not Set", .gray) }
        
        switch value {
        case 1.0..<3.0: return ("Low (\(Int(value))/10)", .green)
        case 3.0..<6.0: return ("Moderate (\(Int(value))/10)", .yellow)
        case 6.0..<9.0: return ("High (\(Int(value))/10)", .orange)
        case 9.0...10.0: return ("Very High (\(Int(value))/10)", .red)
        default: return ("Not Set", .gray)
        }
    }
    
    // MARK: - Health Metrics Section
    
    private var healthMetricsSection: some View {
        VStack(spacing: 12) {
            // Height
            if let height = userProfile.height {
                healthMetricRow(
                    title: "Height",
                    answer: String(format: "%.1f cm", height),
                    color: .green,
                    onTap: {
                        showingHeightEdit = true
                    }
                )
            }
            
            // Weight
            if let weight = userProfile.weight {
                healthMetricRow(
                    title: "Weight",
                    answer: String(format: "%.1f kg", weight),
                    color: .green,
                    onTap: {
                        showingWeightEdit = true
                    }
                )
            }
            
            // Nutrition Quality
            let nutrition = formatNutritionQuality(questionnaireManager.questionnaireData?.nutritionQuality)
            healthMetricRow(
                title: "Nutrition Quality",
                answer: nutrition.displayText,
                color: nutrition.color,
                onTap: {
                    showingNutritionEdit = true
                }
            )
            
            // Smoking Status
            let smoking = formatSmokingStatus(questionnaireManager.questionnaireData?.smokingStatus)
            healthMetricRow(
                title: "Smoking Status",
                answer: smoking.displayText,
                color: smoking.color,
                onTap: {
                    showingSmokingEdit = true
                }
            )
            
            // Alcohol Consumption
            let alcohol = formatAlcoholConsumption(questionnaireManager.questionnaireData?.alcoholConsumption)
            healthMetricRow(
                title: "Alcohol Consumption",
                answer: alcohol.displayText,
                color: alcohol.color,
                onTap: {
                    showingAlcoholEdit = true
                }
            )
            
            // Social Connections
            let social = formatSocialConnections(questionnaireManager.questionnaireData?.socialConnectionsQuality)
            healthMetricRow(
                title: "Social Connections",
                answer: social.displayText,
                color: social.color,
                onTap: {
                    showingSocialEdit = true
                }
            )
            
            // Stress Level
            let stress = formatStressLevel(questionnaireManager.questionnaireData?.stressLevel)
            healthMetricRow(
                title: "Stress Level",
                answer: stress.displayText,
                color: stress.color,
                onTap: {
                    showingStressEdit = true
                }
            )
        }
    }
    
    // MARK: - Health Metric Row
    
    private func healthMetricRow(title: String, answer: String, value: Int? = nil, maxValue: Int? = nil, color: Color, onTap: (() -> Void)? = nil) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                HStack {
                    Text("Answer:")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(answer)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
        )
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var profileManager: ProfileImageManager
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedGender: UserProfile.Gender = .male
    @State private var showingGenderPicker = false
    @State private var showingAgePicker = false
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingCropper = false
    @State private var imageToCrop: UIImage?
    
    var body: some View {
        VStack(spacing: 24) {
            // Profile Picture Section
            profilePictureSection
            
            // Input Fields
            inputFieldsSection
            
            // Save Button
            saveButton
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .background(Color.black)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadCurrentProfileData()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        )
                }
            }
            
            ToolbarItem(placement: .principal) {
                Text("Edit profile")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var profilePictureSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Profile image or default avatar
                if let profileImage = profileManager.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.ampedGreen, .ampedYellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                        .overlay(
                Image(systemName: "person")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                        )
                }
                
                // Edit Button - pencil icon at bottom right corner
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.black)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .frame(width: 100, height: 100)
            .onTapGesture {
                showingImagePicker = true
            }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
        .sheet(isPresented: $showingCropper) {
            if let imageToCrop = imageToCrop {
                ImageCropperView(
                    image: imageToCrop,
                    onCrop: { croppedImage in
                        profileManager.saveProfileImage(croppedImage)
                        showingCropper = false
                        self.imageToCrop = nil
                    },
                    onCancel: {
                        showingCropper = false
                        self.imageToCrop = nil
                    }
                )
            }
        }
        .onChange(of: selectedItem) { newItem in
            Task {
                if let newItem = newItem,
                   let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        imageToCrop = image
                        showingCropper = true
                    }
                }
            }
        }
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 16) {
            // Name Field
            ZStack(alignment: .leading) {
                if name.isEmpty {
                    Text("Enter your full name")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 39/255, green: 39/255, blue: 39/255, opacity: 0.4))
                        .padding(.horizontal, 16)
                }
                
                TextField("", text: $name)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red:35/255,green:57/255, blue:32/255))
                    .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .accentColor(.black)
            
            // Age Field
            Button(action: {
                showingAgePicker = true
            }) {
            HStack {
                    Text(age.isEmpty ? "Select your age" : "\(age) years old")
                    .font(.system(size: 14, weight: .regular))
                        .foregroundColor(age.isEmpty ? Color(red: 39/255, green: 39/255, blue: 39/255, opacity: 0.4) : Color(red:35/255,green:57/255, blue:32/255))
                
                Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red:35/255,green:57/255, blue:32/255))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            }
            .sheet(isPresented: $showingAgePicker) {
                ProfileAgePickerView(selectedAge: $age)
            }
            
            // Gender Field
            Button(action: {
                showingGenderPicker = true
            }) {
            HStack {
                    Text(selectedGender.displayName)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(red:35/255,green:57/255, blue:32/255))
                
                Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red:35/255,green:57/255, blue:32/255))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            }
            .sheet(isPresented: $showingGenderPicker) {
                ProfileGenderPickerView(selectedGender: $selectedGender)
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            saveProfile()
        }) {
            Text("Save Changes")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isFormValid ? Color.ampedGreen : Color.gray.opacity(0.3))
                )
        }
        .disabled(!isFormValid)
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !age.isEmpty &&
        Int(age) != nil
    }
    
    // MARK: - Methods
    
    private func loadCurrentProfileData() {
        // Load current name from UserDefaults
        name = UserDefaults.standard.string(forKey: "userName") ?? ""
        
        // Load current age from userProfile
        if let currentAge = viewModel.userProfile.age {
            age = String(currentAge)
        }
        
        // Load current gender from userProfile
        if let currentGender = viewModel.userProfile.gender {
            selectedGender = currentGender
        }
    }
    
    private func saveProfile() {
        guard let ageInt = Int(age) else { return }
        
        // Update the profile through the view model
        viewModel.updateUserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            age: ageInt,
            gender: selectedGender
        )
        
        // Dismiss the view
        dismiss()
    }
}

// MARK: - Picker Views

struct ProfileAgePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAge: String
    @State private var tempAge: String = ""
    
    private let ages = Array(18...100)
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Age", selection: $tempAge) {
                    ForEach(ages, id: \.self) { age in
                        Text("\(age) years old").tag(String(age))
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedAge = tempAge
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempAge = selectedAge
            }
        }
    }
}

struct ProfileGenderPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedGender: UserProfile.Gender
    @State private var tempGender: UserProfile.Gender = .male
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Gender", selection: $tempGender) {
                    ForEach(UserProfile.Gender.allCases, id: \.self) { gender in
                        Text(gender.displayName).tag(gender)
                    }
                }
                .pickerStyle(WheelPickerStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Gender")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedGender = tempGender
                        dismiss()
                    }
                }
            }
            .onAppear {
                tempGender = selectedGender
            }
        }
    }
}

// MARK: - Edit Views for Questionnaire Metrics

struct NutritionEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var questionnaireManager: QuestionnaireManager
    @State private var selectedNutrition: QuestionnaireViewModel.NutritionQuality?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Nutrition Quality")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("How would you describe your overall nutrition quality?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.NutritionQuality.allCases, id: \.self) { nutrition in
                        Button(action: {
                            selectedNutrition = nutrition
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(nutrition.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text(nutrition.subText)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(selectedNutrition == nutrition ? .white.opacity(0.8) : .gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(
                                        selectedNutrition == nutrition ? 
                                        LinearGradient(
                                            colors: [Color("ampedGreen"), Color("ampedYellow")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.black, Color.black],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let selected = selectedNutrition {
                            saveNutritionQuality(selected)
                        }
                        dismiss()
                    }
                    .foregroundColor(selectedNutrition != nil ? Color("ampedGreen") : .gray)
                    .disabled(selectedNutrition == nil)
                }
            }
        }
        .onAppear {
            // Set current selection if available
            if let currentData = questionnaireManager.questionnaireData?.nutritionQuality {
                selectedNutrition = QuestionnaireViewModel.NutritionQuality.allCases.first { $0.nutritionValue == currentData }
            }
        }
    }
    
    private func saveNutritionQuality(_ nutrition: QuestionnaireViewModel.NutritionQuality) {
        // Update the questionnaire data
        Task {
            await questionnaireManager.updateNutritionQuality(nutrition)
        }
    }
}

struct SmokingEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var questionnaireManager: QuestionnaireManager
    @State private var selectedSmoking: QuestionnaireViewModel.SmokingStatus?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Smoking Status")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("What is your current smoking status?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.SmokingStatus.allCases, id: \.self) { status in
                        Button(action: {
                            selectedSmoking = status
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(status.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                if !status.subText.isEmpty {
                                    Text(status.subText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(selectedSmoking == status ? .white.opacity(0.8) : .gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, status.subText.isEmpty ? 18 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(
                                        selectedSmoking == status ? 
                                        LinearGradient(
                                            colors: [Color("ampedGreen"), Color("ampedYellow")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.black, Color.black],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let selected = selectedSmoking {
                            saveSmokingStatus(selected)
                        }
                        dismiss()
                    }
                    .foregroundColor(selectedSmoking != nil ? Color("ampedGreen") : .gray)
                    .disabled(selectedSmoking == nil)
                }
            }
        }
        .onAppear {
            // Set current selection if available
            if let currentData = questionnaireManager.questionnaireData?.smokingStatus {
                selectedSmoking = QuestionnaireViewModel.SmokingStatus.allCases.first { $0.smokingValue == currentData }
            }
        }
    }
    
    private func saveSmokingStatus(_ status: QuestionnaireViewModel.SmokingStatus) {
        // Update the questionnaire data
        Task {
            await questionnaireManager.updateSmokingStatus(status)
        }
    }
}

struct AlcoholEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var questionnaireManager: QuestionnaireManager
    @State private var selectedAlcohol: QuestionnaireViewModel.AlcoholFrequency?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Alcohol Consumption")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("How often do you consume alcohol?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.AlcoholFrequency.allCases, id: \.self) { frequency in
                        Button(action: {
                            selectedAlcohol = frequency
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(frequency.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)

                                if !frequency.subText.isEmpty {
                                    Text(frequency.subText)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(selectedAlcohol == frequency ? .white.opacity(0.8) : .gray)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, frequency.subText.isEmpty ? 18 : 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(
                                        selectedAlcohol == frequency ? 
                                        LinearGradient(
                                            colors: [Color("ampedGreen"), Color("ampedYellow")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.black, Color.black],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let selected = selectedAlcohol {
                            saveAlcoholFrequency(selected)
                        }
                        dismiss()
                    }
                    .foregroundColor(selectedAlcohol != nil ? Color("ampedGreen") : .gray)
                    .disabled(selectedAlcohol == nil)
                }
            }
        }
        .onAppear {
            // Set current selection if available
            if let currentData = questionnaireManager.questionnaireData?.alcoholConsumption {
                selectedAlcohol = QuestionnaireViewModel.AlcoholFrequency.allCases.first { $0.alcoholValue == currentData }
            }
        }
    }
    
    private func saveAlcoholFrequency(_ frequency: QuestionnaireViewModel.AlcoholFrequency) {
        // Update the questionnaire data
        Task {
            await questionnaireManager.updateAlcoholFrequency(frequency)
        }
    }
}

struct SocialConnectionsEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var questionnaireManager: QuestionnaireManager
    @State private var selectedSocial: QuestionnaireViewModel.SocialConnectionsQuality?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Social Connections")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("How would you describe the quality of your social connections?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.SocialConnectionsQuality.allCases, id: \.self) { quality in
                        Button(action: {
                            selectedSocial = quality
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(quality.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text(quality.subText)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(selectedSocial == quality ? .white.opacity(0.8) : .gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(
                                        selectedSocial == quality ? 
                                        LinearGradient(
                                            colors: [Color("ampedGreen"), Color("ampedYellow")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.black, Color.black],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let selected = selectedSocial {
                            saveSocialConnections(selected)
                        }
                        dismiss()
                    }
                    .foregroundColor(selectedSocial != nil ? Color("ampedGreen") : .gray)
                    .disabled(selectedSocial == nil)
                }
            }
        }
        .onAppear {
            // Set current selection if available
            if let currentData = questionnaireManager.questionnaireData?.socialConnectionsQuality {
                selectedSocial = QuestionnaireViewModel.SocialConnectionsQuality.allCases.first { $0.socialValue == currentData }
            }
        }
    }
    
    private func saveSocialConnections(_ quality: QuestionnaireViewModel.SocialConnectionsQuality) {
        // Update the questionnaire data
        Task {
            await questionnaireManager.updateSocialConnections(quality)
        }
    }
}

struct StressLevelEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var questionnaireManager: QuestionnaireManager
    @State private var selectedStress: QuestionnaireViewModel.StressLevel?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Stress Level")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("How would you describe your typical stress level?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Options
                VStack(spacing: 16) {
                    ForEach(QuestionnaireViewModel.StressLevel.allCases, id: \.self) { level in
                        Button(action: {
                            selectedStress = level
                        }) {
                            VStack(alignment: .center, spacing: 4) {
                                Text(level.mainText)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                
                                Text(level.subText)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(selectedStress == level ? .white.opacity(0.8) : .gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 100)
                                    .fill(
                                        selectedStress == level ? 
                                        LinearGradient(
                                            colors: [Color("ampedGreen"), Color("ampedYellow")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) :
                                        LinearGradient(
                                            colors: [Color.black, Color.black],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.2), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let selected = selectedStress {
                            saveStressLevel(selected)
                        }
                        dismiss()
                    }
                    .foregroundColor(selectedStress != nil ? Color("ampedGreen") : .gray)
                    .disabled(selectedStress == nil)
                }
            }
        }
        .onAppear {
            // Set current selection if available
            if let currentData = questionnaireManager.questionnaireData?.stressLevel {
                selectedStress = QuestionnaireViewModel.StressLevel.allCases.first { $0.stressValue == currentData }
            }
        }
    }
    
    private func saveStressLevel(_ level: QuestionnaireViewModel.StressLevel) {
        // Update the questionnaire data
        Task {
            await questionnaireManager.updateStressLevel(level)
        }
    }
}

// MARK: - Height and Weight Edit Views

struct HeightEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    @State private var heightText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Height")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Enter your height in centimeters")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (cm)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    TextField("Enter height", text: $heightText)
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveHeight()
                        dismiss()
                    }
                    .foregroundColor(isValidHeight ? Color("ampedGreen") : .gray)
                    .disabled(!isValidHeight)
                }
            }
        }
        .onAppear {
            // Set current height if available
            if let height = viewModel.userProfile.height {
                heightText = String(format: "%.1f", height)
            }
            // Focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private var isValidHeight: Bool {
        guard let height = Double(heightText), height > 0, height < 300 else {
            return false
        }
        return true
    }
    
    private func saveHeight() {
        guard let height = Double(heightText), height > 0, height < 300 else { return }
        
        // Update the user profile
        Task {
            await viewModel.updateUserProfile(height: height)
        }
    }
}

struct WeightEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    @State private var weightText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Title
                VStack(spacing: 8) {
                    Text("Weight")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Enter your weight in kilograms")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                // Input Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    TextField("Enter weight", text: $weightText)
                        .keyboardType(.decimalPad)
                        .focused($isTextFieldFocused)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 39/255, green: 39/255, blue: 39/255))
                        )
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveWeight()
                        dismiss()
                    }
                    .foregroundColor(isValidWeight ? Color("ampedGreen") : .gray)
                    .disabled(!isValidWeight)
                }
            }
        }
        .onAppear {
            // Set current weight if available
            if let weight = viewModel.userProfile.weight {
                weightText = String(format: "%.1f", weight)
            }
            // Focus the text field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private var isValidWeight: Bool {
        guard let weight = Double(weightText), weight > 0, weight < 500 else {
            return false
        }
        return true
    }
    
    private func saveWeight() {
        guard let weight = Double(weightText), weight > 0, weight < 500 else { return }
        
        // Update the user profile
        Task {
            await viewModel.updateUserProfile(weight: weight)
        }
    }
}

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
        .preferredColorScheme(.dark)
    }
}
