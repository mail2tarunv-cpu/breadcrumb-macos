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
            .padding(.horizontal, 11)
            .frame(width: 164, height: 36)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.thinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(.white.opacity(isHovering ? 0.045 : 0.025))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(.white.opacity(isHovering ? 0.15 : 0.08), lineWidth: 0.55)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .shadow(color: .black.opacity(isHovering ? 0.12 : 0.07), radius: isHovering ? 10 : 7, y: 4)
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
