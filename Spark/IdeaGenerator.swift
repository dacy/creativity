import Foundation

/// Synthesizes a concrete idea from the user's tap-choices.
///
/// We deliberately keep this fully on-device: it's a structured remix of
/// the choices, plus a clarification note if the user typed one. There's
/// no API key required. The output is intentionally specific (problem,
/// user, solution, twist) so the research step has something to chew on.
enum IdeaGenerator {

    static func generate(
        goal: Goal,
        choices rawChoices: [String: Choice],
        clarification: String
    ) -> GeneratedIdea {
        let choices = DecisionTree.resolveSurprises(in: rawChoices, for: goal)

        let user      = userPhrase(for: goal, choices: choices)
        let problem   = problemPhrase(for: goal, choices: choices, clarification: clarification)
        let solution  = solutionPhrase(for: goal, choices: choices)
        let twist     = twistPhrase(for: goal, choices: choices)
        let title     = titlePhrase(for: goal, choices: choices)
        let oneLiner  = "\(solution) for \(user) — \(twist.lowercased())."

        return GeneratedIdea(
            title: title,
            oneLiner: oneLiner,
            problem: problem,
            user: user,
            solution: solution,
            twist: twist,
            createdAt: Date()
        )
    }

    // MARK: - Phrase builders

    private static func userPhrase(for goal: Goal, choices: [String: Choice]) -> String {
        switch goal {
        case .startup:
            switch choices["audience"]?.key {
            case "consumers":     return "everyday people"
            case "professionals": return "working professionals"
            case "smb":           return "small business owners"
            case "developers":    return "developers and makers"
            case "creators":      return "online creators"
            default:              return "a focused niche audience"
            }
        case .personal:
            switch choices["area"]?.key {
            case "productivity": return "you, on a chaotic workday"
            case "health":       return "you, trying to stick with a habit"
            case "home":         return "you and the people you live with"
            case "money":        return "you, watching your spending"
            case "hobby":        return "you, on a free evening"
            default:             return "you and people like you"
            }
        case .creative:
            switch choices["medium"]?.key {
            case "visual":      return "visual art viewers"
            case "writing":     return "readers who like quiet stories"
            case "music":       return "headphone listeners"
            case "video":       return "short-attention scrollers"
            case "interactive": return "curious players"
            default:            return "an audience hungry for something new"
            }
        case .explore:
            switch choices["energy"]?.key {
            case "curious":   return "the curious, mid-coffee"
            case "restless":  return "the restless, late at night"
            case "cozy":      return "the cozy, on a slow Sunday"
            case "ambitious": return "the ambitious, between meetings"
            default:          return "anyone in the right mood"
            }
        }
    }

    private static func problemPhrase(for goal: Goal, choices: [String: Choice], clarification: String) -> String {
        let base: String
        switch goal {
        case .startup:
            let pain = choices["pain"]?.key ?? "fragmented"
            let domain = choices["domain"]?.label.lowercased() ?? "the space"
            switch pain {
            case "time":       base = "Tasks in \(domain) burn hours that should take minutes."
            case "money":      base = "The current options in \(domain) are absurdly expensive for what they deliver."
            case "fragmented": base = "Solving anything in \(domain) means stitching together three or four tools."
            case "boring":     base = "The work in \(domain) is tedious in ways nobody has bothered to fix."
            case "scary":      base = "Newcomers to \(domain) bounce off because everything feels intimidating."
            default:           base = "There's an obvious gap in \(domain) that incumbents keep missing."
            }
        case .personal:
            let area = choices["area"]?.label.lowercased() ?? "daily life"
            let trigger = choices["trigger"]?.key ?? "decision"
            switch trigger {
            case "decision": base = "\(area.capitalized) collapses under too many small decisions."
            case "memory":   base = "Things in \(area) fall through the cracks because remembering them is its own job."
            case "habit":    base = "A habit in \(area) that should stick keeps slipping."
            case "noise":    base = "Useful signals in \(area) get drowned in noise."
            case "lonely":   base = "\(area.capitalized) gets harder when you're doing it alone."
            default:         base = "\(area.capitalized) has friction that's been quietly accepted for too long."
            }
        case .creative:
            let medium  = choices["medium"]?.label.lowercased() ?? "creative work"
            let emotion = choices["emotion"]?.label.lowercased() ?? "feeling"
            base = "Most \(medium) skips the chance to leave behind \(emotion)."
        case .explore:
            let ingredient = choices["ingredient"]?.label.lowercased() ?? "an unusual ingredient"
            base = "Few projects get to play with \(ingredient) in a personal way."
        }

        let trimmed = clarification.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return base }
        return base + " Specifically: \(trimmed)"
    }

    private static func solutionPhrase(for goal: Goal, choices: [String: Choice]) -> String {
        let vibeKey = choices["vibe"]?.key ?? "useful"
        let prefix: String
        switch vibeKey {
        case "useful":  prefix = "A quietly useful"
        case "playful": prefix = "A playful"
        case "bold":    prefix = "A bold"
        case "calm":    prefix = "A calming"
        case "weird":   prefix = "A pleasantly weird"
        default:        prefix = "A focused"
        }

        switch goal {
        case .startup:
            switch choices["domain"]?.key {
            case "software":    return "\(prefix) software tool"
            case "product":     return "\(prefix) physical product"
            case "service":     return "\(prefix) hands-on service"
            case "media":       return "\(prefix) media product"
            case "marketplace": return "\(prefix) marketplace"
            default:            return "\(prefix) product"
            }
        case .personal:
            return "\(prefix) personal helper"
        case .creative:
            switch choices["medium"]?.key {
            case "visual":      return "\(prefix) visual piece"
            case "writing":     return "\(prefix) piece of writing"
            case "music":       return "\(prefix) audio piece"
            case "video":       return "\(prefix) short film"
            case "interactive": return "\(prefix) interactive toy"
            default:            return "\(prefix) creative piece"
            }
        case .explore:
            return "\(prefix) tiny project"
        }
    }

    private static func twistPhrase(for goal: Goal, choices: [String: Choice]) -> String {
        let constraint = choices["constraint"]?.key ?? "weekend"
        switch constraint {
        case "weekend":   return "Built end-to-end in a weekend"
        case "cheap":     return "Costs almost nothing to run"
        case "original":  return "With a twist nobody else is doing"
        case "shareable": return "Ridiculously easy to share with one tap"
        case "offline":   return "Works fully offline"
        default:          return "With a clear point of view"
        }
    }

    private static func titlePhrase(for goal: Goal, choices: [String: Choice]) -> String {
        let nouns: [String]
        switch goal {
        case .startup:  nouns = ["Lighthouse", "Northstar", "Kindling", "Counter", "Pact", "Compass"]
        case .personal: nouns = ["Pocket", "Anchor", "Quiet", "Habit", "Loop", "Margin"]
        case .creative: nouns = ["Echo", "Ember", "Drift", "Lantern", "Folio", "Murmur"]
        case .explore:  nouns = ["Spark", "Wander", "Hatch", "Pebble", "Curio", "Tinker"]
        }

        let qualifier: String
        switch choices["vibe"]?.key {
        case "useful":  qualifier = "Daily"
        case "playful": qualifier = "Funhouse"
        case "bold":    qualifier = "Loud"
        case "calm":    qualifier = "Slow"
        case "weird":   qualifier = "Odd"
        default:        qualifier = "Open"
        }

        let stem = nouns.randomElement() ?? "Spark"
        return "\(qualifier) \(stem)"
    }
}
