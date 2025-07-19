import SwiftUI

/// A toast popup that displays metric descriptions in an Apple-style modal
struct DescriptionToast: View {
    // MARK: - Properties
    
    /// The name of the metric being described
    let metricName: String
    
    /// The description text to display
    let description: String
    
    /// Binding to control whether the toast is presented
    @Binding var isPresented: Bool
    
    /// Animation state for smooth transitions
    @State private var animationOffset: CGFloat = 300
    @State private var backgroundOpacity: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .opacity(backgroundOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissToast()
                }
            
            // Toast card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    // Icon
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.ampedGreen)
                    
                    // Title
                    Text("About \(metricName)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Description
                    Text(description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 32)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                
                // Divider
                Divider()
                
                // Got it button
                Button(action: {
                    dismissToast()
                }) {
                    Text("Got it")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.ampedGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .contentShape(Rectangle())
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.75))
            )
            .frame(maxWidth: 340)
            .padding(.horizontal, 20)
            .offset(y: animationOffset)
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
        .onAppear {
            presentToast()
        }
    }
    
    // MARK: - Animation Methods
    
    /// Animate the toast into view
    private func presentToast() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animationOffset = 0
        }
        
        withAnimation(.easeOut(duration: 0.3)) {
            backgroundOpacity = 1
        }
    }
    
    /// Animate the toast out of view and dismiss
    private func dismissToast() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            animationOffset = 300
        }
        
        withAnimation(.easeIn(duration: 0.25)) {
            backgroundOpacity = 0
        }
        
        // Delay dismissal to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
} 