import SwiftUI
import Combine

// Import required models and view models
// Note: These will be available at runtime from the main app bundle

/// Profile View - User profile and health metrics overview
struct ProfileView: View {
    // MARK: - State Variables
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
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
                EditProfileView(viewModel: viewModel)
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
    
    // MARK: - Health Metrics Section
    
    private var healthMetricsSection: some View {
        VStack(spacing: 12) {
            // Height
            if let height = userProfile.height {
                healthMetricRow(
                    title: "Height",
                    answer: String(format: "%.1f cm", height),
                    color: .green
                )
            }
            
            // Weight
            if let weight = userProfile.weight {
                healthMetricRow(
                    title: "Weight",
                    answer: String(format: "%.1f kg", weight),
                    color: .green
                )
            }
            
            // HealthKit Status
            healthMetricRow(
                title: "HealthKit Access",
                answer: userProfile.hasGrantedHealthKitPermissions ? "Connected" : "Not Connected",
                color: userProfile.hasGrantedHealthKitPermissions ? .green : .orange
            )
            
            // Subscription Status
            healthMetricRow(
                title: "Subscription",
                answer: userProfile.isSubscribed ? "Active" : "Free Plan",
                color: userProfile.isSubscribed ? .green : .orange
            )
            
            // Onboarding Status
            healthMetricRow(
                title: "Setup Complete",
                answer: userProfile.hasCompletedOnboarding ? "Complete" : "In Progress",
                color: userProfile.hasCompletedOnboarding ? .green : .orange
            )
        }
    }
    
    // MARK: - Health Metric Row
    
    private func healthMetricRow(title: String, answer: String, value: Int? = nil, maxValue: Int? = nil, color: Color) -> some View {
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
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: DashboardViewModel
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var selectedGender: UserProfile.Gender = .male
    @State private var showingGenderPicker = false
    @State private var showingAgePicker = false
    
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
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.ampedGreen, .ampedYellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
                
                // Edit Button - anchored to avatar
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // Handle profile picture edit
//                        }) {
//                            RoundedRectangle(cornerRadius: 6)
//                                .fill(Color.white)
//                                .frame(width: 24, height: 24)
//                                .overlay(
//                                    Image(systemName: "pencil")
//                                        .font(.system(size: 12, weight: .medium))
//                                        .foregroundColor(.black)
//                                )
//                        }
//                        .offset(x: 8, y: 8)
//                    }
//                }
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

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
        .preferredColorScheme(.dark)
    }
}
