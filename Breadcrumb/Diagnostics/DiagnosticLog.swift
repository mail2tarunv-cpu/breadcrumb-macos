import Foundation

final class DiagnosticLog {
    static let shared = DiagnosticLog()

    private let defaults = UserDefaults.standard
    private let storageKey = "breadcrumb.diagnostics.v1"
    private let maximumEvents = 500

    private init() {}

    var events: [DiagnosticEvent] {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([DiagnosticEvent].self, from: data) else {
            return []
        }
        return decoded
    }

    func record(category: String, summary: String, detail: String) {
        var current = events
        current.append(
            DiagnosticEvent(
                category: category,
                summary: summary,
                detail: detail
            )
        )

        if current.count > maximumEvents {
            current.removeFirst(current.count - maximumEvents)
        }

        guard let data = try? JSONEncoder().encode(current) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func supportSummary() -> String {
        let recent = events.suffix(40)
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        let os = ProcessInfo.processInfo.operatingSystemVersionString
        let permission = PermissionManager.hasAccessibilityAccess ? "enabled" : "not enabled"

        let categoryCounts = Dictionary(grouping: events, by: \.category)
            .map { "\($0.key): \($0.value.count)" }
            .sorted()
            .joined(separator: ", ")

        let lines = recent.map { event in
            let timestamp = event.timestamp.formatted(
                date: .abbreviated,
                time: .standard
            )
            return "[\(timestamp)] \(event.category) — \(event.summary)"
        }

        return ([
            "Breadcrumb Support Summary",
            "Version: \(version) (\(build))",
            "macOS: \(os)",
            "Accessibility: \(permission)",
            "Events: \(events.count)",
            "Categories: \(categoryCounts.isEmpty ? "none" : categoryCounts)",
            "",
            "Recent event summaries (note text and diagnostic detail omitted):"
        ] + lines).joined(separator: "\n")
    }

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}
