import Foundation

/// A small, hand-curated decision tree. Every step is a tap target:
/// the user picks one chip and moves on. Each path always ends in a
/// "vibe" + "constraint" pair so the synthesizer has enough texture
/// to generate a concrete idea.
enum DecisionTree {

    static func steps(for goal: Goal) -> [Step] {
        switch goal {
        case .startup:  return startupPath
        case .personal: return personalPath
        case .creative: return creativePath
        case .explore:  return explorePath
        }
    }

    // Common closers reused by every path.
    private static let vibeStep = Step(
        key: "vibe",
        prompt: "What vibe should it have?",
        helper: "Pick the feeling, not the feature.",
        choices: [
            Choice(key: "useful",   label: "Quietly useful", emoji: "🛠"),
            Choice(key: "playful",  label: "Playful",        emoji: "🎈"),
            Choice(key: "bold",     label: "Bold & bossy",   emoji: "⚡️"),
            Choice(key: "calm",     label: "Calming",        emoji: "🌊"),
            Choice(key: "weird",    label: "A little weird", emoji: "🌀"),
            Choice(key: "surprise", label: "Surprise me",    emoji: "🎲")
        ],
        allowSkip: true
    )

    private static let constraintStep = Step(
        key: "constraint",
        prompt: "What constraint excites you?",
        helper: "A good constraint sharpens the idea.",
        choices: [
            Choice(key: "weekend",   label: "Ship in a weekend",  emoji: "🏁"),
            Choice(key: "cheap",     label: "Almost free to run", emoji: "🪙"),
            Choice(key: "original",  label: "Highly original",    emoji: "🌈"),
            Choice(key: "shareable", label: "Easy to share",      emoji: "📣"),
            Choice(key: "offline",   label: "Works offline",      emoji: "📴"),
            Choice(key: "surprise",  label: "Surprise me",        emoji: "🎲")
        ],
        allowSkip: true
    )

    // MARK: Startup path

    private static let startupPath: [Step] = [
        Step(
            key: "domain",
            prompt: "Which domain pulls you in?",
            helper: nil,
            choices: [
                Choice(key: "software",   label: "Software / AI",       emoji: "🧠"),
                Choice(key: "product",    label: "Physical product",    emoji: "📦"),
                Choice(key: "service",    label: "Hands-on service",    emoji: "🤝"),
                Choice(key: "media",      label: "Content / media",     emoji: "🎬"),
                Choice(key: "marketplace",label: "Marketplace",         emoji: "🛒"),
                Choice(key: "surprise",   label: "Surprise me",         emoji: "🎲")
            ],
            allowSkip: false
        ),
        Step(
            key: "audience",
            prompt: "Who would pay for it?",
            helper: nil,
            choices: [
                Choice(key: "consumers",     label: "Everyday people",       emoji: "🧑‍🤝‍🧑"),
                Choice(key: "professionals", label: "Working professionals", emoji: "💼"),
                Choice(key: "smb",           label: "Small businesses",      emoji: "🏪"),
                Choice(key: "developers",    label: "Developers / makers",   emoji: "👩‍💻"),
                Choice(key: "creators",      label: "Creators",              emoji: "🎙"),
                Choice(key: "surprise",      label: "Surprise me",           emoji: "🎲")
            ],
            allowSkip: false
        ),
        Step(
            key: "pain",
            prompt: "What pain do you want to kill?",
            helper: "Pick the one that makes you angry.",
            choices: [
                Choice(key: "time",       label: "Wastes too much time",     emoji: "⏰"),
                Choice(key: "money",      label: "Costs too much money",     emoji: "💸"),
                Choice(key: "fragmented", label: "Tools are fragmented",     emoji: "🧩"),
                Choice(key: "boring",     label: "Feels tedious or boring",  emoji: "😴"),
                Choice(key: "scary",      label: "Feels intimidating",       emoji: "😬"),
                Choice(key: "surprise",   label: "Surprise me",              emoji: "🎲")
            ],
            allowSkip: false
        ),
        vibeStep,
        constraintStep
    ]

    // MARK: Personal path

    private static let personalPath: [Step] = [
        Step(
            key: "area",
            prompt: "Which slice of life?",
            helper: nil,
            choices: [
                Choice(key: "productivity", label: "Productivity / time",  emoji: "⏳"),
                Choice(key: "health",       label: "Health / wellness",   emoji: "🏃‍♀️"),
                Choice(key: "home",         label: "Home / family",        emoji: "🏡"),
                Choice(key: "money",        label: "Money / spending",    emoji: "🧾"),
                Choice(key: "hobby",        label: "Hobbies / fun",        emoji: "🎮"),
                Choice(key: "surprise",     label: "Surprise me",          emoji: "🎲")
            ],
            allowSkip: false
        ),
        Step(
            key: "frequency",
            prompt: "How often does the friction hit you?",
            helper: nil,
            choices: [
                Choice(key: "daily",   label: "Every single day",  emoji: "📅"),
                Choice(key: "weekly",  label: "A few times a week",emoji: "🗓"),
                Choice(key: "monthly", label: "Monthly",           emoji: "📆"),
                Choice(key: "rare",    label: "Rare but painful",  emoji: "💥"),
                Choice(key: "surprise",label: "Surprise me",       emoji: "🎲")
            ],
            allowSkip: true
        ),
        Step(
            key: "trigger",
            prompt: "What sets it off?",
            helper: nil,
            choices: [
                Choice(key: "decision", label: "Too many decisions",  emoji: "🤯"),
                Choice(key: "memory",   label: "Things I forget",     emoji: "🧠"),
                Choice(key: "habit",    label: "Habit I can't keep",  emoji: "🔁"),
                Choice(key: "noise",    label: "Information overload",emoji: "📣"),
                Choice(key: "lonely",   label: "Doing it alone",      emoji: "🪑"),
                Choice(key: "surprise", label: "Surprise me",         emoji: "🎲")
            ],
            allowSkip: false
        ),
        vibeStep,
        constraintStep
    ]

    // MARK: Creative path

    private static let creativePath: [Step] = [
        Step(
            key: "medium",
            prompt: "What medium calls you?",
            helper: nil,
            choices: [
                Choice(key: "visual",    label: "Visual art / design",  emoji: "🖼"),
                Choice(key: "writing",   label: "Writing / story",      emoji: "✍️"),
                Choice(key: "music",     label: "Music / audio",        emoji: "🎵"),
                Choice(key: "video",     label: "Video / film",         emoji: "📹"),
                Choice(key: "interactive",label: "Interactive / game",  emoji: "🕹"),
                Choice(key: "surprise",  label: "Surprise me",          emoji: "🎲")
            ],
            allowSkip: false
        ),
        Step(
            key: "emotion",
            prompt: "What emotion should it leave behind?",
            helper: nil,
            choices: [
                Choice(key: "wonder",   label: "Wonder",     emoji: "🌌"),
                Choice(key: "laugh",    label: "A laugh",    emoji: "😂"),
                Choice(key: "ache",     label: "A sweet ache", emoji: "💔"),
                Choice(key: "comfort",  label: "Comfort",    emoji: "🧸"),
                Choice(key: "rage",     label: "Righteous rage", emoji: "🔥"),
                Choice(key: "surprise", label: "Surprise me",emoji: "🎲")
            ],
            allowSkip: false
        ),
        Step(
            key: "scope",
            prompt: "How big should it be?",
            helper: nil,
            choices: [
                Choice(key: "tiny",     label: "Tiny — one sitting", emoji: "🐣"),
                Choice(key: "weekend",  label: "A weekend project",  emoji: "🏕"),
                Choice(key: "series",   label: "A series",           emoji: "📚"),
                Choice(key: "lifetime", label: "Long-haul",          emoji: "🗿"),
                Choice(key: "surprise", label: "Surprise me",        emoji: "🎲")
            ],
            allowSkip: true
        ),
        vibeStep,
        constraintStep
    ]

    // MARK: Explore path (lighter, fewer questions)

    private static let explorePath: [Step] = [
        Step(
            key: "energy",
            prompt: "What kind of energy are you in?",
            helper: nil,
            choices: [
                Choice(key: "curious", label: "Curious",        emoji: "🦊"),
                Choice(key: "restless",label: "Restless",       emoji: "🌪"),
                Choice(key: "cozy",    label: "Cozy",           emoji: "🛋"),
                Choice(key: "ambitious",label:"Ambitious",      emoji: "🦅"),
                Choice(key: "surprise",label: "Surprise me",    emoji: "🎲")
            ],
            allowSkip: false
        ),
        Step(
            key: "ingredient",
            prompt: "Pick a wildcard ingredient.",
            helper: "We'll bend the idea around it.",
            choices: [
                Choice(key: "ai",       label: "AI assistant",    emoji: "🤖"),
                Choice(key: "physical", label: "Something physical", emoji: "🧱"),
                Choice(key: "social",   label: "Other people",    emoji: "🫂"),
                Choice(key: "nature",   label: "The outdoors",    emoji: "🌲"),
                Choice(key: "ritual",   label: "A daily ritual",  emoji: "🕯"),
                Choice(key: "surprise", label: "Surprise me",     emoji: "🎲")
            ],
            allowSkip: false
        ),
        vibeStep,
        constraintStep
    ]

    /// If the user picked "surprise me" we resolve it to a real choice
    /// at synthesis time so the idea has concrete material to work with.
    static func resolveSurprises(in choices: [String: Choice], for goal: Goal) -> [String: Choice] {
        var resolved = choices
        for step in steps(for: goal) {
            if let picked = resolved[step.key], picked.key == "surprise" {
                let real = step.choices.filter { $0.key != "surprise" }
                if let pick = real.randomElement() {
                    resolved[step.key] = pick
                }
            }
        }
        return resolved
    }
}
