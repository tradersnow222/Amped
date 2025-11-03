//
//  GoalsStatsView.swift
//  Amped
//
//  Created by Yawar Abbas on 03/11/2025.
//
import SwiftUI

import SwiftUI

struct GoalsStatsView: View {
    @State private var angle: Double = 0
    @State private var minutes: Int = 0
    
    var onContinue: ((String) -> Void)?
    var onBack: (() -> Void)?
    
    var body: some View {
        ZStack {
            LinearGradient.grayGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                VStack(spacing: 8) {
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
                        
                        Spacer() // pushes button to leading
                    }
                    
                    Text("Let's set some goals!")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Choose how much time you want to add to\nyour projected lifespan each day.")
                        .font(.poppins(14))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // MARK: - Circular Timer
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 8)
                        .frame(width: 220, height: 220)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(angle / 360))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                    
                    // Center Text
                    VStack(spacing: 4) {
                        Image("goalBattery")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                        Text("\(minutes) Mins")
                            .foregroundColor(.white)
                            .font(.poppins(22, weight: .thin))
                    }
                    
                    // Draggable Knob
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .offset(y: -110)
                        .rotationEffect(.degrees(angle))
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let vector = CGVector(dx: value.location.x - 110, dy: value.location.y - 110)
                                    let radians = atan2(vector.dy, vector.dx)
                                    var degrees = radians * 180 / .pi + 90
                                    if degrees < 0 { degrees += 360 }
                                    
                                    angle = degrees
                                    minutes = Int(angle / 6)  // 360° / 6° = 60 steps (1 min each)
                                }
                        )
                }
                
                // MARK: Continue Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onContinue?("")
                    }
                }) {
                    HStack {
                        Text("Continue")
                            .font(.poppins(20, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                            
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LinearGradient.ampButtonGradient)
                    .cornerRadius(30)
                    .padding(.horizontal, 30)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.bottom, 50)
            }
        }
    }
}


