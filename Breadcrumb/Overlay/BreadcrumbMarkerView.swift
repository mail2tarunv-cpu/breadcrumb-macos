import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let applicationName: String

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(.secondary.opacity(isHovering ? 0.75 : 0.52))
                .frame(width: 7, height: 7)

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 3)

            if isHovering {
                Text(applicationName)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 10)
        .frame(width: 164, height: 34)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.primary.opacity(isHovering ? 0.13 : 0.07), lineWidth: 0.5)
        }
        .shadow(radius: isHovering ? 8 : 5, y: 3)
        .scaleEffect(isHovering ? 1.015 : 1)
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .onHover { isHovering = $0 }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Click to edit. Drag to reposition.")
    }
}
