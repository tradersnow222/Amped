import SwiftUI

/// Circular dial for selecting a sleep goal (hours:minutes)
/// Designed to feel delightful with haptics; keeps logic simple.
struct SleepGoalDial: View {
    @Binding var hours: Int
    @Binding var minutes: Int // 0 or 30 for simplicity

    @State private var angle: Double = -90 // start at top

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 10)
                .frame(width: 220, height: 220)
            // Ticks
            ForEach(0..<12) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 2, height: 10)
                    .offset(y: -95)
                    .rotationEffect(.degrees(Double(i) * 30))
            }

            // Handle with HIG 44pt touch target and precise coordinate space
            ZStack {
                Circle()
                    .fill(Color.ampedGreen)
                    .frame(width: 22, height: 22)
            }
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .offset(x: CGFloat(cos(angle * .pi / 180) * 95),
                    y: CGFloat(sin(angle * .pi / 180) * 95))
            .highPriorityGesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named("sleepDial"))
                    .onChanged { value in
                        let vector = CGVector(dx: value.location.x - 110, dy: value.location.y - 110)
                        var degrees = atan2(vector.dy, vector.dx) * 180 / .pi
                        if degrees < -90 { degrees += 360 } // keep going clockwise from top
                        withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.88)) {
                            angle = degrees
                        }
                        updateTimeFromAngle()
                    }
                    .onEnded { _ in
                        HapticFeedback.selection()
                    }
            )

            // Center readout
            VStack(spacing: 4) {
                Text(String(format: "%dh%02d", hours, minutes))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Sleep goal")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(height: 260)
        .coordinateSpace(name: "sleepDial")
        .onAppear { setAngleFromTime() }
    }

    private func setAngleFromTime() {
        // Map 7h to top (-90deg). Each 30m = 15deg. Range 5h..10h (10 segments)
        let totalHalfHours = max(10, min(20, hours * 2 + (minutes >= 30 ? 1 : 0)))
        let delta = Double(totalHalfHours - 14) * 15 // 14 half-hours = 7h baseline
        angle = -90 + delta
    }

    private func updateTimeFromAngle() {
        // Inverse mapping
        let delta = angle + 90
        let halfHours = Int(round(delta / 15)) + 14
        let clamped = max(10, min(20, halfHours))
        hours = clamped / 2
        minutes = (clamped % 2) * 30
    }
}

#Preview {
    SleepGoalDial(hours: .constant(7), minutes: .constant(30))
        .preferredColorScheme(.dark)
        .background(Color.black)
}
