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
            return Color(red: 0.769, green: 0.353, blue: 0.353)
        case .orange:
            return Color(red: 0.820, green: 0.541, blue: 0.247)
        case .yellow:
            return Color(red: 0.761, green: 0.631, blue: 0.227)
        case .green:
            return Color(red: 0.373, green: 0.541, blue: 0.388)
        case .blue:
            return Color(red: 0.365, green: 0.471, blue: 0.651)
        case .purple:
            return Color(red: 0.482, green: 0.384, blue: 0.561)
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
