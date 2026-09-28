import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    private let contextObserver = ContextObserver()
    private let store = BreadcrumbStore()

    private lazy var overlayManager = OverlayManager(
        contextObserver: contextObserver,
        store: store
    )

    private lazy var historyController = HistoryWindowController(
        recordsProvider: { [weak self] in
            self?.overlayManager.allRecords ?? []
        },
        onRestore: { [weak self] id in
            self?.overlayManager.restore(id)
            self?.rebuildMenu()
        },
        onArchive: { [weak self] id in
            self?.overlayManager.archive(id)
            self?.rebuildMenu()
        },
        onDelete: { [weak self] id in
            self?.overlayManager.delete(id)
            self?.rebuildMenu()
        },
        onSnooze: { [weak self] id, date in
            self?.overlayManager.snooze(id, until: date)
            self?.rebuildMenu()
        },
        onWake: { [weak self] id in
            self?.overlayManager.wake(id)
            self?.rebuildMenu()
        }
    )

    private lazy var diagnosticsController = DiagnosticsWindowController()

    private lazy var settingsController = SettingsWindowController(
        onOpenLibrary: { [weak self] in
            self?.historyController.present()
        },
        onOpenDiagnostics: { [weak self] in
            self?.diagnosticsController.present()
        },
        onShowOnboarding: { [weak self] in
            self?.onboardingController.present()
        }
    )

    private lazy var onboardingController = OnboardingWindowController(
        onFinish: { [weak self] in
            self?.rebuildMenu()
        }
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
                self?.rebuildMenu()
            }
        )

        hotKeyManager = HotKeyManager {
            ComposerController.presentFromGlobalShortcut()
        }

        ComposerController.shared = composerController
        overlayManager.start()

        if !PermissionManager.hasAccessibilityAccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                PermissionManager.requestAccessibilityAccess()
            }
        }

        if !UserDefaults.standard.bool(forKey: "breadcrumb.onboarding.completed") {
            onboardingController.present()
        }
    }

    private func configureMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(
            systemSymbolName: "point.topleft.down.to.point.bottomright.curvepath",
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

        let activeCount = overlayManager.allRecords.filter { !$0.isArchived }.count
        let libraryTitle = activeCount == 0
            ? "Breadcrumbs…"
            : "Breadcrumbs…  \(activeCount)"

        menu.addItem(
            NSMenuItem(
                title: libraryTitle,
                action: #selector(openHistory),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            NSMenuItem(
                title: "Pick Up Where I Left Off…",
                action: #selector(resumeCurrentContext),
                keyEquivalent: ""
            )
        )

        menu.addItem(
            NSMenuItem(
                title: "Context Diagnostics…",
                action: #selector(openDiagnostics),
                keyEquivalent: ""
            )
        )

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

    @objc private func openHistory() {
        historyController.present()
    }

    @objc private func resumeCurrentContext() {
        overlayManager.presentResumeContext()
    }

    @objc private func openDiagnostics() {
        diagnosticsController.present()
    }

    @objc private func enableWindowAwareness() {
        PermissionManager.requestAccessibilityAccess()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.rebuildMenu()
        }
    }

    @objc private func openSettings() {
        settingsController.present()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
