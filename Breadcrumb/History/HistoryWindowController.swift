import AppKit
import SwiftUI

final class HistoryWindowController {
    private var window: NSWindow?
    private let recordsProvider: () -> [BreadcrumbRecord]
    private let onRestore: (UUID) -> Void
    private let onArchive: (UUID) -> Void
    private let onDelete: (UUID) -> Void

    init(
        recordsProvider: @escaping () -> [BreadcrumbRecord],
        onRestore: @escaping (UUID) -> Void,
        onArchive: @escaping (UUID) -> Void,
        onDelete: @escaping (UUID) -> Void
    ) {
        self.recordsProvider = recordsProvider
        self.onRestore = onRestore
        self.onArchive = onArchive
        self.onDelete = onDelete
    }

    func present() {
        let records = recordsProvider()
        let view = HistoryView(
            records: records,
            onRestore: { [weak self] id in
                self?.onRestore(id)
                self?.reload()
            },
            onArchive: { [weak self] id in
                self?.onArchive(id)
                self?.reload()
            },
            onDelete: { [weak self] id in
                self?.onDelete(id)
                self?.reload()
            }
        )

        if let window {
            window.contentView = NSHostingView(rootView: view)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Breadcrumbs"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }

    private func reload() {
        guard window?.isVisible == true else { return }
        present()
    }
}
