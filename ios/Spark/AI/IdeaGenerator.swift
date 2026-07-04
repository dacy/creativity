import Foundation

/// A freshly generated idea, before it's persisted as an `Idea`.
struct GeneratedIdea {
    let title: String
    let details: String
    let category: String
    let durationMinutes: Int?
}

/// Everything the generator needs to produce personalized ideas.
struct GenerationContext {
    let criteria: String
    let profile: String
    let likedTitles: [String]
    let dislikedTitles: [String]
    let seenTitles: [String]
    let count: Int
}

/// One decided swipe, used as evidence for preference inference.
struct SwipeRecord {
    let title: String
    let details: String
    let category: String
    let liked: Bool
    let criteria: String
}

/// Abstraction over the idea-generating model so backends can be swapped:
/// Apple's on-device Foundation Model today, an MLX/llama.cpp model or a
/// remote API tomorrow.
protocol IdeaGenerating: Sendable {
    /// Human-readable label stored on each idea ("on-device", "mock", ...).
    var sourceLabel: String { get }

    /// Generate `context.count` fresh activity ideas.
    func generateIdeas(context: GenerationContext) async throws -> [GeneratedIdea]

    /// Re-infer the user's taste profile from observed swipe history.
    /// Returns nil if this backend can't do inference.
    func inferProfile(currentProfile: String, history: [SwipeRecord]) async throws -> String?
}
