import SwiftUI

struct HistoryView: View {
    @State private var searchText = ""

    let records: [BreadcrumbRecord]
    let onRestore: (UUID) -> Void
    let onArchive: (UUID) -> Void

    private var filteredRecords: [BreadcrumbRecord] {
        let sorted = records.sorted { $0.updatedAt > $1.updatedAt }

        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return sorted
        }

        return sorted.filter {
            $0.text.localizedCaseInsensitiveContains(searchText)
            || $0.applicationName.localizedCaseInsensitiveContains(searchText)
            || ($0.windowTitle?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Breadcrumbs")
                        .font(.system(size: 20, weight: .semibold))
                    Text("\(records.filter { !$0.isArchived }.count) active")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)

            Divider()

            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    "No Breadcrumbs",
                    systemImage: "circle.dotted",
                    description: Text("Press ⌥ Space anywhere on your Mac to leave one.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        HistoryRow(
                            record: record,
                            onRestore: { onRestore(record.id) },
                            onArchive: { onArchive(record.id) }
                        )
                    }
                }
                .listStyle(.inset)
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search thoughts")
        .frame(minWidth: 520, minHeight: 480)
    }
}

private struct HistoryRow: View {
    let record: BreadcrumbRecord
    let onRestore: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: record.isArchived ? "archivebox" : "circle.dotted")
                .frame(width: 20)
                .foregroundStyle(record.isArchived ? .tertiary : .secondary)

            VStack(alignment: .leading, spacing: 5) {
                Text(record.text)
                    .font(.system(size: 14))
                    .lineLimit(2)

                HStack(spacing: 5) {
                    Text(record.applicationName)

                    if let title = record.windowTitle, !title.isEmpty {
                        Text("·")
                        Text(title)
                            .lineLimit(1)
                    }

                    Text("·")
                    Text(record.updatedAt, style: .relative)
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }

            Spacer()

            if record.isArchived {
                Button("Restore", action: onRestore)
                    .buttonStyle(.borderless)
            } else {
                Button {
                    onArchive()
                } label: {
                    Image(systemName: "archivebox")
                }
                .buttonStyle(.borderless)
                .help("Archive")
            }
        }
        .padding(.vertical, 6)
    }
}
