import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let applicationName: String

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 9) {
            ZStack {
                Circle()
                    .fill(.primary.opacity(isHovering ? 0.12 : 0.08))
                    .frame(width: 22, height: 22)

                Circle()
                    .fill(.primary.opacity(0.82))
                    .frame(width: 7, height: 7)
                    .shadow(radius: isHovering ? 2 : 0)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(text)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)

                if isHovering {
                    Text(applicationName)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .transition(.opacity)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.quaternary)
                .opacity(isHovering ? 1 : 0)
        }
        .padding(.horizontal, 9)
        .frame(width: 176, height: 40)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(.primary.opacity(isHovering ? 0.16 : 0.09), lineWidth: 0.7)
        }
        .shadow(radius: isHovering ? 14 : 9, y: isHovering ? 6 : 4)
        .scaleEffect(isHovering ? 1.02 : 1)
        .animation(.easeOut(duration: 0.14), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Click to open. Drag to reposition.")
    }
}
