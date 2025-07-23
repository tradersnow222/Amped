import SwiftUI

/// Enhanced loading view with Apple-quality UX for health impact calculation
/// Rules: Apple-quality loading experience with immediate value and progressive disclosure
struct EnhancedLoadingView: View {
    // MARK: - Properties
    
    let loadingType: LoadingType
    let onComplete: () -> Void
    
    @State private var progress: Double = 0.0
    @State private var currentStep = 0
    @State private var showValueMessage = false
    @State private var batteryLevel: Double = 0.0
    @State private var currentMessage = ""
    @State private var loadingTimer: Timer?
    
    // MARK: - Loading Types
    
    enum LoadingType {
        case healthImpact
        case lifeProjection
        
        fileprivate var messages: [String] {
            switch self {
            case .healthImpact:
                return [
                    "Analyzing your activity data",
                    "Processing heart health metrics",
                    "Evaluating sleep patterns",
                    "Calculating health impact",
                    "Powering up your results"
                ]
            case .lifeProjection:
                return [
                    "Analyzing your health profile",
                    "Comparing to research data",
                    "Calculating life projection",
                    "Finalizing your results"
                ]
            }
        }
        
        var title: String {
            switch self {
            case .healthImpact:
                return "Calculating Your Health Impact"
            case .lifeProjection:
                return "Calculating Your Life Projection"
            }
        }
        
        var valueMessage: String {
            switch self {
            case .healthImpact:
                return "See how your daily habits are affecting your energy levels"
            case .lifeProjection:
                return "Discover your personalized life expectancy based on your health data"
            }
        }
        
        var totalDuration: Double {
            switch self {
            case .healthImpact:
                return 3.2 // Total loading time in seconds
            case .lifeProjection:
                return 2.8
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 32) {
            // Title only (no subtitle)
            if showValueMessage {
                Text(loadingType.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Battery charging animation
            ChargingBatteryView(
                batteryLevel: batteryLevel,
                isCharging: progress < 1.0
            )
            
            // Progress steps with smooth text transitions
            VStack(spacing: 16) {
                // Current step message with smooth transitions
                Text(currentMessage)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(height: 22)
                    .animation(.easeInOut(duration: 0.4), value: currentMessage)
                
                // Smooth progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress with continuous animation
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.ampedGreen, .ampedGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeOut(duration: 0.1), value: progress)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 20)
            
            // Preview skeleton cards (optional)
            if loadingType == .healthImpact {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        SkeletonMetricCard(isLoaded: progress > 0.6)
                    }
                }
                .padding(.horizontal, 20)
                .opacity(0.6)
            }
        }
        .onAppear {
            startSmoothLoadingAnimation()
        }
        .onDisappear {
            stopLoadingAnimation()
        }
    }
    
    // MARK: - Smooth Loading Animation
    
    private func startSmoothLoadingAnimation() {
        // Show value message immediately
        withAnimation(.easeInOut(duration: 0.5)) {
            showValueMessage = true
        }
        
        // Set initial message
        currentMessage = loadingType.messages.first ?? ""
        
        let totalDuration = loadingType.totalDuration
        let messages = loadingType.messages
        let updateInterval: TimeInterval = 0.016 // 60 FPS for ultra-smooth animation
        let totalSteps = Int(totalDuration / updateInterval)
        let progressIncrement = 1.0 / Double(totalSteps)
        
        var currentStepIndex = 0
        var accumulatedProgress: Double = 0
        
        // Calculate when to transition messages (evenly distributed)
        let messageTransitionPoints = messages.enumerated().map { index, _ in
            Double(index + 1) / Double(messages.count)
        }
        
        loadingTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            accumulatedProgress += progressIncrement
            
            // Use a gentler easing function for smoother progress
            let easedProgress = easeInOutQuad(accumulatedProgress)
            
            // Update progress and battery level WITHOUT animation wrapper
            // Let SwiftUI handle implicit animations for smoother experience
            progress = min(easedProgress, 1.0)
            batteryLevel = min(easedProgress, 1.0)
            
            // Check if we should transition to next message
            let nextTransitionIndex = currentStepIndex + 1
            if nextTransitionIndex < messageTransitionPoints.count {
                let nextTransitionPoint = messageTransitionPoints[nextTransitionIndex]
                if easedProgress >= nextTransitionPoint {
                    currentStepIndex = nextTransitionIndex
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentMessage = messages[min(currentStepIndex, messages.count - 1)]
                    }
                }
            }
            
            // Complete loading when progress reaches 100%
            if accumulatedProgress >= 1.0 {
                timer.invalidate()
                loadingTimer = nil
                
                // Brief pause before completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onComplete()
                }
            }
        }
    }
    
    private func stopLoadingAnimation() {
        loadingTimer?.invalidate()
        loadingTimer = nil
    }
    
    // Gentler quadratic easing function for smoother, more consistent progress
    private func easeInOutQuad(_ t: Double) -> Double {
        if t < 0.5 {
            return 2 * t * t
        } else {
            return 1 - 2 * (1 - t) * (1 - t)
        }
    }
}

// MARK: - Supporting Views

/// Charging battery animation for the loading state
private struct ChargingBatteryView: View {
    let batteryLevel: Double
    let isCharging: Bool
    
    @State private var chargingPulse = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Battery visual
            ZStack {
                // Battery outline
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.4), lineWidth: 3)
                    .frame(width: 80, height: 45)
                
                // Battery terminal
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 4, height: 20)
                    .offset(x: 44, y: 0)
                
                // Battery fill with smooth continuous animation
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: batteryFillColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(4, 72 * batteryLevel), height: 37)
                    .offset(x: -36 + (36 * batteryLevel), y: 0)
                    .animation(.easeOut(duration: 0.1), value: batteryLevel)
                
                // Charging effect with subtle animation
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                        .scaleEffect(chargingPulse ? 1.1 : 1.0)
                        .opacity(chargingPulse ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: chargingPulse)
                }
            }
            
            // Battery percentage with smooth updates
            Text("\(Int(batteryLevel * 100))%")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .modifier(NumericTextTransitionModifier(value: batteryLevel * 100))
        }
        .onAppear {
            if isCharging {
                chargingPulse = true
            }
        }
    }
    
    private var batteryFillColors: [Color] {
        if batteryLevel < 0.3 {
            return [.ampedRed, .ampedRed.opacity(0.8)]
        } else if batteryLevel < 0.7 {
            return [.ampedYellow, .ampedYellow.opacity(0.8)]
        } else {
            return [.ampedGreen, .ampedGreen.opacity(0.8)]
        }
    }
}

/// Skeleton card that shows loading state for metric cards
private struct SkeletonMetricCard: View {
    let isLoaded: Bool
    
    @State private var shimmerPhase = 0.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon placeholder
            Circle()
                .fill(isLoaded ? .ampedGreen.opacity(0.3) : .white.opacity(0.1))
                .frame(width: 24, height: 24)
            
            // Title placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(isLoaded ? .ampedGreen.opacity(0.2) : .white.opacity(0.1))
                .frame(height: 12)
            
            // Subtitle placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(isLoaded ? .ampedGreen.opacity(0.1) : .white.opacity(0.05))
                .frame(width: 80, height: 10)
            
            Spacer()
        }
        .frame(height: 120)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
                .overlay(
                    // Shimmer effect
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.1),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerPhase)
                        .animation(
                            .linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                            value: shimmerPhase
                        )
                )
        )
        .onAppear {
            shimmerPhase = 200
        }
    }
}

/// iOS version-compatible numeric text transition modifier
/// Using iOS 17+ numericText transition when available, graceful fallback for iOS 16
private struct NumericTextTransitionModifier: ViewModifier {
    let value: Double
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .contentTransition(.numericText(value: value))
        } else {
            content
                .animation(.easeInOut(duration: 0.3), value: value)
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 40) {
            EnhancedLoadingView(
                loadingType: .healthImpact,
                onComplete: {
                    print("Health impact calculation complete!")
                }
            )
        }
    }
} 