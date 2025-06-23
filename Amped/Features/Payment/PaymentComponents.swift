import SwiftUI

/// Enhanced copy benefit row component - Rules: Extracted to keep files under 300 lines
struct BenefitRow: View {
    let icon: String
    let text: String
    var isHighlighted: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .light))
                .foregroundColor(.secondary)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary.opacity(0.9))
        }
    }
}

/// Benefits list view with animated entries
struct BenefitsListView: View {
    @Binding var showBenefits: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Four key benefits with enhanced copy
            BenefitRow(
                icon: "sparkles",
                text: "Real-time lifespan calculations"
            )
            .opacity(showBenefits ? 1.0 : 0.0)
            .offset(y: showBenefits ? 0 : 15)
            .animation(.easeOut(duration: 0.7).delay(0.15), value: showBenefits)
            
            BenefitRow(
                icon: "chart.line.uptrend.xyaxis",
                text: "See the impact of your daily habits"
            )
            .opacity(showBenefits ? 1.0 : 0.0)
            .offset(y: showBenefits ? 0 : 15)
            .animation(.easeOut(duration: 0.7).delay(0.3), value: showBenefits)
            
            BenefitRow(
                icon: "brain",
                text: "Backed by peer-reviewed science"
            )
            .opacity(showBenefits ? 1.0 : 0.0)
            .offset(y: showBenefits ? 0 : 15)
            .animation(.easeOut(duration: 0.7).delay(0.45), value: showBenefits)
            
            BenefitRow(
                icon: "lock",
                text: "100% private on your device"
            )
            .opacity(showBenefits ? 1.0 : 0.0)
            .offset(y: showBenefits ? 0 : 15)
            .animation(.easeOut(duration: 0.7).delay(0.6), value: showBenefits)
        }
        .frame(maxWidth: 280)
        .frame(maxWidth: .infinity, alignment: .center)
    }
} 