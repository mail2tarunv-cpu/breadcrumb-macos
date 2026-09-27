import AppKit
import SwiftUI

private final class BreadcrumbEditorPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class BreadcrumbEditorController {
    private var panel: NSPanel?

    func present(
        record: BreadcrumbRecord,
        near anchorPoint: CGPoint,
        onSave: @escaping (String) -> Void,
        onArchive: @escaping () -> Void
    ) {
        dismiss()

        let size = NSSize(width: 320, height: 190)
        let preferred = NSPoint(
            x: anchorPoint.x + 12,
            y: anchorPoint.y - size.height / 2
        )

        let origin = constrainedOrigin(preferred: preferred, size: size, anchor: anchorPoint)

        let panel = BreadcrumbEditorPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = true

        let view = BreadcrumbEditorView(
            text: record.text,
            applicationName: record.applicationName,
            windowTitle: record.windowTitle,
            createdAt: record.createdAt,
            onSave: { [weak self] text in
                onSave(text)
                self?.dismiss()
            },
            onArchive: { [weak self] in
                onArchive()
                self?.dismiss()
            },
            onClose: { [weak self] in
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
        anchor: CGPoint
    ) -> NSPoint {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor) }) ?? NSScreen.main else {
            return preferred
        }

        let frame = screen.visibleFrame
        let x = min(max(preferred.x, frame.minX + 10), frame.maxX - size.width - 10)
        let y = min(max(preferred.y, frame.minY + 10), frame.maxY - size.height - 10)

        return NSPoint(x: x, y: y)
    }
}
