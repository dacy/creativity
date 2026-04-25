import Foundation
import SwiftUI

// MARK: - Goals

enum Goal: String, CaseIterable, Identifiable, Codable {
    case startup = "Start a business"
    case personal = "Solve a daily-life problem"
    case creative = "Make something creative"
    case explore = "Just spark something"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .startup:  return "Headed for customers and revenue"
        case .personal: return "A small fix for me, my family, or my work"
        case .creative: return "Art, writing, music, video — for the joy of it"
        case .explore:  return "Surprise me with something fresh"
        }
    }

    var emoji: String {
        switch self {
        case .startup:  return "🚀"
        case .personal: return "🌱"
        case .creative: return "🎨"
        case .explore:  return "✨"
        }
    }

    /// Whether the post-idea research should focus on competitive landscape.
    var researchAsStartup: Bool {
        self == .startup
    }
}

// MARK: - Decision tree primitives

struct Choice: Identifiable, Hashable {
    let id = UUID()
    let key: String
    let label: String
    let emoji: String
}

struct Step: Identifiable {
    let id = UUID()
    /// Stable key used to look up the user's selection later (e.g., "audience").
    let key: String
    let prompt: String
    let helper: String?
    let choices: [Choice]
    /// If true, user can skip this step and let Spark pick a default.
    let allowSkip: Bool
}

// MARK: - Generated artifacts

struct GeneratedIdea: Identifiable {
    let id = UUID()
    let title: String
    let oneLiner: String
    let problem: String
    let user: String
    let solution: String
    let twist: String
    let createdAt: Date
}

enum Verdict: String {
    case build    = "Build it yourself"
    case buy      = "Use what already exists"
    case startup  = "Worth a real startup attempt"
    case explore  = "Promising — explore more"
    case skip     = "Skip — not worth it now"

    var emoji: String {
        switch self {
        case .build:   return "🔨"
        case .buy:     return "🛒"
        case .startup: return "🚀"
        case .explore: return "🔍"
        case .skip:    return "🙅"
        }
    }

    var color: Color {
        switch self {
        case .build:   return .orange
        case .buy:     return .blue
        case .startup: return .pink
        case .explore: return .purple
        case .skip:    return .gray
        }
    }
}

struct ExistingSolution: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let pricingHint: String
}

struct ResearchResult {
    let kind: ResearchKind
    let summary: String
    let existingSolutions: [ExistingSolution]
    let opportunities: [String]
    let risks: [String]
    let verdict: Verdict
    let nextSteps: [String]
}

enum ResearchKind {
    case startup       // competitive landscape
    case buildVsBuy    // is there an off-the-shelf option?
}

// MARK: - Session

enum AppScreen: Equatable {
    case welcome
    case decisions(stepIndex: Int)
    case clarify
    case generating
    case idea
    case researching
    case research
}

@MainActor
final class IdeaSession: ObservableObject {
    @Published var goal: Goal? = nil
    @Published var choices: [String: Choice] = [:]
    @Published var clarification: String = ""
    @Published var idea: GeneratedIdea? = nil
    @Published var research: ResearchResult? = nil
    @Published var screen: AppScreen = .welcome

    var steps: [Step] {
        guard let goal else { return [] }
        return DecisionTree.steps(for: goal)
    }

    func choose(_ choice: Choice, forStepKey key: String) {
        choices[key] = choice
    }

    func reset() {
        goal = nil
        choices = [:]
        clarification = ""
        idea = nil
        research = nil
        screen = .welcome
    }
}
