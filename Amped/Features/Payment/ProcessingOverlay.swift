import SwiftUI

/// Processing overlay component for payment screen - Rules: Extracted to keep files under 300 lines
struct ProcessingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
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
            .background(Color.black.opacity(0.75))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
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