import AppKit
import SwiftUI

private final class MarkerHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }
}

final class OverlayManager: NSObject, NSWindowDelegate {
    private let contextObserver: ContextObserver
    private let store: BreadcrumbStore
    private let editorController = BreadcrumbEditorController()

    private var records: [BreadcrumbRecord]
    private var panels: [UUID: NSPanel] = [:]
    private var panelToRecord: [ObjectIdentifier: UUID] = [:]
    private var workspaceObserver: NSObjectProtocol?
    private var refreshTimer: Timer?
    private var programmaticMoves: Set<UUID> = []

    init(contextObserver: ContextObserver, store: BreadcrumbStore) {
        self.contextObserver = contextObserver
        self.store = store
        self.records = store.load()
        super.init()
    }

    deinit {
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
        refreshTimer?.invalidate()
    }

    var allRecords: [BreadcrumbRecord] {
        records
    }

    func start() {
        for record in records where !record.isArchived {
            createPanelIfNeeded(for: record)
        }

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }

        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: 0.12,
            repeats: true
        ) { [weak self] _ in
            self?.refresh()
        }

        refresh()
    }

    func addBreadcrumb(
        text: String,
        near point: NSPoint,
        context: ContextSnapshot
    ) {
        let record = BreadcrumbRecord(
            text: text,
            context: context,
            anchorPoint: point
        )

        records.append(record)
        persist()

        createPanelIfNeeded(for: record)
        refresh(preferredContext: context)
    }

    func archive(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].isArchived = true
        records[index].updatedAt = Date()
        persist()

        panels[id]?.orderOut(nil)
        editorController.dismiss()
    }

    func restore(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].isArchived = false
        records[index].updatedAt = Date()
        persist()

        createPanelIfNeeded(for: records[index])
        refresh()
    }

    func updateText(_ id: UUID, text: String) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].text = text
        records[index].updatedAt = Date()
        persist()
        rebuildPanel(for: records[index])
        refresh()
    }

    private func persist() {
        store.save(records)
    }

    private func rebuildPanel(for record: BreadcrumbRecord) {
        if let oldPanel = panels[record.id] {
            panelToRecord.removeValue(forKey: ObjectIdentifier(oldPanel))
            oldPanel.orderOut(nil)
            panels.removeValue(forKey: record.id)
        }

        createPanelIfNeeded(for: record)
    }

    private func createPanelIfNeeded(for record: BreadcrumbRecord) {
        guard panels[record.id] == nil, !record.isArchived else { return }

        let size = NSSize(width: 24, height: 24)
        let fallbackPoint = record.anchorPoint(in: nil)

        let panel = NSPanel(
            contentRect: NSRect(
                x: fallbackPoint.x - size.width / 2,
                y: fallbackPoint.y - size.height / 2,
                width: size.width,
                height: size.height
            ),
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
        panel.ignoresMouseEvents = false
        panel.delegate = self

        let rootView = BreadcrumbMarkerView(
            text: record.text,
            applicationName: record.applicationName,
            onOpen: { [weak self] in
                self?.openEditor(for: record.id)
            }
        )

        panel.contentView = MarkerHostingView(rootView: rootView)

        panels[record.id] = panel
        panelToRecord[ObjectIdentifier(panel)] = record.id
    }

    private func openEditor(for id: UUID) {
        guard let record = records.first(where: { $0.id == id }),
              let panel = panels[id] else {
            return
        }

        let anchorPoint = CGPoint(
            x: panel.frame.midX,
            y: panel.frame.midY
        )

        editorController.present(
            record: record,
            near: anchorPoint,
            onSave: { [weak self] text in
                self?.updateText(id, text: text)
            },
            onArchive: { [weak self] in
                self?.archive(id)
            }
        )
    }

    private func refresh(preferredContext: ContextSnapshot? = nil) {
        guard let activeBundle = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else {
            hideAll()
            return
        }

        let context: ContextSnapshot?
        if let preferredContext, preferredContext.bundleIdentifier == activeBundle {
            context = preferredContext
        } else {
            context = contextObserver.captureCurrent()
        }

        for index in records.indices where !records[index].isArchived {
            let record = records[index]
            guard let panel = panels[record.id] else { continue }

            // Bundle identity is the hard boundary. This prevents a breadcrumb
            // from following the user onto Finder/Desktop or another app even
            // if Accessibility briefly reports stale window metadata.
            guard record.bundleIdentifier == activeBundle else {
                panel.orderOut(nil)
                continue
            }

            if let context, !context.matches(record) {
                panel.orderOut(nil)
                continue
            }

            let point = record.anchorPoint(in: context?.windowFrame)
            reposition(panel, recordID: record.id, center: point)
            panel.orderFrontRegardless()
        }
    }

    private func reposition(
        _ panel: NSPanel,
        recordID: UUID,
        center point: CGPoint
    ) {
        let origin = CGPoint(
            x: point.x - panel.frame.width / 2,
            y: point.y - panel.frame.height / 2
        )

        guard abs(panel.frame.origin.x - origin.x) > 0.5
                || abs(panel.frame.origin.y - origin.y) > 0.5 else {
            return
        }

        programmaticMoves.insert(recordID)
        panel.setFrameOrigin(origin)
        programmaticMoves.remove(recordID)
    }

    private func hideAll() {
        panels.values.forEach { $0.orderOut(nil) }
        editorController.dismiss()
    }

    func windowDidMove(_ notification: Notification) {
        guard let panel = notification.object as? NSPanel,
              let recordID = panelToRecord[ObjectIdentifier(panel)],
              !programmaticMoves.contains(recordID),
              let recordIndex = records.firstIndex(where: { $0.id == recordID }),
              let context = contextObserver.captureCurrent(),
              context.matches(records[recordIndex]),
              let frame = context.windowFrame,
              frame.width > 0,
              frame.height > 0 else {
            return
        }

        let center = CGPoint(
            x: panel.frame.midX,
            y: panel.frame.midY
        )

        records[recordIndex].relativeX = min(
            max((center.x - frame.minX) / frame.width, 0),
            1
        )
        records[recordIndex].relativeY = min(
            max((center.y - frame.minY) / frame.height, 0),
            1
        )
        records[recordIndex].updatedAt = Date()

        persist()
    }
}
