import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let breadcrumbColor: BreadcrumbColor
    let onHoverChange: (Bool) -> Void

    var body: some View {
        Circle()
            .fill(breadcrumbColor.color)
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .stroke(.black.opacity(0.08), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            .frame(width: 20, height: 20)
            .contentShape(Circle())
            .onHover(perform: onHoverChange)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Breadcrumb: " + text)
            .accessibilityHint("Hover to preview. Click to edit. Drag to reposition.")
    }
}
