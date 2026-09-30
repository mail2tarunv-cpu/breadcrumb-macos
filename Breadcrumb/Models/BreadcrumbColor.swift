import Foundation
import AppKit
import SwiftUI

enum BreadcrumbColor: String, Codable, CaseIterable, Identifiable {
    case butter
    case peach
    case blush
    case lavender
    case sky
    case mint
    case sage

    var id: String { rawValue }

    var name: String {
        switch self {
        case .butter: return "Butter"
        case .peach: return "Peach"
        case .blush: return "Blush"
        case .lavender: return "Lavender"
        case .sky: return "Sky"
        case .mint: return "Mint"
        case .sage: return "Sage"
        }
    }

    var color: Color {
        switch self {
        case .butter:
            return Color(red: 0.96, green: 0.90, blue: 0.72)
        case .peach:
            return Color(red: 0.96, green: 0.82, blue: 0.73)
        case .blush:
            return Color(red: 0.94, green: 0.80, blue: 0.83)
        case .lavender:
            return Color(red: 0.84, green: 0.80, blue: 0.94)
        case .sky:
            return Color(red: 0.79, green: 0.87, blue: 0.95)
        case .mint:
            return Color(red: 0.78, green: 0.91, blue: 0.85)
        case .sage:
            return Color(red: 0.82, green: 0.88, blue: 0.77)
        }
    }

    static func color(fromHex hex: String?) -> Color? {
        guard var value = hex?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        if value.hasPrefix("#") {
            value.removeFirst()
        }

        guard value.count == 6,
              let rgb = UInt64(value, radix: 16) else {
            return nil
        }

        return Color(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }

    static func hex(from color: Color) -> String? {
        let source = NSColor(color)
        guard let converted = source.usingColorSpace(.sRGB)
                ?? source.usingColorSpace(.deviceRGB) else {
            return nil
        }

        let red = Int(round(converted.redComponent * 255))
        let green = Int(round(converted.greenComponent * 255))
        let blue = Int(round(converted.blueComponent * 255))

        return String(format: "#%02X%02X%02X", red, green, blue)
    }
}
