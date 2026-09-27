import AppKit
import SwiftUI

final class OverlayManager {
    private struct Marker {
        let id = UUID()
        let text: String
        let bundleIdentifier: String
        let panel: NSPanel
    }

    private var markers: [Marker] = []
    private var observer: NSObjectProtocol?

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func startObservingApplications() {
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshVisibility()
        }
    }

    func addBreadcrumb(text: String, near point: NSPoint) {
        guard let activeApp = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = activeApp.bundleIdentifier else {
            return
        }

        let panel = makeMarkerPanel(text: text, point: point)
        let marker = Marker(text: text, bundleIdentifier: bundleIdentifier, panel: panel)
        markers.append(marker)

        panel.orderFrontRegardless()
        refreshVisibility()
    }

    private func makeMarkerPanel(text: String, point: NSPoint) -> NSPanel {
        let size = NSSize(width: 18, height: 18)
        let origin = NSPoint(x: point.x - 9, y: point.y - 9)

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.contentView = NSHostingView(rootView: BreadcrumbMarkerView(text: text))

        return panel
    }

    private func refreshVisibility() {
        guard let activeBundle = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            markers.forEach { $0.panel.orderOut(nil) }
            return
        }

        for marker in markers {
            if marker.bundleIdentifier == activeBundle {
                marker.panel.orderFrontRegardless()
            } else {
                marker.panel.orderOut(nil)
            }
        }
    }
}
