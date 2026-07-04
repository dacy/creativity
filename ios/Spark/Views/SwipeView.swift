import SwiftUI
import SwiftData

struct SwipeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SwipeViewModel()
    @State private var forcedDecision: Bool?

    private let suggestions = [
        "I have 30 minutes and want something fun",
        "Rainy afternoon, low energy, at home",
        "Something creative with my kids this weekend",
        "Free evening, want to learn something new",
        "Outdoors, under an hour, no spending",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Describe your time, energy, and constraints. Swipe right to keep an idea, left to pass — Spark learns your taste as you go, entirely on this device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    criteriaForm

                    if let notice = viewModel.mockNotice {
                        infoBanner(notice)
                    }
                    if viewModel.profileJustUpdated {
                        infoBanner("✦ Spark just updated its read on your taste — see the Your taste tab.")
                    }
                    if let error = viewModel.errorMessage {
                        infoBanner("⚠ \(error)")
                    }

                    if viewModel.activeCriteria != nil {
                        cardStack
                        actionButtons
                    }
                }
                .padding()
            }
            .navigationTitle("✦ Spark")
        }
    }

    private var criteriaForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(
                "e.g. I have 30 minutes, at home, medium energy…",
                text: $viewModel.criteriaInput,
                axis: .vertical
            )
            .lineLimit(2...4)
            .textFieldStyle(.plain)
            .padding(14)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(suggestion) {
                            viewModel.criteriaInput = suggestion
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color(.secondarySystemBackground), in: Capsule())
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Button {
                Task { await viewModel.startSession(context: modelContext) }
            } label: {
                if viewModel.isLoading {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text(viewModel.activeCriteria == nil ? "Get ideas" : "New criteria, new ideas")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isLoading || viewModel.criteriaInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    private var cardStack: some View {
        ZStack {
            if viewModel.queue.isEmpty {
                VStack(spacing: 12) {
                    if viewModel.isLoading {
                        ProgressView()
                        Text("Dreaming up ideas…").foregroundStyle(.secondary)
                    } else {
                        Text("Out of ideas for now — more are coming, or tweak your criteria.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Static preview of the next card, behind the active one.
            if viewModel.queue.count > 1 {
                let next = viewModel.queue[1]
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(alignment: .topLeading) {
                        Text(next.title)
                            .font(.title3.bold())
                            .padding(24)
                    }
                    .scaleEffect(0.95)
                    .offset(y: 12)
            }

            if let current = viewModel.queue.first {
                CardView(idea: current, forcedDecision: $forcedDecision) { liked in
                    forcedDecision = nil
                    Task { await viewModel.decide(current, liked: liked, context: modelContext) }
                }
                .id(current.persistentModelID)
            }
        }
        .frame(height: 400)
    }

    private var actionButtons: some View {
        HStack(spacing: 28) {
            Spacer()
            Button {
                forcedDecision = false
            } label: {
                Image(systemName: "xmark")
                    .font(.title2.bold())
                    .frame(width: 60, height: 60)
                    .background(Color(.secondarySystemBackground), in: Circle())
                    .foregroundStyle(.red)
            }
            Button {
                forcedDecision = true
            } label: {
                Image(systemName: "heart.fill")
                    .font(.title2.bold())
                    .frame(width: 60, height: 60)
                    .background(Color(.secondarySystemBackground), in: Circle())
                    .foregroundStyle(.green)
            }
            Spacer()
        }
        .opacity(viewModel.queue.isEmpty ? 0.4 : 1)
        .disabled(viewModel.queue.isEmpty)
    }

    private func infoBanner(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }
}
