import Foundation

final class BreadcrumbStore {
    private let defaults: UserDefaults
    private let storageKey = "breadcrumb.records.v1"
    private let backupKey = "breadcrumb.records.v1.backup"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [BreadcrumbRecord] {
        if let primary = defaults.data(forKey: storageKey) {
            do {
                return try decode(primary)
            } catch {
                DiagnosticLog.shared.record(
                    category: "Storage",
                    summary: "Primary breadcrumb store could not be read",
                    detail: error.localizedDescription
                )
            }
        }

        guard let backup = defaults.data(forKey: backupKey) else {
            return []
        }

        do {
            let recovered = try decode(backup)

            // Self-heal the primary slot so the next launch follows the
            // normal path instead of repeatedly depending on the backup.
            defaults.set(backup, forKey: storageKey)

            DiagnosticLog.shared.record(
                category: "Storage",
                summary: "Recovered breadcrumbs from local backup",
                detail: "Recovered \(recovered.count) record(s)."
            )

            return recovered
        } catch {
            DiagnosticLog.shared.record(
                category: "Storage",
                summary: "Breadcrumb backup could not be read",
                detail: error.localizedDescription
            )
            return []
        }
    }

    func save(_ records: [BreadcrumbRecord]) {
        do {
            let data = try JSONEncoder().encode(records)

            if let current = defaults.data(forKey: storageKey),
               (try? decode(current)) != nil {
                defaults.set(current, forKey: backupKey)
            } else if defaults.data(forKey: backupKey) == nil {
                // First successful save: seed both slots so recovery is
                // available immediately.
                defaults.set(data, forKey: backupKey)
            }

            defaults.set(data, forKey: storageKey)
        } catch {
            DiagnosticLog.shared.record(
                category: "Storage",
                summary: "Breadcrumbs could not be saved",
                detail: error.localizedDescription
            )
        }
    }

    private func decode(_ data: Data) throws -> [BreadcrumbRecord] {
        try JSONDecoder().decode([BreadcrumbRecord].self, from: data)
    }
}
