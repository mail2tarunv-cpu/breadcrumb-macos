import AppKit
import ApplicationServices

enum PermissionManager {
    static var hasAccessibilityAccess: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityAccess() {
        let before = AXIsProcessTrusted()

        DiagnosticLog.shared.record(
            category: "Permission",
            summary: before ? "Accessibility already granted" : "Requesting Accessibility access",
            detail: [
                "bundle: \(Bundle.main.bundleIdentifier ?? "nil")",
                "path: \(Bundle.main.bundlePath)",
                "trustedBeforeRequest: \(before)"
            ].joined(separator: "\n")
        )

        guard !before else { return }

        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let trusted = AXIsProcessTrusted()

            DiagnosticLog.shared.record(
                category: "Permission",
                summary: trusted ? "Accessibility granted" : "Accessibility still not granted",
                detail: [
                    "bundle: \(Bundle.main.bundleIdentifier ?? "nil")",
                    "path: \(Bundle.main.bundlePath)",
                    "trustedAfterRequest: \(trusted)"
                ].joined(separator: "\n")
            )

            if !trusted {
                openAccessibilitySettings()
            }
        }
    }

    static func openAccessibilitySettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]

        for rawURL in urls {
            guard let url = URL(string: rawURL) else { continue }

            if NSWorkspace.shared.open(url) {
                DiagnosticLog.shared.record(
                    category: "Permission",
                    summary: "Opened Accessibility settings",
                    detail: "URL: \(rawURL)"
                )
                return
            }
        }

        DiagnosticLog.shared.record(
            category: "Permission",
            summary: "Could not open Accessibility settings",
            detail: "Open System Settings → Privacy & Security → Accessibility manually."
        )
    }
}
