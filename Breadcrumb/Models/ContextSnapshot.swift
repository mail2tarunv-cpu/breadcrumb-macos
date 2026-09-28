import AppKit

struct ContextSnapshot: Equatable {
    let bundleIdentifier: String
    let applicationName: String
    let windowTitle: String?
    let windowFrame: CGRect?
    let processIdentifier: pid_t?
    let windowNumber: Int?

    init(
        bundleIdentifier: String,
        applicationName: String,
        windowTitle: String?,
        windowFrame: CGRect?,
        processIdentifier: pid_t? = nil,
        windowNumber: Int? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
        self.windowTitle = windowTitle
        self.windowFrame = windowFrame
        self.processIdentifier = processIdentifier
        self.windowNumber = windowNumber
    }

    var hasStableIdentity: Bool {
        guard let title = normalized(windowTitle),
              !title.isEmpty,
              let frame = windowFrame,
              frame.width > 0,
              frame.height > 0 else {
            return false
        }

        return true
    }

    func matches(_ record: BreadcrumbRecord) -> Bool {
        guard bundleIdentifier == record.bundleIdentifier else { return false }
        guard hasStableIdentity else { return false }
        guard let currentTitle = normalized(windowTitle),
              let savedTitle = normalized(record.windowTitle),
              currentTitle == savedTitle else {
            return false
        }

        if let savedPID = record.processIdentifier,
           let currentPID = processIdentifier,
           savedPID == currentPID,
           let savedWindow = record.windowNumber,
           let currentWindow = windowNumber {
            return savedWindow == currentWindow
        }

        return true
    }

    private func normalized(_ value: String?) -> String? {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }
}
