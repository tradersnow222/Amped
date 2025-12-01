//
//  GoalsStatsView.swift
//  Amped
//
//  Created by Yawar Abbas on 03/11/2025.
//
import SwiftUI

struct GoalsStatsView: View {
    @EnvironmentObject private var appState: AppState

    var isFromSettings: Bool = false
    // Angle represents progress around the circle (0 - 360)
    @State private var angle: Double = 60 // default ~10 mins (10/60 * 360 = 60)
    @State private var minutes: Int = 10  // quantized to 5-minute steps
    
    var onContinue: ((String) -> Void)?
    var onBack: (() -> Void)?
    
    private let dialSize: CGFloat = 260
    private let trackWidth: CGFloat = 12
    private let progressWidth: CGFloat = 14
    private let knobSize: CGFloat = 32
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Back button row
                HStack {
                    Button(action: { onBack?() }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .opacity(0.9)
                    }
                    .padding(.leading, 24)
                    .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                // Title
                Text("Let's set some goals!")
                    .font(.poppins(26, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                // Subtitle
                Text("Choose how much time you want to add to your projected lifespan each day.")
                    .font(.poppins(18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)

                // Dial
                HStack {
                    Spacer()
                    GoalDial(minutes: $minutes)
                        .padding()
                        .padding()
                        .padding()
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        onContinue?("\(minutes)")
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.poppins(20, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(LinearGradient.ampButtonGradient)
                    .cornerRadius(30)
                    .padding(.horizontal, 30)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            // ensure angle and minutes are in sync on first load
            
            // If launched from Settings, prefill from defaults
            if isFromSettings {
                let saved = appState.getFromUserDefault(key: UserDefaultsKeys.userGoalStats)
                if !saved.isEmpty {
                    minutes = Int(saved) ?? 10
                    setMinutesFromAngle(angle)
                }
            } else {
                setMinutesFromAngle(angle)
            }
        }
    }
    
    private func setMinutesFromAngle(_ degrees: Double) {
        let rawMinutes = degrees / 360.0 * 60.0
        let stepped = (round(rawMinutes / 5.0) * 5.0)
        minutes = max(0, min(60, Int(stepped)))
    }
}

#Preview {
    GoalsStatsView()
}

struct GoalDial: View {

    @Binding var minutes: Int   // 0...60
    @State private var angle: Double = 0
    
    // MARK: Config
    private let trackWidth: CGFloat = 10
    private let progressWidth: CGFloat = 12
    private let knobSize: CGFloat = 24
    private let dialSize: CGFloat = 280

    var body: some View {
        GeometryReader { geo in
            
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
            
            // Main radius for progress ring + knob
            let radius = (size - trackWidth) / 2 - (progressWidth / 2)

            ZStack {
                
                backgroundDial(size: size)
                tickMarks(size: size - trackWidth * 2)
                progressRing(size: size, progress: Double(minutes) / 60)
                centerContent()
                knobView(center: center, radius: radius)
                
            }
            .frame(width: size, height: size)
            .onAppear { syncAngleWithMinutes() }
        }
        .frame(height: dialSize)
    }

    // MARK: - Background
    private func backgroundDial(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: trackWidth)
            
            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: size - trackWidth * 2)
        }
    }

    // MARK: - Progress Ring
    private func progressRing(size: CGFloat, progress: Double) -> some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(
                AngularGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#318AFC"),
                        Color(hex: "#0A4188")
                    ]),
                    center: .center
                ),
                style: StrokeStyle(
                    lineWidth: progressWidth,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
            .frame(width: size - trackWidth)
    }

    // MARK: - Center Content
    private func centerContent() -> some View {
        VStack(spacing: 6) {
            Image("goalBattery")
                .renderingMode(.template)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 22, height: 22)

            Text("\(minutes) Mins")
                .foregroundColor(.white)
                .font(.poppins(18, weight: .medium))
        }
    }

    // MARK: - Knob
    private func knobView(center: CGPoint, radius: CGFloat) -> some View {
        knob()
            .position(knobPosition(center: center, radius: radius, angle: angle))
            .gesture(dragGesture(center: center))
    }

    // Knob design
    private func knob() -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: knobSize, height: knobSize)
            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
    }

    // MARK: - Drag Logic
    private func dragGesture(center: CGPoint) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                
                let vector = CGVector(
                    dx: value.location.x - center.x,
                    dy: value.location.y - center.y
                )
                
                let radians = atan2(vector.dy, vector.dx)
                var degrees = radians * 180 / .pi
                
                degrees = (degrees < -90) ? (degrees + 450) : (degrees + 90)
                angle = degrees.truncatingRemainder(dividingBy: 360)
                
                updateMinutesFromAngle()
            }
    }

    // MARK: - Logic
    private func updateMinutesFromAngle() {
        let rawMinutes = angle / 360 * 60
        let stepped = round(rawMinutes / 5) * 5
        minutes = Int(min(max(stepped, 0), 60))
        angle = Double(minutes) / 60 * 360
    }

    private func syncAngleWithMinutes() {
        angle = Double(minutes) / 60 * 360
    }

    // MARK: - Knob Position
    private func knobPosition(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let radians = (angle - 90) * .pi / 180
        
        let x = center.x + radius * cos(radians)
        let y = center.y + radius * sin(radians)
        
        return CGPoint(x: x, y: y)
    }

    // MARK: - Tick Marks
    private func tickMarks(size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<60, id: \.self) { i in
                let isMajor = i % 5 == 0

                Capsule()
                    .fill(Color.white.opacity(isMajor ? 0.8 : 0.5))
                    .frame(width: isMajor ? 3 : 2,
                           height: isMajor ? 16 : 8)
                    .offset(y: -(size / 2) + (isMajor ? 12 : 15))
                    .rotationEffect(.degrees(Double(i) * 6))
            }
        }
        .frame(width: size, height: size)
    }
}
