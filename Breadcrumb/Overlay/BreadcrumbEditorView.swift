import SwiftUI

struct BreadcrumbEditorView: View {
    @State private var text: String
    @FocusState private var isFocused: Bool
    @State private var isConfirmingDelete = false
    @State private var selectedColor: BreadcrumbColor
    @State private var isColorPickerExpanded = false
    @AppStorage(BreadcrumbPreferences.reducedMotionKey) private var reducedMotion = false
    @AppStorage(BreadcrumbPreferences.shadowStrengthKey) private var shadowStrengthRaw = BreadcrumbShadowStrength.standard.rawValue

    let applicationName: String
    let windowTitle: String?
    let createdAt: Date
    let onColorChange: (BreadcrumbColor) -> Void
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
        breadcrumbColor: BreadcrumbColor,
        onColorChange: @escaping (BreadcrumbColor) -> Void,
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
        _selectedColor = State(initialValue: breadcrumbColor)
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
                Button {
                    withAnimation(reducedMotion ? nil : .easeOut(duration: 0.14)) {
                        isColorPickerExpanded.toggle()
                    }
                } label: {
                    Circle()
                        .fill(selectedColor.color.opacity(0.92))
                        .frame(width: 15, height: 15)
                        .overlay {
                            Circle()
                                .fill(.white.opacity(0.16))
                                .frame(width: 2, height: 2)
                                .offset(x: -1, y: -1)
                        }
                        .shadow(
                            color: selectedColor.color.opacity(0.14),
                            radius: 1.5,
                            y: 0.5
                        )
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .help("Change color")

                if isColorPickerExpanded {
                    HStack(spacing: 5) {
                        ForEach(BreadcrumbColor.allCases) { color in
                            Button {
                                selectedColor = color
                                onColorChange(color)
                                withAnimation(reducedMotion ? nil : .easeOut(duration: 0.12)) {
                                    isColorPickerExpanded = false
                                }
                            } label: {
                                Circle()
                                    .fill(color.color.opacity(selectedColor == color ? 0.94 : 0.76))
                                    .frame(width: 12, height: 12)
                                    .overlay {
                                        if selectedColor == color {
                                            Circle()
                                                .stroke(.white.opacity(0.40), lineWidth: 0.8)
                                                .frame(width: 17, height: 17)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .help(color.name)
                        }
                    }
                    .transition(
                        reducedMotion
                            ? .opacity
                            : .opacity.combined(with: .scale(scale: 0.96, anchor: .leading))
                    )
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(applicationName)
                        .font(.system(size: 12, weight: .semibold))

                    if let windowTitle, !windowTitle.isEmpty {
                        Text(windowTitle)
                            .font(.system(size: 9.25, weight: .regular))
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
                        if reducedMotion {
                            isConfirmingDelete = true
                        } else {
                            withAnimation(.easeOut(duration: 0.12)) {
                                isConfirmingDelete = true
                            }
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
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 2)

            TextEditor(text: $text)
                .font(.system(size: 14.5))
                .scrollContentBackground(.hidden)
                .scrollIndicators(.never)
                .focused($isFocused)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(height: 58)
                .background(Color.clear)
                .padding(.horizontal, 9)
                .padding(.vertical, 2)

            if isConfirmingDelete {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Delete breadcrumb?")
                            .font(.system(size: 11.5, weight: .medium))
                        Text("This can’t be undone.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Cancel") {
                        if reducedMotion {
                            isConfirmingDelete = false
                        } else {
                            withAnimation(.easeOut(duration: 0.12)) {
                                isConfirmingDelete = false
                            }
                        }
                    }
                    .controlSize(.small)

                    Button("Delete", role: .destructive, action: onDelete)
                        .controlSize(.small)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
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
                .padding(.horizontal, 12)
                .padding(.top, 1)
                .padding(.bottom, 7)
            }
        }
        .frame(width: 320)
        // Same visual material as the collapsed breadcrumb; the editor is
        // the breadcrumb opened up, not a separate modal surface.
        .background {
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .fill(.thinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(.white.opacity(0.035))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .strokeBorder(.white.opacity(0.11), lineWidth: 0.55)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
        .shadow(color: .black.opacity(0.045), radius: 3, y: 1)
        .onAppear {
            DispatchQueue.main.async { isFocused = true }
        }
    }
}
