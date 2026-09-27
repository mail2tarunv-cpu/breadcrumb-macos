import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let overlayManager = OverlayManager()
    private var hotKeyManager: HotKeyManager!
    private var composerController: ComposerController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        configureMenuBar()

        composerController = ComposerController { [weak self] text, point in
            self?.overlayManager.addBreadcrumb(text: text, near: point)
        }

        hotKeyManager = HotKeyManager {
            ComposerController.presentFromGlobalShortcut()
        }

        ComposerController.shared = composerController
        overlayManager.startObservingApplications()
    }

    private func configureMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "circle.dotted",
            accessibilityDescription: "Breadcrumb"
        )

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "New Breadcrumb", action: #selector(newBreadcrumb), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Breadcrumb", action: #selector(quit), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc private func newBreadcrumb() {
        composerController.present()
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
