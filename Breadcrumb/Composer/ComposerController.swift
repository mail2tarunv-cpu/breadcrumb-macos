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
        let width: CGFloat = 380
        let height: CGFloat = context == nil ? 76 : 58
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
            styleMask: [.borderless, .nonactivatingPanel],
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
            }
        )

        panel.contentView = NSHostingView(rootView: view)
        panel.orderFrontRegardless()
        panel.makeKey()

        self.panel = panel
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
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
