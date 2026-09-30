import SwiftUI

struct BreadcrumbEditorView: View {
    @State private var text: String
    @FocusState private var isFocused: Bool
    @State private var isConfirmingDelete = false
    @State private var selectedColor: Color

    let applicationName: String
    let windowTitle: String?
    let createdAt: Date
    let onColorChange: (Color) -> Void
    let onDone: () -> Void
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
        accentColor: Color,
        onColorChange: @escaping (Color) -> Void,
        onDone: @escaping () -> Void,
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
        _selectedColor = State(initialValue: accentColor)
        self.onColorChange = onColorChange
        self.onDone = onDone
        self.onSave = onSave
        self.onArchive = onArchive
        self.onDelete = onDelete
        self.onSnooze = onSnooze
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
                    .contentShape(Circle())
                    .help("Choose breadcrumb color")
                    .onChange(of: selectedColor) { _, newColor in
                        onColorChange(newColor)
                    }

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
                    Button("Mark Done", systemImage: "checkmark.circle") {
                        onDone()
                    }
                    Divider()
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
                .menuIndicator(.hidden)
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
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .frame(minHeight: 76, maxHeight: 108)
                .background(Color.clear)
                .padding(.horizontal, 10)
                .padding(.vertical, 3)

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
                .stroke(.primary.opacity(0.04), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.13), radius: 14, y: 6)
        .onAppear {
            DispatchQueue.main.async { isFocused = true }
        }
    }
}
