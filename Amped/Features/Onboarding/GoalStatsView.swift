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
    @State private var angle: Double = 60
    @State private var minutes: Int = 10
    
    var onContinue: ((String) -> Void)?
    var onBack: (() -> Void)?
    
    // Adaptive sizing
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var titleSize: CGFloat { isPad ? 32 : 26 }
    private var subtitleSize: CGFloat { isPad ? 20 : 18 }
    private var backIconSize: CGFloat { isPad ? 24 : 20 }
    private var buttonHeight: CGFloat { isPad ? 60 : 56 }
    private var buttonFontSize: CGFloat { isPad ? 22 : 20 }
    private var dialPadding: CGFloat { isPad ? 100 : 16 }
    
    // Dynamic paddings for GoalDial based on screen size (keeps roughly same visual layout)
    private var dialTopPaddingDynamic: CGFloat {
        let h = UIScreen.main.bounds.height
        guard isPad else { return max(20, h * 0.10) }
        return max(160, h * 0.20)
    }
    private var dialLeadingPaddingDynamic: CGFloat {
        let w = UIScreen.main.bounds.width
        if isPad {
            // About ~30% of width
            return max(140, w * 0.30)
        } else {
            return max(30, w * 0.15)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient.customBlueToDarkGray
                .ignoresSafeArea()
            
            VStack(spacing: isPad ? 32 : 28) {
                HStack {
                    Button(action: { onBack?() }) {
                        Image("backIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: backIconSize, height: backIconSize)
                            .opacity(0.9)
                    }
                    .padding(.leading, 24)
                    .padding(.top, isPad ? 12 : 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                Text("Let's set some goals!")
                    .font(.poppins(titleSize, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                Text("Choose how much time you want to add to your projected lifespan each day.")
                    .font(.poppins(subtitleSize, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, isPad ? 60 : 40)

                // Goal Dial with dynamic paddings derived from screen size
                GoalDial(minutes: $minutes)
                    .padding(.top, dialTopPaddingDynamic)
                    .padding(.leading, dialLeadingPaddingDynamic)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        onContinue?("\(minutes)")
                    }
                }) {
                    HStack(spacing: 8) {
                        Text("Continue")
                            .font(.poppins(buttonFontSize, weight: .medium))
                        Image(systemName: "arrow.right")
                            .font(.system(size: isPad ? 19 : 17, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(LinearGradient.ampButtonGradient)
                    .cornerRadius(30)
                    .padding(.horizontal, 30)
                    .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.bottom, isPad ? 60 : 50)
            }
        }
        .onAppear {
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

    @Binding var minutes: Int
    @State private var angle: Double = 0
    
    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }
    private var trackWidth: CGFloat { isPad ? 12 : 10 }
    private var progressWidth: CGFloat { isPad ? 14 : 12 }
    private var knobSize: CGFloat { isPad ? 28 : 24 }
    private var dialSize: CGFloat { isPad ? 340 : 280 }
    private var centerTitleSize: CGFloat { isPad ? 20 : 18 }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: size / 2, y: size / 2)
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

    private func backgroundDial(size: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: trackWidth)
            
            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: size - trackWidth * 2)
        }
    }

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

    private func centerContent() -> some View {
        VStack(spacing: 6) {
            Image("goalBattery")
                .renderingMode(.template)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: isPad ? 26 : 22, height: isPad ? 26 : 22)

            Text("\(minutes) Mins")
                .foregroundColor(.white)
                .font(.poppins(centerTitleSize, weight: .medium))
        }
    }

    private func knobView(center: CGPoint, radius: CGFloat) -> some View {
        knob()
            .position(knobPosition(center: center, radius: radius, angle: angle))
            .gesture(dragGesture(center: center))
    }

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

    private func updateMinutesFromAngle() {
        let rawMinutes = angle / 360 * 60
        let stepped = round(rawMinutes / 5) * 5
        minutes = Int(min(max(stepped, 0), 60))
        angle = Double(minutes) / 60 * 360
    }

    private func syncAngleWithMinutes() {
        angle = Double(minutes) / 60 * 360
    }

    private func knobPosition(center: CGPoint, radius: CGFloat, angle: Double) -> CGPoint {
        let radians = (angle - 90) * .pi / 180
        let x = center.x + radius * cos(radians)
        let y = center.y + radius * sin(radians)
        return CGPoint(x: x, y: y)
    }

    private func tickMarks(size: CGFloat) -> some View {
        ZStack {
            ForEach(0..<60, id: \.self) { i in
                let isMajor = i % 5 == 0

                Capsule()
                    .fill(Color.white.opacity(isMajor ? 0.8 : 0.5))
                    .frame(width: isMajor ? (isPad ? 3.5 : 3) : 2,
                           height: isMajor ? (isPad ? 18 : 16) : (isPad ? 10 : 8))
                    .offset(y: -(size / 2) + (isMajor ? (isPad ? 14 : 12) : (isPad ? 16 : 15)))
                    .rotationEffect(.degrees(Double(i) * 6))
            }
        }
        .frame(width: size, height: size)
    }
}
