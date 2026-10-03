import SwiftUI

struct BreadcrumbEditorView: View {
    @State private var text: String
    @FocusState private var isFocused: Bool
    @State private var isConfirmingDelete = false
    @State private var selectedColor: BreadcrumbColor
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
                HStack(spacing: 5) {
                    ForEach(BreadcrumbColor.allCases) { color in
                        Button {
                            selectedColor = color
                            onColorChange(color)
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 15, height: 15)

                                if selectedColor == color {
                                    Circle()
                                        .stroke(.white.opacity(0.58), lineWidth: 1.0)
                                        .frame(width: 20, height: 20)
                                        .shadow(color: color.color.opacity(0.18), radius: 1.5)
                                }
                            }
                            .frame(width: 23, height: 23)
                            .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(color.name)
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text(applicationName)
                        .font(.system(size: 12, weight: .semibold))

                    if let windowTitle, !windowTitle.isEmpty {
                        Text(windowTitle)
                            .font(.system(size: 9.25))
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
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .white.opacity(0.08), location: 0),
                                    .init(color: .white.opacity(0.018), location: 0.48),
                                    .init(color: .clear, location: 1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: .black.opacity(0.16),
            radius: 15,
            y: 7
        )
        .shadow(
            color: .black.opacity(0.055),
            radius: 3,
            y: 1
        )
        .onAppear {
            DispatchQueue.main.async { isFocused = true }
        }
    }
}
