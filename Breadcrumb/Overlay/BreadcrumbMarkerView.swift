import SwiftUI

struct BreadcrumbMarkerView: View {
    let text: String
    let applicationName: String
    let breadcrumbColor: BreadcrumbColor
    let onHoverChange: (Bool) -> Void

    @State private var isHovering = false

    var body: some View {
        Group {
            if isHovering {
                HStack(alignment: .top, spacing: 9) {
                    Circle()
                        .fill(breadcrumbColor.color)
                        .frame(width: 10, height: 10)
                        .padding(.top, 3)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(text)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(applicationName)
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.42))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 9)
                .frame(width: 280, alignment: .leading)
                .background(Color.white.opacity(0.98))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.black.opacity(0.07), lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.12), radius: 12, y: 5)
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .topLeading)))
            } else {
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
            }
        }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
            onHoverChange(hovering)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breadcrumb: " + text)
        .accessibilityHint("Hover to preview. Click to edit. Drag to reposition.")
    }
}
