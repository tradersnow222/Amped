import SwiftUI

/// Extension to enhance SwiftUI views with improved accessibility
extension View {
    /// Add comprehensive accessibility attributes to a view
    /// - Parameters:
    ///   - label: Accessibility label
    ///   - hint: Optional accessibility hint
    ///   - traits: Optional accessibility traits
    ///   - isElement: Whether this is an accessibility element
    ///   - sortPriority: Optional sort priority
    /// - Returns: View with accessibility attributes
    func accessibilitySupport(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = [],
        isElement: Bool = true,
        sortPriority: Double? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityAddTraits(traits)
            .accessibilityHint(hint ?? "")
            .accessibilitySortPriority(sortPriority ?? 0)
    }
    
    /// Add accessibility for a metric value
    /// - Parameters:
    ///   - metric: The health metric
    ///   - includeImpact: Whether to include impact information
    /// - Returns: View with metric accessibility
    func accessibilityMetric(_ metric: HealthMetric, includeImpact: Bool = true) -> some View {
        let label = "\(metric.type.displayName): \(metric.formattedValue)"
        
        var hint = ""
        if includeImpact, let impact = metric.impactDetails {
            let impactValue = impact.lifespanImpactMinutes
            let comparisonDescription = impactValue > 0 ? "better than the baseline" : (impactValue < 0 ? "worse than the baseline" : "at the baseline")
            hint = "This value is \(comparisonDescription) and has a "
            
            if impact.lifespanImpactMinutes > 0 {
                hint += "positive impact of \(impact.formattedImpact(for: .day)) on your lifespan."
            } else if impact.lifespanImpactMinutes < 0 {
                hint += "negative impact of \(impact.formattedImpact(for: .day)) on your lifespan."
            } else {
                hint += "neutral impact on your lifespan."
            }
        }
        
        return self.accessibilitySupport(
            label: label,
            hint: hint,
            traits: [.updatesFrequently, .startsMediaSession]
        )
    }
    
    /// Add accessibility for a battery component
    /// - Parameters:
    ///   - title: The battery title
    ///   - chargeLevel: The current charge level
    ///   - description: Additional description
    /// - Returns: View with battery accessibility
    func accessibilityBattery(title: String, chargeLevel: Double, description: String) -> some View {
        let percentageString = String(format: "%.0f%%", chargeLevel * 100)
        let label = "\(title): \(percentageString) charged"
        
        return self.accessibilitySupport(
            label: label,
            hint: description,
            traits: [.updatesFrequently]
        )
    }
    
    /// Add accessibility for button actions with specific roles
    /// - Parameters:
    ///   - label: The button label
    ///   - hint: Optional action hint
    ///   - isEnabled: Whether the action is enabled
    /// - Returns: View with action accessibility
    func accessibilityAction(label: String, hint: String? = nil, isEnabled: Bool = true) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityRemoveTraits(isEnabled ? [] : .isStaticText)
    }
    
    /// Add dynamic type support with custom scaling
    /// - Parameters:
    ///   - minScale: Minimum scale factor
    ///   - maxScale: Maximum scale factor
    /// - Returns: View with dynamic type scaling
    func dynamicTypeSize(minScale: CGFloat = 0.8, maxScale: CGFloat = 1.5) -> some View {
        self.modifier(DynamicTypeModifier(minScale: minScale, maxScale: maxScale))
    }
    
    /// Add a semantic title to improve screen reader navigation
    /// - Parameter title: The title to announce
    /// - Returns: View with semantic title
    func semanticTitle(_ title: String) -> some View {
        self.modifier(SemanticTitleModifier(title: title))
    }
    
    /// Make the font readable with proper contrast for accessibility
    /// - Parameters:
    ///   - style: Text style
    ///   - weight: Optional font weight
    /// - Returns: View with accessible font
    func accessibleFont(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> some View {
        self.modifier(AccessibleFontModifier(style: style, weight: weight))
    }
}

// MARK: - Modifiers

/// Modifier to support dynamic type scaling
struct DynamicTypeModifier: ViewModifier {
    let minScale: CGFloat
    let maxScale: CGFloat
    
    @Environment(\.sizeCategory) private var sizeCategory
    
    func body(content: Content) -> some View {
        let scaleFactor = calculateScaleFactor()
        
        return content
            .scaleEffect(scaleFactor)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func calculateScaleFactor() -> CGFloat {
        // Calculate scale factor based on size category
        let baseSizes: [ContentSizeCategory: CGFloat] = [
            .extraSmall: 0.8,
            .small: 0.9,
            .medium: 1.0,
            .large: 1.1,
            .extraLarge: 1.2,
            .extraExtraLarge: 1.3,
            .extraExtraExtraLarge: 1.4,
            .accessibilityMedium: 1.5,
            .accessibilityLarge: 1.6,
            .accessibilityExtraLarge: 1.7,
            .accessibilityExtraExtraLarge: 1.8,
            .accessibilityExtraExtraExtraLarge: 1.9
        ]
        
        let scale = baseSizes[sizeCategory] ?? 1.0
        return min(max(scale, minScale), maxScale)
    }
}

/// Modifier to add semantic title for screen readers
struct SemanticTitleModifier: ViewModifier {
    let title: String
    
    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Modifier for accessible font sizing
struct AccessibleFontModifier: ViewModifier {
    let style: Font.TextStyle
    let weight: Font.Weight?
    
    func body(content: Content) -> some View {
        if let weight = weight {
            return content
                .font(.system(style, design: .rounded).weight(weight))
                .eraseToAnyView()
        } else {
            return content
                .font(.system(style, design: .rounded))
                .eraseToAnyView()
        }
    }
}

// MARK: - Helper Extensions

extension View {
    /// Erase to AnyView type
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
} 