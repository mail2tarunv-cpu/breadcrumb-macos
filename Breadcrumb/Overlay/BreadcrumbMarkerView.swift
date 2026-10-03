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
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.98),
                                accentColor.opacity(0.72)
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
                            .stroke(.white.opacity(0.32), lineWidth: 0.5)
                    }
                    .shadow(color: accentColor.opacity(0.28), radius: 2, y: 0.5)
            }

            Text(shortText)
                .font(.system(size: markerSize.fontSize, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, markerStyle == .microTab ? 9 : 10)
        .frame(
            width: markerSize.dimensions.width,
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
                                    .init(color: .white.opacity(0.16), location: 0),
                                    .init(color: .white.opacity(0.04), location: 0.48),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
        }
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(isHovering ? 0.34 : 0.22),
                            .white.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.65
                )
        }
        .shadow(
            color: .black.opacity(
                isHovering
                    ? min(shadowStrength.opacity + 0.05, 0.24)
                    : min(shadowStrength.opacity + 0.015, 0.20)
            ),
            radius: isHovering
                ? shadowStrength.radius + 2
                : shadowStrength.radius + 0.5,
            y: isHovering ? 3 : 2
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
