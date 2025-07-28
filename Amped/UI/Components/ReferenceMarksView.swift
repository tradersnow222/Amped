import SwiftUI

/// Reference marks to show critical, neutral, and optimal thresholds on the impact ring
/// Rule: Clear visual targets for user understanding
struct ReferenceMarksView: View {
    // MARK: - Properties
    
    let ringSize: CGFloat
    let showLabels: Bool
    
    // MARK: - Initialization
    
    init(ringSize: CGFloat = 200, showLabels: Bool = true) {
        self.ringSize = ringSize
        self.showLabels = showLabels
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Critical mark (0% - worst case at -120 minutes)
            ReferenceMarkView(
                angle: -180,
                label: showLabels ? "Critical" : nil,
                color: .ampedRed.opacity(0.8),
                ringSize: ringSize
            )
            
            // Neutral mark (50% - baseline at 0 minutes)
            ReferenceMarkView(
                angle: 0,
                label: showLabels ? "Neutral" : nil,
                color: .white.opacity(0.6),
                ringSize: ringSize
            )
            
            // Optimal mark (100% - best case at +120 minutes)
            ReferenceMarkView(
                angle: 180,
                label: showLabels ? "Optimal" : nil,
                color: .ampedGreen.opacity(0.8),
                ringSize: ringSize
            )
        }
    }
}

/// Individual reference mark with tick and optional label
struct ReferenceMarkView: View {
    let angle: Double
    let label: String?
    let color: Color
    let ringSize: CGFloat
    
    private var tickLength: CGFloat {
        ringSize * 0.06 // Smaller tick marks for compact design
    }
    
    private var tickOffset: CGFloat {
        ringSize / 2 - tickLength / 2
    }
    
    var body: some View {
        ZStack {
            // Tick mark
            Rectangle()
                .fill(color)
                .frame(width: 2, height: tickLength)
                .offset(y: -tickOffset)
                .rotationEffect(.degrees(angle))
            
            // Optional label
            if let label = label {
                let angleRadians = angle * .pi / 180 - .pi / 2
                let radius = ringSize / 2 + 12 // Tighter spacing for compact layout
                let xOffset = cos(angleRadians) * radius
                let yOffset = sin(angleRadians) * radius
                
                Text(label)
                    .font(.system(size: 9, weight: .medium)) // Compact font size
                    .foregroundColor(color)
                    .offset(x: xOffset, y: yOffset)
            }
        }
    }
}

// MARK: - Supporting Components

/// Impact summary view to display below the ring
struct ImpactSummaryView: View {
    let impact: ImpactValue
    let period: ImpactDataPoint.PeriodType
    
    private var periodText: String {
        switch period {
        case .day:
            return "Today"
        case .month:
            return "This Month"
        case .year:
            return "This Year"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Impact value
            Text(impact.displayString)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(impact.direction == .positive ? .ampedGreen : .ampedRed)
            
            // Context text
            HStack(spacing: 4) {
                Text(periodText)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("•")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                
                Text(impact.direction == .positive ? "gained" : "lost")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Description
            Text("from your lifespan")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Preview

#Preview("Reference Marks") {
    ZStack {
        // Sample progress ring as background
        ProgressRingView(
            progress: 0.65,
            ringWidth: 24,
            size: 200,
            gradientColors: [.ampedYellow, .ampedGreen],
            backgroundColor: Color.white.opacity(0.15)
        )
        
        // Reference marks overlay
        ReferenceMarksView(ringSize: 200)
    }
    .padding(50)
    .background(Color.black)
} 