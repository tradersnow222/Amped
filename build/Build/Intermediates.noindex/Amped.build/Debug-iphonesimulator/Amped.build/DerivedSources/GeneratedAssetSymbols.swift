import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

    /// The "afternoon" asset catalog color resource.
    static let afternoon = ColorResource(name: "afternoon", bundle: resourceBundle)

    /// The "ampedAfternoon" asset catalog color resource.
    static let ampedAfternoon = ColorResource(name: "ampedAfternoon", bundle: resourceBundle)

    /// The "ampedAfternoonSecondary" asset catalog color resource.
    static let ampedAfternoonSecondary = ColorResource(name: "ampedAfternoonSecondary", bundle: resourceBundle)

    /// The "ampedDark" asset catalog color resource.
    static let ampedDark = ColorResource(name: "ampedDark", bundle: resourceBundle)

    /// The "ampedEvening" asset catalog color resource.
    static let ampedEvening = ColorResource(name: "ampedEvening", bundle: resourceBundle)

    /// The "ampedEveningSecondary" asset catalog color resource.
    static let ampedEveningSecondary = ColorResource(name: "ampedEveningSecondary", bundle: resourceBundle)

    /// The "ampedGreen" asset catalog color resource.
    static let ampedGreen = ColorResource(name: "ampedGreen", bundle: resourceBundle)

    /// The "ampedMidday" asset catalog color resource.
    static let ampedMidday = ColorResource(name: "ampedMidday", bundle: resourceBundle)

    /// The "ampedMiddaySecondary" asset catalog color resource.
    static let ampedMiddaySecondary = ColorResource(name: "ampedMiddaySecondary", bundle: resourceBundle)

    /// The "ampedMorning" asset catalog color resource.
    static let ampedMorning = ColorResource(name: "ampedMorning", bundle: resourceBundle)

    /// The "ampedMorningSecondary" asset catalog color resource.
    static let ampedMorningSecondary = ColorResource(name: "ampedMorningSecondary", bundle: resourceBundle)

    /// The "ampedNight" asset catalog color resource.
    static let ampedNight = ColorResource(name: "ampedNight", bundle: resourceBundle)

    /// The "ampedNightSecondary" asset catalog color resource.
    static let ampedNightSecondary = ColorResource(name: "ampedNightSecondary", bundle: resourceBundle)

    /// The "ampedRed" asset catalog color resource.
    static let ampedRed = ColorResource(name: "ampedRed", bundle: resourceBundle)

    /// The "ampedSilver" asset catalog color resource.
    static let ampedSilver = ColorResource(name: "ampedSilver", bundle: resourceBundle)

    /// The "ampedYellow" asset catalog color resource.
    static let ampedYellow = ColorResource(name: "ampedYellow", bundle: resourceBundle)

    /// The "criticalPower" asset catalog color resource.
    static let criticalPower = ColorResource(name: "criticalPower", bundle: resourceBundle)

    /// The "evening" asset catalog color resource.
    static let evening = ColorResource(name: "evening", bundle: resourceBundle)

    /// The "fullPower" asset catalog color resource.
    static let fullPower = ColorResource(name: "fullPower", bundle: resourceBundle)

    /// The "highPower" asset catalog color resource.
    static let highPower = ColorResource(name: "highPower", bundle: resourceBundle)

    /// The "lowPower" asset catalog color resource.
    static let lowPower = ColorResource(name: "lowPower", bundle: resourceBundle)

    /// The "mediumPower" asset catalog color resource.
    static let mediumPower = ColorResource(name: "mediumPower", bundle: resourceBundle)

    /// The "midday" asset catalog color resource.
    static let midday = ColorResource(name: "midday", bundle: resourceBundle)

    /// The "morning" asset catalog color resource.
    static let morning = ColorResource(name: "morning", bundle: resourceBundle)

    /// The "night" asset catalog color resource.
    static let night = ColorResource(name: "night", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "BatteryBackground" asset catalog image resource.
    static let batteryBackground = ImageResource(name: "BatteryBackground", bundle: resourceBundle)

    /// The "DeepBackground" asset catalog image resource.
    static let deepBackground = ImageResource(name: "DeepBackground", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "afternoon" asset catalog color.
    static var afternoon: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .afternoon)
#else
        .init()
#endif
    }

    /// The "ampedAfternoon" asset catalog color.
    static var ampedAfternoon: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedAfternoon)
#else
        .init()
#endif
    }

    /// The "ampedAfternoonSecondary" asset catalog color.
    static var ampedAfternoonSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedAfternoonSecondary)
#else
        .init()
#endif
    }

    /// The "ampedDark" asset catalog color.
    static var ampedDark: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedDark)
#else
        .init()
#endif
    }

    /// The "ampedEvening" asset catalog color.
    static var ampedEvening: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedEvening)
#else
        .init()
#endif
    }

    /// The "ampedEveningSecondary" asset catalog color.
    static var ampedEveningSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedEveningSecondary)
#else
        .init()
#endif
    }

    /// The "ampedGreen" asset catalog color.
    static var ampedGreen: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedGreen)
#else
        .init()
#endif
    }

    /// The "ampedMidday" asset catalog color.
    static var ampedMidday: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedMidday)
#else
        .init()
#endif
    }

    /// The "ampedMiddaySecondary" asset catalog color.
    static var ampedMiddaySecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedMiddaySecondary)
#else
        .init()
#endif
    }

    /// The "ampedMorning" asset catalog color.
    static var ampedMorning: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedMorning)
#else
        .init()
#endif
    }

    /// The "ampedMorningSecondary" asset catalog color.
    static var ampedMorningSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedMorningSecondary)
#else
        .init()
#endif
    }

    /// The "ampedNight" asset catalog color.
    static var ampedNight: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedNight)
#else
        .init()
#endif
    }

    /// The "ampedNightSecondary" asset catalog color.
    static var ampedNightSecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedNightSecondary)
#else
        .init()
#endif
    }

    /// The "ampedRed" asset catalog color.
    static var ampedRed: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedRed)
#else
        .init()
#endif
    }

    /// The "ampedSilver" asset catalog color.
    static var ampedSilver: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedSilver)
#else
        .init()
#endif
    }

    /// The "ampedYellow" asset catalog color.
    static var ampedYellow: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ampedYellow)
#else
        .init()
#endif
    }

    /// The "criticalPower" asset catalog color.
    static var criticalPower: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .criticalPower)
#else
        .init()
#endif
    }

    /// The "evening" asset catalog color.
    static var evening: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .evening)
#else
        .init()
#endif
    }

    /// The "fullPower" asset catalog color.
    static var fullPower: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .fullPower)
#else
        .init()
#endif
    }

    /// The "highPower" asset catalog color.
    static var highPower: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .highPower)
#else
        .init()
#endif
    }

    /// The "lowPower" asset catalog color.
    static var lowPower: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .lowPower)
#else
        .init()
#endif
    }

    /// The "mediumPower" asset catalog color.
    static var mediumPower: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .mediumPower)
#else
        .init()
#endif
    }

    /// The "midday" asset catalog color.
    static var midday: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .midday)
#else
        .init()
#endif
    }

    /// The "morning" asset catalog color.
    static var morning: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .morning)
#else
        .init()
#endif
    }

    /// The "night" asset catalog color.
    static var night: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .night)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "afternoon" asset catalog color.
    static var afternoon: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .afternoon)
#else
        .init()
#endif
    }

    /// The "ampedAfternoon" asset catalog color.
    static var ampedAfternoon: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedAfternoon)
#else
        .init()
#endif
    }

    /// The "ampedAfternoonSecondary" asset catalog color.
    static var ampedAfternoonSecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedAfternoonSecondary)
#else
        .init()
#endif
    }

    /// The "ampedDark" asset catalog color.
    static var ampedDark: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedDark)
#else
        .init()
#endif
    }

    /// The "ampedEvening" asset catalog color.
    static var ampedEvening: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedEvening)
#else
        .init()
#endif
    }

    /// The "ampedEveningSecondary" asset catalog color.
    static var ampedEveningSecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedEveningSecondary)
#else
        .init()
#endif
    }

    /// The "ampedGreen" asset catalog color.
    static var ampedGreen: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedGreen)
#else
        .init()
#endif
    }

    /// The "ampedMidday" asset catalog color.
    static var ampedMidday: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedMidday)
#else
        .init()
#endif
    }

    /// The "ampedMiddaySecondary" asset catalog color.
    static var ampedMiddaySecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedMiddaySecondary)
#else
        .init()
#endif
    }

    /// The "ampedMorning" asset catalog color.
    static var ampedMorning: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedMorning)
#else
        .init()
#endif
    }

    /// The "ampedMorningSecondary" asset catalog color.
    static var ampedMorningSecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedMorningSecondary)
#else
        .init()
#endif
    }

    /// The "ampedNight" asset catalog color.
    static var ampedNight: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedNight)
#else
        .init()
#endif
    }

    /// The "ampedNightSecondary" asset catalog color.
    static var ampedNightSecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedNightSecondary)
#else
        .init()
#endif
    }

    /// The "ampedRed" asset catalog color.
    static var ampedRed: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedRed)
#else
        .init()
#endif
    }

    /// The "ampedSilver" asset catalog color.
    static var ampedSilver: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedSilver)
#else
        .init()
#endif
    }

    /// The "ampedYellow" asset catalog color.
    static var ampedYellow: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ampedYellow)
#else
        .init()
#endif
    }

    /// The "criticalPower" asset catalog color.
    static var criticalPower: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .criticalPower)
#else
        .init()
#endif
    }

    /// The "evening" asset catalog color.
    static var evening: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .evening)
#else
        .init()
#endif
    }

    /// The "fullPower" asset catalog color.
    static var fullPower: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .fullPower)
#else
        .init()
#endif
    }

    /// The "highPower" asset catalog color.
    static var highPower: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .highPower)
#else
        .init()
#endif
    }

    /// The "lowPower" asset catalog color.
    static var lowPower: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .lowPower)
#else
        .init()
#endif
    }

    /// The "mediumPower" asset catalog color.
    static var mediumPower: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .mediumPower)
#else
        .init()
#endif
    }

    /// The "midday" asset catalog color.
    static var midday: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .midday)
#else
        .init()
#endif
    }

    /// The "morning" asset catalog color.
    static var morning: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .morning)
#else
        .init()
#endif
    }

    /// The "night" asset catalog color.
    static var night: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .night)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// The "afternoon" asset catalog color.
    static var afternoon: SwiftUI.Color { .init(.afternoon) }

    /// The "ampedAfternoon" asset catalog color.
    static var ampedAfternoon: SwiftUI.Color { .init(.ampedAfternoon) }

    /// The "ampedAfternoonSecondary" asset catalog color.
    static var ampedAfternoonSecondary: SwiftUI.Color { .init(.ampedAfternoonSecondary) }

    /// The "ampedDark" asset catalog color.
    static var ampedDark: SwiftUI.Color { .init(.ampedDark) }

    /// The "ampedEvening" asset catalog color.
    static var ampedEvening: SwiftUI.Color { .init(.ampedEvening) }

    /// The "ampedEveningSecondary" asset catalog color.
    static var ampedEveningSecondary: SwiftUI.Color { .init(.ampedEveningSecondary) }

    /// The "ampedGreen" asset catalog color.
    static var ampedGreen: SwiftUI.Color { .init(.ampedGreen) }

    /// The "ampedMidday" asset catalog color.
    static var ampedMidday: SwiftUI.Color { .init(.ampedMidday) }

    /// The "ampedMiddaySecondary" asset catalog color.
    static var ampedMiddaySecondary: SwiftUI.Color { .init(.ampedMiddaySecondary) }

    /// The "ampedMorning" asset catalog color.
    static var ampedMorning: SwiftUI.Color { .init(.ampedMorning) }

    /// The "ampedMorningSecondary" asset catalog color.
    static var ampedMorningSecondary: SwiftUI.Color { .init(.ampedMorningSecondary) }

    /// The "ampedNight" asset catalog color.
    static var ampedNight: SwiftUI.Color { .init(.ampedNight) }

    /// The "ampedNightSecondary" asset catalog color.
    static var ampedNightSecondary: SwiftUI.Color { .init(.ampedNightSecondary) }

    /// The "ampedRed" asset catalog color.
    static var ampedRed: SwiftUI.Color { .init(.ampedRed) }

    /// The "ampedSilver" asset catalog color.
    static var ampedSilver: SwiftUI.Color { .init(.ampedSilver) }

    /// The "ampedYellow" asset catalog color.
    static var ampedYellow: SwiftUI.Color { .init(.ampedYellow) }

    /// The "criticalPower" asset catalog color.
    static var criticalPower: SwiftUI.Color { .init(.criticalPower) }

    /// The "evening" asset catalog color.
    static var evening: SwiftUI.Color { .init(.evening) }

    /// The "fullPower" asset catalog color.
    static var fullPower: SwiftUI.Color { .init(.fullPower) }

    /// The "highPower" asset catalog color.
    static var highPower: SwiftUI.Color { .init(.highPower) }

    /// The "lowPower" asset catalog color.
    static var lowPower: SwiftUI.Color { .init(.lowPower) }

    /// The "mediumPower" asset catalog color.
    static var mediumPower: SwiftUI.Color { .init(.mediumPower) }

    /// The "midday" asset catalog color.
    static var midday: SwiftUI.Color { .init(.midday) }

    /// The "morning" asset catalog color.
    static var morning: SwiftUI.Color { .init(.morning) }

    /// The "night" asset catalog color.
    static var night: SwiftUI.Color { .init(.night) }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "afternoon" asset catalog color.
    static var afternoon: SwiftUI.Color { .init(.afternoon) }

    /// The "ampedAfternoon" asset catalog color.
    static var ampedAfternoon: SwiftUI.Color { .init(.ampedAfternoon) }

    /// The "ampedAfternoonSecondary" asset catalog color.
    static var ampedAfternoonSecondary: SwiftUI.Color { .init(.ampedAfternoonSecondary) }

    /// The "ampedDark" asset catalog color.
    static var ampedDark: SwiftUI.Color { .init(.ampedDark) }

    /// The "ampedEvening" asset catalog color.
    static var ampedEvening: SwiftUI.Color { .init(.ampedEvening) }

    /// The "ampedEveningSecondary" asset catalog color.
    static var ampedEveningSecondary: SwiftUI.Color { .init(.ampedEveningSecondary) }

    /// The "ampedGreen" asset catalog color.
    static var ampedGreen: SwiftUI.Color { .init(.ampedGreen) }

    /// The "ampedMidday" asset catalog color.
    static var ampedMidday: SwiftUI.Color { .init(.ampedMidday) }

    /// The "ampedMiddaySecondary" asset catalog color.
    static var ampedMiddaySecondary: SwiftUI.Color { .init(.ampedMiddaySecondary) }

    /// The "ampedMorning" asset catalog color.
    static var ampedMorning: SwiftUI.Color { .init(.ampedMorning) }

    /// The "ampedMorningSecondary" asset catalog color.
    static var ampedMorningSecondary: SwiftUI.Color { .init(.ampedMorningSecondary) }

    /// The "ampedNight" asset catalog color.
    static var ampedNight: SwiftUI.Color { .init(.ampedNight) }

    /// The "ampedNightSecondary" asset catalog color.
    static var ampedNightSecondary: SwiftUI.Color { .init(.ampedNightSecondary) }

    /// The "ampedRed" asset catalog color.
    static var ampedRed: SwiftUI.Color { .init(.ampedRed) }

    /// The "ampedSilver" asset catalog color.
    static var ampedSilver: SwiftUI.Color { .init(.ampedSilver) }

    /// The "ampedYellow" asset catalog color.
    static var ampedYellow: SwiftUI.Color { .init(.ampedYellow) }

    /// The "criticalPower" asset catalog color.
    static var criticalPower: SwiftUI.Color { .init(.criticalPower) }

    /// The "evening" asset catalog color.
    static var evening: SwiftUI.Color { .init(.evening) }

    /// The "fullPower" asset catalog color.
    static var fullPower: SwiftUI.Color { .init(.fullPower) }

    /// The "highPower" asset catalog color.
    static var highPower: SwiftUI.Color { .init(.highPower) }

    /// The "lowPower" asset catalog color.
    static var lowPower: SwiftUI.Color { .init(.lowPower) }

    /// The "mediumPower" asset catalog color.
    static var mediumPower: SwiftUI.Color { .init(.mediumPower) }

    /// The "midday" asset catalog color.
    static var midday: SwiftUI.Color { .init(.midday) }

    /// The "morning" asset catalog color.
    static var morning: SwiftUI.Color { .init(.morning) }

    /// The "night" asset catalog color.
    static var night: SwiftUI.Color { .init(.night) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "BatteryBackground" asset catalog image.
    static var batteryBackground: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .batteryBackground)
#else
        .init()
#endif
    }

    /// The "DeepBackground" asset catalog image.
    static var deepBackground: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .deepBackground)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "BatteryBackground" asset catalog image.
    static var batteryBackground: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .batteryBackground)
#else
        .init()
#endif
    }

    /// The "DeepBackground" asset catalog image.
    static var deepBackground: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .deepBackground)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
@available(watchOS, unavailable)
extension ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif