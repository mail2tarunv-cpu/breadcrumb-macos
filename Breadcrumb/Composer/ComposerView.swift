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
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "circle.dotted")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 3)

                VStack(alignment: .leading, spacing: 5) {
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
                            Text(contextLabel)
                                .font(.system(size: 10.5))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Window awareness unavailable")
                            .font(.system(size: 13, weight: .semibold))

                        Text("Check Accessibility permission, then try again.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                if contextAvailable {
                    Text("↩")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.tertiary)
                } else {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            HStack {
                Text("Enter to save")
                Spacer()
                Text("\((CaptureShortcut(rawValue: captureShortcutRaw) ?? .optionSpace).title)  ·  Shift↩ new line  ·  Esc close")
            }
            .font(.system(size: 9.5))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 14)
            .padding(.bottom, 9)
        }
        .frame(width: 390)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.primary.opacity(0.08), lineWidth: 0.5)
        }
        .shadow(radius: 18, y: 8)
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
