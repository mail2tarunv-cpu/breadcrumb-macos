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
    private var lastDecisionByRecord: [UUID: String] = [:]

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
        for record in records where !record.isArchived && record.hasStableContext {
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
            withTimeInterval: 0.15,
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
        guard context.hasStableIdentity else {
            DiagnosticLog.shared.record(
                category: "Capture",
                summary: "Rejected breadcrumb",
                detail: "Reason: context did not have a stable focused window identity."
            )
            return
        }

        let record = BreadcrumbRecord(
            text: text,
            context: context,
            anchorPoint: point
        )

        records.append(record)
        persist()

        DiagnosticLog.shared.record(
            category: "Capture",
            summary: "Saved breadcrumb in \(context.applicationName)",
            detail: [
                "id: \(record.id.uuidString)",
                "title: \(context.windowTitle ?? "nil")",
                "windowNumber: \(context.windowNumber.map(String.init) ?? "nil")",
                "anchor: \(NSStringFromPoint(point))"
            ].joined(separator: "\n")
        )

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

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Archived breadcrumb",
            detail: "id: \(id.uuidString)"
        )
    }

    func restore(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].isArchived = false
        records[index].updatedAt = Date()
        persist()

        if records[index].hasStableContext {
            createPanelIfNeeded(for: records[index])
        }

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

        if record.hasStableContext {
            createPanelIfNeeded(for: record)
        }
    }

    private func createPanelIfNeeded(for record: BreadcrumbRecord) {
        guard panels[record.id] == nil,
              !record.isArchived,
              record.hasStableContext else {
            return
        }

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
        panel.isMovableByWindowBackground = false
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

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Opened breadcrumb editor",
            detail: "id: \(id.uuidString)\ntext: \(record.text)"
        )

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
        guard let context = preferredContext ?? contextObserver.captureCurrent() else {
            for record in records where !record.isArchived {
                decide(record: record, visible: false, reason: "No stable focused window context")
                panels[record.id]?.orderOut(nil)
            }
            editorController.dismiss()
            return
        }

        for record in records where !record.isArchived {
            guard let panel = panels[record.id] else { continue }

            if context.matches(record) {
                let point = record.anchorPoint(in: context.windowFrame)
                reposition(panel, recordID: record.id, center: point)
                panel.orderFrontRegardless()
                decide(record: record, visible: true, reason: matchReason(record: record, context: context))
            } else {
                panel.orderOut(nil)
                decide(record: record, visible: false, reason: mismatchReason(record: record, context: context))
            }
        }
    }

    private func matchReason(record: BreadcrumbRecord, context: ContextSnapshot) -> String {
        if let savedPID = record.processIdentifier,
           let currentPID = context.processIdentifier,
           savedPID == currentPID,
           record.windowNumber != nil,
           context.windowNumber != nil {
            return "Matched bundle + title + same-session window number"
        }

        return "Matched bundle + persisted window title"
    }

    private func mismatchReason(record: BreadcrumbRecord, context: ContextSnapshot) -> String {
        if record.bundleIdentifier != context.bundleIdentifier {
            return "Bundle mismatch: saved \(record.bundleIdentifier), current \(context.bundleIdentifier)"
        }

        let savedTitle = record.windowTitle ?? "nil"
        let currentTitle = context.windowTitle ?? "nil"

        if savedTitle != currentTitle {
            return "Window title mismatch: saved [\(savedTitle)] current [\(currentTitle)]"
        }

        if let savedPID = record.processIdentifier,
           let currentPID = context.processIdentifier,
           savedPID == currentPID,
           let savedWindow = record.windowNumber,
           let currentWindow = context.windowNumber,
           savedWindow != currentWindow {
            return "Same app/title but different window number: saved \(savedWindow), current \(currentWindow)"
        }

        return "Context did not satisfy strict match"
    }

    private func decide(record: BreadcrumbRecord, visible: Bool, reason: String) {
        let decision = "\(visible ? "SHOW" : "HIDE")|\(reason)"
        guard lastDecisionByRecord[record.id] != decision else { return }
        lastDecisionByRecord[record.id] = decision

        DiagnosticLog.shared.record(
            category: "Match",
            summary: "\(visible ? "SHOW" : "HIDE") · \(record.applicationName)",
            detail: [
                "breadcrumb: \(record.id.uuidString)",
                "text: \(record.text)",
                "reason: \(reason)"
            ].joined(separator: "\n")
        )
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

    func windowDidMove(_ notification: Notification) {
        // Marker dragging is intentionally disabled while we validate click
        // handling and exact-context matching. Re-enable drag after those are
        // stable.
    }
}
