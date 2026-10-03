import AppKit
import SwiftUI

private final class BreadcrumbEditorPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class BreadcrumbEditorController {
    private var panel: NSPanel?
    private var onDismiss: (() -> Void)?

    func present(
        record: BreadcrumbRecord,
        near anchorPoint: CGPoint,
        onSave: @escaping (String) -> Void,
        onColorChange: @escaping (BreadcrumbColor) -> Void,
        onDone: @escaping () -> Void,
        onArchive: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSnooze: @escaping (Date) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        dismiss()

        let size = NSSize(width: 316, height: 164)
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
        panel.hasShadow = false
        panel.level = NSWindow.Level(
            rawValue: NSWindow.Level.floating.rawValue + 2
        )
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = false

        let view = BreadcrumbEditorView(
            text: record.text,
            applicationName: record.applicationName,
            windowTitle: record.windowTitle,
            createdAt: record.createdAt,
            breadcrumbColor: record.breadcrumbColor,
            onColorChange: onColorChange,
            onDone: { [weak self] in
                onDone()
                self?.dismiss()
            },
            onSave: { [weak self] text in
                onSave(text)
                self?.dismiss()
            },
            onArchive: { [weak self] in
                onArchive()
                self?.dismiss()
            },
            onDelete: { [weak self] in
                onDelete()
                self?.dismiss()
            },
            onSnooze: { [weak self] date in
                onSnooze(date)
                self?.dismiss()
            },
            onClose: { [weak self] in
                self?.dismiss()
            }
        )

        self.onDismiss = onDismiss
        panel.contentView = NSHostingView(rootView: view)
        panel.orderFrontRegardless()
        panel.makeKeyAndOrderFront(nil)
        self.panel = panel

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Editor panel presented",
            detail: [
                "breadcrumb: \(record.id.uuidString)",
                "anchor: \(NSStringFromPoint(anchorPoint))",
                "panelFrame: \(NSStringFromRect(panel.frame))"
            ].joined(separator: "\n")
        )
    }

    func dismiss() {
        let callback = onDismiss
        onDismiss = nil
        panel?.orderOut(nil)
        panel = nil
        callback?()
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
