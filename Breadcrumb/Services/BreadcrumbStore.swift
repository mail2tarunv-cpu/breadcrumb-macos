import Foundation

final class BreadcrumbStore {
    private let defaults: UserDefaults
    private let storageKey = "breadcrumb.records.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [BreadcrumbRecord] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }

        do {
            return try JSONDecoder().decode([BreadcrumbRecord].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ records: [BreadcrumbRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
