import AppKit
import ApplicationServices

final class ContextObserver {
    private struct TabIdentity {
        let title: String?
        let index: Int?
        let documentURL: String?
    }

    private var lastFingerprint: String?

    func captureCurrent() -> ContextSnapshot? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = app.bundleIdentifier else {
            logFailure("No frontmost application")
            return nil
        }

        let appName = app.localizedName ?? bundleIdentifier

        guard AXIsProcessTrusted() else {
            logFailure(
                "Accessibility permission missing",
                appName: appName,
                bundleID: bundleIdentifier
            )
            return nil
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        guard let window = copyElementAttribute(
            appElement,
            kAXFocusedWindowAttribute as CFString
        ) else {
            logFailure(
                "No focused window",
                appName: appName,
                bundleID: bundleIdentifier
            )
            return nil
        }

        let title = copyStringAttribute(
            window,
            kAXTitleAttribute as CFString
        )?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let frame = copyWindowFrame(window),
              frame.width > 0,
              frame.height > 0 else {
            logFailure(
                "Focused window has no usable frame",
                appName: appName,
                bundleID: bundleIdentifier
            )
            return nil
        }

        let minimized = copyBoolAttribute(
            window,
            kAXMinimizedAttribute as CFString
        ) ?? false

        let tabIdentity = findSelectedTab(in: window)

        // Browser AX trees are not consistent enough to make a generic
        // "selected tab" walk the primary URL source. For Safari/WebKit,
        // the focused web area exposes kAXURLAttribute directly. Use that
        // first, then the focused window, then the selected-tab/tree fallbacks.
        let focusedElementURL = findFocusedElementURL(in: appElement)
        let windowURL = copyStringLikeAttribute(
            window,
            kAXURLAttribute as CFString
        ) ?? copyStringLikeAttribute(
            window,
            kAXDocumentAttribute as CFString
        )
        let documentURL =
            focusedElementURL
            ?? windowURL
            ?? tabIdentity?.documentURL
            ?? findDocumentURL(in: window)

        let windowNumber = findWindowNumber(
            processIdentifier: app.processIdentifier,
            title: title,
            frame: frame
        )

        let snapshot = ContextSnapshot(
            bundleIdentifier: bundleIdentifier,
            applicationName: appName,
            windowTitle: title,
            windowFrame: frame,
            processIdentifier: app.processIdentifier,
            windowNumber: windowNumber,
            documentURL: documentURL,
            selectedTabTitle: tabIdentity?.title,
            selectedTabIndex: tabIdentity?.index,
            isMinimized: minimized,
            displayIdentifier: displayIdentifier(for: frame)
        )

        logSnapshotIfChanged(snapshot)
        return snapshot
    }

    private func logSnapshotIfChanged(_ snapshot: ContextSnapshot) {
        let tabIndex = snapshot.selectedTabIndex.map(String.init) ?? "-1"
        let processID = snapshot.processIdentifier.map(String.init) ?? "-1"
        let windowNumber = snapshot.windowNumber.map(String.init) ?? "-1"
        let minimized = snapshot.isMinimized ? "true" : "false"
        let frame = NSStringFromRect(snapshot.windowFrame ?? .zero)

        let fingerprintParts: [String] = [
            snapshot.bundleIdentifier,
            snapshot.windowTitle ?? "",
            snapshot.documentURL ?? "",
            snapshot.selectedTabTitle ?? "",
            tabIndex,
            processID,
            windowNumber,
            minimized,
            snapshot.displayIdentifier ?? "",
            frame
        ]
        let fingerprint = fingerprintParts.joined(separator: "|")

        guard fingerprint != lastFingerprint else { return }
        lastFingerprint = fingerprint

        DiagnosticLog.shared.record(
            category: "Context",
            summary: "Detected \(snapshot.applicationName)",
            detail: [
                "bundle: \(snapshot.bundleIdentifier)",
                "pid: \(snapshot.processIdentifier.map(String.init) ?? "nil")",
                "windowNumber: \(snapshot.windowNumber.map(String.init) ?? "nil")",
                "windowTitle: \(snapshot.windowTitle ?? "nil")",
                "documentURL: \(snapshot.documentURL ?? "nil")",
                "selectedTabTitle: \(snapshot.selectedTabTitle ?? "nil")",
                "selectedTabIndex: \(snapshot.selectedTabIndex.map(String.init) ?? "nil")",
                "minimized: \(snapshot.isMinimized)",
                "display: \(snapshot.displayIdentifier ?? "nil")",
                "frame: \(NSStringFromRect(snapshot.windowFrame ?? .zero))",
                "stable: \(snapshot.hasStableIdentity)"
            ].joined(separator: "\n")
        )
    }

    private func logFailure(
        _ reason: String,
        appName: String? = nil,
        bundleID: String? = nil
    ) {
        let fingerprint = "failure|\(reason)|\(bundleID ?? "")"
        guard fingerprint != lastFingerprint else { return }
        lastFingerprint = fingerprint

        DiagnosticLog.shared.record(
            category: "Context",
            summary: reason,
            detail: [
                "app: \(appName ?? "unknown")",
                "bundle: \(bundleID ?? "unknown")"
            ].joined(separator: "\n")
        )
    }

    private func copyElementAttribute(
        _ element: AXUIElement,
        _ attribute: CFString
    ) -> AXUIElement? {
        var value: CFTypeRef?

        guard AXUIElementCopyAttributeValue(
            element,
            attribute,
            &value
        ) == .success,
        let value else {
            return nil
        }

        return unsafeBitCast(value, to: AXUIElement.self)
    }

    private func copyStringAttribute(
        _ element: AXUIElement,
        _ attribute: CFString
    ) -> String? {
        var value: CFTypeRef?

        guard AXUIElementCopyAttributeValue(
            element,
            attribute,
            &value
        ) == .success else {
            return nil
        }

        return value as? String
    }

    private func copyStringLikeAttribute(
        _ element: AXUIElement,
        _ attribute: CFString
    ) -> String? {
        var value: CFTypeRef?

        guard AXUIElementCopyAttributeValue(
            element,
            attribute,
            &value
        ) == .success,
        let value else {
            return nil
        }

        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }

        if let url = value as? URL {
            return url.absoluteString
        }

        return nil
    }

    private func copyBoolAttribute(
        _ element: AXUIElement,
        _ attribute: CFString
    ) -> Bool? {
        var value: CFTypeRef?

        guard AXUIElementCopyAttributeValue(
            element,
            attribute,
            &value
        ) == .success else {
            return nil
        }

        if let bool = value as? Bool {
            return bool
        }

        return (value as? NSNumber)?.boolValue
    }

    private func copyElementArrayAttribute(
        _ element: AXUIElement,
        _ attribute: CFString
    ) -> [AXUIElement] {
        var value: CFTypeRef?

        guard AXUIElementCopyAttributeValue(
            element,
            attribute,
            &value
        ) == .success,
        let array = value as? [AnyObject] else {
            return []
        }

        return array.map {
            unsafeBitCast($0, to: AXUIElement.self)
        }
    }

    private func copyWindowFrame(_ window: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        guard AXUIElementCopyAttributeValue(
            window,
            kAXPositionAttribute as CFString,
            &positionRef
        ) == .success,
        AXUIElementCopyAttributeValue(
            window,
            kAXSizeAttribute as CFString,
            &sizeRef
        ) == .success,
        let positionRef,
        let sizeRef else {
            return nil
        }

        let positionValue = unsafeBitCast(positionRef, to: AXValue.self)
        let sizeValue = unsafeBitCast(sizeRef, to: AXValue.self)

        var position = CGPoint.zero
        var size = CGSize.zero

        guard AXValueGetValue(positionValue, .cgPoint, &position),
              AXValueGetValue(sizeValue, .cgSize, &size) else {
            return nil
        }

        let primaryTop = NSScreen.screens.first?.frame.maxY ?? 0
        let cocoaY = primaryTop - position.y - size.height

        return CGRect(
            x: position.x,
            y: cocoaY,
            width: size.width,
            height: size.height
        )
    }

    private func findFocusedElementURL(in appElement: AXUIElement) -> String? {
        guard let focused = copyElementAttribute(
            appElement,
            kAXFocusedUIElementAttribute as CFString
        ) else {
            return nil
        }

        return copyStringLikeAttribute(
            focused,
            kAXURLAttribute as CFString
        ) ?? copyStringLikeAttribute(
            focused,
            kAXDocumentAttribute as CFString
        )
    }

    private func findDocumentURL(in root: AXUIElement) -> String? {
        if let direct = copyStringLikeAttribute(
            root,
            kAXDocumentAttribute as CFString
        ) {
            return direct
        }

        var queue: [(AXUIElement, Int)] = [(root, 0)]
        var visited = 0

        while !queue.isEmpty, visited < 140 {
            let (element, depth) = queue.removeFirst()
            visited += 1

            if let url = copyStringLikeAttribute(
                element,
                kAXURLAttribute as CFString
            ) {
                return url
            }

            if let document = copyStringLikeAttribute(
                element,
                kAXDocumentAttribute as CFString
            ) {
                return document
            }

            guard depth < 6 else { continue }

            let children = copyElementArrayAttribute(
                element,
                kAXChildrenAttribute as CFString
            )

            queue.append(contentsOf: children.map { ($0, depth + 1) })
        }

        return nil
    }

    private func findSelectedTab(in root: AXUIElement) -> TabIdentity? {
        var queue: [(AXUIElement, Int)] = [(root, 0)]
        var visited = 0

        while !queue.isEmpty, visited < 220 {
            let (element, depth) = queue.removeFirst()
            visited += 1

            // Prefer the explicit AXTabs collection. Apple documents AXTabs
            // as the accessibility representation for tab controls.
            let tabs = copyElementArrayAttribute(
                element,
                kAXTabsAttribute as CFString
            )

            if !tabs.isEmpty {
                let selected = tabs.first {
                    copyBoolAttribute($0, kAXSelectedAttribute as CFString) == true
                }

                if let selected {
                    let index = tabs.firstIndex { CFEqual($0, selected) }
                    let title = copyStringAttribute(
                        selected,
                        kAXTitleAttribute as CFString
                    ) ?? copyStringAttribute(
                        selected,
                        kAXDescriptionAttribute as CFString
                    )
                    let documentURL = copyStringLikeAttribute(
                        selected,
                        kAXURLAttribute as CFString
                    ) ?? copyStringLikeAttribute(
                        selected,
                        kAXDocumentAttribute as CFString
                    )

                    return TabIdentity(
                        title: title,
                        index: index,
                        documentURL: documentURL
                    )
                }
            }

            let role = copyStringAttribute(
                element,
                kAXRoleAttribute as CFString
            )

            if role == "AXTabGroup" {
                let children = copyElementArrayAttribute(
                    element,
                    kAXChildrenAttribute as CFString
                )
                let selected = copyElementArrayAttribute(
                    element,
                    kAXSelectedChildrenAttribute as CFString
                ).first

                if let selected {
                    let index = children.firstIndex {
                        CFEqual($0, selected)
                    }

                    let title = copyStringAttribute(
                        selected,
                        kAXTitleAttribute as CFString
                    ) ?? copyStringAttribute(
                        selected,
                        kAXDescriptionAttribute as CFString
                    )
                    let documentURL = copyStringLikeAttribute(
                        selected,
                        kAXURLAttribute as CFString
                    ) ?? copyStringLikeAttribute(
                        selected,
                        kAXDocumentAttribute as CFString
                    )

                    return TabIdentity(
                        title: title,
                        index: index,
                        documentURL: documentURL
                    )
                }
            }

            guard depth < 7 else { continue }

            let children = copyElementArrayAttribute(
                element,
                kAXChildrenAttribute as CFString
            )

            queue.append(contentsOf: children.map { ($0, depth + 1) })
        }

        return nil
    }

    private func findWindowNumber(
        processIdentifier: pid_t,
        title: String?,
        frame: CGRect
    ) -> Int? {
        guard let info = CGWindowListCopyWindowInfo(
            [.optionAll, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return nil
        }

        let primaryTop = NSScreen.screens.first?.frame.maxY ?? 0

        let candidates = info.compactMap { item -> (Int, String?, CGRect)? in
            guard let ownerPID = item[kCGWindowOwnerPID as String] as? Int,
                  ownerPID == Int(processIdentifier),
                  let number = item[kCGWindowNumber as String] as? Int,
                  let boundsObject = item[kCGWindowBounds as String] as? NSDictionary,
                  let cgFrame = CGRect(
                    dictionaryRepresentation: boundsObject as CFDictionary
                  ) else {
                return nil
            }

            let cocoaFrame = CGRect(
                x: cgFrame.origin.x,
                y: primaryTop - cgFrame.origin.y - cgFrame.height,
                width: cgFrame.width,
                height: cgFrame.height
            )

            let name = item[kCGWindowName as String] as? String
            return (number, name, cocoaFrame)
        }

        if let title, !title.isEmpty {
            let titleMatch = candidates.first {
                ($0.1 ?? "").trimmingCharacters(in: .whitespacesAndNewlines) == title
                && approximatelyEqual($0.2, frame)
            }

            if let titleMatch {
                return titleMatch.0
            }
        }

        return candidates.first(where: {
            approximatelyEqual($0.2, frame)
        })?.0
    }

    private func displayIdentifier(for frame: CGRect) -> String? {
        let screen = NSScreen.screens.max {
            $0.frame.intersection(frame).area < $1.frame.intersection(frame).area
        }

        guard let screen,
              let number = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
              ] as? NSNumber else {
            return nil
        }

        return number.stringValue
    }

    private func approximatelyEqual(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        abs(lhs.minX - rhs.minX) < 4
        && abs(lhs.minY - rhs.minY) < 4
        && abs(lhs.width - rhs.width) < 4
        && abs(lhs.height - rhs.height) < 4
    }
}

private extension CGRect {
    var area: CGFloat {
        guard !isNull, !isInfinite else { return 0 }
        return max(0, width) * max(0, height)
    }
}
