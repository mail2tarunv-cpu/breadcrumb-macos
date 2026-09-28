import AppKit
import SwiftUI

final class ContextStackController {
    private var panel: NSPanel?

    var isPresented: Bool {
        panel?.isVisible == true
    }

    func present(
        records: [BreadcrumbRecord],
        in windowFrame: CGRect?,
        onOpen: @escaping () -> Void
    ) {
        guard !records.isEmpty else {
            dismiss()
            return
        }

        let size = NSSize(width: 154, height: 34)

        let center: CGPoint
        if let frame = windowFrame {
            center = CGPoint(
                x: frame.maxX - size.width / 2 - 14,
                y: frame.maxY - size.height / 2 - 14
            )
        } else if let screen = NSScreen.main {
            center = CGPoint(
                x: screen.visibleFrame.maxX - size.width / 2 - 16,
                y: screen.visibleFrame.maxY - size.height / 2 - 16
            )
        } else {
            center = CGPoint(x: size.width / 2, y: size.height / 2)
        }

        let targetFrame = NSRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )

        let rootView = ContextStackView(
            records: records,
            onOpen: onOpen
        )

        if let panel {
            panel.setFrame(targetFrame, display: true)
            panel.contentView = NSHostingView(rootView: rootView)
            panel.orderFrontRegardless()
            return
        }

        let panel = NSPanel(
            contentRect: targetFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.contentView = NSHostingView(rootView: rootView)
        panel.orderFrontRegardless()

        self.panel = panel
    }

    func dismiss() {
        panel?.orderOut(nil)
    }
}
