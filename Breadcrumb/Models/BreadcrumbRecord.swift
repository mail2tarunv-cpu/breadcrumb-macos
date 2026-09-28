import Foundation

struct BreadcrumbRecord: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    let bundleIdentifier: String
    let applicationName: String
    let windowTitle: String?
    let processIdentifier: pid_t?
    let windowNumber: Int?
    let documentURL: String?
    let selectedTabTitle: String?
    let selectedTabIndex: Int?
    let displayIdentifier: String?
    let contextVersion: Int?
    var relativeX: Double
    var relativeY: Double
    let fallbackScreenX: Double
    let fallbackScreenY: Double
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var snoozedUntil: Date?
    var colorName: String?

    init(
        id: UUID = UUID(),
        text: String,
        context: ContextSnapshot,
        anchorPoint: CGPoint
    ) {
        self.id = id
        self.text = text
        self.bundleIdentifier = context.bundleIdentifier
        self.applicationName = context.applicationName
        self.windowTitle = context.windowTitle
        self.processIdentifier = context.processIdentifier
        self.windowNumber = context.windowNumber
        self.documentURL = context.documentURL
        self.selectedTabTitle = context.selectedTabTitle
        self.selectedTabIndex = context.selectedTabIndex
        self.displayIdentifier = context.displayIdentifier
        self.contextVersion = 2
        self.fallbackScreenX = anchorPoint.x
        self.fallbackScreenY = anchorPoint.y
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false
        self.snoozedUntil = nil
        self.colorName = BreadcrumbColor.lavender.rawValue

        if let frame = context.windowFrame, frame.width > 0, frame.height > 0 {
            self.relativeX = min(max((anchorPoint.x - frame.minX) / frame.width, 0), 1)
            self.relativeY = min(max((anchorPoint.y - frame.minY) / frame.height, 0), 1)
        } else {
            self.relativeX = 0.5
            self.relativeY = 0.5
        }
    }

    var breadcrumbColor: BreadcrumbColor {
        get { BreadcrumbColor(rawValue: colorName ?? "") ?? .lavender }
        set { colorName = newValue.rawValue }
    }

    var isSnoozed: Bool {
        guard let snoozedUntil else { return false }
        return snoozedUntil > Date()
    }

    var isLegacyContext: Bool {
        contextVersion != 2
    }

    var hasStableContext: Bool {
        guard !isLegacyContext else { return false }

        let hasDocument = !(documentURL?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true)

        let hasTitle = !(windowTitle?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty ?? true)

        return hasDocument || hasTitle
    }

    var contextSummary: String {
        if let documentURL, !documentURL.isEmpty {
            return documentURL
        }

        if let selectedTabTitle, !selectedTabTitle.isEmpty {
            return selectedTabTitle
        }

        return windowTitle ?? applicationName
    }

    func anchorPoint(in windowFrame: CGRect?) -> CGPoint {
        guard let frame = windowFrame, frame.width > 0, frame.height > 0 else {
            return CGPoint(x: fallbackScreenX, y: fallbackScreenY)
        }

        let safeX = relativeX.isFinite ? min(max(relativeX, 0), 1) : 0.5
        let safeY = relativeY.isFinite ? min(max(relativeY, 0), 1) : 0.5

        return CGPoint(
            x: frame.minX + frame.width * safeX,
            y: frame.minY + frame.height * safeY
        )
    }
}
