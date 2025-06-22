import SwiftUI
import Foundation

/// Manager for Apple Liquid Glass themed app interface
/// Implements comprehensive glass effects throughout the app
@MainActor
final class GlassThemeManager: ObservableObject {
    // MARK: - Glass Material Types
    
    enum GlassMaterial {
        case ultraThin      // Most transparent - for overlays
        case thin           // Light glass effect - for secondary content
        case regular        // Standard glass effect - for primary content
        case thick          // Heavy glass effect - for prominent elements
        case prominent      // Most opaque - for hero elements
        
        var material: Material {
            switch self {
            case .ultraThin: return .ultraThinMaterial
            case .thin: return .thinMaterial
            case .regular: return .regularMaterial
            case .thick: return .thickMaterial
            case .prominent: return .ultraThickMaterial
            }
        }
    }
    
    // MARK: - Glass Color Palette
    
    /// Primary glass accent color - vibrant green
    public let primaryGlass: Color = Color.ampedGreen
    
    /// Secondary glass accent color - soft silver
    public let secondaryGlass: Color = Color.ampedSilver
    
    /// Glass tint colors for different states
    public let glassTints = GlassTints()
    
    /// Glass background colors
    public let glassBackgrounds = GlassBackgrounds()
    
    // MARK: - Glass Visual Effects
    
    /// Standard glass corner radius
    public let glassCornerRadius: CGFloat = 16
    
    /// Large glass corner radius for prominent elements
    public let largeGlassCornerRadius: CGFloat = 24
    
    /// Small glass corner radius for compact elements
    public let smallGlassCornerRadius: CGFloat = 12
    
    /// Glass shadow configuration
    public let glassShadow = GlassShadow()
    
    /// Glass border configuration
    public let glassBorder = GlassBorder()
    
    // MARK: - Text Colors for Glass Backgrounds
    
    /// Primary text color on glass
    public let primaryTextOnGlass: Color = .white
    
    /// Secondary text color on glass
    public let secondaryTextOnGlass: Color = .white.opacity(0.8)
    
    /// Tertiary text color on glass
    public let tertiaryTextOnGlass: Color = .white.opacity(0.6)
    
    /// Accent text color on glass
    public let accentTextOnGlass: Color = Color.ampedGreen
    
    // MARK: - Initialization
    
    nonisolated init() {
        // Glass theme is static but extensible
    }
    
    // MARK: - Glass Theme Application Methods
    
    /// Apply glass background with specified material
    func glassBackground(_ material: GlassMaterial = .regular) -> some View {
        RoundedRectangle(cornerRadius: glassCornerRadius)
            .fill(material.material)
            .overlay(
                RoundedRectangle(cornerRadius: glassCornerRadius)
                    .stroke(glassBorder.standardBorder, lineWidth: glassBorder.standardWidth)
            )
            .shadow(
                color: glassShadow.standardColor,
                radius: glassShadow.standardRadius,
                x: glassShadow.standardX,
                y: glassShadow.standardY
            )
    }
    
    /// Apply glass card style with custom corner radius
    func glassCard(
        material: GlassMaterial = .regular,
        cornerRadius: CGFloat? = nil,
        withBorder: Bool = true,
        withShadow: Bool = true
    ) -> some View {
        let radius = cornerRadius ?? glassCornerRadius
        
        return RoundedRectangle(cornerRadius: radius)
            .fill(material.material)
            .overlay(
                withBorder ? 
                RoundedRectangle(cornerRadius: radius)
                    .stroke(glassBorder.cardBorder, lineWidth: glassBorder.cardWidth) : nil
            )
            .shadow(
                color: withShadow ? glassShadow.cardColor : .clear,
                radius: withShadow ? glassShadow.cardRadius : 0,
                x: withShadow ? glassShadow.cardX : 0,
                y: withShadow ? glassShadow.cardY : 0
            )
    }
    
    /// Apply prominent glass effect for hero elements
    func prominentGlass(cornerRadius: CGFloat? = nil) -> some View {
        let radius = cornerRadius ?? largeGlassCornerRadius
        
        return RoundedRectangle(cornerRadius: radius)
            .fill(.ultraThickMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(glassBorder.prominentBorder, lineWidth: glassBorder.prominentWidth)
            )
            .shadow(color: glassShadow.prominentColor, radius: glassShadow.prominentRadius, x: 0, y: glassShadow.prominentY)
            .shadow(color: primaryGlass.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    /// Get appropriate text color for glass material
    func textColor(for material: GlassMaterial) -> Color {
        switch material {
        case .ultraThin, .thin:
            return primaryTextOnGlass
        case .regular:
            return primaryTextOnGlass
        case .thick, .prominent:
            return primaryTextOnGlass.opacity(0.95)
        }
    }
}

// MARK: - Glass Theme Supporting Structures

/// Glass tint colors for different UI states
struct GlassTints {
    let success: Color = Color.ampedGreen.opacity(0.3)
    let warning: Color = Color.ampedYellow.opacity(0.3)
    let error: Color = Color.ampedRed.opacity(0.3)
    let info: Color = Color.ampedSilver.opacity(0.3)
    let accent: Color = Color.ampedGreen.opacity(0.2)
}

/// Glass background configurations
struct GlassBackgrounds {
    // For components that need colored glass backgrounds
    let successGlass: Color = Color.ampedGreen.opacity(0.15)
    let warningGlass: Color = Color.ampedYellow.opacity(0.15)
    let errorGlass: Color = Color.ampedRed.opacity(0.15)
    let accentGlass: Color = Color.ampedGreen.opacity(0.1)
}

/// Glass shadow configurations
struct GlassShadow {
    // Standard glass shadows
    let standardColor: Color = .black.opacity(0.1)
    let standardRadius: CGFloat = 8
    let standardX: CGFloat = 0
    let standardY: CGFloat = 4
    
    // Card glass shadows
    let cardColor: Color = .black.opacity(0.15)
    let cardRadius: CGFloat = 12
    let cardX: CGFloat = 0
    let cardY: CGFloat = 6
    
    // Prominent glass shadows
    let prominentColor: Color = .black.opacity(0.2)
    let prominentRadius: CGFloat = 16
    let prominentY: CGFloat = 8
}

/// Glass border configurations
struct GlassBorder {
    // Standard glass borders
    let standardBorder: LinearGradient = LinearGradient(
        colors: [.white.opacity(0.3), .white.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    let standardWidth: CGFloat = 1
    
    // Card glass borders
    let cardBorder: LinearGradient = LinearGradient(
        colors: [.white.opacity(0.4), .white.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    let cardWidth: CGFloat = 1.5
    
    // Prominent glass borders
    let prominentBorder: LinearGradient = LinearGradient(
        colors: [Color.ampedGreen.opacity(0.6), Color.ampedYellow.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    let prominentWidth: CGFloat = 2
}

// MARK: - Environment Integration

/// Environment key for glass theme manager
struct GlassThemeManagerKey: EnvironmentKey {
    static let defaultValue = GlassThemeManager()
}

extension EnvironmentValues {
    var glassTheme: GlassThemeManager {
        get { self[GlassThemeManagerKey.self] }
        set { self[GlassThemeManagerKey.self] = newValue }
    }
}

// MARK: - Glass View Modifiers

/// View modifier for applying glass background
struct GlassBackgroundModifier: ViewModifier {
    let material: GlassThemeManager.GlassMaterial
    let cornerRadius: CGFloat
    let withBorder: Bool
    let withShadow: Bool
    
    @Environment(\.glassTheme) private var glassTheme
    
    func body(content: Content) -> some View {
        content
            .background(
                glassTheme.glassCard(
                    material: material,
                    cornerRadius: cornerRadius,
                    withBorder: withBorder,
                    withShadow: withShadow
                )
            )
    }
}

/// View modifier for prominent glass effect
struct ProminentGlassModifier: ViewModifier {
    let cornerRadius: CGFloat?
    
    @Environment(\.glassTheme) private var glassTheme
    
    func body(content: Content) -> some View {
        content
            .background(glassTheme.prominentGlass(cornerRadius: cornerRadius))
    }
}

/// View modifier for glass overlay effects
struct GlassOverlayModifier: ViewModifier {
    let tintColor: Color
    let intensity: Double
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(tintColor.opacity(intensity))
                    .allowsHitTesting(false)
            )
    }
}

// MARK: - View Extensions

extension View {
    /// Apply glass background with specified material
    func glassBackground(
        _ material: GlassThemeManager.GlassMaterial = .regular,
        cornerRadius: CGFloat = 16,
        withBorder: Bool = true,
        withShadow: Bool = true
    ) -> some View {
        self.modifier(GlassBackgroundModifier(
            material: material,
            cornerRadius: cornerRadius,
            withBorder: withBorder,
            withShadow: withShadow
        ))
    }
    
    /// Apply prominent glass effect for hero elements
    func prominentGlass(cornerRadius: CGFloat? = nil) -> some View {
        self.modifier(ProminentGlassModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply glass tint overlay
    func glassTint(_ color: Color, intensity: Double = 0.2) -> some View {
        self.modifier(GlassOverlayModifier(tintColor: color, intensity: intensity))
    }
    
    /// Apply glass card styling
    func glassCard(
        material: GlassThemeManager.GlassMaterial = .regular,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self
            .padding()
            .glassBackground(material, cornerRadius: cornerRadius)
    }
    
    /// Apply complete glass theme to entire view
    func withGlassTheme() -> some View {
        self
            .foregroundColor(.white)
            .environment(\.glassTheme, GlassThemeManager())
    }
} 