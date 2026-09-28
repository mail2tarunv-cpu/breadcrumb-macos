import SwiftUI

struct BreadcrumbEditorView: View {
    @State private var text: String
    @FocusState private var isFocused: Bool

    let applicationName: String
    let windowTitle: String?
    let createdAt: Date
    let onSave: (String) -> Void
    let onArchive: () -> Void
    let onDelete: () -> Void
    let onClose: () -> Void

    init(
        text: String,
        applicationName: String,
        windowTitle: String?,
        createdAt: Date,
        onSave: @escaping (String) -> Void,
        onArchive: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        _text = State(initialValue: text)
        self.applicationName = applicationName
        self.windowTitle = windowTitle
        self.createdAt = createdAt
        self.onSave = onSave
        self.onArchive = onArchive
        self.onDelete = onDelete
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(.primary.opacity(0.08))
                        .frame(width: 25, height: 25)
                    Circle()
                        .fill(.primary.opacity(0.78))
                        .frame(width: 7, height: 7)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(applicationName)
                        .font(.system(size: 12, weight: .semibold))

                    if let windowTitle, !windowTitle.isEmpty {
                        Text(windowTitle)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 24, height: 24)
                        .background(.quaternary.opacity(0.6))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            TextEditor(text: $text)
                .font(.system(size: 15))
                .scrollContentBackground(.hidden)
                .scrollIndicators(.hidden)
                .frame(minHeight: 118, maxHeight: 190)
                .focused($isFocused)
                .padding(9)
                .background(.primary.opacity(0.035))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                HStack(spacing: 3) {
                    Text("Left")
                    Text(createdAt, style: .relative)
                }
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)

                Spacer()

                Menu {
                    Button("Archive", systemImage: "archivebox", action: onArchive)
                    Divider()
                    Button("Delete Permanently", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 26, height: 22)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button("Save") {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onSave(trimmed)
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(16)
        .frame(width: 360)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.primary.opacity(0.09), lineWidth: 0.7)
        }
        .onAppear {
            DispatchQueue.main.async { isFocused = true }
        }
    }
}
