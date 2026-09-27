import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let applicationName: String
    let onOpen: () -> Void

    @State private var isHovering = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onOpen) {
            ZStack {
                Circle()
                    .fill(.regularMaterial)

                Circle()
                    .stroke(.primary.opacity(0.14), lineWidth: 0.5)

                Circle()
                    .fill(.primary.opacity(isHovering ? 0.88 : 0.58))
                    .frame(width: 5, height: 5)
            }
            .frame(width: 20, height: 20)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering && !reduceMotion ? 1.08 : 1)
        .animation(
            reduceMotion ? nil : .easeOut(duration: 0.12),
            value: isHovering
        )
        .help(text + " — " + applicationName)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel("Breadcrumb: " + text)
    }
}
