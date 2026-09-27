import ApplicationServices

enum PermissionManager {
    static var hasAccessibilityAccess: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityAccess() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
