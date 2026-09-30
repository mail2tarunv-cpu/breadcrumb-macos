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
            return Color(red: 0.855, green: 0.420, blue: 0.420)
        case .orange:
            return Color(red: 0.902, green: 0.612, blue: 0.290)
        case .yellow:
            return Color(red: 0.855, green: 0.725, blue: 0.275)
        case .green:
            return Color(red: 0.420, green: 0.650, blue: 0.455)
        case .blue:
            return Color(red: 0.410, green: 0.565, blue: 0.790)
        case .purple:
            return Color(red: 0.610, green: 0.455, blue: 0.710)
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
