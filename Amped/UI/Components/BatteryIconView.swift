import SwiftUI

/// A battery icon view that displays charge level with color-coded visualization
/// Rule: Follow Apple's Human Interface Guidelines for familiar battery visualization
struct BatteryIconView: View {
    // MARK: - Properties
    
    /// Battery level from 0 to 100
    let level: Int
    
    /// Size of the battery icon
    let size: CGSize
    
    /// Whether to show the battery level text
    let showPercentage: Bool
    
    // MARK: - Initialization
    
    init(level: Int, size: CGSize = CGSize(width: 60, height: 30), showPercentage: Bool = false) {
        self.level = max(0, min(100, level)) // Clamp to 0-100
        self.size = size
        self.showPercentage = showPercentage
    }
    
    // MARK: - Computed Properties
    
    private var fillColor: Color {
        // Rule: Consistent color scheme based on charge level
        switch level {
        case 0..<20:
            return .ampedRed
        case 20..<50:
            return .ampedYellow
        default:
            return .ampedGreen
        }
    }
    
    private var fillWidth: CGFloat {
        let batteryBodyWidth = size.width * 0.9
        let padding: CGFloat = 3
        let availableWidth = batteryBodyWidth - (padding * 2)
        return availableWidth * CGFloat(level) / 100.0
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Battery outline
            HStack(spacing: 0) {
                // Main battery body
                RoundedRectangle(cornerRadius: size.height * 0.15)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: size.width * 0.9, height: size.height)
                
                // Battery cap
                RoundedRectangle(cornerRadius: size.height * 0.1)
                    .fill(Color.white.opacity(0.8))
                    .frame(width: size.width * 0.1, height: size.height * 0.5)
                    .offset(x: -1) // Slight overlap for seamless connection
            }
            
            // Battery fill
            HStack {
                RoundedRectangle(cornerRadius: size.height * 0.1)
                    .fill(fillColor)
                    .frame(width: fillWidth, height: size.height - 6)
                    .padding(.leading, 3)
                    .animation(.easeInOut(duration: 0.3), value: level)
                
                Spacer(minLength: 0)
            }
            .frame(width: size.width * 0.9, height: size.height)
            .offset(x: -size.width * 0.05) // Align with battery body
            
            // Optional percentage text overlay
            if showPercentage {
                Text("\(level)%")
                    .font(.system(size: size.height * 0.4, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Preview

#Preview("Battery Icon Variations") {
    VStack(spacing: 30) {
        // Different charge levels
        HStack(spacing: 20) {
            VStack {
                BatteryIconView(level: 10)
                Text("10%")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            VStack {
                BatteryIconView(level: 45)
                Text("45%")
                    .font(.caption)
                    .foregroundColor(.white)
            }
            
            VStack {
                BatteryIconView(level: 85)
                Text("85%")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        
        Divider()
            .background(Color.white.opacity(0.3))
        
        // Different sizes
        VStack(spacing: 20) {
            BatteryIconView(level: 75, size: CGSize(width: 40, height: 20))
            BatteryIconView(level: 75, size: CGSize(width: 80, height: 40))
            BatteryIconView(level: 75, size: CGSize(width: 100, height: 50), showPercentage: true)
        }
    }
    .padding()
    .background(Color.black)
} 