import SwiftUI

struct HistoryView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"

    let records: [BreadcrumbRecord]
    let onRestore: (UUID) -> Void
    let onArchive: (UUID) -> Void

    private var filteredRecords: [BreadcrumbRecord] {
        var source = records

        if selectedFilter == "Active" {
            source = source.filter { !$0.isArchived }
        } else if selectedFilter == "Archived" {
            source = source.filter { $0.isArchived }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        if !query.isEmpty {
            source = source.filter {
                $0.text.localizedCaseInsensitiveContains(query)
                || $0.applicationName.localizedCaseInsensitiveContains(query)
                || ($0.windowTitle?.localizedCaseInsensitiveContains(query) ?? false)
                || ($0.documentURL?.localizedCaseInsensitiveContains(query) ?? false)
                || ($0.selectedTabTitle?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }

        return source.sorted { $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Breadcrumbs")
                        .font(.system(size: 22, weight: .semibold))

                    Text("\(records.filter { !$0.isArchived }.count) active · \(records.filter { $0.isArchived }.count) archived")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag("All")
                    Text("Active").tag("Active")
                    Text("Archived").tag("Archived")
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            .padding(20)

            Divider()

            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    "No Breadcrumbs",
                    systemImage: "circle.dotted",
                    description: Text("Press ⌥ Space inside a supported window to leave one.")
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
        .searchable(
            text: $searchText,
            placement: .toolbar,
            prompt: "Search text, app, tab, title, or URL"
        )
        .frame(minWidth: 720, minHeight: 560)
    }
}

private struct HistoryRow: View {
    let record: BreadcrumbRecord
    let onRestore: () -> Void
    let onArchive: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: record.isArchived ? "archivebox" : "circle.dotted")
                    .frame(width: 20)
                    .foregroundStyle(record.isArchived ? .tertiary : .secondary)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Text(record.text)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(isExpanded ? nil : 2)

                        if record.isLegacyContext {
                            Text("Legacy context")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                    }

                    HStack(spacing: 5) {
                        Text(record.applicationName)

                        if let tabTitle = record.selectedTabTitle, !tabTitle.isEmpty {
                            Text("·")
                            Text(tabTitle)
                                .lineLimit(1)
                        } else if let title = record.windowTitle, !title.isEmpty {
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

                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.borderless)
                .help(isExpanded ? "Hide context details" : "Show context details")

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

            if isExpanded {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 5) {
                    contextRow("App", record.applicationName)
                    contextRow("Bundle", record.bundleIdentifier)
                    contextRow("Window", record.windowTitle ?? "Unavailable")
                    contextRow("Document", record.documentURL ?? "Unavailable")
                    contextRow("Tab", record.selectedTabTitle ?? "Unavailable")
                    contextRow(
                        "Tab index",
                        record.selectedTabIndex.map(String.init) ?? "Unavailable"
                    )
                    contextRow(
                        "Window number",
                        record.windowNumber.map(String.init) ?? "Unavailable"
                    )
                    contextRow("Display", record.displayIdentifier ?? "Unavailable")
                    contextRow("Context version", record.contextVersion.map(String.init) ?? "Legacy")
                    contextRow(
                        "Anchor",
                        String(
                            format: "%.3f, %.3f",
                            record.relativeX,
                            record.relativeY
                        )
                    )
                }
                .font(.system(size: 11))
                .padding(.leading, 32)
                .padding(.bottom, 4)
            }
        }
        .padding(.vertical, 7)
    }

    @ViewBuilder
    private func contextRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.tertiary)
            Text(value)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}
