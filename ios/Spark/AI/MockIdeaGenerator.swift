import Foundation

/// Fallback generator for the simulator and for devices without Apple
/// Intelligence. Ideas come from a canned pool; the "profile" is a simple
/// heuristic summary of category counts, so the whole app stays usable.
struct MockIdeaGenerator: IdeaGenerating {
    var sourceLabel: String { "mock" }

    private static let pool: [GeneratedIdea] = [
        .init(title: "Blind contour self-portrait", details: "Draw your own face without looking at the paper or lifting the pen. The results are always hilariously wrong, which is the point — it trains observation and kills perfectionism.", category: "creative", durationMinutes: 15),
        .init(title: "One-song kitchen dance mix", details: "Pick one song you loved as a teenager, play it loud, and cook or clean while it loops. Nostalgia plus movement is an instant mood shift.", category: "movement", durationMinutes: 10),
        .init(title: "Micro photo essay", details: "Take exactly five photos that tell a story about the room you're in, then give the series a title. Constraints make it art instead of snapshots.", category: "creative", durationMinutes: 20),
        .init(title: "Speedrun a Wikipedia rabbit hole", details: "Start at a random article and reach 'Philosophy' by clicking only in-article links. Time yourself. You'll learn three weird facts minimum.", category: "mental", durationMinutes: 15),
        .init(title: "Letter to future you", details: "Write a short letter to yourself one year from now and schedule it with an email-later service. Takes ten minutes, pays off in a year.", category: "reflection", durationMinutes: 10),
        .init(title: "Five-object still life", details: "Grab five random objects from around you and arrange them into the most dramatic still-life composition you can, then photograph it like a museum piece.", category: "creative", durationMinutes: 20),
        .init(title: "Stairwell interval sprint", details: "Find the nearest stairs and do 8 rounds of up-fast, down-slow. A legit workout hiding in your building.", category: "fitness", durationMinutes: 15),
        .init(title: "Learn a card flourish", details: "Pull up a tutorial for the 'charlier cut' one-handed card flourish and drill it. A pocket-sized skill that impresses forever.", category: "skill", durationMinutes: 25),
        .init(title: "Sound map meditation", details: "Sit still, close your eyes, and mentally map every sound you can hear by direction and distance. Mindfulness disguised as a spy exercise.", category: "reflection", durationMinutes: 10),
        .init(title: "Haiku news digest", details: "Read three headlines, then summarize each as a haiku. Absurdly effective way to feel informed and amused at once.", category: "creative", durationMinutes: 15),
        .init(title: "Text a micro-compliment", details: "Send three people one specific, true compliment each — not 'you're great' but 'the way you handled X was sharp'. Watch the replies roll in.", category: "social", durationMinutes: 10),
        .init(title: "Desk-drawer archaeology", details: "Empty one drawer completely and treat every object as an artifact: keep, gift, or toss. You'll find at least one forgotten treasure.", category: "practical", durationMinutes: 20),
    ]

    func generateIdeas(context: GenerationContext) async throws -> [GeneratedIdea] {
        let seen = Set(context.seenTitles)
        let fresh = Self.pool.filter { !seen.contains($0.title) }
        let source = fresh.count >= context.count ? fresh : Self.pool
        return Array(source.shuffled().prefix(context.count))
    }

    func inferProfile(currentProfile: String, history: [SwipeRecord]) async throws -> String? {
        guard !history.isEmpty else { return nil }

        var likedCategories: [String: Int] = [:]
        var rejectedCategories: [String: Int] = [:]
        for record in history {
            if record.liked {
                likedCategories[record.category, default: 0] += 1
            } else {
                rejectedCategories[record.category, default: 0] += 1
            }
        }

        func top(_ counts: [String: Int]) -> String {
            counts.sorted { $0.value > $1.value }
                .prefix(3)
                .map { "\($0.key) (\($0.value)×)" }
                .joined(separator: ", ")
        }

        return """
        ## Drawn to
        \(likedCategories.isEmpty ? "Not enough likes yet." : top(likedCategories))

        ## Avoids
        \(rejectedCategories.isEmpty ? "Not enough rejections yet." : top(rejectedCategories))

        *This is a simple category tally — on a device with Apple Intelligence, \
        Spark's on-device model writes a much richer inferred profile.*
        """
    }
}
