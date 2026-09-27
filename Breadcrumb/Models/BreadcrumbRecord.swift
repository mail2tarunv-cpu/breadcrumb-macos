import Foundation

struct BreadcrumbRecord: Codable, Identifiable, Equatable {
    let id: UUID
    var text: String
    let bundleIdentifier: String
    let applicationName: String
    let windowTitle: String?
    var relativeX: Double
    var relativeY: Double
    let fallbackScreenX: Double
    let fallbackScreenY: Double
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

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
        self.fallbackScreenX = anchorPoint.x
        self.fallbackScreenY = anchorPoint.y
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false

        if let frame = context.windowFrame, frame.width > 0, frame.height > 0 {
            self.relativeX = min(max((anchorPoint.x - frame.minX) / frame.width, 0), 1)
            self.relativeY = min(max((anchorPoint.y - frame.minY) / frame.height, 0), 1)
        } else {
            self.relativeX = 0.5
            self.relativeY = 0.5
        }
    }

    func anchorPoint(in windowFrame: CGRect?) -> CGPoint {
        guard let frame = windowFrame, frame.width > 0, frame.height > 0 else {
            return CGPoint(x: fallbackScreenX, y: fallbackScreenY)
        }

        return CGPoint(
            x: frame.minX + frame.width * relativeX,
            y: frame.minY + frame.height * relativeY
        )
    }
}
