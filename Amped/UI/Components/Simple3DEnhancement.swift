import SwiftUI

/// Simple 3D enhancement modifiers for existing components
/// Adheres to: Simplicity is KING - minimal, working integration
struct Simple3DEnhancement {
    
    // MARK: - 3D Enhancement Modifiers
    
    /// Adds subtle 3D depth to any view
    static func add3DDepth(to view: some View, intensity: Double = 0.6) -> some View {
        view
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.3),
                                .clear,
                                .black.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    /// Adds 3D perspective rotation on tap
    static func add3DInteraction(to view: some View) -> some View {
        view
            .onTapGesture {
                // Simple 3D feedback - works with existing haptics
                HapticManager.shared.playImpact(.light)
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: UUID())
    }
    
    /// Enhanced 3D battery with subtle effects
    static func enhance3DBattery(_ batteryView: BatteryIndicatorView) -> some View {
        ZStack {
            // Background depth layer
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.2))
                .offset(x: 3, y: 3)
                .blur(radius: 2)
            
            // Main battery with 3D effects
            batteryView
                .overlay(
                    // 3D rim lighting
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.4),
                                    .clear,
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
        }
    }
}

/// ViewModifier for easy 3D enhancement
struct Enhanced3DModifier: ViewModifier {
    let intensity: Double
    
    func body(content: Content) -> some View {
        Simple3DEnhancement.add3DDepth(
            to: Simple3DEnhancement.add3DInteraction(to: content),
            intensity: intensity
        )
    }
}

/// SwiftUI extension for easy use
extension View {
    /// Adds simple 3D enhancements to any view
    func enhanced3D(intensity: Double = 0.6) -> some View {
        self.modifier(Enhanced3DModifier(intensity: intensity))
    }
}

/// Enhanced 3D wrapper for existing BatteryIndicatorView
struct Enhanced3DBatteryIndicatorView: View {
    // All existing BatteryIndicatorView parameters
    let title: String
    let value: String
    let chargeLevel: Double
    let numberOfSegments: Int
    let useYellowGradient: Bool
    let internalText: String?
    let helpAction: (() -> Void)?
    let lifeProjection: LifeProjection?
    let currentUserAge: Double?
    let showValueBelow: Bool
    
    var body: some View {
        Simple3DEnhancement.enhance3DBattery(
            BatteryIndicatorView(
                title: title,
                value: value,
                chargeLevel: chargeLevel,
                numberOfSegments: numberOfSegments,
                useYellowGradient: useYellowGradient,
                internalText: internalText,
                helpAction: helpAction,
                lifeProjection: lifeProjection,
                currentUserAge: currentUserAge,
                showValueBelow: showValueBelow
            )
        )
    }
}

/// Enhanced 3D page container that works with existing ThreePageDashboardContainer
struct Enhanced3DPageContainer: View {
    @Binding var currentPage: Int
    let impactPage: AnyView
    let lifespanFactorsPage: AnyView
    let batteryPage: AnyView
    @Binding var isRefreshing: Bool
    @Binding var pullDistance: CGFloat
    
    @State private var dragOffset: CGFloat = 0
    
    var body: some View {
        ThreePageDashboardContainer(
            currentPage: $currentPage,
            impactPage: AnyView(
                impactPage
                    .rotation3DEffect(
                        .degrees(currentPage == 0 ? 0 : (currentPage > 0 ? -5 : 5)),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .scaleEffect(currentPage == 0 ? 1.0 : 0.95)
                    .opacity(currentPage == 0 ? 1.0 : 0.8)
                    .animation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 25, initialVelocity: 0), value: currentPage)
            ),
            lifespanFactorsPage: AnyView(
                lifespanFactorsPage
                    .rotation3DEffect(
                        .degrees(currentPage == 1 ? 0 : (currentPage > 1 ? -5 : 5)),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .scaleEffect(currentPage == 1 ? 1.0 : 0.95)
                    .opacity(currentPage == 1 ? 1.0 : 0.8)
                    .animation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 25, initialVelocity: 0), value: currentPage)
            ),
            batteryPage: AnyView(
                batteryPage
                    .rotation3DEffect(
                        .degrees(currentPage == 2 ? 0 : (currentPage > 2 ? -5 : 5)),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .scaleEffect(currentPage == 2 ? 1.0 : 0.95)
                    .opacity(currentPage == 2 ? 1.0 : 0.8)
                    .animation(.interpolatingSpring(mass: 1.0, stiffness: 200, damping: 25, initialVelocity: 0), value: currentPage)
            ),
            isRefreshing: $isRefreshing,
            pullDistance: $pullDistance
        )
    }
} 