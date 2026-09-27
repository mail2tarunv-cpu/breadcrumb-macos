import AppKit
import ApplicationServices

final class ContextObserver {
    func captureCurrent() -> ContextSnapshot? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let bundleIdentifier = app.bundleIdentifier else {
            return nil
        }

        let appName = app.localizedName ?? bundleIdentifier

        guard AXIsProcessTrusted() else {
            return ContextSnapshot(
                bundleIdentifier: bundleIdentifier,
                applicationName: appName,
                windowTitle: nil,
                windowFrame: nil
            )
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        guard let window = copyElementAttribute(
            appElement,
            kAXFocusedWindowAttribute as CFString
        ) else {
            return ContextSnapshot(
                bundleIdentifier: bundleIdentifier,
                applicationName: appName,
                windowTitle: nil,
                windowFrame: nil
            )
        }

        let title = copyStringAttribute(
            window,
            kAXTitleAttribute as CFString
        )
        let frame = copyWindowFrame(window)

        return ContextSnapshot(
            bundleIdentifier: bundleIdentifier,
            applicationName: appName,
            windowTitle: title,
            windowFrame: frame
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
}
