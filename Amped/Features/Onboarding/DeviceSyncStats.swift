//
//  DeviceSyncStats.swift
//  Amped
//
//  Created by Yawar Abbas   on 04/11/2025.
//

import SwiftUI
import HealthKit

struct SyncDeviceView: View {
    @StateObject private var viewModel = QuestionnaireViewModel()
    @StateObject private var questionnaireManager = QuestionnaireManager()
    @State private var isWaitingForHealthKitAuth = false
    @EnvironmentObject var appState: AppState
    
    private let healthStore = HKHealthStore()
    var onContinue: ((Bool) -> Void)?
    var onBack: (() -> Void)?
    
    // MARK: - Adaptive Sizing
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var backIconSize: CGFloat { isPad ? 24 : 20 }
    private var topSpacing: CGFloat { isPad ? 34 : 30 }
    private var imageWidth: CGFloat { isPad ? 420 : 240 }
    private var imageHeight: CGFloat { isPad ? 280 : 160 }
    private var imageTopPadding: CGFloat { isPad ? 36 : 20 }
    private var imageBottomPadding: CGFloat { isPad ? 18 : 10 }
    private var titleFontSize: CGFloat { isPad ? 28 : 24 }
    private var bodyFontSize: CGFloat { isPad ? 17 : 15 }
    private var bodyHorizontalPadding: CGFloat { isPad ? 80 : 40 }
    private var buttonFontSize: CGFloat { isPad ? 19 : 17 }
    private var buttonHorizontalPadding: CGFloat { isPad ? 80 : 40 }
    private var buttonVStackSpacing: CGFloat { isPad ? 18 : 15 }
    private var bottomPadding: CGFloat { isPad ? 55 : 40 }
    
    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: topSpacing) {
                
                // Back
                HStack {
                    Button(action: {
                        onBack?()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: backIconSize, height: backIconSize)
                    }
                    .padding(.leading, 30)
                    .padding(.top, isPad ? 14 : 10)
                    
                    Spacer()
                }
                
                // Image section
                Image("syncDevice")
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageWidth, height: imageHeight)
                    .padding(.top, imageTopPadding)
                    .padding(.bottom, imageBottomPadding)
                
                // Title and description
                VStack(spacing: isPad ? 14 : 10) {
                    Text("Let’s Get You Synced")
                        .font(.poppins(titleFontSize, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("To provide the most accurate lifespan calculations, we’ll need access to steps, heart rate, activity etc. and daily health scores.")
                        .font(.poppins(bodyFontSize))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, bodyHorizontalPadding)
                    
                    Text("Make sure your wearable is already linked to Apple Health.")
                        .font(.poppins(bodyFontSize))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, bodyHorizontalPadding)
                    
                    Text("No wearable? No problem! Your iPhone works too.")
                        .font(.poppins(bodyFontSize))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, bodyHorizontalPadding)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: buttonVStackSpacing) {
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .yesBoth
                        requestHealthKitAuthorization()
                    }) {
                        Text("Yes, I track with a device")
                            .font(.poppins(buttonFontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.ampedGreen, lineWidth: 1.5)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(Color.ampedGreen.opacity(0.15))
                            )
                            .padding(.horizontal, buttonHorizontalPadding)
                    }
                    
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .no
                        completeQuestionnaire()
                        onContinue?(false)
                    }) {
                        Text("No, I don’t use any device")
                            .font(.poppins(buttonFontSize, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.ampedGreen, lineWidth: 1.5)
                            )
                            .padding(.horizontal, buttonHorizontalPadding)
                    }
                }
                .padding(.bottom, bottomPadding)
            }
        }
    }
    
    // MARK: - Health Permission Function
    private func requestHealthKitAuthorization() {
        print("🔍 DEVICE TRACKING: Requesting HealthKit authorization")
        print("🔍 DEVICE TRACKING: Current question before auth: \(viewModel.currentQuestion)")
        
        isWaitingForHealthKitAuth = true
        
        HealthKitManager.shared.requestAuthorizationUltraFast {
            print("🔍 DEVICE TRACKING: HealthKit authorization completed")
            
            DispatchQueue.main.async {
                if self.isWaitingForHealthKitAuth {
                    print("🔍 DEVICE TRACKING: Completing questionnaire")
                    self.isWaitingForHealthKitAuth = false
                    self.completeQuestionnaire()
                    self.onContinue?(true)
                }
            }
        }
    }
    
    private func completeQuestionnaire() {
        // Sync user name
        let userName = appState.getFromUserDefault(key: UserDefaultsKeys.userName)
        if viewModel.userName != userName {
            viewModel.userName = userName
        }
        
        // Sync gender
        let gender = UserProfile.Gender(rawValue: appState.getFromUserDefault(key: UserDefaultsKeys.userGender))
        if viewModel.selectedGender != gender {
            viewModel.selectedGender = gender
        }
        
        // Sync age
        let age = calculateAge(from: appState.getFromUserDefault(key: UserDefaultsKeys.userDateOfBirth))
        if age >= 18 && age <= 120 {
            viewModel.setAge(age)
        }
        
        // Birth year
        let year = extractYear(from: appState.getFromUserDefault(key: UserDefaultsKeys.userDateOfBirth))
        viewModel.selectedBirthYear = year
        
        // Height
        let height = appState.getFromUserDefault(key: UserDefaultsKeys.userHeight)
        if let heightInt = Int(height.trimmingCharacters(in: .whitespacesAndNewlines)),
           heightInt >= 100 && heightInt <= 250 {
            viewModel.setHeight(Double(heightInt))
        }
        
        // Weight
        let weight = appState.getFromUserDefault(key: UserDefaultsKeys.userWeight)
        if let weightInt = Int(weight.trimmingCharacters(in: .whitespacesAndNewlines)),
           weightInt >= 30 && weightInt <= 300 {
            viewModel.setWeight(Double(weightInt))
        }
        
        // Stress
        let stressLevel = appState.getFromUserDefault(key: UserDefaultsKeys.userStressLevel)
        viewModel.selectedStressLevel = stressLevel == "High" ? QuestionnaireViewModel.StressLevel.high : stressLevel == "Low" ? QuestionnaireViewModel.StressLevel.low : QuestionnaireViewModel.StressLevel.moderate
        
        // Anxiety
        let anxietyLevel = appState.getFromUserDefault(key: UserDefaultsKeys.userAnxietyLevel)
        viewModel.selectedAnxietyLevel = anxietyLevel == "High" ? QuestionnaireViewModel.AnxietyLevel.high : anxietyLevel == "Low" ? QuestionnaireViewModel.AnxietyLevel.low : QuestionnaireViewModel.AnxietyLevel.moderate
        
        // Diet
        let dietLevel = appState.getFromUserDefault(key: UserDefaultsKeys.userDietLevel)
        viewModel.selectedNutritionQuality = dietLevel == "Very Healthy" ? QuestionnaireViewModel.NutritionQuality.low : dietLevel == "Mixed" ? QuestionnaireViewModel.NutritionQuality.moderate : QuestionnaireViewModel.NutritionQuality.high
        
        // Smoking
        let smokeStats = appState.getFromUserDefault(key: UserDefaultsKeys.userSmokeStats)
        viewModel.selectedSmokingStatus = smokeStats == "Never" ? QuestionnaireViewModel.SmokingStatus.low : smokeStats == "Former smoker" ? QuestionnaireViewModel.SmokingStatus.moderate : QuestionnaireViewModel.SmokingStatus.high
        
        // Alcohol
        let alcoholStats = appState.getFromUserDefault(key: UserDefaultsKeys.userAlcoholStats)
        viewModel.selectedAlcoholFrequency = alcoholStats == "Never" ? QuestionnaireViewModel.AlcoholFrequency.low : alcoholStats == "Occassionally" ? QuestionnaireViewModel.AlcoholFrequency.moderate : QuestionnaireViewModel.AlcoholFrequency.high
        
        // Social
        let socialStats = appState.getFromUserDefault(key: UserDefaultsKeys.userSocialStats)
        viewModel.selectedSocialConnectionsQuality = socialStats == "Isolated" ? QuestionnaireViewModel.SocialConnectionsQuality.high : socialStats == "Moderate" ? QuestionnaireViewModel.SocialConnectionsQuality.moderate : QuestionnaireViewModel.SocialConnectionsQuality.low
        
        // Blood Pressure
        let bloodPressureStats = appState.getFromUserDefault(key: UserDefaultsKeys.userBloodPressureStats)
        viewModel.selectedBloodPressureCategory = bloodPressureStats == "Below 120/80" ? QuestionnaireViewModel.BloodPressureCategory.low : bloodPressureStats == "130/80+" ? QuestionnaireViewModel.BloodPressureCategory.moderate : QuestionnaireViewModel.BloodPressureCategory.unknown
        
        // Motivation
        let mainReasonStats = appState.getFromUserDefault(key: UserDefaultsKeys.userMainReasonStats)
        viewModel.selectedLifeMotivation = mainReasonStats == "Watch my family grow" ? QuestionnaireViewModel.LifeMotivation.family : mainReasonStats == "Achieve my dreams" ? QuestionnaireViewModel.LifeMotivation.dreams : QuestionnaireViewModel.LifeMotivation.experience
        
        // Daily goal
        viewModel.desiredDailyLifespanGainMinutes = Int(appState.getFromUserDefault(key: UserDefaultsKeys.userGoalStats)) ?? 10
        
        questionnaireManager.saveQuestionnaireData(from: viewModel)
    }
    
    // MARK: - Helpers
    func calculateAge(from dobString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard let dateOfBirth = formatter.date(from: dobString) else {
            return 0
        }

        let calendar = Calendar.current
        let now = Date()

        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: now)
        return ageComponents.year ?? 0
    }
    
    func extractYear(from dateString: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        guard let date = formatter.date(from: dateString) else {
            return 0
        }

        let calendar = Calendar.current
        return calendar.component(.year, from: date)
    }
}

#Preview {
    SyncDeviceView()
}
