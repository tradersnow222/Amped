import SwiftUI
import Combine

/// Profile View - User profile and health metrics overview
struct ProfileView: View {
    // MARK: - State Variables
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    
    // MARK: - Computed Properties
    private var userProfile: UserProfileData {
        UserProfileData(
            name: "Matt Snow",
            dob: "1 January 1995",
            age: 29,
            gender: "Male",
            profileImage: nil,
            nutritionQuality: 5,
            smokingStatus: "Never",
            alcoholConsumption: "Never",
            socialConnections: 5,
            stressLevel: 5
        )
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
                EditProfileView()
            }
        }
    }
    
    // MARK: - Header Components
    
    private var personalizedHeader: some View {
        ProfileImageView(size: 44, showBorder: false, showEditIndicator: false, showWelcomeMessage: true)
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
                    Text("Not Set")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    Text("DOB: \(userProfile.dob)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Age: \(userProfile.age) Sex: \(userProfile.gender)")
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
            // Nutrition Quality
            healthMetricRow(
                title: "Nutrition Quality",
                answer: "Good",
                value: userProfile.nutritionQuality,
                maxValue: 10,
                color: .green
            )
            
            // Smoking Status
            healthMetricRow(
                title: "Smoking Status",
                answer: userProfile.smokingStatus,
                color: .green
            )
            
            // Alcohol Consumption
            healthMetricRow(
                title: "Alcohol Consumption",
                answer: userProfile.alcoholConsumption,
                color: .green
            )
            
            // Social Connections
            healthMetricRow(
                title: "Social Connections",
                answer: "Moderate (\(userProfile.socialConnections)/10)",
                value: userProfile.socialConnections,
                maxValue: 10,
                color: .orange
            )
            
            // Stress Level
            healthMetricRow(
                title: "Stress Level",
                answer: "Moderate (\(userProfile.stressLevel)/10)",
                value: userProfile.stressLevel,
                maxValue: 10,
                color: .orange
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

//struct EditProfileView: View {
//    @Environment(\.dismiss) private var dismiss
//    @State private var name: String = ""
//    @State private var dob: String = "1 January 1995"
//    @State private var gender: String = "Male"
//    
//    var body: some View {
//        VStack(spacing: 24) {
//            // Profile Picture Section
//            profilePictureSection
//            
//            // Input Fields
//            inputFieldsSection
//            
//            // Continue Button
//            continueButton
//            
//            Spacer()
//        }
//        .padding(.horizontal, 20)
//        .padding(.top, 20)
//        .background(Color.black)
//        .navigationBarTitleDisplayMode(.inline)
//        .navigationBarBackButtonHidden(true)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button(action: {
//                    dismiss()
//                }) {
//                    RoundedRectangle(cornerRadius: 8)
//                        .fill(Color.gray.opacity(0.3))
//                        .frame(width: 32, height: 32)
//                        .overlay(
//                            Image(systemName: "chevron.left")
//                                .font(.system(size: 14, weight: .medium))
//                                .foregroundColor(.white)
//                        )
//                }
//            }
//            
//            ToolbarItem(placement: .principal) {
//                Text("Edit profile")
//                    .font(.system(size: 18, weight: .semibold))
//                    .foregroundColor(.white)
//            }
//        }
//        .preferredColorScheme(.dark)
//    }
//    
//    private var profilePictureSection: some View {
//        VStack(spacing: 16) {
//            ZStack {
//                Circle()
//                    .fill(
//                        LinearGradient(
//                            colors: [.ampedGreen, .ampedYellow],
//                            startPoint: .topLeading,
//                            endPoint: .bottomTrailing
//                        )
//                    )
//                    .frame(width: 100, height: 100)
//                
//                Image(systemName: "person")
//                    .font(.system(size: 40, weight: .medium))
//                    .foregroundColor(.white)
//                
//                // Edit Button - anchored to avatar
////                VStack {
////                    Spacer()
////                    HStack {
////                        Spacer()
////                        Button(action: {
////                            // Handle profile picture edit
////                        }) {
////                            RoundedRectangle(cornerRadius: 6)
////                                .fill(Color.white)
////                                .frame(width: 24, height: 24)
////                                .overlay(
////                                    Image(systemName: "pencil")
////                                        .font(.system(size: 12, weight: .medium))
////                                        .foregroundColor(.black)
////                                )
////                        }
////                        .offset(x: 8, y: 8)
////                    }
////                }
//            }
//        }
//    }
//    
//    private var inputFieldsSection: some View {
//        VStack(spacing: 16) {
//            // Name Field
//            ZStack(alignment: .leading) {
//                if name.isEmpty {
//                    Text("Enter your full name")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(Color(red: 39/255, green: 39/255, blue: 39/255, opacity: 0.4))
//                        .padding(.horizontal, 16)
//                }
//                
//                TextField("", text: $name)
//                    .font(.system(size: 14, weight: .regular))
//                    .foregroundColor(Color(red:35/255,green:57/255, blue:32/255))
//                    .padding(16)
//            }
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color.white)
//            )
//            .accentColor(.black)
//            
//            // Date of Birth Field
//            HStack {
//                Text(dob)
//                    .font(.system(size: 14, weight: .regular))
//                    .foregroundColor(Color(red:35/255,green:57/255, blue:32/255))
//                
//                Spacer()
//            }
//            .padding(16)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color.white)
//            )
//            
//            // Gender Field
//            HStack {
//                Text(gender)
//                    .font(.system(size: 14, weight: .regular))
//                    .foregroundColor(Color(red:35/255,green:57/255, blue:32/255))
//                
//                Spacer()
//            }
//            .padding(16)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color.white)
//            )
//        }
//    }
//    
//    private var continueButton: some View {
//        Button(action: {
//            dismiss()
//        }) {
//            Text("Continue")
//                .font(.system(size: 16, weight: .semibold))
//                .foregroundColor(.white)
//                .frame(maxWidth: .infinity)
//                .padding(.vertical, 16)
//                .background(
//                    RoundedRectangle(cornerRadius: 12)
//                        .fill(Color.gray.opacity(0.3))
//                )
//        }
//    }
//}

// MARK: - Data Models

struct UserProfileData {
    let name: String
    let dob: String
    let age: Int
    let gender: String
    let profileImage: String?
    let nutritionQuality: Int
    let smokingStatus: String
    let alcoholConsumption: String
    let socialConnections: Int
    let stressLevel: Int
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
