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
        },
        onReopen: { [weak self] id in
            self?.overlayManager.reopen(id)
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
    private var shortcutObserver: NSObjectProtocol?
    private var workspaceLaunchObserver: NSObjectProtocol?
    private var workspaceTerminateObserver: NSObjectProtocol?

    deinit {
        if let shortcutObserver {
            NotificationCenter.default.removeObserver(shortcutObserver)
        }
        if let workspaceLaunchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceLaunchObserver)
        }
        if let workspaceTerminateObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceTerminateObserver)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        BreadcrumbPreferences.registerDefaults()
        BreadcrumbPreferences.applyAppearance()
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

        shortcutObserver = NotificationCenter.default.addObserver(
            forName: HotKeyManager.shortcutDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildMenu()
        }

        ComposerController.shared = composerController
        overlayManager.start()

        workspaceLaunchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }

            // Newly launched apps can take a moment before their AX window
            // hierarchy is queryable. Refresh again after the window exists.
            self.scheduleContextRefresh()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                self.scheduleContextRefresh()
            }
        }

        workspaceTerminateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleContextRefresh()
        }

        if !PermissionManager.hasAccessibilityAccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                PermissionManager.requestAccessibilityAccess()
            }
        }

        if !UserDefaults.standard.bool(forKey: "breadcrumb.onboarding.completed") {
            onboardingController.present()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        overlayManager.prepareForTermination()
    }

    private func configureMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = makeMenuBarIcon()
        statusItem.button?.imageScaling = .scaleProportionallyDown
        statusItem.button?.toolTip = "Breadcrumb"

        rebuildMenu()
    }

    private func makeMenuBarIcon() -> NSImage {
        // A small broken ring + dot: the ring represents context, and the
        // dot represents the thought left there. Draw at 2x and display at
        // menu-bar size for a cleaner Retina result.
        let image = NSImage(size: NSSize(width: 36, height: 36))
        image.lockFocus()

        let center = NSPoint(x: 18, y: 18)
        let ring = NSBezierPath()
        ring.lineWidth = 5.0
        ring.lineCapStyle = .round
        ring.appendArc(
            withCenter: center,
            radius: 12.5,
            startAngle: 45,
            endAngle: 320,
            clockwise: false
        )

        NSColor.labelColor.setStroke()
        ring.stroke()

        NSColor.systemOrange.setFill()
        // The dot follows the ring's 45° endpoint. Keeping its center on
        // that endpoint makes the mark read as one intentional symbol.
        NSBezierPath(
            ovalIn: NSRect(x: 24, y: 24, width: 8, height: 8)
        ).fill()

        image.unlockFocus()
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = false
        return image
    }

    private func scheduleContextRefresh() {
        DispatchQueue.main.async { [weak self] in
            self?.performContextRefresh()
        }
    }

    private func performContextRefresh() {
        // A short debounce lets the target app finish creating its focused
        // window before Accessibility is queried.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.overlayManager.refreshForWorkspaceChange()
        }
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let shortcut = CaptureShortcut.current
        let newItem = NSMenuItem(
            title: "New Breadcrumb    \(shortcut.title)",
            action: #selector(newBreadcrumb),
            keyEquivalent: ""
        )
        menu.addItem(newItem)

        menu.addItem(
            NSMenuItem(
                title: "Pick Up Where I Left Off…",
                action: #selector(resumeCurrentContext),
                keyEquivalent: ""
            )
        )

        let activeCount = overlayManager.allRecords.filter { !$0.isArchived && !$0.isSnoozed && !$0.isDone }.count
        let libraryTitle = activeCount == 0
            ? "Open Library…"
            : "Open Library…  \(activeCount)"

        menu.addItem(
            NSMenuItem(
                title: libraryTitle,
                action: #selector(openHistory),
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
