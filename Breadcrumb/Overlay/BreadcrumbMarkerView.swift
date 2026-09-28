import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let applicationName: String

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                Circle()
                    .fill(.primary.opacity(0.10))
                    .frame(width: 20, height: 20)

                Circle()
                    .fill(.primary.opacity(0.78))
                    .frame(width: 6, height: 6)
            }

            Text(text)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .frame(width: 132, height: 34)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(.primary.opacity(0.14), lineWidth: 0.5)
        }
        .shadow(radius: 8, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Click to open. Drag to reposition.")
    }
}
