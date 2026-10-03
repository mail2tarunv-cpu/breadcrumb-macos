import AppKit
import SwiftUI

struct ComposerView: View {
    @State private var text = ""
    @State private var editorHeight: CGFloat = 24
    @AppStorage("breadcrumb.capture.shortcut") private var captureShortcutRaw = CaptureShortcut.optionSpace.rawValue

    let contextAvailable: Bool
    let contextLabel: String?
    let onSubmit: (String) -> Void
    let onCancel: () -> Void
    let onHeightChange: (CGFloat) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 11) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(.primary.opacity(0.055))
                        .frame(width: 28, height: 28)

                    Image(systemName: "circle.dotted")
                        .font(.system(size: 13.5, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("New breadcrumb")
                            .font(.system(size: 12.5, weight: .semibold))

                        if contextAvailable {
                            Text("Capture")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(.primary.opacity(0.055), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        }
                    }

                    if contextAvailable {
                        GrowingComposerTextView(
                            text: $text,
                            height: $editorHeight,
                            placeholder: "Leave a thought here…",
                            onSubmit: submit,
                            onCancel: onCancel
                        )
                        .frame(height: editorHeight)

                        if let contextLabel, !contextLabel.isEmpty {
                            HStack(spacing: 5) {
                                Image(systemName: "scope")
                                    .font(.system(size: 8.5, weight: .medium))

                                Text(contextLabel)
                                    .lineLimit(1)
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                    } else {
                        Text("Window awareness unavailable")
                            .font(.system(size: 13, weight: .semibold))

                        Text("Check Accessibility permission, then try again.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 4)

                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                        .frame(width: 24, height: 24)
                        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Close")
            }
            .padding(.horizontal, 14)
            .padding(.top, 13)
            .padding(.bottom, 10)

            Divider()
                .opacity(0.22)

            HStack(spacing: 6) {
                Text("Enter")
                    .fontWeight(.medium)

                Text("save")
                    .foregroundStyle(.secondary)

                Text("·")

                Text("((CaptureShortcut(rawValue: captureShortcutRaw) ?? .optionSpace).title)")
                Text("capture")

                Text("·")

                Text("Shift↩")
                Text("new line")

                Spacer(minLength: 8)

                Text("Esc")
                Text("close")
            }
            .font(.system(size: 9.5))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
        .frame(width: 382)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.035))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.11), lineWidth: 0.55)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        .onChange(of: editorHeight) { _, newHeight in
            onHeightChange(newHeight)
        }
    }

    private func submit() {
        guard contextAvailable else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmit(trimmed)
    }
}

private struct GrowingComposerTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat

    let placeholder: String
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = ComposerNSTextView()
        textView.delegate = context.coordinator
        textView.onSubmit = onSubmit
        textView.onCancel = onCancel
        textView.isRichText = false
        textView.drawsBackground = false
        textView.font = .systemFont(ofSize: 15)
        textView.textColor = .labelColor
        textView.insertionPointColor = .labelColor
        textView.textContainerInset = NSSize(width: 0, height: 1)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.setAccessibilityLabel("New breadcrumb")

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.borderType = .noBorder
        scrollView.documentView = textView

        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
            context.coordinator.updateHeight(for: textView)
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? ComposerNSTextView else { return }

        textView.onSubmit = onSubmit
        textView.onCancel = onCancel

        if textView.string != text {
            textView.string = text
        }

        context.coordinator.parent = self
        DispatchQueue.main.async {
            context.coordinator.updateHeight(for: textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: GrowingComposerTextView

        init(_ parent: GrowingComposerTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            updateHeight(for: textView)
        }

        func updateHeight(for textView: NSTextView) {
            guard let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else {
                return
            }

            layoutManager.ensureLayout(for: textContainer)
            let usedHeight = ceil(layoutManager.usedRect(for: textContainer).height + 4)
            let nextHeight = min(max(usedHeight, 24), 96)

            if abs(parent.height - nextHeight) > 0.5 {
                parent.height = nextHeight
            }
        }
    }
}

private final class ComposerNSTextView: NSTextView {
    var onSubmit: (() -> Void)?
    var onCancel: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onCancel?()
            return
        }

        if event.keyCode == 36 || event.keyCode == 76 {
            if event.modifierFlags.contains(.shift) {
                insertNewline(nil)
            } else {
                onSubmit?()
            }
            return
        }

        super.keyDown(with: event)
    }
}
