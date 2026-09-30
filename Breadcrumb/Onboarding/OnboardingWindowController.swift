import AppKit
import SwiftUI

final class OnboardingWindowController {
    private var window: NSWindow?
    private var permissionTimer: Timer?
    private let onFinish: () -> Void

    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    deinit {
        permissionTimer?.invalidate()
    }

    func present() {
        render()

        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self, self.window?.isVisible == true else { return }
            self.render()
        }
    }

    private func render() {
        let view = OnboardingView(
            hasAccessibilityAccess: PermissionManager.hasAccessibilityAccess,
            onEnableAccessibility: {
                PermissionManager.requestAccessibilityAccess()
            },
            onFinish: { [weak self] in
                UserDefaults.standard.set(true, forKey: "breadcrumb.onboarding.completed")
                self?.window?.close()
                self?.permissionTimer?.invalidate()
                self?.onFinish()
            }
        )

        if let window {
            window.contentView = NSHostingView(rootView: view)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 620),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "Welcome to Breadcrumb"
        window.titleVisibility = .visible
        window.isReleasedWhenClosed = false
        window.center()
        window.contentView = NSHostingView(rootView: view)
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
