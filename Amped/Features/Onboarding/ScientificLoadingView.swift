import SwiftUI

/// Loading screen that builds scientific credibility by showing research statistics
struct ScientificLoadingView: View {
    @State private var isLoaded = false
    @State private var progress: CGFloat = 0.0
    @State private var currentStatIndex = 0
    
    let onComplete: () -> Void
    
    // Loading statistics to display
    private let statistics = [
        "1,217 Longevity studies",
        "53+ million participants",
        "Backed by science",
        "Powered by AI"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.ampedDark.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Battery loading icon
                VStack(spacing: 20) {
                    // Large battery icon with animated fill
                    ZStack {
                        // Battery outline
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.ampedGreen, lineWidth: 3)
                            .frame(width: 80, height: 120)
                        
                        // Battery fill (animated)
                        VStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.ampedGreen)
                                .frame(width: 74, height: 114 * progress)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        .frame(width: 74, height: 114)
                        
                        // Battery terminal
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.ampedGreen)
                            .frame(width: 24, height: 8)
                            .offset(y: -68)
                    }
                    
                    // Loading text
                    Text("Analyzing health data...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Scientific statistics
                VStack(spacing: 16) {
                    ForEach(Array(statistics.enumerated()), id: \.offset) { index, stat in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.ampedGreen)
                                .opacity(index <= currentStatIndex ? 1.0 : 0.3)
                                .scaleEffect(index == currentStatIndex ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: currentStatIndex)
                            
                            Text(stat)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .opacity(index <= currentStatIndex ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 0.3), value: currentStatIndex)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
            }
        }
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        // Animate progress bar
        withAnimation(.easeInOut(duration: 2.5)) {
            progress = 1.0
        }
        
        // Animate statistics appearance
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
            if currentStatIndex < statistics.count - 1 {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStatIndex += 1
                }
            } else {
                timer.invalidate()
                // Complete after a brief pause
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    onComplete()
                }
            }
        }
    }
}

#Preview {
    ScientificLoadingView(onComplete: {})
}
