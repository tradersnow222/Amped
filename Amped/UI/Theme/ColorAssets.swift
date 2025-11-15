import SwiftUI

/// IMPORTANT: Color Naming Convention
/// Throughout the app, we use asset catalog extensions for color references.
/// Always use: Color.ampedGreen (not Color("ampedGreen") or AmpedColors.green)
/// This approach provides type safety, better IDE autocomplete, and consistent styling.
/// The AmpedColors enum is maintained for backward compatibility but should not be used in new code.

// Define direct fallback colors in case asset catalog isn't loading in previews
extension Color {
    // Fallback colors with direct RGB values matching the asset catalog
    static var ampedGreenFallback: Color { Color(red: 0.298, green: 0.851, blue: 0.392) }
    static var ampedYellowFallback: Color { Color(red: 1.0, green: 0.843, blue: 0.0) }
    static var ampedRedFallback: Color { Color(red: 0.910, green: 0.235, blue: 0.235) }
    static var ampedSilverFallback: Color { Color(red: 0.8, green: 0.8, blue: 0.8) }
    static var ampedDarkFallback: Color { Color(red: 0.2, green: 0.2, blue: 0.2) }
    
    // Primary button gradient colors from Figma design
    static var primaryButtonStart: Color { Color(red: 0.988, green: 0.933, blue: 0.129) } // #FCEE21
    static var primaryButtonEnd: Color { Color(red: 0.0, green: 0.573, blue: 0.271) }    // #009245
    
    // Energy level colors
    static var fullPowerFallback: Color { ampedGreenFallback }
    static var highPowerFallback: Color { Color(red: 0.533, green: 0.796, blue: 0.251) }
    static var mediumPowerFallback: Color { ampedYellowFallback }
    static var lowPowerFallback: Color { Color(red: 0.9, green: 0.6, blue: 0.3) }
    static var criticalPowerFallback: Color { ampedRedFallback }
    
    // MARK: - Glass/Card Backgrounds
    static var cardBackground: Color { Color.black.opacity(0.7) }
    
    // Additional glass background variants
    static var secondaryCardBackground: Color { Color.black.opacity(0.4) }
    
    // Lighter variant for nested cards
    static var lightCardBackground: Color { Color.black.opacity(0.3) }
    
    /// Tertiary background for very subtle elements
    static var tertiaryBackground: Color { Color.black.opacity(0.2) }
    
    static var cardBgBackground: Color { Color(hex: "#3D3D3D").opacity(0.45) }
}

/// Custom namespace for theme colors to avoid conflicts with auto-generated asset symbols
enum AmpedColors {
    // Base colors
    static var green: Color { 
        // Try to use asset catalog color first, then fallback
        if #available(iOS 17.0, *) {
            return Color.ampedGreen 
        } else {
            return Color.ampedGreenFallback
        }
    }
    static var yellow: Color { 
        if #available(iOS 17.0, *) {
            return Color.ampedYellow 
        } else {
            return Color.ampedYellowFallback
        }
    }
    static var red: Color { 
        if #available(iOS 17.0, *) {
            return Color.ampedRed 
        } else {
            return Color.ampedRedFallback
        }
    }
    static var silver: Color { 
        if #available(iOS 17.0, *) {
            return Color.ampedSilver 
        } else {
            return Color.ampedSilverFallback
        }
    }
    static var dark: Color { 
        if #available(iOS 17.0, *) {
            return Color.ampedDark 
        } else {
            return Color.ampedDarkFallback
        }
    }
    
    // Energy level colors
    static var fullPower: Color { 
        if #available(iOS 17.0, *) {
            return Color.fullPower 
        } else {
            return Color.fullPowerFallback
        }
    }
    static var highPower: Color { 
        if #available(iOS 17.0, *) {
            return Color.highPower 
        } else {
            return Color.highPowerFallback
        }
    }
    static var mediumPower: Color { 
        if #available(iOS 17.0, *) {
            return Color.mediumPower 
        } else {
            return Color.mediumPowerFallback
        }
    }
    static var lowPower: Color { 
        if #available(iOS 17.0, *) {
            return Color.lowPower 
        } else {
            return Color.lowPowerFallback
        }
    }
    static var criticalPower: Color { 
        if #available(iOS 17.0, *) {
            return Color.criticalPower 
        } else {
            return Color.criticalPowerFallback
        }
    }
    
    // MARK: - Consistent Background System
    // Apply user-specific rule: Simplicity is KING
    
    /// Primary card/row background for consistent theming
    static var cardBackground: Color { Color.cardBackground }
    
    /// Secondary card background for nested content
    static var secondaryCardBackground: Color { Color.secondaryCardBackground }
    
    /// Light card background for subtle elements
    static var lightCardBackground: Color { Color.lightCardBackground }
    
    /// Tertiary background for very subtle elements
    static var tertiaryBackground: Color { Color.tertiaryBackground }
}

/// A struct to create all the required colors in the asset catalog
struct ColorAssets {
    /// Create all color assets in Assets.xcassets
    static func createColorAssets() {
        // This is a utility function meant to help create color assets
        // during development. Not meant to be called during runtime.
        
        // This method is only used for documenting color values
        // and is not actually called in the app.
        // The color assets are created in Assets.xcassets.
    }
}

// How to add color assets to catalog
/*
 1. In Xcode, open Assets.xcassets
 2. Right-click and select "New Color Set"
 3. Name the color set (e.g., "ampedGreen")
 4. Select the color set and use the Attributes inspector to set the colors:
    - For Any Appearance: Set the color value (e.g., #4CD964 for ampedGreen)
    - Check "Any Appearance" and set Dark Appearance color if different
 5. Repeat for all colors
 
 Note: This approach provides type-safe color access and supports dark mode
 */ 

extension Color {
    
}
