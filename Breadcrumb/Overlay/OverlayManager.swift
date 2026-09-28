import AppKit
import SwiftUI

private final class MarkerHostingView<Content: View>: NSHostingView<Content> {
    var onClick: (() -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

    private var mouseDownScreenPoint: CGPoint?
    private var startingWindowOrigin: CGPoint?

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        addCursorRect(bounds, cursor: .pointingHand)
    }

    override func mouseDown(with event: NSEvent) {
        NSCursor.closedHand.push()
        mouseDownScreenPoint = NSEvent.mouseLocation
        startingWindowOrigin = window?.frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard let window,
              let mouseDownScreenPoint,
              let startingWindowOrigin else {
            return
        }

        let current = NSEvent.mouseLocation
        let deltaX = current.x - mouseDownScreenPoint.x
        let deltaY = current.y - mouseDownScreenPoint.y

        window.setFrameOrigin(
            CGPoint(
                x: startingWindowOrigin.x + deltaX,
                y: startingWindowOrigin.y + deltaY
            )
        )
    }

    override func mouseUp(with event: NSEvent) {
        NSCursor.pop()

        guard let window,
              let mouseDownScreenPoint else {
            resetGesture()
            return
        }

        let current = NSEvent.mouseLocation
        let distance = hypot(
            current.x - mouseDownScreenPoint.x,
            current.y - mouseDownScreenPoint.y
        )

        if distance < 4 {
            onClick?()
        } else {
            onDragEnded?(
                CGPoint(
                    x: window.frame.midX,
                    y: window.frame.midY
                )
            )
        }

        resetGesture()
    }

    private func resetGesture() {
        mouseDownScreenPoint = nil
        startingWindowOrigin = nil
    }
}

final class OverlayManager: NSObject {
    private let contextObserver: ContextObserver
    private let store: BreadcrumbStore
    private let editorController = BreadcrumbEditorController()
    private let resumeContextController = ResumeContextController()

    private var records: [BreadcrumbRecord]
    private var panels: [UUID: NSPanel] = [:]
    private var workspaceObserver: NSObjectProtocol?
    private var refreshTimer: Timer?
    private var lastDecisionByRecord: [UUID: String] = [:]
    private var editingRecordID: UUID?

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

    func presentResumeContext() {
        guard let context = contextObserver.captureCurrent() else {
            DiagnosticLog.shared.record(
                category: "Action",
                summary: "Resume Context unavailable",
                detail: "No focused window context."
            )
            return
        }

        let matching = records
            .filter { !$0.isArchived && !$0.isSnoozed && context.matches($0) }
            .sorted { $0.updatedAt > $1.updatedAt }

        guard !matching.isEmpty else {
            DiagnosticLog.shared.record(
                category: "Action",
                summary: "Resume Context empty",
                detail: "No active breadcrumbs matched the current context."
            )
            return
        }

        let contextTitle: String?
        if let tab = context.selectedTabTitle, !tab.isEmpty {
            contextTitle = tab
        } else {
            contextTitle = context.windowTitle
        }

        resumeContextController.present(
            applicationName: context.applicationName,
            contextTitle: contextTitle,
            records: matching,
            near: context.windowFrame,
            onEdit: { [weak self] id in
                self?.openEditor(for: id)
            },
            onArchive: { [weak self] id in
                self?.archive(id)
            },
            onSnooze: { [weak self] id, date in
                self?.snooze(id, until: date)
            }
        )
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
                detail: [
                    "reason: context was not stable enough",
                    "app: \(context.applicationName)",
                    "title: \(context.windowTitle ?? "nil")",
                    "documentURL: \(context.documentURL ?? "nil")",
                    "tabTitle: \(context.selectedTabTitle ?? "nil")",
                    "tabIndex: \(context.selectedTabIndex.map(String.init) ?? "nil")",
                    "minimized: \(context.isMinimized)"
                ].joined(separator: "\n")
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
                "windowTitle: \(context.windowTitle ?? "nil")",
                "documentURL: \(context.documentURL ?? "nil")",
                "selectedTabTitle: \(context.selectedTabTitle ?? "nil")",
                "selectedTabIndex: \(context.selectedTabIndex.map(String.init) ?? "nil")",
                "windowNumber: \(context.windowNumber.map(String.init) ?? "nil")",
                "display: \(context.displayIdentifier ?? "nil")",
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
        if editingRecordID == id {
            editingRecordID = nil
        }
        editorController.dismiss()

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Archived breadcrumb",
            detail: "id: \(id.uuidString)"
        )
    }

    func delete(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        panels[id]?.orderOut(nil)
        panels.removeValue(forKey: id)
        records.remove(at: index)
        persist()
        if editingRecordID == id {
            editingRecordID = nil
        }
        editorController.dismiss()

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Deleted breadcrumb",
            detail: "id: \(id.uuidString)"
        )
    }

    func snooze(_ id: UUID, until date: Date) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].snoozedUntil = date
        records[index].updatedAt = Date()
        persist()

        panels[id]?.orderOut(nil)
        if editingRecordID == id {
            editingRecordID = nil
        }
        editorController.dismiss()

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Snoozed breadcrumb",
            detail: "id: \(id.uuidString)\nuntil: \(date)"
        )
    }

    func wake(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].snoozedUntil = nil
        records[index].updatedAt = Date()
        persist()
        refresh()
    }

    func restore(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].isArchived = false
        records[index].snoozedUntil = nil
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

        let size = NSSize(width: 176, height: 40)
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
        panel.isMovable = false
        panel.level = .floating
        panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false

        let host = MarkerHostingView(
            rootView: BreadcrumbMarkerView(
                text: record.text,
                applicationName: record.applicationName
            )
        )

        host.onClick = { [weak self] in
            self?.openEditor(for: record.id)
        }

        host.onDragEnded = { [weak self] center in
            self?.saveDraggedPosition(for: record.id, center: center)
        }

        panel.contentView = host
        panels[record.id] = panel
    }

    private func hideAllPanelsForEditing() {
        for panel in panels.values {
            panel.orderOut(nil)
        }
    }

    private func finishEditing() {
        editingRecordID = nil
        refresh()
    }

    private func openEditor(for id: UUID) {
        guard let record = records.first(where: { $0.id == id }),
              let panel = panels[id] else {
            return
        }

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Opened breadcrumb editor",
            detail: [
                "id: \(id.uuidString)",
                "text: \(record.text)",
                "context: \(record.contextSummary)"
            ].joined(separator: "\n")
        )

        let anchorPoint = CGPoint(
            x: panel.frame.midX,
            y: panel.frame.midY
        )

        editingRecordID = id
        hideAllPanelsForEditing()

        editorController.present(
            record: record,
            near: anchorPoint,
            onSave: { [weak self] text in
                self?.updateText(id, text: text)
            },
            onArchive: { [weak self] in
                self?.archive(id)
            },
            onDelete: { [weak self] in
                self?.delete(id)
            },
            onSnooze: { [weak self] date in
                self?.snooze(id, until: date)
            },
            onDismiss: { [weak self] in
                self?.finishEditing()
            }
        )
    }

    private func saveDraggedPosition(for id: UUID, center: CGPoint) {
        guard let index = records.firstIndex(where: { $0.id == id }),
              let context = contextObserver.captureCurrent(),
              context.matches(records[index]),
              let frame = context.windowFrame,
              frame.width > 0,
              frame.height > 0 else {
            DiagnosticLog.shared.record(
                category: "Action",
                summary: "Could not save dragged position",
                detail: "id: \(id.uuidString)\nreason: current context did not match the breadcrumb"
            )
            refresh()
            return
        }

        records[index].relativeX = min(
            max((center.x - frame.minX) / frame.width, 0),
            1
        )
        records[index].relativeY = min(
            max((center.y - frame.minY) / frame.height, 0),
            1
        )
        records[index].updatedAt = Date()
        persist()

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Moved breadcrumb",
            detail: [
                "id: \(id.uuidString)",
                "relativeX: \(records[index].relativeX)",
                "relativeY: \(records[index].relativeY)"
            ].joined(separator: "\n")
        )

        refresh(preferredContext: context)
    }

    private func refresh(preferredContext: ContextSnapshot? = nil) {
        if editingRecordID != nil {
            hideAllPanelsForEditing()
            return
        }

        guard let context = preferredContext ?? contextObserver.captureCurrent() else {
            for record in records where !record.isArchived {
                hide(record: record, reason: "No focused window context")
            }
            editorController.dismiss()
            return
        }

        if context.isMinimized {
            for record in records where !record.isArchived {
                hide(record: record, reason: "Focused target window is minimized")
            }
            editorController.dismiss()
            return
        }

        let matchingRecords = records
            .filter { !$0.isArchived && !$0.isSnoozed && context.matches($0) }
            .sorted { $0.createdAt < $1.createdAt }

        let resolvedCenters = resolvedMarkerCenters(
            for: matchingRecords,
            context: context
        )

        for record in records where !record.isArchived {
            guard let panel = panels[record.id] else { continue }

            if record.isSnoozed {
                panel.orderOut(nil)
                decide(
                    record: record,
                    visible: false,
                    reason: "Snoozed until \(record.snoozedUntil?.description ?? "later")"
                )
                continue
            }

            if context.matches(record) {
                let point = resolvedCenters[record.id]
                    ?? record.anchorPoint(in: context.windowFrame)
                reposition(panel, center: point)
                panel.orderFrontRegardless()
                decide(
                    record: record,
                    visible: true,
                    reason: matchReason(record: record, context: context)
                )
            } else {
                panel.orderOut(nil)
                decide(
                    record: record,
                    visible: false,
                    reason: mismatchReason(record: record, context: context)
                )
            }
        }
    }

    private func hide(record: BreadcrumbRecord, reason: String) {
        panels[record.id]?.orderOut(nil)
        decide(record: record, visible: false, reason: reason)
    }

    private func matchReason(
        record: BreadcrumbRecord,
        context: ContextSnapshot
    ) -> String {
        var components = ["bundle"]

        if record.documentURL != nil {
            components.append("documentURL")
        } else {
            components.append("windowTitle")
        }

        if record.processIdentifier == context.processIdentifier,
           record.windowNumber != nil,
           context.windowNumber != nil {
            components.append("windowNumber")
        }

        if record.selectedTabIndex != nil,
           context.selectedTabIndex != nil {
            components.append("tabIndex")
        }

        if record.selectedTabTitle != nil,
           context.selectedTabTitle != nil {
            components.append("tabTitle")
        }

        return "Matched " + components.joined(separator: " + ")
    }

    private func mismatchReason(
        record: BreadcrumbRecord,
        context: ContextSnapshot
    ) -> String {
        if context.isMinimized {
            return "Current window is minimized"
        }

        if record.bundleIdentifier != context.bundleIdentifier {
            return "Bundle mismatch: saved \(record.bundleIdentifier), current \(context.bundleIdentifier)"
        }

        let sameSession = record.processIdentifier != nil
            && context.processIdentifier != nil
            && record.processIdentifier == context.processIdentifier

        if sameSession,
           let savedWindow = record.windowNumber,
           let currentWindow = context.windowNumber,
           savedWindow != currentWindow {
            return "Window mismatch: saved \(savedWindow), current \(currentWindow)"
        }

        if let savedDocument = record.documentURL {
            let currentDocument = context.documentURL ?? "nil"
            if savedDocument != currentDocument {
                return "Document mismatch: saved [\(savedDocument)] current [\(currentDocument)]"
            }
        } else {
            let savedTitle = record.windowTitle ?? "nil"
            let currentTitle = context.windowTitle ?? "nil"

            if savedTitle != currentTitle {
                return "Window title mismatch: saved [\(savedTitle)] current [\(currentTitle)]"
            }
        }

        if sameSession,
           let savedTabIndex = record.selectedTabIndex,
           let currentTabIndex = context.selectedTabIndex,
           savedTabIndex != currentTabIndex {
            return "Selected tab mismatch: saved index \(savedTabIndex), current index \(currentTabIndex)"
        }

        if let savedTabTitle = record.selectedTabTitle,
           let currentTabTitle = context.selectedTabTitle,
           savedTabTitle != currentTabTitle {
            return "Selected tab title mismatch: saved [\(savedTabTitle)] current [\(currentTabTitle)]"
        }

        return "Context did not satisfy exact matching"
    }

    private func decide(
        record: BreadcrumbRecord,
        visible: Bool,
        reason: String
    ) {
        let decision = "\(visible ? "SHOW" : "HIDE")|\(reason)"
        guard lastDecisionByRecord[record.id] != decision else { return }
        lastDecisionByRecord[record.id] = decision

        DiagnosticLog.shared.record(
            category: "Match",
            summary: "\(visible ? "SHOW" : "HIDE") · \(record.applicationName)",
            detail: [
                "breadcrumb: \(record.id.uuidString)",
                "text: \(record.text)",
                "savedContext: \(record.contextSummary)",
                "reason: \(reason)"
            ].joined(separator: "\n")
        )
    }

    private func resolvedMarkerCenters(
        for records: [BreadcrumbRecord],
        context: ContextSnapshot
    ) -> [UUID: CGPoint] {
        guard let frame = context.windowFrame else {
            return Dictionary(
                uniqueKeysWithValues: records.map { ($0.id, $0.anchorPoint(in: nil)) }
            )
        }

        let markerSize = CGSize(width: 176, height: 40)
        let verticalStep: CGFloat = 46
        let horizontalPadding: CGFloat = 8
        let verticalPadding: CGFloat = 8

        var result: [UUID: CGPoint] = [:]
        var occupied: [CGRect] = []

        func rect(for center: CGPoint) -> CGRect {
            CGRect(
                x: center.x - markerSize.width / 2,
                y: center.y - markerSize.height / 2,
                width: markerSize.width,
                height: markerSize.height
            )
        }

        func clamped(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: min(
                    max(point.x, frame.minX + markerSize.width / 2 + horizontalPadding),
                    frame.maxX - markerSize.width / 2 - horizontalPadding
                ),
                y: min(
                    max(point.y, frame.minY + markerSize.height / 2 + verticalPadding),
                    frame.maxY - markerSize.height / 2 - verticalPadding
                )
            )
        }

        for record in records {
            let desired = clamped(record.anchorPoint(in: frame))
            var candidates: [CGPoint] = [desired]

            for step in 1...6 {
                candidates.append(
                    clamped(CGPoint(x: desired.x, y: desired.y - CGFloat(step) * verticalStep))
                )
                candidates.append(
                    clamped(CGPoint(x: desired.x, y: desired.y + CGFloat(step) * verticalStep))
                )
            }

            let chosen = candidates.first { candidate in
                let candidateRect = rect(for: candidate).insetBy(dx: -4, dy: -3)
                return !occupied.contains { $0.intersects(candidateRect) }
            } ?? desired

            result[record.id] = chosen
            occupied.append(rect(for: chosen))
        }

        return result
    }

    private func reposition(_ panel: NSPanel, center point: CGPoint) {
        let origin = CGPoint(
            x: point.x - panel.frame.width / 2,
            y: point.y - panel.frame.height / 2
        )

        guard abs(panel.frame.origin.x - origin.x) > 0.5
                || abs(panel.frame.origin.y - origin.y) > 0.5 else {
            return
        }

        panel.setFrameOrigin(origin)
    }
}
