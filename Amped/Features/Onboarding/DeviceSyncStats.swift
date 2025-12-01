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
    
    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                
                HStack {
                    Button(action: {
                        // back action
                        onBack?()
                    }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    .padding(.leading, 30)
                    .padding(.top, 10)
                    
                    Spacer() // pushes button to leading
                }
                
                // Image section
                Image("syncDevice") 
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 160)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                // Title and description
                VStack(spacing: 10) {
                    Text("Let’s Get You Synced")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("To provide the most accurate lifespan calculations, we’ll need access to steps, heart rate, activity etc. and daily health scores.")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 40)
                    
                    Text("Make sure your wearable is already linked to Apple Health.")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 40)
                    
                    Text("No wearable? No problem! Your iPhone works too.")
                        .font(.system(size: 15))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 15) {
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .yesBoth
                        requestHealthKitAuthorization()
                    }) {
                        Text("Yes, I track with a device")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.green, lineWidth: 1.5))
                            .background(RoundedRectangle(cornerRadius: 30)
                                .fill(Color.green.opacity(0.15)))
                            .padding(.horizontal, 40)
                    }
                    
                    Button(action: {
                        viewModel.selectedDeviceTrackingStatus = .no
                        completeQuestionnaire()
                        onContinue?(false)
                    }) {
                        Text("No, I don’t use any device")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.green, lineWidth: 1.5))
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    // MARK: - Health Permission Function
    private func requestHealthKitAuthorization() {
        print("🔍 DEVICE TRACKING: Requesting HealthKit authorization")
        print("🔍 DEVICE TRACKING: Current question before auth: \(viewModel.currentQuestion)")
        
        // Set flag to track that we're waiting for authorization
        isWaitingForHealthKitAuth = true
        
        // ULTRA-FAST: Fire the authorization immediately with completion handler
        HealthKitManager.shared.requestAuthorizationUltraFast {
            print("🔍 DEVICE TRACKING: HealthKit authorization completed")
            
            // Complete the questionnaire when authorization completes
            DispatchQueue.main.async {
                if self.isWaitingForHealthKitAuth {
                    print("🔍 DEVICE TRACKING: Completing questionnaire")
                    self.isWaitingForHealthKitAuth = false
                    self.completeQuestionnaire()
                    self.onContinue?(true)
                }
            }
        }
        
        // DO NOT navigate yet - stay on current screen while dialog is shown
        // Navigation will happen when authorization completes
    }
    
    private func completeQuestionnaire() {
        // Only sync if actually different to avoid unnecessary updates
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
        
        let year = extractYear(from: appState.getFromUserDefault(key: UserDefaultsKeys.userDateOfBirth))
        viewModel.selectedBirthYear = year
        
        // Sync height
        let height = appState.getFromUserDefault(key: UserDefaultsKeys.userHeight)
        if let heightInt = Int(height.trimmingCharacters(in: .whitespacesAndNewlines)),
           heightInt >= 100 && heightInt <= 250 {
            viewModel.setHeight(Double(heightInt))
        }
        
        // Sync weight
        let weight = appState.getFromUserDefault(key: UserDefaultsKeys.userWeight)
        if let weightInt = Int(weight.trimmingCharacters(in: .whitespacesAndNewlines)),
           weightInt >= 30 && weightInt <= 300 {
            viewModel.setWeight(Double(weightInt))
        }
        
        // Sync stressLevel
        let stressLevel = appState.getFromUserDefault(key: UserDefaultsKeys.userStressLevel)
        viewModel.selectedStressLevel = stressLevel == "High" ? QuestionnaireViewModel.StressLevel.high : stressLevel == "Low" ? QuestionnaireViewModel.StressLevel.low : QuestionnaireViewModel.StressLevel.moderate
        
        // Sync AnxietyLevel
        let anxietyLevel = appState.getFromUserDefault(key: UserDefaultsKeys.userAnxietyLevel)
        viewModel.selectedAnxietyLevel = anxietyLevel == "High" ? QuestionnaireViewModel.AnxietyLevel.high : anxietyLevel == "Low" ? QuestionnaireViewModel.AnxietyLevel.low : QuestionnaireViewModel.AnxietyLevel.moderate
        
        // Sync DietLevel
        let dietLevel = appState.getFromUserDefault(key: UserDefaultsKeys.userDietLevel)
        viewModel.selectedNutritionQuality = dietLevel == "Very Healthy" ? QuestionnaireViewModel.NutritionQuality.low : dietLevel == "Mixed" ? QuestionnaireViewModel.NutritionQuality.moderate : QuestionnaireViewModel.NutritionQuality.high
        
        // Sync smokeStats
        let smokeStats = appState.getFromUserDefault(key: UserDefaultsKeys.userSmokeStats)
        viewModel.selectedSmokingStatus = smokeStats == "Never" ? QuestionnaireViewModel.SmokingStatus.low : smokeStats == "Former smoker" ? QuestionnaireViewModel.SmokingStatus.moderate : QuestionnaireViewModel.SmokingStatus.high
        
        // Sync alcoholStats
        let alcoholStats = appState.getFromUserDefault(key: UserDefaultsKeys.userAlcoholStats)
        viewModel.selectedAlcoholFrequency = alcoholStats == "Never" ? QuestionnaireViewModel.AlcoholFrequency.low : alcoholStats == "Occassionally" ? QuestionnaireViewModel.AlcoholFrequency.moderate : QuestionnaireViewModel.AlcoholFrequency.high
        
        // Sync socialStats
        let socialStats = appState.getFromUserDefault(key: UserDefaultsKeys.userSocialStats)
        viewModel.selectedSocialConnectionsQuality = socialStats == "Isolated" ? QuestionnaireViewModel.SocialConnectionsQuality.high : socialStats == "Moderate" ? QuestionnaireViewModel.SocialConnectionsQuality.moderate : QuestionnaireViewModel.SocialConnectionsQuality.low
        
        // Sync bloodPressureStats
        let bloodPressureStats = appState.getFromUserDefault(key: UserDefaultsKeys.userBloodPressureStats)
        viewModel.selectedBloodPressureCategory = bloodPressureStats == "Below 120/80" ? QuestionnaireViewModel.BloodPressureCategory.low : bloodPressureStats == "130/80+" ? QuestionnaireViewModel.BloodPressureCategory.moderate : QuestionnaireViewModel.BloodPressureCategory.unknown
        
        // Sync mainReasonStats
        let mainReasonStats = appState.getFromUserDefault(key: UserDefaultsKeys.userMainReasonStats)
        viewModel.selectedLifeMotivation = mainReasonStats == "Watch my family grow" ? QuestionnaireViewModel.LifeMotivation.family : mainReasonStats == "Achieve my dreams" ? QuestionnaireViewModel.LifeMotivation.dreams : QuestionnaireViewModel.LifeMotivation.experience
        
        // Sync DailyLifespanGainMinutes
        viewModel.desiredDailyLifespanGainMinutes = Int(appState.getFromUserDefault(key: UserDefaultsKeys.userGoalStats)) ?? 10
        
        questionnaireManager.saveQuestionnaireData(from: viewModel)
        
        // Clear persisted questionnaire state since we're done
//        UserDefaults.standard.removeObject(forKey: "questionnaire_current_question")

    }
    
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
