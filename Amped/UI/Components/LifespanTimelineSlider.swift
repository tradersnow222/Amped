import SwiftUI
import OSLog

/// Clean, minimal lifespan timeline slider showing past life, current projection, and potential
/// Rule: Simplicity is KING - Minimal timeline interface matching the clean design aesthetic
struct LifespanTimelineSlider: View {
    // MARK: - Properties
    
    let lifeProjection: LifeProjection
    let userProfile: UserProfile
    let healthMetrics: [HealthMetric]
    let onTapForDetails: () -> Void
    let showLabels: Bool // New property to control label display
    
    @Environment(\.glassTheme) private var glassTheme
    @State private var animateIn = false
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.amped.Amped", category: "LifespanTimelineSlider")
    
    // MARK: - Computed Properties
    
    private var currentAge: Double {
        Double(userProfile.age ?? 30)
    }
    
    private var projectedTotalLifespan: Double {
        lifeProjection.adjustedLifeExpectancyYears
    }
    
    private var pastLifeRatio: Double {
        currentAge / projectedTotalLifespan
    }
    
    private var futureLifeRatio: Double {
        (projectedTotalLifespan - currentAge) / projectedTotalLifespan
    }
    
    // MARK: - Initializers
    
    init(lifeProjection: LifeProjection, userProfile: UserProfile, healthMetrics: [HealthMetric], onTapForDetails: @escaping () -> Void, showLabels: Bool = true) {
        self.lifeProjection = lifeProjection
        self.userProfile = userProfile
        self.healthMetrics = healthMetrics
        self.onTapForDetails = onTapForDetails
        self.showLabels = showLabels
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 24) {
            // Timeline container with better spacing
            VStack(spacing: 16) {
                // Timeline track
                timelineTrack
                
                // Labels below the timeline (only if showLabels is true)
                if showLabels {
                    timelineLabels
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                animateIn = true
            }
        }
        .onTapGesture {
            onTapForDetails()
        }
    }
    
    // MARK: - Timeline Components
    
    private var timelineTrack: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let trackHeight: CGFloat = 8
            let knobSize: CGFloat = 24
            
            ZStack(alignment: .leading) {
                // Background track - dark
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.white.opacity(0.15))
                    .frame(height: trackHeight)
                
                // Past life segment (years already lived)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.white.opacity(0.4))
                    .frame(
                        width: animateIn ? trackWidth * pastLifeRatio : 0,
                        height: trackHeight
                    )
                    .animation(.easeOut(duration: 1.0), value: animateIn)
                
                // Future life segment (projected years remaining)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.yellow.opacity(0.85))
                    .frame(
                        width: animateIn ? trackWidth * futureLifeRatio : 0,
                        height: trackHeight
                    )
                    .offset(x: trackWidth * pastLifeRatio)
                    .animation(.easeOut(duration: 1.0).delay(0.3), value: animateIn)
                
                // Current position knob
                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .offset(x: (trackWidth * pastLifeRatio) - (knobSize / 2))
                    .scaleEffect(animateIn ? 1.0 : 0.8)
                    .animation(.easeOut(duration: 0.8).delay(0.6), value: animateIn)
            }
        }
        .frame(height: 32) // Increased height for better touch target
    }
    
    private var timelineLabels: some View {
        HStack {
            // Past label
            Text("Past")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            // Future label  
            Text("Future")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.yellow.opacity(0.8))
            
            Spacer()
            
            // Potential improvement label
            Text("Lifestyle adj. difference")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.green.opacity(0.8))
        }
        .opacity(animateIn ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateIn)
    }
}

// MARK: - Separate Timeline Labels Component

/// Standalone timeline labels that can be positioned independently
struct TimelineLabels: View {
    @State private var animateIn = false
    
    var body: some View {
        HStack {
            // Past label
            Text("Past")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            // Future label  
            Text("Future")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.yellow.opacity(0.8))
            
            Spacer()
            
            // Potential improvement label
            Text("Lifestyle adj. difference")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.green.opacity(0.8))
        }
        .opacity(animateIn ? 1.0 : 0.0)
        .animation(.easeOut(duration: 0.8).delay(1.0), value: animateIn)
        .onAppear {
            animateIn = true
        }
    }
}

// MARK: - Supporting Types

/// Data structure for timeline positioning
struct TimelineData {
    let currentPosition: CGFloat  // Where the thumb sits (current age)
    let pastWidth: CGFloat       // Width of lived years segment
    let currentWidth: CGFloat    // Width of projected years segment
    let potentialWidth: CGFloat  // Width of potential additional years
}

// MARK: - Preview

#Preview {
    let mockProfile = UserProfile(
        birthYear: 1990,
        gender: .male,
        height: 175,
        weight: 70
    )
    
    let mockProjection = LifeProjection(
        baselineLifeExpectancyYears: 78.0,
        adjustedLifeExpectancyYears: 72.0,
        currentAge: 30.0
    )
    
    let mockMetrics: [HealthMetric] = []
    
    return VStack(spacing: 40) {
        LifespanTimelineSlider(
            lifeProjection: mockProjection,
            userProfile: mockProfile,
            healthMetrics: mockMetrics,
            onTapForDetails: {},
            showLabels: true // Set to true for preview
        )
        .padding(.horizontal, 20)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .preferredColorScheme(.dark)
} 