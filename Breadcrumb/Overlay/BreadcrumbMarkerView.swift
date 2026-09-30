import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let breadcrumbColor: BreadcrumbColor
    let onHoverChange: (Bool) -> Void

    @State private var isHovering = false

    private var shortText: String {
        let words = text
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(2)
            .map(String.init)
            .joined(separator: " ")

        return words.isEmpty ? "Note" : words
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(breadcrumbColor.color)
                .frame(width: 8, height: 8)

            Text(shortText)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 8)
        .frame(height: 26)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(.primary.opacity(isHovering ? 0.10 : 0.06), lineWidth: 0.5)
        }
        .shadow(
            color: .black.opacity(isHovering ? 0.16 : 0.10),
            radius: isHovering ? 6 : 4,
            y: isHovering ? 2.5 : 1.5
        )
        .scaleEffect(isHovering ? 1.02 : 1)
        .animation(.easeOut(duration: 0.10), value: isHovering)
        .contentShape(Capsule())
        .onHover { hovering in
            isHovering = hovering
            onHoverChange(hovering)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Click to edit. Drag to reposition.")
    }
}
