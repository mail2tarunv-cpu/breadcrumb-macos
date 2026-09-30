import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?
    private let onOpenLibrary: () -> Void
    private let onOpenDiagnostics: () -> Void
    private let onShowOnboarding: () -> Void

    init(
        onOpenLibrary: @escaping () -> Void,
        onOpenDiagnostics: @escaping () -> Void,
        onShowOnboarding: @escaping () -> Void
    ) {
        self.onOpenLibrary = onOpenLibrary
        self.onOpenDiagnostics = onOpenDiagnostics
        self.onShowOnboarding = onShowOnboarding
    }

    func present() {
        let view = SettingsView(
            onOpenLibrary: onOpenLibrary,
            onOpenDiagnostics: onOpenDiagnostics,
            onShowOnboarding: onShowOnboarding
        )

        if let window {
            window.contentView = NSHostingView(rootView: view)
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
