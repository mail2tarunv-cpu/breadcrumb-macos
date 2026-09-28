import AppKit
import SwiftUI

final class DiagnosticsWindowController {
    private var window: NSWindow?

    func present() {
        let view = DiagnosticsView(
            events: DiagnosticLog.shared.events,
            onRefresh: {
                DiagnosticLog.shared.events
            },
            onClear: {
                DiagnosticLog.shared.clear()
            }
        )

        if let window {
            window.contentView = NSHostingView(rootView: view)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Breadcrumb Diagnostics"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
