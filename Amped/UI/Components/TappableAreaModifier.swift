import SwiftUI

/// Ensures a minimum tappable area per Apple HIG and Fitts's Law
/// - Rule reference: Always-applied workspace rules and user_rules (Simplicity is KING; 44pt min tap targets)
public struct MinTappableArea: ViewModifier {
    private let minSide: CGFloat

    /// Create a modifier that guarantees at least `minSide` square tap area (default 44pt)
    /// - Parameter minSide: Minimum width and height for the hit target
    public init(minSide: CGFloat = 44) {
        self.minSide = minSide
    }

    public func body(content: Content) -> some View {
        content
            .frame(minWidth: minSide, minHeight: minSide)
            .contentShape(Rectangle())
    }
}

public extension View {
    /// Apply a 44pt minimum tap target without changing visual emphasis
    func minTappableArea(_ side: CGFloat = 44) -> some View {
        modifier(MinTappableArea(minSide: side))
    }
}


