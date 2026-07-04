import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class SwipeViewModel {
    var queue: [Idea] = []
    var criteriaInput: String = ""
    var activeCriteria: String?
    var isLoading = false
    var errorMessage: String?
    var usingMock = false
    var profileJustUpdated = false

    /// Re-infer the taste profile every N decisive swipes.
    private let profileUpdateInterval = 4
    private let batchSize = 3
    private let generator = GeneratorFactory.make()
    private var isFetching = false

    init() {
        usingMock = !(generator is FoundationModelGenerator)
    }

    // MARK: - Session

    func startSession(context: ModelContext) async {
        let trimmed = criteriaInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activeCriteria = trimmed
        queue.removeAll()
        await fetchIdeas(context: context, showSpinner: true)
    }

    // MARK: - Swiping

    func decide(_ idea: Idea, liked: Bool, context: ModelContext) async {
        idea.status = liked ? .liked : .disliked
        idea.decidedAt = .now
        let profile = fetchOrCreateProfile(context: context)
        profile.swipeCount += 1
        try? context.save()

        queue.removeAll { $0.persistentModelID == idea.persistentModelID }

        // Top up the queue in the background.
        if queue.count <= 2 {
            Task { await self.fetchIdeas(context: context, showSpinner: false) }
        }

        // Periodically re-infer the taste profile from observed behavior.
        if profile.swipeCount > 0, profile.swipeCount % profileUpdateInterval == 0 {
            await updateProfile(profile: profile, context: context)
        }
    }

    // MARK: - Generation

    private func fetchIdeas(context: ModelContext, showSpinner: Bool) async {
        guard !isFetching, let criteria = activeCriteria else { return }
        isFetching = true
        if showSpinner { isLoading = true }
        errorMessage = nil
        defer {
            isFetching = false
            isLoading = false
        }

        do {
            let generated = try await generator.generateIdeas(context: GenerationContext(
                criteria: criteria,
                profile: fetchOrCreateProfile(context: context).content,
                likedTitles: titles(status: .liked, limit: 10, context: context),
                dislikedTitles: titles(status: .disliked, limit: 10, context: context),
                seenTitles: allTitles(limit: 60, context: context),
                count: batchSize
            ))

            for item in generated {
                let idea = Idea(
                    title: item.title,
                    details: item.details,
                    category: item.category,
                    durationMinutes: item.durationMinutes,
                    criteria: criteria,
                    source: generator.sourceLabel
                )
                context.insert(idea)
                queue.append(idea)
            }
            try context.save()
        } catch {
            errorMessage = "Couldn't generate ideas: \(error.localizedDescription)"
        }
    }

    private func updateProfile(profile: TasteProfile, context: ModelContext) async {
        let history = recentDecisions(limit: 30, context: context)
        do {
            if let updated = try await generator.inferProfile(
                currentProfile: profile.content,
                history: history
            ) {
                profile.content = updated
                profile.updatedAt = .now
                try? context.save()
                profileJustUpdated = true
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    self.profileJustUpdated = false
                }
            }
        } catch {
            // Profile inference failing should never interrupt swiping.
        }
    }

    // MARK: - Queries

    private func fetchOrCreateProfile(context: ModelContext) -> TasteProfile {
        let descriptor = FetchDescriptor<TasteProfile>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let profile = TasteProfile()
        context.insert(profile)
        return profile
    }

    private func titles(status: IdeaStatus, limit: Int, context: ModelContext) -> [String] {
        let raw = status.rawValue
        var descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.statusRaw == raw },
            sortBy: [SortDescriptor(\.decidedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor).map(\.title)) ?? []
    }

    private func allTitles(limit: Int, context: ModelContext) -> [String] {
        var descriptor = FetchDescriptor<Idea>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? context.fetch(descriptor).map(\.title)) ?? []
    }

    private func recentDecisions(limit: Int, context: ModelContext) -> [SwipeRecord] {
        let liked = IdeaStatus.liked.rawValue
        let disliked = IdeaStatus.disliked.rawValue
        var descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.statusRaw == liked || $0.statusRaw == disliked },
            sortBy: [SortDescriptor(\.decidedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let ideas = (try? context.fetch(descriptor)) ?? []
        return ideas.map {
            SwipeRecord(
                title: $0.title,
                details: $0.details,
                category: $0.category,
                liked: $0.status == .liked,
                criteria: $0.criteria
            )
        }
    }
}
