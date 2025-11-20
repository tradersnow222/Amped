//
//  NotificationSettingsView.swift
//  Amped
//
//  Created by Sheraz Hussain on 15/11/2025.
//

import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = NotificationManager.shared
    
    // Toggles
    @State private var prefs = NotificationPreferences.load()
    @State private var requestingPermission = false
    @State private var permissionError: String?
    
    // Derived target (fallback to 30 if questionnaire not set)
    private var targetMinutes: Int {
        if let data = UserDefaults.standard.data(forKey: "questionnaire_data"),
           let q = try? JSONDecoder().decode(QuestionnaireData.self, from: data),
           let goal = q.desiredDailyLifespanGainMinutes {
            return max(1, goal)
        }
        return 30
    }
    
    var body: some View {
        ZStack {
            // Full-screen background gradient 
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            // Header
            VStack {
                
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Spacer()
                    Text("Notification Settings")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    // spacer for symmetry
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 16)
                
                // List of toggles
                ScrollView {
                    VStack(spacing: 8) {
                        settingsRow(title: "Streak Protection Alerts", isOn: $prefs.streakProtectionAlerts)
                        settingsRow(title: "Personalized Habit Reminders", isOn: $prefs.personalizedHabitReminders)
                        settingsRow(title: "Motivational Boosts", isOn: $prefs.motivationalBoosts)
                        settingsRow(title: "Daily Check-in Summary", isOn: $prefs.dailyCheckInSummary)
                        settingsRow(title: "Health Sync Notifications", isOn: $prefs.healthSyncNotifications)
                        settingsRow(title: "Challenges & Milestones", isOn: $prefs.challengesAndMilestones)
                        settingsRow(title: "Weekly & Monthly Reports", isOn: $prefs.weeklyMonthlyReports)
                        settingsRow(title: "System & App Updates", isOn: $prefs.systemAppUpdates)
                        
                        if let permissionError {
                            Text(permissionError)
                                .foregroundStyle(.red)
                                .font(.footnote)
                                .padding(.top, 6)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                
                Spacer()
                
                // Save button
                Button(action: saveTapped) {
                    Text("Save")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(colors: [Color.green.opacity(0.9), Color.green],
                                           startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                }
                Spacer()
            }
        }
        .onAppear {
            // Ensure we reflect current permission state
            manager.checkPermissionStatus()
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - UI
    
    @ViewBuilder
    private func settingsRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white)
                .font(.system(size: 13, weight: .regular))
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
    
    // MARK: - Actions
    
    private func saveTapped() {
        // Persist preferences first
        prefs.save()
        
        Task {
            // Ensure permission
            if manager.permissionStatus != .authorized {
                requestingPermission = true
                let granted = await manager.requestPermissions()
                requestingPermission = false
                if !granted {
                    permissionError = "Please enable notifications in Settings to use these features."
                    return
                }
            }
            permissionError = nil
            
            // Apply selections
            manager.applyPreferences(prefs, targetMinutes: targetMinutes)
            
            // Done
            await MainActor.run {
                dismiss()
            }
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NotificationSettingsView()
        }
    }
}
