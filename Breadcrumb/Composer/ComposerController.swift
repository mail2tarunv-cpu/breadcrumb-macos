import AppKit
import SwiftUI

private final class ComposerPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class ComposerController {
    static weak var shared: ComposerController?

    private var panel: NSPanel?
    private let contextProvider: () -> ContextSnapshot?
    private let onCreate: (String, NSPoint, ContextSnapshot) -> Void

    init(
        contextProvider: @escaping () -> ContextSnapshot?,
        onCreate: @escaping (String, NSPoint, ContextSnapshot) -> Void
    ) {
        self.contextProvider = contextProvider
        self.onCreate = onCreate
    }

    static func presentFromGlobalShortcut() {
        DiagnosticLog.shared.record(
            category: "Hotkey",
            summary: "⌥ Space received",
            detail: "Opening composer."
        )
        shared?.present()
    }

    func present() {
        dismiss()

        // Context capture is intentionally optional here. The composer must
        // always appear so a failed context lookup can never masquerade as a
        // broken keyboard shortcut.
        let context = contextProvider()

        if context == nil {
            DiagnosticLog.shared.record(
                category: "Capture",
                summary: "Composer opened without precise context",
                detail: "The hotkey worked, but ContextObserver returned nil."
            )
        }

        let pointer = NSEvent.mouseLocation
        let width: CGFloat = 390
        let height: CGFloat = context == nil ? 96 : 92
        let size = NSSize(width: width, height: height)

        let origin = constrainedOrigin(
            preferred: NSPoint(
                x: pointer.x + 12,
                y: pointer.y - size.height - 8
            ),
            size: size,
            pointer: pointer
        )

        let panel = ComposerPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false

        let contextLabel: String?
        if let context {
            if let tab = context.selectedTabTitle, !tab.isEmpty {
                contextLabel = context.applicationName + " · " + tab
            } else if let title = context.windowTitle, !title.isEmpty {
                contextLabel = context.applicationName + " · " + title
            } else {
                contextLabel = context.applicationName
            }
        } else {
            contextLabel = nil
        }

        let view = ComposerView(
            contextAvailable: context != nil,
            contextLabel: contextLabel,
            onSubmit: { [weak self] text in
                guard let self, let context else { return }
                self.onCreate(text, pointer, context)
                self.dismiss()
            },
            onCancel: { [weak self] in
                self?.dismiss()
            },
            onHeightChange: { [weak self] editorHeight in
                self?.resizePanel(forEditorHeight: editorHeight)
            }
        )

        panel.contentView = NSHostingView(rootView: view)
        self.panel = panel

        // The composer is invoked from a global shortcut while another app
        // owns focus. Explicitly activate Breadcrumb before making the text
        // field first responder; otherwise the panel can appear correctly but
        // the first keystroke is swallowed until the user clicks.
        NSApp.activate(ignoringOtherApps: true)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)

    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }

    private func resizePanel(forEditorHeight editorHeight: CGFloat) {
        guard let panel else { return }

        let baseEditorHeight: CGFloat = 24
        let basePanelHeight: CGFloat = 92
        let targetHeight = basePanelHeight + max(editorHeight - baseEditorHeight, 0)

        guard abs(panel.frame.height - targetHeight) > 0.5 else { return }

        let currentTop = panel.frame.maxY
        var nextFrame = panel.frame
        nextFrame.size.height = targetHeight
        nextFrame.origin.y = currentTop - targetHeight
        panel.setFrame(nextFrame, display: true, animate: false)
    }

    private func constrainedOrigin(
        preferred: NSPoint,
        size: NSSize,
        pointer: NSPoint
    ) -> NSPoint {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(pointer) })
                ?? NSScreen.main else {
            return preferred
        }

        let frame = screen.visibleFrame
        let x = min(
            max(preferred.x, frame.minX + 8),
            frame.maxX - size.width - 8
        )
        let y = min(
            max(preferred.y, frame.minY + 8),
            frame.maxY - size.height - 8
        )

        return NSPoint(x: x, y: y)
    }
}
