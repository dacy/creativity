import Foundation
import FoundationModels

// MARK: - Guided-generation output shapes

@Generable
struct GenerableIdea {
    @Guide(description: "Short, punchy name of the activity (under 8 words)")
    var title: String

    @Guide(description: "2-3 sentences: concretely what to do and why it's interesting")
    var details: String

    @Guide(description: "One-word category, e.g. creative, fitness, social, mental, reflection, practical")
    var category: String

    @Guide(description: "Estimated minutes the activity takes; 0 if open-ended")
    var durationMinutes: Int
}

@Generable
struct GenerableIdeaBatch {
    @Guide(description: "The generated activity ideas")
    var ideas: [GenerableIdea]
}

@Generable
struct GenerableProfile {
    @Guide(description: "Concise markdown taste profile, under 250 words, with short sections like 'Drawn to', 'Avoids', 'Patterns', 'Open questions'")
    var profile: String
}

// MARK: - Generator backed by Apple's on-device Foundation Model

/// Uses the Apple Intelligence on-device model (iOS 26+). Everything runs
/// locally — prompts and swipe history never leave the device.
struct FoundationModelGenerator: IdeaGenerating {
    var sourceLabel: String { "on-device" }

    static var isAvailable: Bool {
        SystemLanguageModel.default.availability == .available
    }

    func generateIdeas(context: GenerationContext) async throws -> [GeneratedIdea] {
        let session = LanguageModelSession(instructions: """
            You are the recommendation engine of an activity-idea app. The user \
            swipes right (like) or left (dislike) on your ideas, and you learn \
            their taste over time. Propose creative, specific, immediately doable \
            activities that fit the user's stated criteria and observed preferences. \
            Avoid generic filler; vary categories so swipes reveal taste.
            """)

        var prompt = "The user's current criteria: \(context.criteria)\n"
        if !context.profile.isEmpty {
            prompt += "\nInferred taste profile (strong guidance):\n\(context.profile)\n"
        }
        if !context.likedTitles.isEmpty {
            prompt += "\nRecently LIKED: \(context.likedTitles.prefix(10).joined(separator: "; "))\n"
        }
        if !context.dislikedTitles.isEmpty {
            prompt += "\nRecently REJECTED: \(context.dislikedTitles.prefix(10).joined(separator: "; "))\n"
        }
        if !context.seenTitles.isEmpty {
            // Keep the prompt small — the on-device model has a modest context window.
            prompt += "\nAlready shown, do not repeat: \(context.seenTitles.prefix(30).joined(separator: "; "))\n"
        }
        prompt += "\nGenerate exactly \(context.count) activity ideas."

        let response = try await session.respond(
            to: prompt,
            generating: GenerableIdeaBatch.self
        )

        return response.content.ideas.prefix(context.count).map {
            GeneratedIdea(
                title: $0.title,
                details: $0.details,
                category: $0.category.lowercased(),
                durationMinutes: $0.durationMinutes > 0 ? $0.durationMinutes : nil
            )
        }
    }

    func inferProfile(currentProfile: String, history: [SwipeRecord]) async throws -> String? {
        guard !history.isEmpty else { return nil }

        let session = LanguageModelSession(instructions: """
            You maintain a taste profile for a user of an activity-recommendation \
            app, purely by observing which ideas they liked or rejected. You never \
            ask the user questions — you infer the underlying WHY: themes, energy \
            level, social vs solo, indoor vs outdoor, creative vs analytical, cost \
            sensitivity, novelty vs comfort. Hedge where evidence is thin.
            """)

        let lines = history.prefix(20).map { record in
            "[\(record.liked ? "LIKED" : "REJECTED")] \"\(record.title)\" (\(record.category)) — \(record.details)"
        }

        let prompt = """
        Current profile (may be empty):
        \(currentProfile.isEmpty ? "(empty)" : currentProfile)

        Recent swipe history, newest first:
        \(lines.joined(separator: "\n"))

        Update the profile. Note both attractions and aversions. This text is \
        fed to the idea generator, so make it actionable.
        """

        let response = try await session.respond(
            to: prompt,
            generating: GenerableProfile.self
        )
        return response.content.profile
    }
}
