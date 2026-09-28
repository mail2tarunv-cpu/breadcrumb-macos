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

    func clear() {
        defaults.removeObject(forKey: storageKey)
    }
}
