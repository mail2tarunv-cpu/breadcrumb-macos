import AppKit
import SwiftUI

private final class ResumeContextPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

final class ResumeContextController {
    private var panel: NSPanel?

    var isPresented: Bool {
        panel?.isVisible == true
    }

    func present(
        applicationName: String,
        contextTitle: String?,
        records: [BreadcrumbRecord],
        near frame: CGRect?,
        onEdit: @escaping (UUID) -> Void,
        onArchive: @escaping (UUID) -> Void,
        onDone: @escaping (UUID) -> Void,
        onSnooze: @escaping (UUID, Date) -> Void
    ) {
        dismiss()

        guard !records.isEmpty else { return }

        let height = min(CGFloat(92 + min(records.count, 6) * 61 + 32), 430)
        let size = NSSize(width: 390, height: height)

        let origin: CGPoint
        if let frame {
            origin = CGPoint(
                x: max(frame.maxX - size.width - 18, 12),
                y: max(frame.maxY - size.height - 54, 12)
            )
        } else if let screen = NSScreen.main {
            origin = CGPoint(
                x: screen.visibleFrame.maxX - size.width - 24,
                y: screen.visibleFrame.maxY - size.height - 24
            )
        } else {
            origin = .zero
        }

        let panel = ResumeContextPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.titlebarSeparatorStyle = .none
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = false
        panel.isReleasedWhenClosed = false

        let view = ResumeContextView(
            applicationName: applicationName,
            contextTitle: contextTitle,
            records: records,
            onEdit: { [weak self] id in
                self?.dismiss()
                onEdit(id)
            },
            onArchive: { id in
                onArchive(id)
            },
            onDone: { id in
                onDone(id)
            },
            onSnooze: { id, date in
                onSnooze(id, date)
            },
            onClose: { [weak self] in
                self?.dismiss()
            }
        )

        panel.contentView = NSHostingView(rootView: view)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
    }
}
