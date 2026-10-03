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
        let words = text
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(markerStyle == .microTab ? 2 : 3)
            .map(String.init)
            .joined(separator: " ")

        return words.isEmpty ? "Note" : words
    }

    var body: some View {
        HStack(spacing: 0) {
            markerIdentity

            if state.isColorPickerExpanded && markerStyle == .microTab {
                Divider()
                    .frame(height: 14)
                    .opacity(0.28)
                    .padding(.horizontal, 8)

                colorPalette
                    .transition(.opacity.combined(with: .scale(scale: 0.94, anchor: .leading)))
            }
        }
        .padding(.horizontal, 9)
        .frame(
            width: state.isColorPickerExpanded && markerStyle == .microTab
                ? markerSize.expandedWidth
                : markerSize.dimensions.width,
            height: markerSize.dimensions.height,
            alignment: .leading
        )
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay {
                    Capsule()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(state.isDragging ? 0.22 : 0.14), location: 0),
                                    .init(color: .white.opacity(0.045), location: 0.5),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(
                    .white.opacity(isHovering || state.isDragging ? 0.24 : 0.15),
                    lineWidth: 0.55
                )
        }
        .shadow(
            color: .black.opacity(
                state.isDragging
                    ? min(shadowStrength.opacity + 0.10, 0.28)
                    : isHovering
                        ? min(shadowStrength.opacity + 0.025, 0.17)
                        : min(shadowStrength.opacity, 0.13)
            ),
            radius: state.isDragging
                ? shadowStrength.radius + 5
                : isHovering
                    ? shadowStrength.radius + 1
                    : shadowStrength.radius,
            y: state.isDragging ? 5 : 2
        )
        .scaleEffect(
            reducedMotion
                ? 1
                : state.isDragging
                    ? 1.015
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
        .contentShape(Capsule())
        .onHover { hovering in
            isHovering = hovering
            onHoverChange(hovering)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Click the color dot to change color. Click the label to edit. Drag to reposition.")
    }

    private var markerIdentity: some View {
        HStack(spacing: markerStyle == .microTab ? 6 : 0) {
            if markerStyle == .microTab {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.98),
                                accentColor.opacity(0.68)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: markerSize == .large ? 5 : 4
                        )
                    )
                    .frame(
                        width: markerSize == .large ? 9 : 8,
                        height: markerSize == .large ? 9 : 8
                    )
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.28), lineWidth: 0.5)
                    }
                    .shadow(
                        color: accentColor.opacity(0.22),
                        radius: 2,
                        y: 0.5
                    )
            }

            Text(shortText)
                .font(.system(size: markerSize.fontSize, weight: .medium))
                .foregroundStyle(.primary.opacity(0.88))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var colorPalette: some View {
        HStack(spacing: 5) {
            ForEach(BreadcrumbColor.allCases) { color in
                Circle()
                    .fill(color.color)
                    .frame(width: 13, height: 13)
                    .overlay {
                        Circle()
                            .stroke(.white.opacity(0.24), lineWidth: 0.45)
                    }
                    .shadow(color: color.color.opacity(0.16), radius: 1.5, y: 0.5)
            }
        }
    }
}
