import SwiftUI
import Combine

/// A card that displays total projected life expectancy as a battery
struct BatteryLifeProjectionCard: View {
    // MARK: - Properties
    
    let lifeProjection: LifeProjection
    let userAge: Int
    
    @EnvironmentObject private var settingsManager: SettingsManager
    @State private var batteryFillPercent: Double = 0.0
    @State private var showPercentRemaining: Bool = false // Toggle between years and percentage - default to years for realtime countdown
    @State private var currentTime = Date()
    
    // Timer for realtime updates - update every 10ms for visible countdown
    private let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    // MARK: - UI Constants
    
    private let batteryHeight: CGFloat = 180
    private let batteryWidth: CGFloat = 90
    private let batteryCornerRadius: CGFloat = 12
    private let batteryTerminalWidth: CGFloat = 30
    private let batteryTerminalHeight: CGFloat = 12
    private let segmentCount: Int = 10
    private let segmentSpacing: CGFloat = 3
    
    // MARK: - Initialization
    
    init(lifeProjection: LifeProjection, userAge: Int) {
        self.lifeProjection = lifeProjection
        self.userAge = userAge
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            // Title - centered over battery
            Text("Lifespan remaining")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Battery visualization
            verticalBatteryVisualization
                .frame(height: batteryHeight + batteryTerminalHeight + 10)
                .padding(.horizontal)
            
            // Impact value display (toggleable between years and percentage)
            VStack(alignment: .center) {
                if showPercentRemaining {
                    // Percentage remaining
                    Text("\(Int(remainingPercentage))%")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(projectionColor)
                    
                    Text("Energy Remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    // Years remaining - with optional realtime countdown
                    Text(formattedRemainingYears)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(projectionColor)
                    
                    Text("Years Remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .onTapGesture {
                withAnimation {
                    showPercentRemaining.toggle()
                }
            }
            
            // Impact description
            Text(projectionDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
            
            // Net Impact
            HStack {
                Spacer()
                Text("Net impact: \(lifeProjection.formattedNetImpact)")
                    .font(.caption)
                    .foregroundColor(
                        lifeProjection.netImpactYears > 0 ? .ampedGreen : 
                        lifeProjection.netImpactYears < 0 ? .ampedRed : .secondary
                    )
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                batteryFillPercent = remainingPercentage / 100.0
            }
        }
        .onReceive(timer) { _ in
            if settingsManager.showRealtimeCountdown {
                currentTime = Date()
            }
        }
    }
    
    // MARK: - UI Components
    
    /// Vertical battery visualization
    private var verticalBatteryVisualization: some View {
        VStack(spacing: 0) {
            // Battery terminal (top)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray)
                .frame(width: batteryTerminalWidth, height: batteryTerminalHeight)
            
            // Battery body
            ZStack(alignment: .bottom) {
                // Battery outline
                RoundedRectangle(cornerRadius: batteryCornerRadius)
                    .stroke(Color.gray, lineWidth: 3)
                    .frame(width: batteryWidth, height: batteryHeight)
                
                // Battery fill with segments
                GeometryReader { geometry in
                    VStack(spacing: segmentSpacing) {
                        ForEach(0..<segmentCount, id: \.self) { index in
                            batterySegment(index: index, totalHeight: geometry.size.height)
                        }
                    }
                    .padding(6)
                }
                .frame(width: batteryWidth, height: batteryHeight)
                
                // Battery percentage
                Text("\(Int(remainingPercentage))%")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
                    .padding(.bottom, 24)
                    .opacity(batteryFillPercent > 0.15 ? 1.0 : 0.0)
            }
        }
    }
    
    /// Individual battery segment
    private func batterySegment(index: Int, totalHeight: CGFloat) -> some View {
        let reversedIndex = segmentCount - 1 - index
        let segmentHeight = (totalHeight - (CGFloat(segmentCount - 1) * segmentSpacing) - 12) / CGFloat(segmentCount)
        let segmentFillPercent = min(max(batteryFillPercent * Double(segmentCount) - Double(reversedIndex), 0), 1)
        
        return HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(segmentColor(index: index))
                .frame(height: segmentHeight)
                .scaleEffect(x: CGFloat(segmentFillPercent), anchor: .leading)
                .animation(.easeInOut(duration: 0.3), value: segmentFillPercent)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculate the segment color based on position
    private func segmentColor(index: Int) -> Color {
        // Colors go from red at bottom to green at top
        switch index {
        case 0, 1:
            return .fullPower
        case 2, 3:
            return .highPower
        case 4, 5:
            return .mediumPower
        case 6, 7:
            return .lowPower
        case 8, 9:
            return .criticalPower
        default:
            return .mediumPower
        }
    }
    
    /// Calculate remaining percentage
    private var remainingPercentage: Double {
        let ageInYears = Double(userAge)
        let remainingYears = lifeProjection.adjustedLifeExpectancyYears - ageInYears
        
        // Calculate percentage (cap between 0 and 100)
        return min(max((remainingYears / lifeProjection.adjustedLifeExpectancyYears) * 100.0, 0.0), 100.0)
    }
    
    /// Format remaining years
    private var formattedRemainingYears: String {
        let baseRemainingYears = lifeProjection.adjustedLifeExpectancyYears - Double(userAge)
        
        if settingsManager.showRealtimeCountdown {
            // Calculate time elapsed since start of current year to simulate countdown
            let calendar = Calendar.current
            let now = currentTime
            let startOfYear = calendar.dateInterval(of: .year, for: now)?.start ?? now
            let timeElapsed = now.timeIntervalSince(startOfYear)
            let yearsElapsed = timeElapsed / (365.25 * 24 * 3600)
            
            let preciseRemainingYears = baseRemainingYears - yearsElapsed
            
            // Format with high precision showing seconds as decimal places
            let result = String(format: "%.6f", max(preciseRemainingYears, 0.0))
            return result
        } else {
            let result = String(format: "%.1f", max(baseRemainingYears, 0.0))
            return result
        }
    }
    
    /// Generate projection description
    private var projectionDescription: String {
        if lifeProjection.netImpactYears > 3.0 {
            return "Your healthy habits are significantly extending your life expectancy!"
        } else if lifeProjection.netImpactYears > 1.0 {
            return "Your habits are adding valuable time to your life expectancy."
        } else if lifeProjection.netImpactYears > 0 {
            return "You're gaining some time from your current lifestyle."
        } else if lifeProjection.netImpactYears > -1.0 {
            return "Your habits are slightly reducing your projected lifespan."
        } else {
            return "Consider changing habits to increase your battery life."
        }
    }
    
    /// Calculate projection color
    private var projectionColor: Color {
        if remainingPercentage > 80 {
            return .ampedGreen
        } else if remainingPercentage > 60 {
            return .ampedGreen.opacity(0.8)
        } else if remainingPercentage > 40 {
            return .ampedYellow
        } else if remainingPercentage > 20 {
            return .ampedYellow.opacity(0.8)
        } else {
            return .ampedRed
        }
    }
}

// MARK: - Preview

struct BatteryLifeProjectionCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Good projection example - represents a real user with good health habits
            BatteryLifeProjectionCard(
                lifeProjection: LifeProjection(
                    calculationDate: Date(),
                    baselineLifeExpectancyYears: 80.0,
                    adjustedLifeExpectancyYears: 83.5,
                    confidencePercentage: 0.95,
                    confidenceIntervalYears: 2.0
                ),
                userAge: 30 // Early career professional with healthy habits
            )
            
            // Moderate projection example - represents a real user needing improvement
            BatteryLifeProjectionCard(
                lifeProjection: LifeProjection(
                    calculationDate: Date(),
                    baselineLifeExpectancyYears: 80.0,
                    adjustedLifeExpectancyYears: 77.2,
                    confidencePercentage: 0.95,
                    confidenceIntervalYears: 2.0
                ),
                userAge: 45 // Mid-career professional with room for improvement
            )
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .environmentObject(SettingsManager())
    }
} 