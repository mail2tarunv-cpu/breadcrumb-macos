import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String

    @State private var isHovering = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.ultraThickMaterial)

            Circle()
                .stroke(.primary.opacity(0.16), lineWidth: 0.5)

            Circle()
                .fill(.primary.opacity(isHovering ? 0.80 : 0.56))
                .frame(width: 5, height: 5)
        }
        .frame(width: 18, height: 18)
        .scaleEffect(isHovering ? 1.08 : 1)
        .animation(.easeOut(duration: 0.14), value: isHovering)
        .help(text)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
