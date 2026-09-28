import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let applicationName: String

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)

            Circle()
                .stroke(.primary.opacity(0.16), lineWidth: 0.5)

            Circle()
                .fill(.primary.opacity(isHovering ? 0.92 : 0.62))
                .frame(width: 6, height: 6)
        }
        .frame(width: 24, height: 24)
        .contentShape(Circle())
        .scaleEffect(isHovering && !reduceMotion ? 1.10 : 1)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.12),
            value: isHovering
        )
        .help(text + " — " + applicationName)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Click to open. Drag to reposition.")
    }
}
