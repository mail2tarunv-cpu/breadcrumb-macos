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
            return Color(red: 0.96, green: 0.86, blue: 0.55)
        case .peach:
            return Color(red: 0.96, green: 0.72, blue: 0.58)
        case .blush:
            return Color(red: 0.94, green: 0.68, blue: 0.73)
        case .lavender:
            return Color(red: 0.77, green: 0.70, blue: 0.93)
        case .sky:
            return Color(red: 0.66, green: 0.81, blue: 0.94)
        case .mint:
            return Color(red: 0.62, green: 0.88, blue: 0.78)
        case .sage:
            return Color(red: 0.72, green: 0.82, blue: 0.67)
        }
    }
}
