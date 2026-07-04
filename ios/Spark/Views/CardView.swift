import SwiftUI

/// A draggable idea card. Swipe right = like, left = dislike;
/// releases past the threshold fly off and report the decision.
struct CardView: View {
    let idea: Idea
    /// Set by the parent's ♥ / ✕ buttons to trigger the same fly-out
    /// animation as a drag. Reset to nil by the parent after each card.
    @Binding var forcedDecision: Bool?
    let onDecision: (_ liked: Bool) -> Void

    @State private var offset: CGSize = .zero
    @State private var isFlyingOut = false

    private let threshold: CGFloat = 110

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(.secondarySystemBackground), Color(.tertiarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.35), radius: 14, y: 8)

            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text(idea.category.uppercased())
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.purple.opacity(0.2), in: Capsule())
                        .foregroundStyle(.purple)
                    if let minutes = idea.durationMinutes {
                        Text("~\(minutes) min")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(.white.opacity(0.08), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Text(idea.title)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)

                Text(idea.details)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(24)

            // LIKE / NOPE stamps that fade in as you drag
            HStack {
                stamp("LIKE", color: .green, rotation: -14)
                    .opacity(min(max(offset.width / threshold, 0), 1))
                Spacer()
                stamp("NOPE", color: .red, rotation: 14)
                    .opacity(min(max(-offset.width / threshold, 0), 1))
            }
            .padding(20)
        }
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(offset.width / 18))
        .opacity(isFlyingOut ? 0 : 1)
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard !isFlyingOut else { return }
                    offset = value.translation
                }
                .onEnded { value in
                    guard !isFlyingOut else { return }
                    if value.translation.width > threshold {
                        fly(liked: true)
                    } else if value.translation.width < -threshold {
                        fly(liked: false)
                    } else {
                        withAnimation(.spring(duration: 0.3)) { offset = .zero }
                    }
                }
        )
        .animation(.easeOut(duration: 0.22), value: isFlyingOut)
        .onChange(of: forcedDecision) { _, newValue in
            if let liked = newValue {
                fly(liked: liked)
            }
        }
    }

    private func fly(liked: Bool) {
        guard !isFlyingOut else { return }
        isFlyingOut = true
        withAnimation(.easeOut(duration: 0.22)) {
            offset = CGSize(width: liked ? 600 : -600, height: offset.height)
        }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            onDecision(liked)
        }
    }

    private func stamp(_ text: String, color: Color, rotation: Double) -> some View {
        Text(text)
            .font(.title.bold())
            .kerning(2)
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 3))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
    }
}
