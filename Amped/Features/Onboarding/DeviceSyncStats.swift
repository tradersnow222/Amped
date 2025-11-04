//
//  DeviceSyncStats.swift
//  Amped
//
//  Created by Yawar Abbas   on 04/11/2025.
//

import SwiftUI
import HealthKit

struct SyncDeviceView: View {
    private let healthStore = HKHealthStore()
    var onContinue: ((Bool) -> Void)?
    var onBack: (() -> Void)?
    
    var body: some View {
        ZStack {
            LinearGradient.grayGradient
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
                        requestHealthPermissions()
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
    private func requestHealthPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available on this device.")
            return
        }
        
        // Define the types you want to read
        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { success, error in
            if success {
                print("✅ HealthKit permission granted!")
                DispatchQueue.main.async {
                    onContinue?(true)
                }
                // Navigate to next screen
            } else {
                print("❌ HealthKit permission denied: \(error?.localizedDescription ?? "Unknown error")")
                
                DispatchQueue.main.async {
                    onContinue?(true)
                }
            }
        }
    }
}
