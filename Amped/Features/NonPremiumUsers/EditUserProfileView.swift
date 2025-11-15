//
//  EditProfileView.swift
//  Amped
//
//  Created by Shadeem Kazmi on 04/11/2025.
//

import SwiftUI

struct EditUserProfileView: View {
    @State private var name: String = "Adam John"
    @State private var progressValue: Float = 0.01 // 1%
    
    // Background gradient colors (rgba(63, 169, 245, 1) to rgba(13, 13, 13, 0.4))
    let startColor = Color(red: 63/255.0, green: 169/255.0, blue: 245/255.0, opacity: 1.0)
    let endColor = Color(red: 13/255.0, green: 13/255.0, blue: 13/255.0, opacity: 0.4)
    
    // Next button solid color (The bright green from the subscription button gradient #18EF47)
    let nextButtonColor = Color(hex: "18EF47")

    var body: some View {
        ZStack {
            // 1. Full Screen Background Gradient
            LinearGradient(
                colors: [startColor, endColor],
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Custom Navigation Bar
                CustomProfileNavBar()
                
                ScrollView {
                    VStack(spacing: 40) {
                        // 2. Character Image (Using the name "BatteryCharacter" as shown in the design)
                        Image("emma")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .padding(.top, 20)
                        
                        // 3. Welcome Text
                        Text("Let's get familiar!")
                            .font(.largeTitle)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.bottom, 20)
                        
                        // 4. Progress Bar
                        VStack(spacing: 8) {
                            ProgressView(value: progressValue)
                                .progressViewStyle(LinearProgressViewStyle(tint: nextButtonColor))
                                .scaleEffect(x: 1, y: 3, anchor: .center)
                                .padding(.horizontal, 40)
                                .frame(height: 20)
                                .cornerRadius(64)
                            
                            Text("\(Int(progressValue * 100))%")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.bottom, 60)
                        
                        // 5. Question
                        Text("What should I call you?")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        // 6. Name Input/Display Box
                        HStack {
                            Text(name)
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "#828282"))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20) // Use the same corner radius as the background
                                .stroke(LinearGradient(
                                    colors: [Color(hex: "#18EF47"), Color(hex: "#0E8929")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                }
                
                // 7. Next Button (Fixed to the bottom)
                VStack {
                    Button(action: {
                        // Action for "Next"
                    }) {
                        HStack {
                            Text("Next")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                            
                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(nextButtonColor)
                        .cornerRadius(100)

                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)

                }
            }
        }
        .navigationBarHidden(true)
        .navigationTitle("")
    }
}

// Custom Navigation Bar Component
struct CustomProfileNavBar: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        HStack {
            // 1. Left Button (Back Arrow)
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "arrow.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            // Use a fixed frame to define the space used by the button
            .frame(width: 44, alignment: .leading)
            
            Spacer()
            
            // 2. Center Title
            Text("Edit Profile")
                .font(.poppins(24, weight: .regular))
                .foregroundColor(.white)
            
            Spacer()
            
            // 3. Right Placeholder (Must match the left button's fixed width for perfect centering)
            Rectangle()
                .fill(Color.clear)
                .frame(width: 44, height: 44) // Match the width of the left button
        }
        .padding(.horizontal, 10) // Small horizontal padding
        // Crucial: Add necessary top padding to account for the Status Bar/Notch area
        .padding(.top, 10)
        .padding(.bottom, 8) // Small spacing below the bar
        .background(Color.clear) // Ensure the Hstack itself doesn't have a background
    }
}
