import SwiftUI

struct BreadcrumbHoverPreviewView: View {
    let record: BreadcrumbRecord

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Circle()
                .fill(record.breadcrumbColor.color)
                .frame(width: 9, height: 9)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.text)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Text(record.applicationName)

                    if !record.contextGroupName.isEmpty {
                        Text("·")
                        Text(record.contextGroupName)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 9.5, weight: .medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .frame(width: 280, alignment: .leading)
         .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.14), radius: 12, y: 5)
    }
}
