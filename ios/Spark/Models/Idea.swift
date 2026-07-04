import Foundation
import SwiftData

enum IdeaStatus: String, Codable, CaseIterable {
    case pending
    case liked
    case disliked
    case skipped
}

@Model
final class Idea {
    var title: String
    var details: String
    var category: String
    var durationMinutes: Int?
    /// The user's criteria text at the moment this idea was generated.
    var criteria: String
    var statusRaw: String
    /// "on-device" (Apple Intelligence) or "mock"
    var source: String
    var createdAt: Date
    var decidedAt: Date?

    var status: IdeaStatus {
        get { IdeaStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    init(
        title: String,
        details: String,
        category: String,
        durationMinutes: Int?,
        criteria: String,
        source: String
    ) {
        self.title = title
        self.details = details
        self.category = category
        self.durationMinutes = durationMinutes
        self.criteria = criteria
        self.statusRaw = IdeaStatus.pending.rawValue
        self.source = source
        self.createdAt = .now
        self.decidedAt = nil
    }
}
