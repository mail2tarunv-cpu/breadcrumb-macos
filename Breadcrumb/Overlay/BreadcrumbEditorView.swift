import SwiftUI

struct BreadcrumbEditorView: View {
    @State private var text: String
    @FocusState private var isFocused: Bool
    @State private var isConfirmingDelete = false

    let applicationName: String
    let windowTitle: String?
    let createdAt: Date
    let breadcrumbColor: BreadcrumbColor
    let onColorChange: (BreadcrumbColor) -> Void
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
        breadcrumbColor: BreadcrumbColor,
        onColorChange: @escaping (BreadcrumbColor) -> Void,
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
        self.breadcrumbColor = breadcrumbColor
        self.onColorChange = onColorChange
        self.onSave = onSave
        self.onArchive = onArchive
        self.onDelete = onDelete
        self.onSnooze = onSnooze
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Menu {
                    ForEach(BreadcrumbColor.allCases) { color in
                        Button {
                            onColorChange(color)
                        } label: {
                            Label {
                                Text(color.name)
                            } icon: {
                                Image(systemName: breadcrumbColor == color ? "checkmark.circle.fill" : "circle.fill")
                            }
                        }
                    }
                } label: {
                    Circle()
                        .fill(breadcrumbColor.color)
                        .frame(width: 9, height: 9)
                        .contentShape(Circle())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Change breadcrumb color")

                VStack(alignment: .leading, spacing: 0) {
                    Text(applicationName)
                        .font(.system(size: 12, weight: .semibold))

                    if let windowTitle, !windowTitle.isEmpty {
                        Text(windowTitle)
                            .font(.system(size: 9.5))
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 10)

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
                    Button("Delete…", systemImage: "trash", role: .destructive) {
                        withAnimation(.easeOut(duration: 0.12)) {
                            isConfirmingDelete = true
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 11, weight: .semibold))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .semibold))
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("Close")
            }
            .padding(.horizontal, 13)
            .padding(.top, 10)
            .padding(.bottom, 4)

            TextEditor(text: $text)
                .font(.system(size: 14.5))
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .focused($isFocused)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(minHeight: 76, maxHeight: 108)
                .background(.clear)

            if isConfirmingDelete {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Delete breadcrumb?")
                            .font(.system(size: 11.5, weight: .semibold))
                        Text("This can’t be undone.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.primary.opacity(0.035))
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Text("Left")
                        Text(createdAt, style: .relative)
                    }
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)

                    Spacer()

                    Text("⌘↩")
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundStyle(.quaternary)

                    Button("Save") {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                    }
                    .keyboardShortcut(.return, modifiers: [.command])
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 13)
                .padding(.top, 2)
                .padding(.bottom, 9)
            }
        }
        .frame(width: 316)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 0.5)
        }
        .shadow(radius: 16, y: 7)
        .onAppear {
            DispatchQueue.main.async { isFocused = true }
        }
    }
}
