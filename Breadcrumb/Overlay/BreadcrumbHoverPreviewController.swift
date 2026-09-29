import AppKit
import SwiftUI

final class BreadcrumbHoverPreviewController {
    private var panel: NSPanel?
    private var showWorkItem: DispatchWorkItem?
    private var hideWorkItem: DispatchWorkItem?
    private var currentRecordID: UUID?

    func scheduleShow(record: BreadcrumbRecord, anchor: CGPoint) {
        hideWorkItem?.cancel()
        showWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.show(record: record, anchor: anchor)
        }
        showWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: workItem)
    }

    func scheduleHide() {
        showWorkItem?.cancel()
        hideWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.dismiss()
        }
        hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08, execute: workItem)
    }

    func dismiss() {
        showWorkItem?.cancel()
        hideWorkItem?.cancel()
        currentRecordID = nil
        panel?.orderOut(nil)
    }

    private func show(record: BreadcrumbRecord, anchor: CGPoint) {
        currentRecordID = record.id

        let width: CGFloat = 280
        let textWidth = width - 42
        let font = NSFont.systemFont(ofSize: 12.5, weight: .medium)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]

        let bounding = (record.text as NSString).boundingRect(
            with: NSSize(width: textWidth, height: 1000),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes
        )

        let height = min(max(58 + ceil(bounding.height), 72), 240)
        let size = NSSize(width: width, height: height)

        let preferred = CGPoint(
            x: anchor.x + 12,
            y: anchor.y - size.height / 2
        )

        let origin = constrainedOrigin(
            preferred: preferred,
            size: size,
            anchor: anchor
        )

        let frame = NSRect(origin: origin, size: size)

        let preview = BreadcrumbHoverPreviewView(record: record)

        if let panel {
            panel.setFrame(frame, display: true)
            panel.contentView = NSHostingView(rootView: preview)
            panel.orderFrontRegardless()
            return
        }

        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = NSWindow.Level(
            rawValue: NSWindow.Level.floating.rawValue + 1
        )
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true
        panel.contentView = NSHostingView(rootView: preview)
        panel.orderFrontRegardless()

        self.panel = panel
    }

    private func constrainedOrigin(
        preferred: CGPoint,
        size: NSSize,
        anchor: CGPoint
    ) -> CGPoint {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(anchor) }) ?? NSScreen.main else {
            return preferred
        }

        let frame = screen.visibleFrame
        var x = preferred.x
        var y = preferred.y

        if x + size.width > frame.maxX - 8 {
            x = anchor.x - size.width - 12
        }

        x = min(max(x, frame.minX + 8), frame.maxX - size.width - 8)
        y = min(max(y, frame.minY + 8), frame.maxY - size.height - 8)

        return CGPoint(x: x, y: y)
    }
}
