import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    private let contextObserver = ContextObserver()
    private let store = BreadcrumbStore()

    private lazy var overlayManager = OverlayManager(
        contextObserver: contextObserver,
        store: store
    )

    private var hotKeyManager: HotKeyManager!
    private var composerController: ComposerController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        configureMenuBar()

        composerController = ComposerController(
            contextProvider: { [weak self] in
                self?.contextObserver.captureCurrent()
            },
            onCreate: { [weak self] text, point, context in
                self?.overlayManager.addBreadcrumb(
                    text: text,
                    near: point,
                    context: context
                )
            }
        )

        hotKeyManager = HotKeyManager {
            ComposerController.presentFromGlobalShortcut()
        }

        ComposerController.shared = composerController
        overlayManager.start()
    }

    private func configureMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "circle.dotted",
            accessibilityDescription: "Breadcrumb"
        )

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let newItem = NSMenuItem(
            title: "New Breadcrumb",
            action: #selector(newBreadcrumb),
            keyEquivalent: ""
        )
        newItem.keyEquivalentModifierMask = [.option]
        menu.addItem(newItem)

        if !PermissionManager.hasAccessibilityAccess {
            menu.addItem(.separator())
            menu.addItem(
                NSMenuItem(
                    title: "Enable Window Awareness…",
                    action: #selector(enableWindowAwareness),
                    keyEquivalent: ""
                )
            )
        }

        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Settings…",
                action: #selector(openSettings),
                keyEquivalent: ","
            )
        )
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit Breadcrumb",
                action: #selector(quit),
                keyEquivalent: "q"
            )
        )

        statusItem.menu = menu
    }

    @objc private func newBreadcrumb() {
        composerController.present()
    }

    @objc private func enableWindowAwareness() {
        PermissionManager.requestAccessibilityAccess()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.rebuildMenu()
        }
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
