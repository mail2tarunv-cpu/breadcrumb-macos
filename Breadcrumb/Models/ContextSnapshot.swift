import AppKit

struct ContextSnapshot: Equatable {
    let bundleIdentifier: String
    let applicationName: String
    let windowTitle: String?
    let windowFrame: CGRect?

    func matches(_ record: BreadcrumbRecord) -> Bool {
        guard bundleIdentifier == record.bundleIdentifier else { return false }

        switch (windowTitle, record.windowTitle) {
        case let (.some(current), .some(saved)):
            return current == saved
        default:
            return true
        }
    }
}
