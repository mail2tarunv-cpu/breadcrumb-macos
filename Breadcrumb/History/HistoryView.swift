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
        case "Active": source = source.filter { !$0.isArchived }
        case "Archived": source = source.filter { $0.isArchived }
        default: break
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

    private var activeCount: Int { records.filter { !$0.isArchived }.count }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if filteredRecords.isEmpty {
                ContentUnavailableView {
                    Label("Nothing here yet", systemImage: "circle.dotted")
                } description: {
                    Text(searchText.isEmpty
                         ? "Press ⌥ Space in any window to leave your first breadcrumb."
                         : "No breadcrumbs match your search.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredRecords) { record in
                            HistoryCard(
                                record: record,
                                onRestore: { onRestore(record.id) },
                                onArchive: { onArchive(record.id) },
                                onDelete: { onDelete(record.id) },
                                onSnooze: { date in onSnooze(record.id, date) },
                                onWake: { onWake(record.id) }
                            )
                        }
                    }
                    .padding(18)
                }
                .background(.primary.opacity(0.015))
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search breadcrumbs")
        .frame(minWidth: 760, minHeight: 600)
    }

    private var header: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Breadcrumbs")
                    .font(.system(size: 26, weight: .semibold))

                Text(activeCount == 1 ? "1 thought waiting for you" : "\(activeCount) thoughts waiting for you")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Filter", selection: $selectedFilter) {
                Text("All").tag("All")
                Text("Active").tag("Active")
                Text("Archived").tag("Archived")
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

private struct HistoryCard: View {
    let record: BreadcrumbRecord
    let onRestore: () -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onSnooze: (Date) -> Void
    let onWake: () -> Void

    @State private var isExpanded = false
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.primary.opacity(0.055))
                        .frame(width: 34, height: 34)

                    Image(systemName: record.isArchived ? "archivebox" : (record.isSnoozed ? "clock" : "circle.dotted"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(record.text)
                        .font(.system(size: 14.5, weight: .medium))
                        .lineLimit(isExpanded ? nil : 3)
                        .textSelection(.enabled)

                    HStack(spacing: 5) {
                        Text(record.applicationName)
                            .fontWeight(.medium)

                        if let context = visibleContext {
                            Text("·")
                            Text(context).lineLimit(1)
                        }

                        Text("·")
                        if record.isSnoozed, let snoozedUntil = record.snoozedUntil {
                            Text("·")
                            Text("Snoozed")
                            Text(snoozedUntil, style: .relative)
                        } else {
                            Text("·")
                            Text(record.updatedAt, style: .relative)
                        }
                    }
                    .font(.system(size: 10.5))
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                if record.isArchived {
                    Button("Restore", action: onRestore)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                } else if record.isSnoozed {
                    Button("Wake", action: onWake)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                } else {
                    Button {
                        onArchive()
                    } label: {
                        Image(systemName: "archivebox")
                    }
                    .buttonStyle(.borderless)
                    .help("Archive")
                }

                Menu {
                    if !record.isArchived {
                        if record.isSnoozed {
                            Button("Wake Now", systemImage: "sun.max", action: onWake)
                        } else {
                            Button("Snooze for 1 Hour", systemImage: "clock") {
                                onSnooze(Date().addingTimeInterval(60 * 60))
                            }
                            Button("Snooze for 1 Day", systemImage: "moon.zzz") {
                                onSnooze(Date().addingTimeInterval(60 * 60 * 24))
                            }
                        }
                        Divider()
                    }
                    Button(isExpanded ? "Hide Context" : "Show Context") {
                        isExpanded.toggle()
                    }
                    Divider()
                    Button("Delete Permanently", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 24, height: 24)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            if isExpanded {
                Divider().opacity(0.65)

                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
                    contextRow("App", record.applicationName)
                    contextRow("Window", record.windowTitle ?? "Unavailable")
                    contextRow("Document", record.documentURL ?? "Unavailable")
                    contextRow("Tab", record.selectedTabTitle ?? "Unavailable")
                    contextRow("Created", record.createdAt.formatted(date: .abbreviated, time: .shortened))
                    contextRow("Updated", record.updatedAt.formatted(date: .abbreviated, time: .shortened))
                }
                .font(.system(size: 10.5))
                .padding(.leading, 46)
            }
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(isHovering ? 0.11 : 0.06), lineWidth: 0.7)
        }
        .shadow(radius: isHovering ? 8 : 0, y: 3)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .opacity(record.isArchived ? 0.68 : (record.isSnoozed ? 0.78 : 1))
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
                .frame(width: 62, alignment: .leading)
            Text(value)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(2)
        }
    }
}
