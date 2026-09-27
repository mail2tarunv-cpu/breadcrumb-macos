import SwiftUI

struct BreadcrumbEditorView: View {
    @State private var text: String
    @FocusState private var isFocused: Bool

    let applicationName: String
    let windowTitle: String?
    let createdAt: Date
    let onSave: (String) -> Void
    let onArchive: () -> Void
    let onClose: () -> Void

    init(
        text: String,
        applicationName: String,
        windowTitle: String?,
        createdAt: Date,
        onSave: @escaping (String) -> Void,
        onArchive: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        _text = State(initialValue: text)
        self.applicationName = applicationName
        self.windowTitle = windowTitle
        self.createdAt = createdAt
        self.onSave = onSave
        self.onArchive = onArchive
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 7) {
                Image(systemName: "circle.dotted")
                    .foregroundStyle(.secondary)

                Text(applicationName)
                    .font(.system(size: 12, weight: .medium))

                if let windowTitle, !windowTitle.isEmpty {
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(windowTitle)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .font(.system(size: 12))

            TextEditor(text: $text)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 72, maxHeight: 140)
                .focused($isFocused)

            HStack {
                Text(createdAt, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)

                Spacer()

                Button("Archive", role: .destructive, action: onArchive)
                    .buttonStyle(.borderless)

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
        .padding(14)
        .frame(width: 320)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 0.5)
        }
        .onAppear {
            DispatchQueue.main.async {
                isFocused = true
            }
        }
    }
}
