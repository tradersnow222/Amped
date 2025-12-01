import Foundation
import SwiftUI

@MainActor
final class EditProfileViewModel: ObservableObject {
    // Basic profile
    @Published var fullName: String = ""
    @Published var gender: UserProfile.Gender? = nil
    @Published var dateOfBirth: Date? = nil // Stored as year in UserProfile
    @Published var heightText: String = ""  // store as text for easy editing
    @Published var weightText: String = ""
    
    // Extended fields (kept in UserDefaults via your keys)
    @Published var stressLevel: String = ""
    @Published var anxietyLevel: String = ""
    @Published var dietLevel: String = ""
    @Published var smokingStatus: String = ""
    @Published var alcoholStatus: String = ""
    @Published var socialConnections: String = ""
    @Published var bloodPressureCategory: String = ""
    @Published var mainReasonToLive: String = ""
    
    // UI state
    @Published var isSaving: Bool = false
    @Published var errorMessage: String? = nil
    @Published var saveSucceeded: Bool = false
    
    private let defaults = UserDefaults.standard
    
    func load() {
        // Load from UserDefaultsKeys first (these power other parts of your app)
        fullName = defaults.string(forKey: UserDefaultsKeys.userName)
            ?? defaults.string(forKey: UserDefaultsKeys.userNameLegacy)
            ?? ""
        
        if let rawGender = defaults.string(forKey: UserDefaultsKeys.userGender),
           let g = UserProfile.Gender(rawValue: rawGender) {
            gender = g
        } else {
            // Try user_profile
            if let profile = loadUserProfile() {
                gender = profile.gender
            }
        }
        
        // Date of birth (your flow saved a string; we convert to Date if possible)
        if let dobString = defaults.string(forKey: UserDefaultsKeys.userDateOfBirth) {
            if let iso = ISO8601DateFormatter().date(from: dobString) {
                dateOfBirth = iso
            } else {
                let df = DateFormatter()
                df.locale = Locale(identifier: "en_US_POSIX")
                df.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
                if let parsed = df.date(from: dobString) {
                    dateOfBirth = parsed
                } else if let year = Int(dobString.prefix(4)) {
                    dateOfBirth = Calendar.current.date(from: DateComponents(year: year, month: 6, day: 15))
                }
            }
        } else if let profile = loadUserProfile(), let year = profile.birthYear {
            dateOfBirth = Calendar.current.date(from: DateComponents(year: year, month: 6, day: 15))
        }
        
        // Height / Weight
        if let hAny = defaults.object(forKey: UserDefaultsKeys.userHeight) {
            heightText = String(describing: hAny)
        } else if let profile = loadUserProfile(), let h = profile.height {
            heightText = String(h)
        }
        if let wAny = defaults.object(forKey: UserDefaultsKeys.userWeight) {
            weightText = String(describing: wAny)
        } else if let profile = loadUserProfile(), let w = profile.weight {
            // Stored in kg per your codebase
            weightText = String(w)
        }
        
        // Extended fields
        stressLevel = defaults.string(forKey: UserDefaultsKeys.userStressLevel) ?? ""
        anxietyLevel = defaults.string(forKey: UserDefaultsKeys.userAnxietyLevel) ?? ""
        dietLevel = defaults.string(forKey: UserDefaultsKeys.userDietLevel) ?? ""
        smokingStatus = defaults.string(forKey: UserDefaultsKeys.userSmokeStats) ?? ""
        alcoholStatus = defaults.string(forKey: UserDefaultsKeys.userAlcoholStats) ?? ""
        socialConnections = defaults.string(forKey: UserDefaultsKeys.userSocialStats) ?? ""
        bloodPressureCategory = defaults.string(forKey: UserDefaultsKeys.userBloodPressureStats) ?? ""
        mainReasonToLive = defaults.string(forKey: UserDefaultsKeys.userMainReasonStats) ?? ""
    }
    
    func save() {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        // Validate numeric inputs
        let heightDouble: Double? = Double(heightText.trimmingCharacters(in: .whitespaces))
        let weightDouble: Double? = Double(weightText.trimmingCharacters(in: .whitespaces))
        
        // Persist to UserDefaults (keys used across onboarding + metrics)
        defaults.set(fullName, forKey: UserDefaultsKeys.userName)
        if let gender { defaults.set(gender.rawValue, forKey: UserDefaultsKeys.userGender) } else { defaults.removeObject(forKey: UserDefaultsKeys.userGender) }
        
        if let dob = dateOfBirth {
            let iso = ISO8601DateFormatter().string(from: dob)
            defaults.set(iso, forKey: UserDefaultsKeys.userDateOfBirth)
        } else {
            defaults.removeObject(forKey: UserDefaultsKeys.userDateOfBirth)
        }
        
        if let h = heightDouble {
            defaults.set(h, forKey: UserDefaultsKeys.userHeight)
        } else {
            defaults.removeObject(forKey: UserDefaultsKeys.userHeight)
        }
        if let w = weightDouble {
            defaults.set(w, forKey: UserDefaultsKeys.userWeight)
        } else {
            defaults.removeObject(forKey: UserDefaultsKeys.userWeight)
        }
        
        // Extended fields
        defaults.set(stressLevel, forKey: UserDefaultsKeys.userStressLevel)
        defaults.set(anxietyLevel, forKey: UserDefaultsKeys.userAnxietyLevel)
        defaults.set(dietLevel, forKey: UserDefaultsKeys.userDietLevel)
        defaults.set(smokingStatus, forKey: UserDefaultsKeys.userSmokeStats)
        defaults.set(alcoholStatus, forKey: UserDefaultsKeys.userAlcoholStats)
        defaults.set(socialConnections, forKey: UserDefaultsKeys.userSocialStats)
        defaults.set(bloodPressureCategory, forKey: UserDefaultsKeys.userBloodPressureStats)
        defaults.set(mainReasonToLive, forKey: UserDefaultsKeys.userMainReasonStats)
        
        // Update the canonical UserProfile blob
        var profile = loadUserProfile() ?? UserProfile()
        profile.firstName = fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fullName.components(separatedBy: " ").first
        if let dob = dateOfBirth {
            profile.birthYear = Calendar.current.component(.year, from: dob)
        } else {
            profile.birthYear = nil
        }
        profile.gender = gender
        profile.height = heightDouble
        profile.weight = weightDouble
        profile.lastActive = Date()
        
        do {
            let data = try JSONEncoder().encode(profile)
            defaults.set(data, forKey: "user_profile")
            saveSucceeded = true
            // Let other parts of the app refresh
            NotificationCenter.default.post(name: NSNotification.Name("ProfileDataUpdated"), object: nil)
        } catch {
            errorMessage = "Failed to save profile."
            saveSucceeded = false
        }
    }
    
    private func loadUserProfile() -> UserProfile? {
        if let data = defaults.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return nil
    }
}

