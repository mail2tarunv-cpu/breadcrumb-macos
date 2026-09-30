import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let accentColor: Color
    let onHoverChange: (Bool) -> Void

    @AppStorage(BreadcrumbPreferences.markerStyleKey) private var markerStyleRaw = BreadcrumbMarkerStyle.microTab.rawValue
    @AppStorage(BreadcrumbPreferences.markerSizeKey) private var markerSizeRaw = BreadcrumbMarkerSize.medium.rawValue
    @AppStorage(BreadcrumbPreferences.reducedMotionKey) private var reducedMotion = false
    @AppStorage(BreadcrumbPreferences.shadowStrengthKey) private var shadowStrengthRaw = BreadcrumbShadowStrength.standard.rawValue

    @State private var isHovering = false

    private var markerStyle: BreadcrumbMarkerStyle {
        BreadcrumbMarkerStyle(rawValue: markerStyleRaw) ?? .microTab
    }

    private var markerSize: BreadcrumbMarkerSize {
        BreadcrumbMarkerSize(rawValue: markerSizeRaw) ?? .medium
    }

    private var shadowStrength: BreadcrumbShadowStrength {
        BreadcrumbShadowStrength(rawValue: shadowStrengthRaw) ?? .standard
    }

    private var shortText: String {
        let count = markerStyle == .microTab ? 2 : 3
        let words = text
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(count)
            .map(String.init)
            .joined(separator: " ")

        return words.isEmpty ? "Note" : words
    }

    var body: some View {
        HStack(spacing: markerStyle == .microTab ? 6 : 0) {
            if markerStyle == .microTab {
                Circle()
                    .fill(accentColor)
                    .frame(width: markerSize == .large ? 9 : 8, height: markerSize == .large ? 9 : 8)
            }

            Text(shortText)
                .font(.system(size: markerSize.fontSize, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, markerStyle == .microTab ? 8 : 10)
        .frame(width: markerSize.dimensions.width, height: markerSize.dimensions.height, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.primary.opacity(isHovering ? 0.10 : 0.055), lineWidth: 0.5)
        }
        .shadow(
            color: .black.opacity(
                isHovering
                    ? min(shadowStrength.opacity + 0.04, 0.22)
                    : shadowStrength.opacity
            ),
            radius: isHovering
                ? shadowStrength.radius + 1.5
                : shadowStrength.radius,
            y: isHovering ? 2.5 : 1.5
        )
        .scaleEffect(reducedMotion ? 1 : (isHovering ? 1.018 : 1))
        .animation(
            reducedMotion ? nil : .easeOut(duration: 0.10),
            value: isHovering
        )
        .contentShape(Capsule())
        .onHover { hovering in
            isHovering = hovering
            onHoverChange(hovering)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Click to edit. Drag to reposition.")
    }
}
