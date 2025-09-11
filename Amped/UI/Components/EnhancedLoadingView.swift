import SwiftUI

/// Enhanced loading view with Apple-quality UX for health impact calculation
/// Rules: Apple-quality loading experience with immediate value and progressive disclosure
struct EnhancedLoadingView: View {
    // MARK: - Properties
    
    let loadingType: LoadingType
    let onComplete: () -> Void
    
    @State private var progress: Double = 0.0
    @State private var currentMetric = "AGE"
    @State private var loadingTimer: Timer?
    
    // MARK: - Loading Types
    
    enum LoadingType {
        case healthImpact
        case lifeProjection
        
        fileprivate var metrics: [String] {
            switch self {
            case .healthImpact:
                return ["AGE", "ACTIVITY", "HEART", "SLEEP", "NUTRITION"]
            case .lifeProjection:
                return ["AGE", "HEALTH", "LIFESTYLE", "GENETICS"]
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
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main loading indicator with person icon
                VStack(spacing: 24) {
                    // Horizontal loading bar with person icon
                    ZStack(alignment: .leading) {
                        // Background bar with clipping shape
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.3), lineWidth: 4)
                            .frame(width: 158, height: 70)
                            .overlay(
                                // Progress fill with green-to-yellow gradient
                                HStack {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.0, green: 0.57, blue: 0.27),   // #009245 (green)
                                                    Color(red: 0.99, green: 0.93, blue: 0.13)  // #FCEE21 (yellow)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: 165 * progress, height: 66)
                                        .animation(.easeOut(duration: 0.1), value: progress)
                                    
                                    Spacer()
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        
                        // Person/Heart icon in center of the entire bar
                        ZStack {
                            // Heart shape (body)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                            
                            // Circle (head) above heart
                            Circle()
                                .stroke(Color.white,lineWidth:2 )
                                .frame(width: 8, height: 12)
                                .offset(y: -14)
                        }
                        .offset(x:70)
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 2)
                    }
                    
                    // Loading text
                    VStack(spacing: 4) {
                        Text("Calculating your lifespan impact from")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(currentMetric)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .animation(.easeInOut(duration: 0.4), value: currentMetric)
                    }
                }
                
                Spacer()
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
        // Set initial metric
        currentMetric = loadingType.metrics.first ?? "AGE"
        
        let totalDuration = loadingType.totalDuration
        let metrics = loadingType.metrics
        let updateInterval: TimeInterval = 0.016 // 60 FPS for ultra-smooth animation
        let totalSteps = Int(totalDuration / updateInterval)
        let progressIncrement = 1.0 / Double(totalSteps)
        
        var currentStepIndex = 0
        var accumulatedProgress: Double = 0
        
        // Calculate when to transition metrics (evenly distributed)
        let metricTransitionPoints = metrics.enumerated().map { index, _ in
            Double(index + 1) / Double(metrics.count)
        }
        
        loadingTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            accumulatedProgress += progressIncrement
            
            // Use a gentler easing function for smoother progress
            let easedProgress = easeInOutQuad(accumulatedProgress)
            
            // Update progress
            progress = min(easedProgress, 1.0)
            
            // Check if we should transition to next metric
            let nextTransitionIndex = currentStepIndex + 1
            if nextTransitionIndex < metricTransitionPoints.count {
                let nextTransitionPoint = metricTransitionPoints[nextTransitionIndex]
                if easedProgress >= nextTransitionPoint {
                    currentStepIndex = nextTransitionIndex
                    withAnimation(.easeInOut(duration: 0.4)) {
                        currentMetric = metrics[min(currentStepIndex, metrics.count - 1)]
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
