import SwiftUI

enum BreadcrumbColor: String, Codable, CaseIterable, Identifiable {
    case red
    case orange
    case yellow
    case green
    case blue
    case purple

    var id: String { rawValue }

    var name: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .red:
            return Color(red: 0.90, green: 0.20, blue: 0.20)
        case .orange:
            return Color(red: 0.95, green: 0.45, blue: 0.10)
        case .yellow:
            return Color(red: 0.95, green: 0.75, blue: 0.08)
        case .green:
            return Color(red: 0.16, green: 0.65, blue: 0.32)
        case .blue:
            return Color(red: 0.12, green: 0.45, blue: 0.92)
        case .purple:
            return Color(red: 0.50, green: 0.25, blue: 0.85)
        }
    }

    static func migrated(from rawValue: String?) -> BreadcrumbColor {
        guard let rawValue else { return .blue }

        if let current = BreadcrumbColor(rawValue: rawValue) {
            return current
        }

        switch rawValue {
        case "butter": return .yellow
        case "peach": return .orange
        case "blush": return .red
        case "lavender": return .purple
        case "sky": return .blue
        case "mint", "sage": return .green
        default: return .blue
        }
    }
}
