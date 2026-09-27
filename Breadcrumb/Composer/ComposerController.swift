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
        shared?.present()
    }

    func present() {
        dismiss()

        // Capture context before Breadcrumb presents any UI.
        guard let context = contextProvider() else { return }

        let pointer = NSEvent.mouseLocation
        let size = NSSize(width: 340, height: 46)
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

        let view = ComposerView(
            onSubmit: { [weak self] text in
                guard let self else { return }
                self.onCreate(text, pointer, context)
                self.dismiss()
            },
            onCancel: { [weak self] in
                self?.dismiss()
            }
        )

        panel.contentView = NSHostingView(rootView: view)

        // A non-activating panel keeps the originating app as the real context.
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
