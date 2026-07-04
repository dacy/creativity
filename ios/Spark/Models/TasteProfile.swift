import Foundation
import SwiftData

/// The AI-inferred read on the user's taste, updated every few swipes
/// by observing likes/dislikes. Single-row table.
@Model
final class TasteProfile {
    var content: String
    var swipeCount: Int
    var updatedAt: Date?

    init() {
        self.content = ""
        self.swipeCount = 0
        self.updatedAt = nil
    }
}
