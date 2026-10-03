import SwiftUI

struct BreadcrumbHoverPreviewView: View {
    let record: BreadcrumbRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(record.breadcrumbColor.color.opacity(0.92))
                    .frame(width: 8, height: 8)
                    .overlay {
                        Circle()
                            .fill(.white.opacity(0.18))
                            .frame(width: 2, height: 2)
                            .offset(x: -1, y: -1)
                    }

                HStack(spacing: 5) {
                    Text(record.applicationName)
                        .font(.system(size: 10.5, weight: .semibold))

                    if !record.contextGroupName.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)

                        Text(record.contextGroupName)
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(.tertiary)
            }

            Text(record.text)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.primary.opacity(0.94))
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(6)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .frame(width: 280, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(.white.opacity(0.035))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(.white.opacity(0.11), lineWidth: 0.55)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .shadow(color: .black.opacity(0.13), radius: 14, y: 6)
    }
}
