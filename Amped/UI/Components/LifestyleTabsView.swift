import SwiftUI

/// Intuitive lifestyle tabs - designed to match time selector styling
struct LifestyleTabsView: View {
    @Binding var selectedLifestyleTab: Int
    @Binding var shouldPulseTabsForNewUsers: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Current lifespan tab
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedLifestyleTab = 0
                }
                HapticManager.shared.playSelection()
            } label: {
                Text("Current Lifespan")
                    .fontWeight(selectedLifestyleTab == 0 ? .bold : .medium)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 16)
                    .background(
                        ZStack {
                            if selectedLifestyleTab == 0 {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.ampedGreen.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.ampedGreen, lineWidth: 1.5)
                                    .shadow(color: Color.ampedGreen.opacity(0.6), radius: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            }
                        }
                    )
                    .foregroundColor(selectedLifestyleTab == 0 ? Color.ampedGreen : .gray)
            }
            .buttonStyle(.plain)
            .minTappableArea(44)
            
            // Potential lifespan tab
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedLifestyleTab = 1
                }
                HapticManager.shared.playSelection()
            } label: {
                Text("Potential Lifespan")
                    .fontWeight(selectedLifestyleTab == 1 ? .bold : .medium)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, 16)
                    .background(
                        ZStack {
                            if selectedLifestyleTab == 1 {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.ampedGreen.opacity(0.2))
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.ampedGreen, lineWidth: 1.5)
                                    .shadow(color: Color.ampedGreen.opacity(0.6), radius: 4)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            }
                        }
                    )
                    .foregroundColor(selectedLifestyleTab == 1 ? Color.ampedGreen : .gray)
            }
            .buttonStyle(.plain)
            .minTappableArea(44)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.3))
        )
        .padding(.horizontal, 16)
        // Keep the pulsing animation for new user discoverability
        .scaleEffect(shouldPulseTabsForNewUsers ? 1.02 : 1.0)
        .animation(
            shouldPulseTabsForNewUsers ? 
                .easeInOut(duration: 1.5).repeatCount(3, autoreverses: true) : 
                .none,
            value: shouldPulseTabsForNewUsers
        )
        .onAppear {
            // Start pulsing animation for new users
            if shouldPulseTabsForNewUsers {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 1.5).repeatCount(3, autoreverses: true)) {
                        shouldPulseTabsForNewUsers = false
                    }
                    
                    // Stop the pulsing after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        shouldPulseTabsForNewUsers = false
                    }
                }
            }
        }
    }
} 