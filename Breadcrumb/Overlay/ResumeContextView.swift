import SwiftUI

struct ResumeContextView: View {
    let applicationName: String
    let contextTitle: String?
    let records: [BreadcrumbRecord]
    let onEdit: (UUID) -> Void
    let onArchive: (UUID) -> Void
    let onSnooze: (UUID, Date) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Pick up where you left off")
                        .font(.system(size: 13.5, weight: .semibold))

                    HStack(spacing: 4) {
                        Text(applicationName)
                        if let contextTitle, !contextTitle.isEmpty {
                            Text("·")
                            Text(contextTitle)
                                .lineLimit(1)
                        }
                    }
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            VStack(spacing: 0) {
                ForEach(records.prefix(5)) { record in
                    HStack(alignment: .top, spacing: 10) {
                        Circle()
                            .fill(.secondary.opacity(0.45))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(record.text)
                                .font(.system(size: 12.5, weight: .medium))
                                .lineLimit(2)

                            Text(record.updatedAt, style: .relative)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }

                        Spacer(minLength: 8)

                        Button("Edit") {
                            onEdit(record.id)
                        }
                        .buttonStyle(.borderless)
                        .controlSize(.small)

                        Menu {
                            Button("Snooze for 1 Hour", systemImage: "clock") {
                                onSnooze(record.id, Date().addingTimeInterval(60 * 60))
                            }
                            Button("Archive", systemImage: "archivebox") {
                                onArchive(record.id)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .menuStyle(.borderlessButton)
                        .fixedSize()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if record.id != records.prefix(5).last?.id {
                        Divider().padding(.leading, 30)
                    }
                }
            }

            Divider()

            HStack {
                if records.count > 5 {
                    Text("+\(records.count - 5) more in this context")
                } else {
                    Text("\(records.count) active breadcrumb\(records.count == 1 ? "" : "s")")
                }

                Spacer()

                Text("Esc to close")
            }
            .font(.system(size: 10))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .frame(width: 390)
        .background(Color(nsColor: .windowBackgroundColor))
        .onExitCommand(perform: onClose)
    }
}
