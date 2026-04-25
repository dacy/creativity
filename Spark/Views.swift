import SwiftUI

// MARK: - Welcome

struct WelcomeView: View {
    @EnvironmentObject private var session: IdeaSession

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Spark")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.primaryAccent)
                Text("Tap your way to a creative idea — and find out if it's worth pursuing.")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.top, 32)

            Text("What kind of idea are we sparking?")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 8)

            VStack(spacing: 12) {
                ForEach(Goal.allCases) { goal in
                    Button {
                        select(goal)
                    } label: {
                        GoalRow(goal: goal)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            Text("No typing required — but you can always add detail later.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.5))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 8)
        }
        .padding(24)
    }

    private func select(_ goal: Goal) {
        session.goal = goal
        session.screen = .decisions(stepIndex: 0)
    }
}

private struct GoalRow: View {
    let goal: Goal
    var body: some View {
        HStack(spacing: 16) {
            Text(goal.emoji).font(.system(size: 36))
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.rawValue)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(goal.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .multilineTextAlignment(.leading)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.45))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Decision step

struct DecisionStepView: View {
    @EnvironmentObject private var session: IdeaSession
    let stepIndex: Int

    private var step: Step { session.steps[stepIndex] }
    private var totalSteps: Int { session.steps.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeaderBar(
                progress: Double(stepIndex) / Double(max(totalSteps, 1)),
                back: { goBack() },
                title: "Step \(stepIndex + 1) of \(totalSteps)"
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(step.prompt)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                if let helper = step.helper {
                    Text(helper)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 4)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(step.choices) { choice in
                        Button {
                            pick(choice)
                        } label: {
                            ChoiceRow(
                                choice: choice,
                                selected: session.choices[step.key]?.id == choice.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)

            if step.allowSkip, let surprise = step.choices.first(where: { $0.key == "surprise" }) {
                Button {
                    pick(surprise)
                } label: {
                    Text("Skip — let Spark choose")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
    }

    private func pick(_ choice: Choice) {
        session.choose(choice, forStepKey: step.key)
        let next = stepIndex + 1
        if next < totalSteps {
            session.screen = .decisions(stepIndex: next)
        } else {
            session.screen = .clarify
        }
    }

    private func goBack() {
        if stepIndex == 0 {
            session.reset()
        } else {
            session.screen = .decisions(stepIndex: stepIndex - 1)
        }
    }
}

private struct ChoiceRow: View {
    let choice: Choice
    let selected: Bool
    var body: some View {
        HStack(spacing: 14) {
            Text(choice.emoji).font(.system(size: 28))
            Text(choice.label)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.primaryAccent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(selected: selected)
    }
}

// MARK: - Header / progress

private struct HeaderBar: View {
    let progress: Double
    let back: () -> Void
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button(action: back) {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(10)
                        .background(Circle().fill(.white.opacity(0.08)))
                }
                Spacer()
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.65))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.1)).frame(height: 4)
                    Capsule().fill(Theme.primaryAccent)
                        .frame(width: max(8, geo.size.width * progress), height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Clarify (optional free text, with "skip" preset)

struct ClarifyView: View {
    @EnvironmentObject private var session: IdeaSession
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HeaderBar(
                progress: 1.0,
                back: { session.screen = .decisions(stepIndex: max(session.steps.count - 1, 0)) },
                title: "Optional clarification"
            )

            VStack(alignment: .leading, spacing: 6) {
                Text("Anything specific bouncing around?")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("One sentence is plenty. You can skip this — Spark will work fine without it.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            ZStack(alignment: .topLeading) {
                if session.clarification.isEmpty {
                    Text("e.g. \"something I could build with my kid\"")
                        .foregroundStyle(.white.opacity(0.35))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $session.clarification)
                    .focused($focused)
                    .scrollContentBackground(.hidden)
                    .foregroundStyle(.white)
                    .padding(8)
            }
            .frame(minHeight: 120)
            .cardStyle()

            VStack(spacing: 10) {
                Button(action: generate) {
                    Text("Spark my idea")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.primaryAccent)
                        )
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                Button {
                    session.clarification = ""
                    generate()
                } label: {
                    Text("Skip — use my taps as-is")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(20)
        .onAppear { focused = false }
    }

    private func generate() {
        session.screen = .generating
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard let goal = session.goal else { return }
            session.idea = IdeaGenerator.generate(
                goal: goal,
                choices: session.choices,
                clarification: session.clarification
            )
            session.screen = .idea
        }
    }
}

// MARK: - Generating spinner

struct GeneratingView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("✨")
                .font(.system(size: 64))
                .scaleEffect(1.0)
            Text("Sparking...")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            ProgressView().tint(Theme.primaryAccent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Idea

struct IdeaView: View {
    @EnvironmentObject private var session: IdeaSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Button {
                        session.screen = .clarify
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }
                    Spacer()
                    Button("Start over") { session.reset() }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                if let idea = session.idea {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your spark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(Theme.primaryAccent)
                        Text(idea.title)
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text(idea.oneLiner)
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    IdeaSection(title: "Problem",  body: idea.problem)
                    IdeaSection(title: "Who it's for", body: idea.user)
                    IdeaSection(title: "Solution", body: idea.solution)
                    IdeaSection(title: "Twist",    body: idea.twist)
                }

                VStack(spacing: 10) {
                    Button(action: research) {
                        Text(researchCTA)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Theme.primaryAccent)
                            )
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)

                    Button {
                        regenerate()
                    } label: {
                        Text("Try a different spark")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .foregroundStyle(.white.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
            .padding(20)
        }
    }

    private var researchCTA: String {
        guard let goal = session.goal else { return "Research it" }
        return goal.researchAsStartup ? "Research the market" : "Should I build or buy?"
    }

    private func research() {
        session.screen = .researching
        Task { @MainActor in
            guard let goal = session.goal, let idea = session.idea else { return }
            let result = await ResearchService.research(idea: idea, goal: goal, choices: session.choices)
            session.research = result
            session.screen = .research
        }
    }

    private func regenerate() {
        guard let goal = session.goal else { return }
        session.idea = IdeaGenerator.generate(
            goal: goal,
            choices: session.choices,
            clarification: session.clarification
        )
    }
}

private struct IdeaSection: View {
    let title: String
    let body: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.6))
            Text(self.body)
                .font(.body)
                .foregroundStyle(.white.opacity(0.92))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

// MARK: - Researching spinner

struct ResearchingView: View {
    @State private var phaseIndex: Int = 0
    private let phases = [
        "Scanning the landscape...",
        "Looking for incumbents...",
        "Weighing build vs. buy...",
        "Sketching next steps..."
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("🔎").font(.system(size: 64))
            Text(phases[phaseIndex])
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            ProgressView().tint(Theme.primaryAccent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .task {
            for i in 0..<phases.count {
                try? await Task.sleep(nanoseconds: 350_000_000)
                phaseIndex = i
            }
        }
    }
}

// MARK: - Research result

struct ResearchView: View {
    @EnvironmentObject private var session: IdeaSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Button {
                        session.screen = .idea
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(10)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }
                    Spacer()
                    Button("Start over") { session.reset() }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                }

                if let r = session.research {
                    VerdictCard(verdict: r.verdict)

                    SectionBlock(title: "Summary") {
                        Text(r.summary)
                            .foregroundStyle(.white.opacity(0.92))
                    }

                    if !r.existingSolutions.isEmpty {
                        SectionBlock(title: r.kind == .startup ? "Competitive landscape" : "What already exists") {
                            VStack(spacing: 10) {
                                ForEach(r.existingSolutions) { sol in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundStyle(Theme.secondaryAccent)
                                            .padding(.top, 8)
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text(sol.name)
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundStyle(.white)
                                                Spacer()
                                                Text(sol.pricingHint)
                                                    .font(.caption.weight(.semibold))
                                                    .foregroundStyle(.white.opacity(0.6))
                                            }
                                            Text(sol.description)
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.75))
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SectionBlock(title: "Where it could win") {
                        BulletList(items: r.opportunities, color: .green)
                    }

                    SectionBlock(title: "What to watch out for") {
                        BulletList(items: r.risks, color: .orange)
                    }

                    SectionBlock(title: "Next steps") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(r.nextSteps.enumerated()), id: \.offset) { idx, step in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(idx + 1)")
                                        .font(.footnote.weight(.bold))
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(Theme.primaryAccent.opacity(0.25)))
                                        .foregroundStyle(Theme.primaryAccent)
                                    Text(step).foregroundStyle(.white.opacity(0.92))
                                }
                            }
                        }
                    }
                }

                Button {
                    session.reset()
                } label: {
                    Text("Spark another idea")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.primaryAccent)
                        )
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
            }
            .padding(20)
        }
    }
}

private struct VerdictCard: View {
    let verdict: Verdict
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VERDICT")
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.65))
            HStack(spacing: 14) {
                Text(verdict.emoji).font(.system(size: 40))
                Text(verdict.rawValue)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.white)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(verdict.color.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(verdict.color.opacity(0.6), lineWidth: 1.5)
        )
    }
}

private struct SectionBlock<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.6))
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

private struct BulletList: View {
    let items: [String]
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(color)
                        .padding(.top, 8)
                    Text(item).foregroundStyle(.white.opacity(0.92))
                }
            }
        }
    }
}
