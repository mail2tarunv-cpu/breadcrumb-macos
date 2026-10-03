import AppKit
import SwiftUI

enum BreadcrumbMarkerStyle: String, CaseIterable, Identifiable {
    case microTab
    case label

    var id: String { rawValue }

    var title: String {
        switch self {
        case .microTab: return "Micro-tab"
        case .label: return "Text tab"
        }
    }
}

enum BreadcrumbMarkerSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var dimensions: CGSize {
        switch self {
        case .small: return CGSize(width: 72, height: 24)
        case .medium: return CGSize(width: 88, height: 26)
        case .large: return CGSize(width: 108, height: 30)
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small: return 10.5
        case .medium: return 11.25
        case .large: return 12.25
        }
    }

    var expandedWidth: CGFloat {
        dimensions.width + 112
    }
}

enum BreadcrumbAppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var appKitAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }
}

enum BreadcrumbShadowStrength: String, CaseIterable, Identifiable {
    case subtle
    case standard
    case strong

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var opacity: Double {
        switch self {
        case .subtle: return 0.07
        case .standard: return 0.11
        case .strong: return 0.17
        }
    }

    var radius: CGFloat {
        switch self {
        case .subtle: return 3
        case .standard: return 5
        case .strong: return 8
        }
    }
}

enum BreadcrumbPreferences {
    static let defaultAccentColorKey = "breadcrumb.appearance.defaultAccentColor"
    static let markerStyleKey = "breadcrumb.appearance.markerStyle"
    static let markerSizeKey = "breadcrumb.appearance.markerSize"
    static let appearanceModeKey = "breadcrumb.appearance.mode"
    static let reducedMotionKey = "breadcrumb.appearance.reducedMotion"
    static let shadowStrengthKey = "breadcrumb.appearance.shadowStrength"

    static let appearanceDidChange = Notification.Name("breadcrumb.appearance.changed")

    static let defaultAccentColor = BreadcrumbColor.blue.rawValue

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            defaultAccentColorKey: defaultAccentColor,
            markerStyleKey: BreadcrumbMarkerStyle.microTab.rawValue,
            markerSizeKey: BreadcrumbMarkerSize.medium.rawValue,
            appearanceModeKey: BreadcrumbAppearanceMode.system.rawValue,
            reducedMotionKey: false,
            shadowStrengthKey: BreadcrumbShadowStrength.standard.rawValue
        ])
    }

    static var markerStyle: BreadcrumbMarkerStyle {
        BreadcrumbMarkerStyle(rawValue: UserDefaults.standard.string(forKey: markerStyleKey) ?? "") ?? .microTab
    }

    static var markerSize: BreadcrumbMarkerSize {
        BreadcrumbMarkerSize(rawValue: UserDefaults.standard.string(forKey: markerSizeKey) ?? "") ?? .medium
    }

    static var shadowStrength: BreadcrumbShadowStrength {
        BreadcrumbShadowStrength(rawValue: UserDefaults.standard.string(forKey: shadowStrengthKey) ?? "") ?? .standard
    }

    static var reducedMotion: Bool {
        UserDefaults.standard.bool(forKey: reducedMotionKey)
    }

    static var defaultBreadcrumbColor: BreadcrumbColor {
        BreadcrumbColor.migrated(
            from: UserDefaults.standard.string(forKey: defaultAccentColorKey)
        )
    }

    static func applyAppearance() {
        let raw = UserDefaults.standard.string(forKey: appearanceModeKey) ?? BreadcrumbAppearanceMode.system.rawValue
        let mode = BreadcrumbAppearanceMode(rawValue: raw) ?? .system
        NSApp.appearance = mode.appKitAppearance
    }

    static func notifyAppearanceChanged() {
        applyAppearance()
        NotificationCenter.default.post(name: appearanceDidChange, object: nil)
    }
}
