import SwiftUI

/// Cross‑version helper to keep bottom content clear of the home indicator
/// Applied rule(s): Simplicity is KING; Correctness over speed; Follow Apple HIG for safe areas
private struct BottomInsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct BottomSafeAreaPadding: ViewModifier {
    /// Minimum visual padding to keep, even on devices without a bottom inset
    let minimum: CGFloat
    @State private var bottomInset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .background(
                // Read the container's safe area insets using GeometryReader (iOS 15+)
                GeometryReader { proxy in
                    Color.clear
                        .preference(key: BottomInsetPreferenceKey.self, value: proxy.safeAreaInsets.bottom)
                }
            )
            .onPreferenceChange(BottomInsetPreferenceKey.self) { inset in
                bottomInset = inset
            }
            .padding(.bottom, max(minimum, bottomInset))
    }
}

extension View {
    /// Adds bottom padding equal to the device's bottom safe‑area inset (or `minimum`, whichever is greater).
    /// Use when you need content, especially CTAs, to sit above the home indicator on iOS 16+ without
    /// depending on iOS 17's `safeAreaPadding` API.
    func bottomSafeAreaPadding(minimum: CGFloat = 0) -> some View {
        modifier(BottomSafeAreaPadding(minimum: minimum))
    }
}


