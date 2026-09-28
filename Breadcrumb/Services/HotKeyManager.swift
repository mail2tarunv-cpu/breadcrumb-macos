import AppKit
import Carbon.HIToolbox

enum CaptureShortcut: String, CaseIterable, Identifiable {
    case optionSpace
    case controlSpace
    case commandShiftB
    case optionB

    var id: String { rawValue }

    var title: String {
        switch self {
        case .optionSpace: return "⌥ Space"
        case .controlSpace: return "⌃ Space"
        case .commandShiftB: return "⌘⇧ B"
        case .optionB: return "⌥ B"
        }
    }

    var keyCode: UInt32 {
        switch self {
        case .optionSpace, .controlSpace:
            return UInt32(kVK_Space)
        case .commandShiftB, .optionB:
            return UInt32(kVK_ANSI_B)
        }
    }

    var modifiers: UInt32 {
        switch self {
        case .optionSpace:
            return UInt32(optionKey)
        case .controlSpace:
            return UInt32(controlKey)
        case .commandShiftB:
            return UInt32(cmdKey | shiftKey)
        case .optionB:
            return UInt32(optionKey)
        }
    }

    static var current: CaptureShortcut {
        let raw = UserDefaults.standard.string(forKey: "breadcrumb.capture.shortcut") ?? ""
        return CaptureShortcut(rawValue: raw) ?? .optionSpace
    }
}

final class HotKeyManager {
    static let shortcutDidChange = Notification.Name("BreadcrumbCaptureShortcutDidChange")

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var shortcutObserver: NSObjectProtocol?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        installHandler()
        registerShortcut()

        shortcutObserver = NotificationCenter.default.addObserver(
            forName: Self.shortcutDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.registerShortcut()
        }
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        if let shortcutObserver {
            NotificationCenter.default.removeObserver(shortcutObserver)
        }
    }

    private func installHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let pointer = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                guard hotKeyID.id == 1 else { return noErr }

                let manager = Unmanaged<HotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                DispatchQueue.main.async {
                    manager.action()
                }

                return noErr
            },
            1,
            &eventType,
            pointer,
            &eventHandler
        )

        DiagnosticLog.shared.record(
            category: "Hotkey",
            summary: status == noErr ? "Hotkey handler installed" : "Hotkey handler failed",
            detail: "InstallEventHandler status: \(status)"
        )
    }

    private func registerShortcut() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        let shortcut = CaptureShortcut.current
        let id = EventHotKeyID(signature: fourCharCode("BRDC"), id: 1)

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        DiagnosticLog.shared.record(
            category: "Hotkey",
            summary: status == noErr
                ? "\(shortcut.title) registered"
                : "\(shortcut.title) registration failed",
            detail: "RegisterEventHotKey status: \(status)"
        )
    }

    private func fourCharCode(_ value: String) -> OSType {
        value.utf8.reduce(0) { ($0 << 8) + OSType($1) }
    }
}
