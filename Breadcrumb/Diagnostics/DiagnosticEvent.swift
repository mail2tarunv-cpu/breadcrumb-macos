import Foundation

struct DiagnosticEvent: Codable, Identifiable, Equatable {
    let id: UUID
    let timestamp: Date
    let category: String
    let summary: String
    let detail: String

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: String,
        summary: String,
        detail: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.summary = summary
        self.detail = detail
    }
}
