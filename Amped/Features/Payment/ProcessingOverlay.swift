import SwiftUI

/// Processing overlay component for payment screen - Rules: Extracted to keep files under 300 lines
struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .ampedGreen))
                    .scaleEffect(1.3)
                
                Text("Processing your subscription...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Preview

struct ProcessingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray
            
            ProcessingOverlay()
        }
    }
} 