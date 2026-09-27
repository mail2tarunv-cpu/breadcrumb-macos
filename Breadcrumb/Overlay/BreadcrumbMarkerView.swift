import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let applicationName: String

    @State private var isHovering = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)

            Circle()
                .stroke(.primary.opacity(0.14), lineWidth: 0.5)

            Circle()
                .fill(.primary.opacity(isHovering ? 0.86 : 0.58))
                .frame(width: 5, height: 5)
        }
        .frame(width: 20, height: 20)
        .contentShape(Circle())
        .scaleEffect(isHovering ? 1.08 : 1)
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .help(text + " — " + applicationName)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel("Breadcrumb: " + text)
    }
}
