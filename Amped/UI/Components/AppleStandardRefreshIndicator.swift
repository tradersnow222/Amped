import SwiftUI

/// Apple-standard refresh indicator that matches iOS system behavior exactly
struct AppleStandardRefreshIndicator: View {
    let isRefreshing: Bool
    let pullDistance: CGFloat
    let opacity: Double
    let rotation: Double
    let threshold: CGFloat
    
    @State private var spinningRotation: Double = 0
    
    var body: some View {
        HStack {
            Spacer()
            
            ZStack {
                // Background circle with Apple's exact styling
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                if isRefreshing {
                    // Apple's spinning refresh indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .secondary))
                        .scaleEffect(0.8)
                        .rotationEffect(.degrees(spinningRotation))
                        .onAppear {
                            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                                spinningRotation = 360
                            }
                        }
                        .onDisappear {
                            spinningRotation = 0
                        }
                } else {
                    // Apple's pull arrow with exact design
                    Image(systemName: "arrow.down")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(min(pullDistance / threshold, 1.0))
                        .animation(.easeOut(duration: 0.2), value: rotation)
                }
            }
            .opacity(opacity)
            .scaleEffect(isRefreshing ? 1.0 : min(max(pullDistance / threshold, 0.3), 1.0))
            .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.7), value: isRefreshing)
            
            Spacer()
        }
        .frame(height: (pullDistance > 0 || isRefreshing) ? 44 : 0) // Show when pulling or refreshing
        .clipped()
        .accessibilityLabel("Pull to refresh")
        .accessibilityHint("Pull down to refresh the content")
        .accessibilityAction {
            // Accessibility action for VoiceOver users
            if !isRefreshing {
                // This would trigger refresh programmatically for accessibility
                // The actual refresh logic is handled by the parent view's gesture
            }
        }
    }
} 