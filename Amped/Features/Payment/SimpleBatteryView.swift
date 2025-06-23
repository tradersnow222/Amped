import SwiftUI

/// Battery visualization component for payment screen - Rules: Extracted to keep files under 300 lines
struct SimpleBatteryView: View {
    let percentage: Double
    var animateBars: Bool = false
    @State private var barsFilled: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Battery outline with thicker border
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.ampedGreen, lineWidth: 2.5)
                
                // Battery segments/bars
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        let isActive = Double(index) < (percentage * 5)
                        let isFilled = index < barsFilled
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: isActive ? [Color.ampedGreen, Color.ampedGreen.opacity(0.8)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .opacity(isFilled || !animateBars ? 1.0 : 0.3)
                            .animation(.easeInOut(duration: 0.4).delay(Double(index) * 0.3), value: barsFilled)
                    }
                }
                .padding(3)
                
                // Battery tip (nob) - more prominent and properly positioned
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.ampedGreen)
                    .frame(width: 6, height: geometry.size.height * 0.6)
                    .offset(x: geometry.size.width + 1)  // Moved slightly right to extend from outline
            }
        }
        .onChange(of: animateBars) { newValue in
            if newValue {
                // Animate bars filling one by one
                for i in 0..<5 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.3) {
                        withAnimation {
                            barsFilled = i + 1
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct SimpleBatteryView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            SimpleBatteryView(percentage: 0.3, animateBars: false)
                .frame(width: 60, height: 30)
            
            SimpleBatteryView(percentage: 0.85, animateBars: true)
                .frame(width: 60, height: 30)
            
            SimpleBatteryView(percentage: 0.92, animateBars: true)
                .frame(width: 60, height: 30)
        }
        .padding()
        .background(Color.black)
    }
} 