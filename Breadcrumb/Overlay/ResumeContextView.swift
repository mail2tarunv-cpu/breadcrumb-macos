import SwiftUI

struct ResumeContextView: View {
    let applicationName: String
    let contextTitle: String?
    let records: [BreadcrumbRecord]
    let onEdit: (UUID) -> Void
    let onArchive: (UUID) -> Void
    let onDone: (UUID) -> Void
    let onSnooze: (UUID, Date) -> Void
    let onClose: () -> Void

    @State private var hoveredRecord: UUID?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.28)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(records) { record in
                        recordRow(record)
                    }
                }
                .padding(10)
            }
            .scrollIndicators(.never)
            .frame(maxHeight: 320)

            Divider().opacity(0.28)

            footer
        }
         .frame(width: 390)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.16), location: 0),
                                    .init(color: .white.opacity(0.045), location: 0.5),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0.28),
                                    .white.opacity(0.07)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.7
                        )
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .onExitCommand(perform: onClose)
    }

    private var header: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 32, height: 32)

                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.82))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Pick up where you left off")
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Text(applicationName)
                        .fontWeight(.medium)

                    if let contextTitle, !contextTitle.isEmpty {
                        Text("·")
                        Text(contextTitle)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)
                .frame(maxWidth: 290, alignment: .leading)
            }

            Spacer(minLength: 8)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 24, height: 24)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
    }

    private func recordRow(_ record: BreadcrumbRecord) -> some View {
        let hovering = hoveredRecord == record.id

        return HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(record.accentColor)
                .frame(width: 3, height: 30)
                .shadow(color: record.accentColor.opacity(0.22), radius: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.text)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(record.updatedAt, style: .relative)
                    .font(.system(size: 9.5, weight: .regular))
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 2)

            if hovering {
                Button("Edit") {
                    onEdit(record.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.primary.opacity(0.8))
                .transition(.opacity)
            }

            Menu {
                Button("Mark Done", systemImage: "checkmark.circle") {
                    onDone(record.id)
                }
                Divider()
                Button("Snooze for 1 Hour", systemImage: "clock") {
                    onSnooze(record.id, Date().addingTimeInterval(60 * 60))
                }
                Button("Archive", systemImage: "archivebox") {
                    onArchive(record.id)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .background(.white.opacity(hovering ? 0.10 : 0.055), in: Circle())
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 9)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(.white.opacity(hovering ? 0.075 : 0.035))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(.white.opacity(hovering ? 0.11 : 0.035), lineWidth: 0.5)
        }
        .contentShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .onHover { isHovering in
            hoveredRecord = isHovering ? record.id : nil
        }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 5) {
                Circle()
                    .fill(.primary.opacity(0.22))
                    .frame(width: 4, height: 4)

                Text("\(records.count) active")
            }

            Spacer()

            Text("Esc to close")
        }
        .font(.system(size: 9.5, weight: .medium))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 15)
        .padding(.vertical, 9)
    }
}
