import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let breadcrumbColor: BreadcrumbColor
    let onHoverChange: (Bool) -> Void

    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .frame(width: 18, height: 18)

            Circle()
                .fill(breadcrumbColor.color)
                .frame(width: 14, height: 14)
                .overlay {
                    Circle()
                        .stroke(.primary.opacity(0.16), lineWidth: 0.75)
                }
        }
        .shadow(color: .black.opacity(0.16), radius: 3.5, y: 1.5)
        .frame(width: 20, height: 20)
        .contentShape(Circle())
        .onHover(perform: onHoverChange)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Hover to preview. Click to edit. Drag to reposition.")
    }
}
