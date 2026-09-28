import SwiftUI

struct BreadcrumbEditorView: View {
    @State private var text: String
    @FocusState private var isFocused: Bool
    @State private var showDeleteConfirmation = false

    let applicationName: String
    let windowTitle: String?
    let createdAt: Date
    let onSave: (String) -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onSnooze: (Date) -> Void
    let onClose: () -> Void

    init(
        text: String,
        applicationName: String,
        windowTitle: String?,
        createdAt: Date,
        onSave: @escaping (String) -> Void,
        onArchive: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSnooze: @escaping (Date) -> Void,
        onClose: @escaping () -> Void
    ) {
        _text = State(initialValue: text)
        self.applicationName = applicationName
        self.windowTitle = windowTitle
        self.createdAt = createdAt
        self.onSave = onSave
        self.onArchive = onArchive
        self.onDelete = onDelete
        self.onSnooze = onSnooze
        self.onClose = onClose
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(applicationName)
                        .font(.system(size: 12, weight: .semibold))

                    if let windowTitle, !windowTitle.isEmpty {
                        Text(windowTitle)
                            .font(.system(size: 10.5))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Menu {
                    Button("Snooze for 1 Hour", systemImage: "clock") {
                        onSnooze(Date().addingTimeInterval(60 * 60))
                    }
                    Button("Snooze for 1 Day", systemImage: "moon.zzz") {
                        onSnooze(Date().addingTimeInterval(60 * 60 * 24))
                    }
                    Divider()
                    Button("Archive", systemImage: "archivebox", action: onArchive)
                    Divider()
                    Button("Delete Permanently", systemImage: "trash", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 14))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .help("Close")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)

            Divider()

            TextEditor(text: $text)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .scrollIndicators(.automatic)
                .focused($isFocused)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minHeight: 112, maxHeight: 156)
                .background(Color(nsColor: .textBackgroundColor))

            Divider()

            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    Text("Left")
                    Text(createdAt, style: .relative)
                }
                .font(.system(size: 10.5))
                .foregroundStyle(.secondary)

                Spacer()

                Text("⌘↩")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.tertiary)

                Button("Save") {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onSave(trimmed)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 340)
        .background(Color(nsColor: .windowBackgroundColor))
        .confirmationDialog(
            "Delete this breadcrumb permanently?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Permanently", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
        .onAppear {
            DispatchQueue.main.async { isFocused = true }
        }
    }
}
