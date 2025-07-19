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
    
    // MARK: - Loading Types
    
    enum LoadingType {
        case healthImpact
        case lifeProjection
        
        fileprivate var steps: [LoadingStep] {
            switch self {
            case .healthImpact:
                return [
                    LoadingStep(message: "Analyzing your activity data", duration: 0.8),
                    LoadingStep(message: "Processing heart health metrics", duration: 0.6),
                    LoadingStep(message: "Evaluating sleep patterns", duration: 0.6),
                    LoadingStep(message: "Calculating health impact", duration: 0.8),
                    LoadingStep(message: "Powering up your results", duration: 0.4)
                ]
            case .lifeProjection:
                return [
                    LoadingStep(message: "Analyzing your health profile", duration: 0.6),
                    LoadingStep(message: "Comparing to research data", duration: 0.8),
                    LoadingStep(message: "Calculating life projection", duration: 0.8),
                    LoadingStep(message: "Finalizing your results", duration: 0.6)
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
            
            // Progress steps
            VStack(spacing: 16) {
                if currentStep < loadingType.steps.count {
                    HStack(spacing: 12) {
                        // Animated checkmark or loading indicator
                        if progress >= stepProgress(for: currentStep) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ampedGreen)
                                .font(.system(size: 16, weight: .medium))
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .ampedGreen))
                                .scaleEffect(0.8)
                        }
                        
                        Text(loadingType.steps[currentStep].message)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.ampedGreen, .ampedGreen.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: progress)
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
            startLoadingAnimation()
        }
    }
    
    // MARK: - Helper Methods
    
    private func stepProgress(for step: Int) -> Double {
        let totalSteps = Double(loadingType.steps.count)
        return Double(step + 1) / totalSteps
    }
    
    private func startLoadingAnimation() {
        // Show value message immediately
        withAnimation(.easeInOut(duration: 0.5)) {
            showValueMessage = true
        }
        
        // Start the loading sequence
        var cumulativeDuration: Double = 0.4
        
        for (index, step) in loadingType.steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + cumulativeDuration) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = index
                    progress = stepProgress(for: index)
                    batteryLevel = progress
                }
            }
            cumulativeDuration += step.duration
        }
        
        // Complete the loading
        DispatchQueue.main.asyncAfter(deadline: .now() + cumulativeDuration + 0.6) {
            withAnimation(.easeInOut(duration: 0.4)) {
                progress = 1.0
                batteryLevel = 1.0
            }
            
            // Call completion after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
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
                
                // Battery fill
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
                    .animation(.easeInOut(duration: 0.6), value: batteryLevel)
                
                // Charging effect
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .bold))
                        .scaleEffect(chargingPulse ? 1.2 : 1.0)
                        .opacity(chargingPulse ? 0.8 : 1.0)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: chargingPulse)
                }
            }
            
            // Battery percentage
            Text("\(Int(batteryLevel * 100))%")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
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
                .fill(
                    isLoaded ? 
                    .white.opacity(0.2) : 
                    .white.opacity(0.1)
                )
                .frame(height: 12)
                .frame(maxWidth: .infinity)
            
            // Value placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    isLoaded ? 
                    .ampedGreen.opacity(0.3) : 
                    .white.opacity(0.1)
                )
                .frame(height: 16)
                .frame(maxWidth: .infinity)
        }
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

// MARK: - Supporting Models

fileprivate struct LoadingStep {
    let message: String
    let duration: Double // Duration in seconds
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