import SwiftUI

/// Premium circular dial for selecting desired daily lifespan gain (minutes/day)
/// Range: 5–120 minutes, in 5-minute steps. Designed to feel luxurious.
/// Applied rules: Simplicity is KING (User rule) and files under 300 lines with single responsibility.
struct LifespanGainDial: View {
    @Binding var minutesPerDay: Int // 5...120, step 5

    private let minMinutes = 5
    private let maxMinutes = 120
    private let step = 5

    @State private var angle: Double = -90 // degrees, -90 at top
    @State private var lastHapticStep: Int = -1
    @State private var lastDialDegrees: Double? = nil // Track last dial angle (0...360) to block crossing 0°
    @State private var isDraggingHandle: Bool = false // Only allow movement when drag begins on handle
    @State private var cumulativeDegrees: Double = 0   // Continuous, clamped 0...360 dial angle for robust stops

    private enum BoundaryLock {
        case none
        case atZero
        case atFull
    }
    @State private var boundaryLock: BoundaryLock = .none

    var body: some View {
        ZStack {
            backgroundView
            trackView
            progressArcView
            tickMarksView
            handleView
            centerReadoutView
        }
        .frame(width: 300, height: 300)
        .coordinateSpace(name: "lifespanDial")
        .onAppear { setAngleFromMinutes() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Desired daily lifespan gain")
        .accessibilityValue(accessibilityValueText)
    }
    
    // MARK: - View Components (Simplicity is KING - breaking up complex view)
    
    private var backgroundView: some View {
        // Subtle glow backdrop
        Circle()
            .fill(
                RadialGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.02)],
                               center: .center, startRadius: 10, endRadius: 140)
            )
            .blur(radius: 8)
            .frame(width: 250, height: 250)
    }
    
    private var trackView: some View {
        // Track with multi-layer luxury effect
        Circle()
            .stroke(Color.white.opacity(0.10), lineWidth: 14)
            .frame(width: 240, height: 240)
    }
    
    private var progressArcView: some View {
        // Progress arc
        Circle()
            .trim(from: 0, to: progressFraction)
            .stroke(progressGradient, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
            .rotationEffect(.degrees(-90))
            .frame(width: 240, height: 240)
            .shadow(color: Color.ampedGreen.opacity(0.45), radius: 10, x: 0, y: 0)
    }
    
    private var progressGradient: AngularGradient {
        AngularGradient(
            gradient: Gradient(colors: [
                Color.ampedGreen.opacity(0.25),
                Color.ampedGreen,
                Color.ampedYellow,
                Color.ampedGreen
            ]),
            center: .center
        )
    }
    
    private var tickMarksView: some View {
        // Ticks every 15 minutes (three 5-min steps)
        ForEach(0..<24) { i in
            Rectangle()
                .fill(Color.white.opacity(i % 3 == 0 ? 0.45 : 0.25))
                .frame(width: i % 3 == 0 ? 3 : 1.5, height: i % 3 == 0 ? 14 : 9)
                .offset(y: -107)
                .rotationEffect(.degrees(Double(i) * (360.0 / 24.0)))
        }
    }
    
    private var handleView: some View {
        // Handle with inner glow
        // Rules applied: Simplicity is KING; smooth & precise. HIG: 44pt minimum touch target.
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .overlay(handleGlow)
                .overlay(handleStroke)
        }
        .frame(width: 44, height: 44) // HIG-compliant invisible hit target
        .contentShape(Circle())
        .offset(x: CGFloat(cos(angleRadians) * 120), y: CGFloat(sin(angleRadians) * 120))
        .highPriorityGesture(dragGesture)
    }
    
    private var handleGlow: some View {
        Circle()
            .fill(Color.ampedGreen)
            .blur(radius: 8)
            .opacity(0.9)
            .allowsHitTesting(false)
    }
    
    private var handleStroke: some View {
        Circle()
            .stroke(Color.white.opacity(0.7), lineWidth: 2)
            .allowsHitTesting(false)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("lifespanDial"))
            .onChanged(handleDragChanged)
            .onEnded { _ in
                HapticFeedback.buttonPress()
                isDraggingHandle = false
                boundaryLock = .none
                lastDialDegrees = nil
            }
    }
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        // Apple HIG: Direct manipulation with smooth, predictable behavior
        let center = CGPoint(x: 150, y: 150)
        let vector = CGPoint(x: value.location.x - center.x,
                              y: value.location.y - center.y)

        // Require the drag to begin on the handle for a premium, precise feel
        // Compute current handle center in this coordinate space
        let handleCenter = CGPoint(x: center.x + CGFloat(cos(angleRadians) * 120),
                                   y: center.y + CGFloat(sin(angleRadians) * 120))
        let startDistance = hypot(value.startLocation.x - handleCenter.x,
                                  value.startLocation.y - handleCenter.y)
        let handleTouchRadius: CGFloat = 18 // Tight radius for sensitive feel
        if !isDraggingHandle {
            // Only arm the drag if the gesture started on the handle
            if startDistance <= handleTouchRadius {
                isDraggingHandle = true
            } else {
                return
            }
        }

        // Calculate dial angle in degrees with 0° at top, increasing clockwise in [0, 360]
        // UIKit coords: y grows downward → atan2 uses (y, x) and we shift by +90° to make 0° = top
        // Compute raw dial degrees 0...360 (0 at top, CW positive)
        var rawDegrees = atan2(vector.y, vector.x) * 180 / .pi + 90
        if rawDegrees < 0 { rawDegrees += 360 }
        if rawDegrees > 360 { rawDegrees = 360 }

        // Minimal signed delta relative to previous raw angle
        let previousRaw = lastDialDegrees ?? rawDegrees
        let delta = ((rawDegrees - previousRaw + 540).truncatingRemainder(dividingBy: 360)) - 180

        // Update continuous cumulative angle and clamp to hard stops [0, 360]
        cumulativeDegrees = max(0, min(360, cumulativeDegrees + delta))
        let dialDegrees = cumulativeDegrees

        // Track raw position for next delta computation
        lastDialDegrees = rawDegrees

        // Map angle fraction (0..1) to 5-minute steps between 5..120
        let fraction = dialDegrees / 360
        let totalSteps = (maxMinutes - minMinutes) / step
        let stepIndex = Int(round(fraction * Double(totalSteps)))
        let clampedStepIndex = max(0, min(totalSteps, stepIndex))
        let newMinutes = minMinutes + clampedStepIndex * step

        // Haptic feedback on step changes
        let currentStep = (newMinutes - minMinutes) / step
        if currentStep != lastHapticStep {
            HapticFeedback.selection()
            lastHapticStep = currentStep
        }

        // Update both minutes and angle together
        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.95)) {
            minutesPerDay = newMinutes
            angle = -90 + dialDegrees  // convert 0° top → -90° coordinate used by handle layout
        }
    }
    
    private var centerReadoutView: some View {
        // Center readout
        VStack(spacing: 6) {
            Text(displayValueText)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text("added per day")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.75))
        }
    }

    // MARK: - Private Helpers
    private var progressFraction: CGFloat {
        let clamped = max(minMinutes, min(minutesPerDay, maxMinutes))
        return CGFloat(Double(clamped - minMinutes) / Double(maxMinutes - minMinutes))
    }

    private var angleRadians: Double { angle * .pi / 180 }

    // Display formatting: minutes under 60, hours with 1 decimal at 60+
    private var displayValueText: String {
        if minutesPerDay >= 60 {
            let hours = Double(minutesPerDay) / 60.0
            return String(format: "%.1f hr", hours)
        } else {
            return "\(minutesPerDay) min"
        }
    }

    private var accessibilityValueText: String {
        if minutesPerDay >= 60 {
            let hours = Double(minutesPerDay) / 60.0
            return String(format: "%.1f hours per day", hours)
        } else {
            return "\(minutesPerDay) minutes per day"
        }
    }

    private func normalizedStep(for minutes: Int) -> Int {
        let clamped = max(minMinutes, min(minutes, maxMinutes))
        return ((clamped - minMinutes) / step)
    }

    private func setAngleFromMinutes() {
        // Apple HIG: Consistent mapping between data and visual representation
        let fraction = Double(minutesPerDay - minMinutes) / Double(maxMinutes - minMinutes)
        let dialDegrees = max(0, min(360, fraction * 360))
        cumulativeDegrees = dialDegrees
        angle = -90 + dialDegrees
        lastHapticStep = (minutesPerDay - minMinutes) / step
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LifespanGainDial(minutesPerDay: .constant(25))
    }
    .preferredColorScheme(.dark)
}


