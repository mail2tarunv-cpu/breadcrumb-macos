import SwiftUI

final class BreadcrumbMarkerState: ObservableObject {
    @Published var isColorPickerExpanded = false
    @Published var isDragging = false
 }

struct BreadcrumbMarkerView: View {
    let text: String
    let accentColor: Color
    @ObservedObject var state: BreadcrumbMarkerState
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
        let allWords = text
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .map(String.init)

        let limit = markerStyle == .microTab ? 2 : 3
        let visible = allWords.prefix(limit).joined(separator: " ")

        guard !visible.isEmpty else { return "Note" }
        return allWords.count > limit ? visible + "…" : visible
    }

    var body: some View {
        HStack(spacing: 0) {
            markerIdentity

            if state.isColorPickerExpanded && markerStyle == .microTab {
                colorPalette
                    .padding(.leading, 6)
                    .transition(
                        reducedMotion
                            ? .opacity
                            : .opacity.combined(with: .scale(scale: 0.96, anchor: .leading))
                    )
            }
        }
        .padding(.horizontal, 8)
        .frame(
            width: markerWidth,
            height: markerSize.dimensions.height,
            alignment: .leading
        )
        // The surface should read as atmosphere, not as a drawn button.
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial.opacity(state.isDragging ? 0.76 : 0.62))
                .overlay {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(state.isDragging ? 0.045 : 0.025))
                }
        }
        .clipShape(Capsule(style: .continuous))
        .shadow(
            color: .black.opacity(
                state.isDragging
                    ? 0.15
                    : isHovering
                        ? 0.06
                        : 0.035
            ),
            radius: state.isDragging ? 7 : 5,
            y: state.isDragging ? 4 : 2
        )
        .scaleEffect(
            reducedMotion
                ? 1
                : state.isDragging
                    ? 1.012
                    : 1
        )
        .animation(
            reducedMotion ? nil : .easeOut(duration: 0.14),
            value: state.isDragging
        )
        .animation(
            reducedMotion ? nil : .easeOut(duration: 0.16),
            value: state.isColorPickerExpanded
        )
         .contentShape(Capsule(style: .continuous))
        .onHover { hovering in
            isHovering = hovering
            onHoverChange(hovering)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Click the color dot to change color. Click the label to edit. Drag to reposition.")
    }

    private var markerWidth: CGFloat {
        if state.isColorPickerExpanded && markerStyle == .microTab {
            return markerSize.expandedWidth
        }
        return markerSize.dimensions.width
    }

    private var markerIdentity: some View {
        HStack(spacing: markerStyle == .microTab ? 6 : 0) {
            if markerStyle == .microTab {
                Circle()
                    .fill(accentColor.opacity(isHovering ? 0.96 : 0.9))
                    .frame(
                        width: markerSize == .large ? 9 : 8,
                        height: markerSize == .large ? 9 : 8
                    )
                    .overlay {
                        Circle()
                            .fill(.white.opacity(0.16))
                            .frame(width: 2.2, height: 2.2)
                            .offset(x: -1, y: -1)
                    }
                    .shadow(
                        color: accentColor.opacity(isHovering ? 0.20 : 0.12),
                        radius: 1.5,
                        y: 0.5
                    )
            }

            Text(shortText)
                .font(.system(size: markerSize.fontSize, weight: .medium))
                .foregroundStyle(.primary.opacity(0.86))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var colorPalette: some View {
        HStack(spacing: 4) {
            ForEach(BreadcrumbColor.allCases) { color in
                Circle()
                    .fill(color.color.opacity(0.86))
                    .frame(width: 9, height: 9)
                    .overlay {
                        Circle()
                            .fill(.white.opacity(0.14))
                            .frame(width: 1.8, height: 1.8)
                            .offset(x: -1, y: -1)
                    }
                    .shadow(
                        color: color.color.opacity(0.10),
                        radius: 1,
                        y: 0.3
                    )
            }
        }
    }
}
