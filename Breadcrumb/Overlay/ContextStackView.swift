import SwiftUI

struct ContextStackView: View {
    let records: [BreadcrumbRecord]
    let onOpen: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 8) {
                HStack(spacing: -3) {
                    ForEach(Array(records.prefix(3))) { record in
                        Circle()
                            .fill(record.breadcrumbColor.color)
                            .frame(width: 9, height: 9)
                            .overlay {
                                Circle()
                                    .stroke(.background.opacity(0.9), lineWidth: 1)
                            }
                    }
                }

                Text("\(records.count) breadcrumbs")
                    .font(.system(size: 12, weight: .medium))

                Spacer(minLength: 2)

                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 10)
            .frame(width: 154, height: 34)
             .background(.thinMaterial)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(.primary.opacity(isHovering ? 0.13 : 0.07), lineWidth: 0.5)
            }
            .shadow(radius: isHovering ? 8 : 5, y: 3)
            .scaleEffect(isHovering ? 1.015 : 1)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .accessibilityLabel("\(records.count) breadcrumbs in this context")
        .accessibilityHint("Open context summary")
    }
}
