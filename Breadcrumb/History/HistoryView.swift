import SwiftUI

struct HistoryView: View {
    @State private var searchText = ""
    @State private var selectedFilter = "All"

    let records: [BreadcrumbRecord]
    let onRestore: (UUID) -> Void
    let onArchive: (UUID) -> Void
    let onDelete: (UUID) -> Void
    let onSnooze: (UUID, Date) -> Void
    let onWake: (UUID) -> Void

    private var filteredRecords: [BreadcrumbRecord] {
        var source = records

        switch selectedFilter {
        case "Active":
            source = source.filter { !$0.isArchived }
        case "Archived":
            source = source.filter { $0.isArchived }
        default:
            break
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

    private var activeCount: Int {
        records.filter { !$0.isArchived && !$0.isSnoozed }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Breadcrumbs")
                        .font(.system(size: 22, weight: .semibold))

                    Text(activeCount == 1 ? "1 active breadcrumb" : "\(activeCount) active breadcrumbs")
                        .font(.system(size: 11.5))
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            Divider()

            if filteredRecords.isEmpty {
                ContentUnavailableView {
                    Label("No Breadcrumbs", systemImage: "circle.dotted")
                } description: {
                    Text(searchText.isEmpty
                         ? "Press ⌥ Space in any window to leave a thought."
                         : "No breadcrumbs match your search.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredRecords) { record in
                        BreadcrumbLibraryRow(
                            record: record,
                            onRestore: { onRestore(record.id) },
                            onArchive: { onArchive(record.id) },
                            onDelete: { onDelete(record.id) },
                            onSnooze: { date in onSnooze(record.id, date) },
                            onWake: { onWake(record.id) }
                        )
                    }
                }
                .listStyle(.inset)
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search Breadcrumbs")
        .frame(minWidth: 720, minHeight: 560)
    }
}

private struct BreadcrumbLibraryRow: View {
    let record: BreadcrumbRecord
    let onRestore: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onSnooze: (Date) -> Void
    let onWake: () -> Void

    @State private var isExpanded = false
    @State private var isConfirmingDelete = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: statusIcon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.text)
                        .font(.system(size: 13.5, weight: .medium))
                        .lineLimit(isExpanded ? nil : 2)
                        .textSelection(.enabled)

                    HStack(spacing: 4) {
                        Text(record.applicationName)
                            .fontWeight(.medium)

                        if let context = visibleContext {
                            Text("·")
                            Text(context)
                                .lineLimit(1)
                        }

                        Text("·")

                        if record.isSnoozed, let snoozedUntil = record.snoozedUntil {
                            Text("Snoozed")
                            Text(snoozedUntil, style: .relative)
                        } else {
                            Text(record.updatedAt, style: .relative)
                        }
                    }
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if record.isArchived {
                    Button("Restore", action: onRestore)
                        .controlSize(.small)
                } else if record.isSnoozed {
                    Button("Wake", action: onWake)
                        .controlSize(.small)
                }

                Menu {
                    Button(isExpanded ? "Hide Context" : "Show Context") {
                        isExpanded.toggle()
                    }

                    if !record.isArchived {
                        Divider()

                        if record.isSnoozed {
                            Button("Wake Now", systemImage: "sun.max", action: onWake)
                        } else {
                            Button("Snooze for 1 Hour", systemImage: "clock") {
                                onSnooze(Date().addingTimeInterval(60 * 60))
                            }
                            Button("Snooze for 1 Day", systemImage: "moon.zzz") {
                                onSnooze(Date().addingTimeInterval(60 * 60 * 24))
                            }
                            Button("Archive", systemImage: "archivebox", action: onArchive)
                        }
                    }

                    Divider()

                    Button("Delete…", systemImage: "trash", role: .destructive) {
                        withAnimation(.easeOut(duration: 0.12)) {
                            isConfirmingDelete = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            if isExpanded {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 5) {
                    contextRow("App", record.applicationName)
                    contextRow("Window", record.windowTitle ?? "Unavailable")
                    contextRow("Document", record.documentURL ?? "Unavailable")
                    contextRow("Tab", record.selectedTabTitle ?? "Unavailable")
                    contextRow("Created", record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    contextRow("Updated", record.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.system(size: 10.5))
                .padding(.leading, 28)
                .padding(.top, 2)
            }

            if isConfirmingDelete {
                HStack(spacing: 8) {
                    Text("Delete this breadcrumb?")
                        .font(.system(size: 11.5, weight: .medium))

                    Text("This can’t be undone.")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Cancel") {
                        withAnimation(.easeOut(duration: 0.12)) {
                            isConfirmingDelete = false
                        }
                    }
                    .controlSize(.small)

                    Button("Delete", role: .destructive, action: onDelete)
                        .controlSize(.small)
                }
                .padding(.leading, 28)
                .padding(.top, 3)
            }
        }
        .padding(.vertical, 6)
        .opacity(record.isArchived ? 0.65 : (record.isSnoozed ? 0.78 : 1))
    }

    private var statusIcon: String {
        if record.isArchived { return "archivebox" }
        if record.isSnoozed { return "clock" }
        return "circle.dotted"
    }

    private var visibleContext: String? {
        if let tab = record.selectedTabTitle, !tab.isEmpty { return tab }
        if let title = record.windowTitle, !title.isEmpty { return title }
        return nil
    }

    @ViewBuilder
    private func contextRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.tertiary)
                .frame(width: 60, alignment: .leading)

            Text(value)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(2)
        }
    }
}
