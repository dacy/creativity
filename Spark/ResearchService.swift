import Foundation

/// Validates an idea after it's been generated.
///
/// Two modes:
///   - .startup     : focuses on competitive landscape, market risks, GTM hints.
///   - .buildVsBuy  : surfaces existing tools so the user can decide between
///                    building, buying, or just using something free.
///
/// We do this on-device with curated content keyed off the user's choices.
/// Swap `runMock` for a real API call (Claude / web search) when you're
/// ready — the shape of `ResearchResult` won't change.
enum ResearchService {

    /// Simulated network latency so the loading screen feels real.
    static func research(idea: GeneratedIdea, goal: Goal, choices: [String: Choice]) async -> ResearchResult {
        let nanos: UInt64 = 1_400_000_000
        try? await Task.sleep(nanoseconds: nanos)
        return runMock(idea: idea, goal: goal, choices: choices)
    }

    // MARK: - Mock

    private static func runMock(idea: GeneratedIdea, goal: Goal, choices: [String: Choice]) -> ResearchResult {
        let kind: ResearchKind = goal.researchAsStartup ? .startup : .buildVsBuy

        let solutions = existingSolutions(goal: goal, choices: choices)
        let opportunities = opportunityNotes(goal: goal, choices: choices)
        let risks = riskNotes(goal: goal, choices: choices)
        let verdict = decideVerdict(goal: goal, choices: choices, solutions: solutions)
        let nextSteps = nextStepsList(verdict: verdict, kind: kind)

        let summary = summary(kind: kind, idea: idea, solutions: solutions)

        return ResearchResult(
            kind: kind,
            summary: summary,
            existingSolutions: solutions,
            opportunities: opportunities,
            risks: risks,
            verdict: verdict,
            nextSteps: nextSteps
        )
    }

    private static func summary(kind: ResearchKind, idea: GeneratedIdea, solutions: [ExistingSolution]) -> String {
        switch kind {
        case .startup:
            if solutions.isEmpty {
                return "We couldn't find direct competitors. That's either an opening or a sign nobody wanted this — your job is to find out which."
            }
            return "There are \(solutions.count) credible incumbents in this space. The wedge for \"\(idea.title)\" needs to be sharper than 'better UX'."
        case .buildVsBuy:
            if solutions.isEmpty {
                return "Nothing off-the-shelf does exactly this. A small build is probably the right call."
            }
            return "Several existing tools cover most of \"\(idea.title)\". Buying or composing them is likely cheaper than building."
        }
    }

    // MARK: - Existing solutions

    private static func existingSolutions(goal: Goal, choices: [String: Choice]) -> [ExistingSolution] {
        switch goal {
        case .startup:
            switch choices["domain"]?.key {
            case "software":
                return [
                    ExistingSolution(name: "Notion + Zapier",   description: "DIY workflow stack many teams already pay for.", pricingHint: "$10–30/user/mo"),
                    ExistingSolution(name: "Vertical SaaS incumbents", description: "Established players with deep features and sticky contracts.", pricingHint: "Enterprise pricing"),
                    ExistingSolution(name: "Open-source alternative", description: "Self-hosted option with a small community.", pricingHint: "Free + hosting")
                ]
            case "product":
                return [
                    ExistingSolution(name: "Amazon white-label", description: "Generic options dominate search and price.", pricingHint: "$10–40"),
                    ExistingSolution(name: "Premium boutique brand", description: "Expensive niche brand with strong story.", pricingHint: "$80–200")
                ]
            case "service":
                return [
                    ExistingSolution(name: "Local providers", description: "Word-of-mouth providers with no online presence.", pricingHint: "Varies"),
                    ExistingSolution(name: "Marketplace aggregators", description: "Platforms that match clients with pros.", pricingHint: "15–25% take rate")
                ]
            case "media":
                return [
                    ExistingSolution(name: "Substack / YouTube creators", description: "Independent creators owning the niche.", pricingHint: "$5–10/mo or ad-supported"),
                    ExistingSolution(name: "Legacy publications", description: "Slow but trusted. Hard to displace.", pricingHint: "$10–20/mo")
                ]
            case "marketplace":
                return [
                    ExistingSolution(name: "Etsy/eBay-style horizontal", description: "Wide selection, weak curation.", pricingHint: "5–15% fees"),
                    ExistingSolution(name: "Vertical incumbent", description: "Existing niche marketplace with two-sided lock-in.", pricingHint: "10–20% fees")
                ]
            default:
                return []
            }

        case .personal:
            switch choices["area"]?.key {
            case "productivity":
                return [
                    ExistingSolution(name: "Apple Reminders + Shortcuts", description: "Free and probably enough for 80% of cases.", pricingHint: "Free"),
                    ExistingSolution(name: "Todoist / Things 3",          description: "Polished task apps with deep features.",   pricingHint: "$5/mo or $50 once"),
                    ExistingSolution(name: "Notion / Obsidian",           description: "DIY systems if you like to tinker.",       pricingHint: "Free–$10/mo")
                ]
            case "health":
                return [
                    ExistingSolution(name: "Apple Health + Streaks",      description: "Built-in habit tracking on iOS.",          pricingHint: "Free–$5"),
                    ExistingSolution(name: "Strong / MyFitnessPal",       description: "Vertical health trackers.",                pricingHint: "Free or $5–10/mo")
                ]
            case "home":
                return [
                    ExistingSolution(name: "Shared Reminders / Notes",    description: "iCloud sharing covers the basics.",        pricingHint: "Free"),
                    ExistingSolution(name: "Cozi / FamilyWall",           description: "Family-shared calendars and lists.",       pricingHint: "Free–$30/yr")
                ]
            case "money":
                return [
                    ExistingSolution(name: "Copilot Money",               description: "Polished iOS budgeting app.",              pricingHint: "$95/yr"),
                    ExistingSolution(name: "Apple Wallet + Numbers",      description: "DIY tracking with the built-ins.",         pricingHint: "Free")
                ]
            case "hobby":
                return [
                    ExistingSolution(name: "Discord communities",         description: "Free, social, low pressure.",              pricingHint: "Free"),
                    ExistingSolution(name: "Niche forums",                description: "Slow but full of expertise.",              pricingHint: "Free")
                ]
            default:
                return []
            }

        case .creative:
            return [
                ExistingSolution(name: "Existing creator templates", description: "Plenty of templates and starters in your medium.", pricingHint: "Often free"),
                ExistingSolution(name: "Established works in the genre", description: "Study them, then deviate on purpose.", pricingHint: "—")
            ]

        case .explore:
            return [
                ExistingSolution(name: "Free no-code tools", description: "Glide, Softr, Bubble cover most prototypes.", pricingHint: "Free–$20/mo"),
                ExistingSolution(name: "Apple Shortcuts",   description: "Often enough for personal experiments.",        pricingHint: "Free")
            ]
        }
    }

    private static func opportunityNotes(goal: Goal, choices: [String: Choice]) -> [String] {
        switch goal {
        case .startup:
            var notes = [
                "If the pain you picked is real for 1% of the audience, that's still a viable wedge.",
                "Sharp focus on a single workflow beats broad coverage in year one."
            ]
            if choices["constraint"]?.key == "shareable" {
                notes.append("Built-in sharing turns each user into a distribution channel.")
            }
            if choices["audience"]?.key == "developers" || choices["audience"]?.key == "creators" {
                notes.append("Developer/creator audiences are reachable cheaply — DM, Discord, indie newsletters.")
            }
            return notes
        case .personal:
            return [
                "If it saves you 10 minutes a day, it's worth building even if no one else uses it.",
                "Start by doing it manually for two weeks before automating anything."
            ]
        case .creative:
            return [
                "Constraint plus emotion is enough — you don't need a giant concept.",
                "Make a tiny version first. Ship it to one person."
            ]
        case .explore:
            return [
                "Treat this as a 4-hour experiment, not a project.",
                "Set a hard budget — time and money — before you start."
            ]
        }
    }

    private static func riskNotes(goal: Goal, choices: [String: Choice]) -> [String] {
        switch goal {
        case .startup:
            var risks = [
                "Incumbents can copy any single feature in a quarter. The moat is taste, speed, or a real audience.",
                "Distribution is harder than the build. Plan how the first 100 users hear about it."
            ]
            if choices["domain"]?.key == "marketplace" {
                risks.append("Marketplaces are cold-start problems. Solve one side first.")
            }
            if choices["domain"]?.key == "product" {
                risks.append("Physical inventory ties up cash. Pre-orders before manufacturing.")
            }
            return risks
        case .personal:
            return [
                "You're optimizing for yourself — beware solving a problem nobody else has.",
                "Maintenance is the real tax. Keep the surface area small."
            ]
        case .creative:
            return [
                "The biggest risk is not finishing. Reduce scope until 'done' is one sitting.",
                "Originality fades when you over-research. Make the thing first, study after."
            ]
        case .explore:
            return [
                "Scope creep will eat the weekend. Cut features, not corners."
            ]
        }
    }

    private static func decideVerdict(goal: Goal, choices: [String: Choice], solutions: [ExistingSolution]) -> Verdict {
        switch goal {
        case .startup:
            if solutions.count >= 3 { return .explore }
            return .startup
        case .personal:
            let cheapAlternatives = solutions.contains { $0.pricingHint.lowercased().contains("free") }
            if cheapAlternatives { return .buy }
            return .build
        case .creative:
            return .build
        case .explore:
            if choices["constraint"]?.key == "weekend" { return .build }
            return .explore
        }
    }

    private static func nextStepsList(verdict: Verdict, kind: ResearchKind) -> [String] {
        switch verdict {
        case .startup:
            return [
                "Write the landing page first. One headline, one CTA, one screenshot.",
                "Talk to 5 potential users this week. Don't pitch — listen.",
                "Define the one metric that proves it's working."
            ]
        case .build:
            return [
                "Strip the idea to one screen / one flow.",
                "Box it to a weekend. If it slips, ship what's done.",
                "Use it yourself for 7 days before showing anyone."
            ]
        case .buy:
            return [
                "Pick the cheapest existing tool that gets to 80%.",
                "Use it for 2 weeks. If 80% is enough, you saved a build.",
                "Only build the missing 20% if it's still painful after that."
            ]
        case .explore:
            return [
                "List the 3 unanswered questions that would change your decision.",
                "Spend 1 hour answering each before doing anything else.",
                "Re-decide after that hour."
            ]
        case .skip:
            return [
                "Park it. Note the trigger that brought it up.",
                "Revisit in a month — if it's still nagging, it's real."
            ]
        }
    }
}
