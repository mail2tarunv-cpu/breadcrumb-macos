import AppKit

struct ContextSnapshot: Equatable {
    let bundleIdentifier: String
    let applicationName: String
    let windowTitle: String?
    let windowFrame: CGRect?
    let processIdentifier: pid_t?
    let windowNumber: Int?
    let documentURL: String?
    let selectedTabTitle: String?
    let selectedTabIndex: Int?
    let isMinimized: Bool
    let displayIdentifier: String?

    init(
        bundleIdentifier: String,
        applicationName: String,
        windowTitle: String?,
        windowFrame: CGRect?,
        processIdentifier: pid_t? = nil,
        windowNumber: Int? = nil,
        documentURL: String? = nil,
        selectedTabTitle: String? = nil,
        selectedTabIndex: Int? = nil,
        isMinimized: Bool = false,
        displayIdentifier: String? = nil
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
        self.windowTitle = windowTitle
        self.windowFrame = windowFrame
        self.processIdentifier = processIdentifier
        self.windowNumber = windowNumber
        self.documentURL = documentURL
        self.selectedTabTitle = selectedTabTitle
        self.selectedTabIndex = selectedTabIndex
        self.isMinimized = isMinimized
        self.displayIdentifier = displayIdentifier
    }

    var hasStableIdentity: Bool {
        guard !isMinimized,
              let frame = windowFrame,
              frame.width > 0,
              frame.height > 0 else {
            return false
        }

        return normalized(documentURL) != nil || normalized(windowTitle) != nil
    }

    func matches(_ record: BreadcrumbRecord) -> Bool {
        guard bundleIdentifier == record.bundleIdentifier else { return false }
        guard hasStableIdentity else { return false }

        let sameSession = processIdentifier != nil
            && record.processIdentifier != nil
            && processIdentifier == record.processIdentifier

        if sameSession,
           let savedWindow = record.windowNumber,
           let currentWindow = windowNumber,
           savedWindow != currentWindow {
            return false
        }

        let savedDocument = normalized(record.documentURL)
        let currentDocument = normalized(documentURL)
        let savedTitle = normalized(record.windowTitle)
        let currentTitle = normalized(windowTitle)
        let savedTabTitle = normalized(record.selectedTabTitle)
        let currentTabTitle = normalized(selectedTabTitle)

        // Document identity is stronger than presentation metadata. Safari can
        // restore a page with a new tab title while keeping the same URL.
        if let savedDocument,
           let currentDocument,
           savedDocument == currentDocument {
            if sameSession,
               let savedTabIndex = record.selectedTabIndex,
               let currentTabIndex = selectedTabIndex,
               savedTabIndex != currentTabIndex {
                return false
            }

            return true
        }

        // If the URL is unavailable or changed during restoration, use the
        // selected tab title as the next stable identifier.
        if let savedTabTitle,
           let currentTabTitle,
           savedTabTitle == currentTabTitle {
            return true
        }

        // Finally use the window title. This is especially useful while a
        // browser is still restoring its accessibility hierarchy.
        if let savedTitle,
           let currentTitle,
           savedTitle == currentTitle {
            return true
        }

        return false
    }

    private func normalized(_ value: String?) -> String? {
        guard let value else { return nil }

        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")

        return normalized.isEmpty ? nil : normalized
    }
}
