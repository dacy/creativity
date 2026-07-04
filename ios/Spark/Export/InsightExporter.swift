import Foundation

/// Builds shareable exports of everything Spark has learned about the user,
/// so they can carry their taste to any external LLM (ChatGPT, Claude,
/// Gemini, a local model — anywhere). Export is the ONLY way data leaves
/// the device, and it's always user-initiated via the share sheet.
enum InsightExporter {

    /// A markdown "taste dossier" with a ready-to-paste preamble, designed
    /// to be dropped straight into a chat with any LLM.
    static func markdown(profile: TasteProfile, liked: [Idea], disliked: [Idea]) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        var doc = """
        # My activity taste profile (from Spark)

        > Paste-ready context for an AI assistant. Spark is an app where I \
        swipe on activity ideas; it inferred the profile below purely by \
        observing my likes and dislikes. Use it to recommend activities, \
        plan projects, or develop the liked ideas below into concrete plans.

        Exported \(formatter.string(from: .now)) · \(profile.swipeCount) swipes recorded

        ## Inferred taste profile

        \(profile.content.isEmpty ? "_No profile inferred yet._" : profile.content)

        ## Ideas I liked (\(liked.count))

        """

        if liked.isEmpty {
            doc += "_None yet._\n"
        } else {
            for idea in liked {
                doc += "- **\(idea.title)** (\(idea.category)"
                if let minutes = idea.durationMinutes { doc += ", ~\(minutes) min" }
                doc += ") — \(idea.details)\n"
            }
        }

        doc += "\n## Ideas I rejected (\(disliked.count))\n\n"
        if disliked.isEmpty {
            doc += "_None yet._\n"
        } else {
            for idea in disliked {
                doc += "- \(idea.title) (\(idea.category))\n"
            }
        }

        return doc
    }

    /// Machine-readable export of the full local dataset.
    static func json(profile: TasteProfile, ideas: [Idea]) -> String {
        struct ExportIdea: Codable {
            let title: String
            let details: String
            let category: String
            let durationMinutes: Int?
            let criteria: String
            let status: String
            let source: String
            let createdAt: Date
            let decidedAt: Date?
        }
        struct Export: Codable {
            let app: String
            let exportedAt: Date
            let swipeCount: Int
            let tasteProfile: String
            let profileUpdatedAt: Date?
            let ideas: [ExportIdea]
        }

        let payload = Export(
            app: "Spark",
            exportedAt: .now,
            swipeCount: profile.swipeCount,
            tasteProfile: profile.content,
            profileUpdatedAt: profile.updatedAt,
            ideas: ideas.map {
                ExportIdea(
                    title: $0.title,
                    details: $0.details,
                    category: $0.category,
                    durationMinutes: $0.durationMinutes,
                    criteria: $0.criteria,
                    status: $0.statusRaw,
                    source: $0.source,
                    createdAt: $0.createdAt,
                    decidedAt: $0.decidedAt
                )
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
