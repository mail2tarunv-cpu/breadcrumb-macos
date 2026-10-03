import AppKit
import SwiftUI

private final class MarkerHostingView<Content: View>: NSHostingView<Content> {
    var onClick: (() -> Void)?
    var onColorToggle: (() -> Void)?
    var onColorSelected: ((BreadcrumbColor) -> Void)?
    var markerState: BreadcrumbMarkerState?
    var onDragBegan: (() -> Void)?
    var onDragEnded: ((CGPoint) -> Void)?

    private var mouseDownScreenPoint: CGPoint?
    private var startingWindowOrigin: CGPoint?
    private var isDragging = false

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
        mouseDownScreenPoint = NSEvent.mouseLocation
        startingWindowOrigin = window?.frame.origin
        isDragging = false
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
        let distance = hypot(deltaX, deltaY)

        if !isDragging {
            guard distance >= 3 else { return }
            isDragging = true
            markerState?.isDragging = true
            NSCursor.closedHand.push()
            onDragBegan?()
        }

        window.setFrameOrigin(
            CGPoint(
                x: startingWindowOrigin.x + deltaX,
                y: startingWindowOrigin.y + deltaY
            )
        )
    }

    override func mouseUp(with event: NSEvent) {
        guard let window,
              mouseDownScreenPoint != nil else {
            resetGesture()
            return
        }

        if isDragging {
            NSCursor.pop()
            markerState?.isDragging = false
            onDragEnded?(
                CGPoint(
                    x: window.frame.midX,
                    y: window.frame.midY
                )
            )
        } else {
            let localPoint = convert(
                event.locationInWindow,
                from: nil
            )

            if let markerState, markerState.isColorPickerExpanded {
                // Keep hit testing aligned with the fixed identity area.
                let paletteStart = BreadcrumbPreferences.markerSize.dimensions.width
                if localPoint.x >= paletteStart {
                    let paletteX = localPoint.x - paletteStart - 7
                    let step: CGFloat = 13
                    let index = min(
                        max(Int((paletteX / step).rounded(.down)), 0),
                        BreadcrumbColor.allCases.count - 1
                    )
                    onColorSelected?(BreadcrumbColor.allCases[index])
                } else if localPoint.x <= 30 {
                    onColorToggle?()
                } else {
                    onClick?()
                }
            } else if localPoint.x <= 30 {
                onColorToggle?()
            } else {
                onClick?()
            }
        }

        resetGesture()
    }

    private func resetGesture() {
        mouseDownScreenPoint = nil
        startingWindowOrigin = nil
        isDragging = false
    }
}

final class OverlayManager: NSObject {
    private let contextObserver: ContextObserver
    private let store: BreadcrumbStore
    private let editorController = BreadcrumbEditorController()
    private let resumeContextController = ResumeContextController()
    private let contextStackController = ContextStackController()

    private var records: [BreadcrumbRecord]
    private var panels: [UUID: NSPanel] = [:]
    private var workspaceObserver: NSObjectProtocol?
    private var appearanceObserver: NSObjectProtocol?
    private var refreshTimer: Timer?
    private var lastDecisionByRecord: [UUID: String] = [:]
    private var editingRecordID: UUID?
    private var draggingRecordID: UUID?
    private var lastManuallyPositionedRecordID: UUID?
    private var markerStates: [UUID: BreadcrumbMarkerState] = [:]
    private var lastStableTargetContext: ContextSnapshot?
    private var pendingTargetContext: ContextSnapshot?
    private var pendingTargetContextKey: String?
    private var pendingTargetContextSince: Date?
    private let targetContextStabilityInterval: TimeInterval = 0.24

    private var autoResumeCandidateKey: String?
    private var autoResumeCandidateSince: Date?
    private var lastAutoResumeByContext: [String: Date] = [:]
    private var activeContextKey: String?
    private var lastLeftAtByContext: [String: Date] = [:]

    private let crowdedContextThreshold = 5

    private let autoResumeEnabledKey = "breadcrumb.resume.autoEnabled"
    private let autoResumeCooldownKey = "breadcrumb.resume.cooldownMinutes"
    private let contextHistoryKey = "breadcrumb.context.lastLeft.v1"

    init(contextObserver: ContextObserver, store: BreadcrumbStore) {
        self.contextObserver = contextObserver
        self.store = store
        self.records = store.load()
        UserDefaults.standard.register(defaults: [
            autoResumeEnabledKey: true,
            autoResumeCooldownKey: 15.0
        ])

        if let stored = UserDefaults.standard.dictionary(forKey: contextHistoryKey) as? [String: Double] {
            self.lastLeftAtByContext = stored.reduce(into: [:]) { result, item in
                result[item.key] = Date(timeIntervalSince1970: item.value)
            }
        }

        super.init()

        appearanceObserver = NotificationCenter.default.addObserver(
            forName: BreadcrumbPreferences.appearanceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildAllMarkerPanels()
        }
    }

    deinit {
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
        if let appearanceObserver {
            NotificationCenter.default.removeObserver(appearanceObserver)
        }
        refreshTimer?.invalidate()
    }

    var allRecords: [BreadcrumbRecord] {
        records
    }

    func prepareForTermination() {
        if let activeContextKey {
            lastLeftAtByContext[activeContextKey] = Date()
            persistContextHistory()
        }
    }

    func presentResumeContext() {
        guard let context = contextObserver.captureCurrent() else {
            DiagnosticLog.shared.record(
                category: "Action",
                summary: "Context summary unavailable",
                detail: "No focused window context."
            )
            return
        }

        let matching = matchingRecords(for: context)

        guard !matching.isEmpty else {
            DiagnosticLog.shared.record(
                category: "Action",
                summary: "Context summary empty",
                detail: "No active breadcrumbs matched the current context."
            )
            return
        }

        showResumeContext(
            context: context,
            records: matching,
            source: "manual"
        )
    }

    func refreshForWorkspaceChange() {
        refresh()
    }

    func start() {
        for record in records where !record.isArchived && !record.isDone && record.hasStableContext {
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
        markerStates.removeValue(forKey: id)
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

    func markDone(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].completedAt = Date()
        records[index].snoozedUntil = nil
        records[index].updatedAt = Date()
        persist()

        panels[id]?.orderOut(nil)
        if editingRecordID == id {
            editingRecordID = nil
        }
        editorController.dismiss()

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Completed breadcrumb",
            detail: "id: \(id.uuidString)"
        )

        refresh(preferredContext: lastStableTargetContext)
    }

    func reopen(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].completedAt = nil
        records[index].updatedAt = Date()
        persist()

        if records[index].hasStableContext {
            createPanelIfNeeded(for: records[index])
        }

        refresh()
    }

    func restore(_ id: UUID) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].isArchived = false
        records[index].snoozedUntil = nil
        records[index].completedAt = nil
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

    func updateColor(_ id: UUID, color: BreadcrumbColor) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].breadcrumbColor = color
        records[index].updatedAt = Date()
        persist()

        markerStates[id]?.isColorPickerExpanded = false
        resizeMarkerPanel(for: id, expanded: false)
        rebuildPanel(for: records[index])

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Changed breadcrumb color",
            detail: "id: \(id.uuidString)\ncolor: \(color.rawValue)"
        )

        refresh(preferredContext: lastStableTargetContext)
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

    private func rebuildAllMarkerPanels() {
        for panel in panels.values {
            panel.orderOut(nil)
        }
        panels.removeAll()

        for record in records where !record.isArchived && !record.isDone && record.hasStableContext {
            createPanelIfNeeded(for: record)
        }

        refresh(preferredContext: lastStableTargetContext)
    }

    private func createPanelIfNeeded(for record: BreadcrumbRecord) {
        guard panels[record.id] == nil,
              !record.isArchived,
              !record.isDone,
              record.hasStableContext else {
            return
        }

        let size = BreadcrumbPreferences.markerSize.dimensions
        let fallbackPoint = record.anchorPoint(in: nil)
        let markerState = markerStates[record.id] ?? BreadcrumbMarkerState()
        markerStates[record.id] = markerState

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
                accentColor: record.accentColor,
                state: markerState,
                onHoverChange: { _ in }
            )
        )

        host.markerState = markerState

        host.onColorToggle = { [weak self] in
            self?.toggleColorPicker(for: record.id)
        }

        host.onColorSelected = { [weak self] color in
            self?.updateColorFromPicker(record.id, color: color)
        }

        host.onClick = { [weak self] in
            self?.openEditor(for: record.id)
        }

        host.onDragBegan = { [weak self] in
            self?.draggingRecordID = record.id
        }

        host.onDragEnded = { [weak self] center in
            self?.lastManuallyPositionedRecordID = record.id
            self?.draggingRecordID = nil
            self?.saveDraggedPosition(for: record.id, center: center)
        }

        panel.contentView = host
        panels[record.id] = panel
    }

    private func toggleColorPicker(for id: UUID) {
        guard let state = markerStates[id],
              panels[id] != nil else { return }

        state.isColorPickerExpanded.toggle()
        resizeMarkerPanel(for: id, expanded: state.isColorPickerExpanded)
    }

    private func updateColorFromPicker(_ id: UUID, color: BreadcrumbColor) {
        guard let index = records.firstIndex(where: { $0.id == id }) else { return }

        records[index].breadcrumbColor = color
        records[index].updatedAt = Date()
        persist()

        if let state = markerStates[id] {
            state.isColorPickerExpanded = false
        }

        resizeMarkerPanel(for: id, expanded: false)
        rebuildPanel(for: records[index])

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Changed breadcrumb color",
            detail: "id: \(id.uuidString)\\ncolor: \(color.rawValue)"
        )

        refresh(preferredContext: lastStableTargetContext)
    }

    private func resizeMarkerPanel(
        for id: UUID,
        expanded: Bool
    ) {
        guard let panel = panels[id] else { return }

        let markerSize = BreadcrumbPreferences.markerSize
        let width = expanded ? markerSize.expandedWidth : markerSize.dimensions.width
        let size = CGSize(
            width: width,
            height: markerSize.dimensions.height
        )
        let center = CGPoint(
            x: panel.frame.midX,
            y: panel.frame.midY
        )
        let frame = NSRect(
            x: center.x - size.width / 2,
            y: center.y - size.height / 2,
            width: size.width,
            height: size.height
        )

        panel.setFrame(frame, display: true, animate: !BreadcrumbPreferences.reducedMotion)
    }

    private func markerDimensions(for id: UUID) -> CGSize {
        let markerSize = BreadcrumbPreferences.markerSize
        if markerStates[id]?.isColorPickerExpanded == true {
            return CGSize(width: markerSize.expandedWidth, height: markerSize.dimensions.height)
        }
        return markerSize.dimensions
    }

    private func hideEditingPanel() {
        guard let editingRecordID else { return }
        panels[editingRecordID]?.orderOut(nil)
        contextStackController.dismiss()
    }

    private func finishEditing() {
        editingRecordID = nil
        refresh(preferredContext: lastStableTargetContext)
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
        if let current = contextObserver.captureCurrent(),
           current.bundleIdentifier != "com.tarun.breadcrumb" {
            lastStableTargetContext = current
        }
        hideEditingPanel()

        editorController.present(
            record: record,
            near: anchorPoint,
            onSave: { [weak self] text in
                self?.updateText(id, text: text)
            },
            onColorChange: { [weak self] color in
                self?.updateColor(id, color: color)
            },
            onDone: { [weak self] in
                self?.markDone(id)
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
        let captured = preferredContext ?? contextObserver.captureCurrent()
        let context: ContextSnapshot?

        // Breadcrumb is an accessory app. Opening its menu, library, editor,
        // or another Breadcrumb-owned panel can temporarily make Breadcrumb
        // the frontmost application. That must never replace the last real
        // target application as the context we use for marker visibility.
        let targetContext: ContextSnapshot? = {
            // No focused window means the target context is no longer visible
            // (for example Safari was minimized and the desktop became
            // frontmost). Do not fall back to the old context here: doing so
            // leaves its floating pill/card stranded on the desktop.
            guard let captured else {
                return nil
            }

            guard captured.bundleIdentifier != "com.tarun.breadcrumb" else {
                return lastStableTargetContext
            }

            // Accessibility can return a transient browser snapshot while a
            // tab is moving/restoring (missing URL/title/frame identity).
            // Never replace a known-good target with that transient state.
            // Minimization is an intentional context transition, not a
            // transient Accessibility state. Hide immediately instead of
            // waiting for the stability debounce.
            if captured.isMinimized {
                pendingTargetContext = nil
                pendingTargetContextKey = nil
                pendingTargetContextSince = nil
                lastStableTargetContext = captured
                return captured
            }

            guard captured.hasStableIdentity else {
                return lastStableTargetContext
            }

            // Browser accessibility snapshots can alternate between the old
            // and new tab/window while a tab is being dragged or restored.
            // Do not let either transient snapshot immediately drive panel
            // visibility. A candidate must remain stable for a short interval
            // before it becomes the active target context.
            let candidateKey = targetContextKey(for: captured)
            let now = Date()

            if lastStableTargetContext == nil {
                pendingTargetContext = nil
                pendingTargetContextKey = nil
                pendingTargetContextSince = nil
                lastStableTargetContext = captured
                return captured
            }

            if candidateKey == targetContextKey(for: lastStableTargetContext!) {
                pendingTargetContext = nil
                pendingTargetContextKey = nil
                pendingTargetContextSince = nil
                lastStableTargetContext = captured
                return captured
            }

            if pendingTargetContextKey != candidateKey {
                pendingTargetContext = captured
                pendingTargetContextKey = candidateKey
                pendingTargetContextSince = now
                return lastStableTargetContext
            }

            pendingTargetContext = captured

            guard let pendingSince = pendingTargetContextSince,
                  now.timeIntervalSince(pendingSince) >= targetContextStabilityInterval else {
                return lastStableTargetContext
            }

            pendingTargetContext = nil
            pendingTargetContextKey = nil
            pendingTargetContextSince = nil
            lastStableTargetContext = captured
            return captured
        }()

        if editingRecordID != nil {
            context = targetContext
            hideEditingPanel()
        } else {
            context = targetContext
        }

        guard let context else {
            for record in records where !record.isArchived && !record.isDone {
                hide(record: record, reason: "No focused window context")
            }
            contextStackController.dismiss()
            resumeContextController.dismiss()
            editorController.dismiss()
            return
        }

        if context.isMinimized {
            // A minimized target invalidates every floating surface tied to it.
            // Dismiss the context card/stack immediately as well as the pills;
            // otherwise those independent panels can remain visible after the
            // target window disappears.
            for record in records where !record.isArchived && !record.isDone {
                hide(record: record, reason: "Focused target window is minimized")
            }
            contextStackController.dismiss()
            resumeContextController.dismiss()
            editorController.dismiss()
            return
        }

        let matchingRecords = matchingRecords(for: context)
            .sorted { $0.createdAt < $1.createdAt }

        updateContextVisit(for: context)

        let isCrowdedContext = matchingRecords.count >= crowdedContextThreshold
            && editingRecordID == nil
            && draggingRecordID == nil

        let layoutRecords = isCrowdedContext
            ? []
            : matchingRecords.filter { $0.id != draggingRecordID }

        let resolvedCenters = resolvedMarkerCenters(
            for: layoutRecords,
            context: context
        )

        for record in records where !record.isArchived && !record.isDone {
            guard let panel = panels[record.id] else { continue }

            if record.id == editingRecordID {
                panel.orderOut(nil)
                continue
            }

            if record.id == draggingRecordID {
                panel.orderFrontRegardless()
                continue
            }

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
                if isCrowdedContext {
                    panel.orderOut(nil)
                    decide(
                        record: record,
                        visible: false,
                        reason: "Collapsed into context stack"
                    )
                    continue
                }

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

        if isCrowdedContext {
            contextStackController.present(
                records: matchingRecords,
                in: context.windowFrame,
                onOpen: { [weak self] in
                    self?.contextStackController.dismiss()
                    self?.showResumeContext(
                        context: context,
                        records: matchingRecords,
                        source: "stack"
                    )
                }
            )
        } else {
            contextStackController.dismiss()
        }

        if editingRecordID == nil {
            maybeAutoPresentResumeContext(
                context: context,
                matchingRecords: matchingRecords
            )
        }
    }

    private func matchingRecords(for context: ContextSnapshot) -> [BreadcrumbRecord] {
        records
            .filter { !$0.isArchived && !$0.isDone && !$0.isSnoozed && context.matches($0) }
            .sorted {
                if $0.createdAt != $1.createdAt {
                    return $0.createdAt < $1.createdAt
                }
                return $0.updatedAt < $1.updatedAt
            }
    }

    private func targetContextKey(for context: ContextSnapshot) -> String {
        let document = context.documentURL?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let title = context.windowTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let tab = context.selectedTabTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return [
            context.bundleIdentifier,
            document?.isEmpty == false ? document! : (title ?? ""),
            tab ?? ""
        ].joined(separator: "|")
    }

    private func contextKey(for context: ContextSnapshot) -> String {
        targetContextKey(for: context)
    }

    private func updateContextVisit(for context: ContextSnapshot) {
        let key = contextKey(for: context)
        guard activeContextKey != key else { return }

        let now = Date()

        if let previous = activeContextKey {
            lastLeftAtByContext[previous] = now
            persistContextHistory()
        }

        activeContextKey = key
        autoResumeCandidateKey = key
        autoResumeCandidateSince = now
    }

    private func persistContextHistory() {
        let encoded = lastLeftAtByContext.mapValues { $0.timeIntervalSince1970 }
        UserDefaults.standard.set(encoded, forKey: contextHistoryKey)
    }

    private func maybeAutoPresentResumeContext(
        context: ContextSnapshot,
        matchingRecords: [BreadcrumbRecord]
    ) {
        guard UserDefaults.standard.bool(forKey: autoResumeEnabledKey),
              matchingRecords.count >= 2,
              !resumeContextController.isPresented else {
            if matchingRecords.count < 2 {
                autoResumeCandidateKey = nil
                autoResumeCandidateSince = nil
            }
            return
        }

        let key = contextKey(for: context)
        let now = Date()

        if autoResumeCandidateKey != key {
            autoResumeCandidateKey = key
            autoResumeCandidateSince = now
            return
        }

        guard let candidateSince = autoResumeCandidateSince,
              now.timeIntervalSince(candidateSince) >= 0.9 else {
            return
        }

        let awayMinutes = max(
            UserDefaults.standard.double(forKey: autoResumeCooldownKey),
            1
        )
        let minimumAway = awayMinutes * 60

        guard let leftAt = lastLeftAtByContext[key],
              now.timeIntervalSince(leftAt) >= minimumAway else {
            return
        }

        if let lastShown = lastAutoResumeByContext[key],
           now.timeIntervalSince(lastShown) < minimumAway {
            return
        }

        lastAutoResumeByContext[key] = now

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Auto surfaced context summary",
            detail: "context: \(key)\nbreadcrumbs: \(matchingRecords.count)"
        )

        showResumeContext(
            context: context,
            records: matchingRecords,
            source: "automatic"
        )
    }

    private func showResumeContext(
        context: ContextSnapshot,
        records: [BreadcrumbRecord],
        source: String
    ) {
        contextStackController.dismiss()
        let contextTitle: String?
        if let tab = context.selectedTabTitle, !tab.isEmpty {
            contextTitle = tab
        } else {
            contextTitle = context.windowTitle
        }

        resumeContextController.present(
            applicationName: context.applicationName,
            contextTitle: contextTitle,
            records: records,
            near: context.windowFrame,
            onEdit: { [weak self] id in
                self?.openEditor(for: id)
            },
            onArchive: { [weak self] id in
                self?.archive(id)
            },
            onDone: { [weak self] id in
                self?.markDone(id)
            },
            onSnooze: { [weak self] id, date in
                self?.snooze(id, until: date)
            }
        )

        DiagnosticLog.shared.record(
            category: "Action",
            summary: "Presented context summary",
            detail: "source: \(source)\ncount: \(records.count)"
        )
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

        if let savedDocument = record.documentURL,
           let currentDocument = context.documentURL,
           savedDocument == currentDocument {
            if sameSession,
               let savedTabIndex = record.selectedTabIndex,
               let currentTabIndex = context.selectedTabIndex,
               savedTabIndex != currentTabIndex {
                return "Selected tab mismatch: saved index \(savedTabIndex), current index \(currentTabIndex)"
            }

            return "Document matched"
        }

        if let savedTabTitle = record.selectedTabTitle,
           let currentTabTitle = context.selectedTabTitle,
           savedTabTitle == currentTabTitle {
            return "Selected tab title matched"
        }

        if let savedTitle = record.windowTitle,
           let currentTitle = context.windowTitle,
           savedTitle == currentTitle {
            return "Window title matched"
        }

        if let savedDocument = record.documentURL {
            return "Document mismatch: saved [\(savedDocument)] current [\(context.documentURL ?? "nil")]"
        }

        return "Window title mismatch: saved [\(record.windowTitle ?? "nil")] current [\(context.windowTitle ?? "nil")]"
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

        let baseSize = BreadcrumbPreferences.markerSize.dimensions
        let verticalStep: CGFloat = baseSize.height + 6
        let horizontalPadding: CGFloat = 8
        let verticalPadding: CGFloat = 8

        var result: [UUID: CGPoint] = [:]
        var occupied: [CGRect] = []

        func rect(for center: CGPoint, size: CGSize) -> CGRect {
            CGRect(
                x: center.x - size.width / 2,
                y: center.y - size.height / 2,
                width: size.width,
                height: size.height
            )
        }

        func clamped(_ point: CGPoint, size: CGSize) -> CGPoint {
            CGPoint(
                x: min(
                    max(point.x, frame.minX + size.width / 2 + horizontalPadding),
                    frame.maxX - size.width / 2 - horizontalPadding
                ),
                y: min(
                    max(point.y, frame.minY + size.height / 2 + verticalPadding),
                    frame.maxY - size.height / 2 - verticalPadding
                )
            )
        }

        let orderedRecords = records.sorted { lhs, rhs in
            if lhs.id == lastManuallyPositionedRecordID { return true }
            if rhs.id == lastManuallyPositionedRecordID { return false }
            return lhs.createdAt < rhs.createdAt
        }

        for record in orderedRecords {
            let size = markerDimensions(for: record.id)
            let desired = clamped(record.anchorPoint(in: frame), size: size)
            var candidates: [CGPoint] = [desired]

            for step in 1...6 {
                candidates.append(
                    clamped(
                        CGPoint(
                            x: desired.x,
                            y: desired.y - CGFloat(step) * verticalStep
                        ),
                        size: size
                    )
                )
                candidates.append(
                    clamped(
                        CGPoint(
                            x: desired.x,
                            y: desired.y + CGFloat(step) * verticalStep
                        ),
                        size: size
                    )
                )
            }

            let chosen = candidates.first { candidate in
                let candidateRect = rect(for: candidate, size: size).insetBy(dx: -4, dy: -3)
                return !occupied.contains { $0.intersects(candidateRect) }
            } ?? desired

            result[record.id] = chosen
            occupied.append(rect(for: chosen, size: size))
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
