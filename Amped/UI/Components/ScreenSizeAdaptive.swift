import SwiftUI
import UIKit

/// Screen size categories for responsive design
enum ScreenSizeCategory {
    case compact    // iPhone SE, iPhone 8 and smaller
    case regular    // iPhone 12-15, iPhone X-11 Pro
    case large      // iPhone 12-15 Pro Max, iPhone 11 Pro Max
    
    /// Current device's screen size category
    static var current: ScreenSizeCategory {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        let maxDimension = max(screenHeight, screenWidth)
        
        switch maxDimension {
        case ...667:  // iPhone SE 2020 (667), iPhone 8 (667) and smaller
            return .compact
        case 668...845: // iPhone 12 mini (812), iPhone X-11 Pro (812), iPhone 12-14 (844)
            return .regular
        default:        // iPhone 12-14 Pro Max (926) and larger
            return .large
        }
    }
    
    /// Available content height after accounting for safe areas and navigation
    var availableContentHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        let safeAreaTop = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
        let safeAreaBottom = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 34
        
        // Account for category header (~100pt) and progress indicator (~60pt)
        let reservedSpace: CGFloat = 160
        
        return screenHeight - safeAreaTop - safeAreaBottom - reservedSpace
    }
    
    /// Adaptive spacing values for different screen sizes
    var adaptiveSpacing: AdaptiveSpacing {
        switch self {
        case .compact:
            return AdaptiveSpacing(
                questionBottomPadding: 16,    // Reduced from 30
                buttonSpacing: 8,             // Reduced from 12
                maxSpacerHeight: 20,          // Limit spacer expansion
                sectionSpacing: 8             // Reduced section spacing
            )
        case .regular:
            return AdaptiveSpacing(
                questionBottomPadding: 24,    // Slightly reduced from 30
                buttonSpacing: 10,            // Slightly reduced from 12
                maxSpacerHeight: 40,          // Moderate spacer limit
                sectionSpacing: 12            // Standard spacing
            )
        case .large:
            return AdaptiveSpacing(
                questionBottomPadding: 30,    // Full spacing
                buttonSpacing: 12,            // Full spacing
                maxSpacerHeight: 60,          // Full spacer expansion
                sectionSpacing: 16            // Generous spacing
            )
        }
    }
}

/// Adaptive spacing configuration for different screen sizes
struct AdaptiveSpacing {
    let questionBottomPadding: CGFloat
    let buttonSpacing: CGFloat
    let maxSpacerHeight: CGFloat
    let sectionSpacing: CGFloat
}

/// View modifier for adaptive spacing based on screen size
struct AdaptiveSpacingModifier: ViewModifier {
    let spacing: AdaptiveSpacing
    
    init() {
        self.spacing = ScreenSizeCategory.current.adaptiveSpacing
    }
    
    func body(content: Content) -> some View {
        content
            .environment(\.adaptiveSpacing, spacing)
    }
}

/// Environment key for adaptive spacing
private struct AdaptiveSpacingKey: EnvironmentKey {
    static let defaultValue = ScreenSizeCategory.regular.adaptiveSpacing
}

extension EnvironmentValues {
    var adaptiveSpacing: AdaptiveSpacing {
        get { self[AdaptiveSpacingKey.self] }
        set { self[AdaptiveSpacingKey.self] = newValue }
    }
}

/// Adaptive spacer that respects screen size constraints
struct AdaptiveSpacer: View {
    let minHeight: CGFloat
    let maxHeight: CGFloat?
    
    @Environment(\.adaptiveSpacing) private var spacing
    
    init(minHeight: CGFloat = 8, maxHeight: CGFloat? = nil) {
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        Spacer()
            .frame(
                minHeight: minHeight,
                maxHeight: maxHeight ?? spacing.maxSpacerHeight
            )
    }
}

/// Extension for easy application of adaptive spacing
extension View {
    func adaptiveSpacing() -> some View {
        self.modifier(AdaptiveSpacingModifier())
    }
    
    /// Apply screen-size appropriate bottom padding
    func adaptiveBottomPadding() -> some View {
        self.padding(.bottom, ScreenSizeCategory.current.adaptiveSpacing.questionBottomPadding)
    }
    
    /// Apply screen-size appropriate button spacing
    func adaptiveButtonSpacing() -> some View {
        self.padding(.vertical, ScreenSizeCategory.current.adaptiveSpacing.buttonSpacing / 2)
    }
}

/// Safe area padding that works across all iOS versions and screen sizes
struct ResponsiveSafeAreaPadding: ViewModifier {
    let edges: Edge.Set
    let minimum: CGFloat
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(edges, max(minimum, getSafeAreaInset(for: edges, in: geometry)))
        }
    }
    
    private func getSafeAreaInset(for edges: Edge.Set, in geometry: GeometryProxy) -> CGFloat {
        if edges.contains(.bottom) {
            return geometry.safeAreaInsets.bottom
        } else if edges.contains(.top) {
            return geometry.safeAreaInsets.top
        } else if edges.contains(.leading) {
            return geometry.safeAreaInsets.leading
        } else if edges.contains(.trailing) {
            return geometry.safeAreaInsets.trailing
        }
        return 0
    }
}

extension View {
    /// Apply responsive safe area padding with minimum values
    func responsiveSafeAreaPadding(_ edges: Edge.Set, minimum: CGFloat = 0) -> some View {
        self.modifier(ResponsiveSafeAreaPadding(edges: edges, minimum: minimum))
    }
}
