import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var profiles: [TasteProfile]
    @Query(
        filter: #Predicate<Idea> { $0.statusRaw == "liked" },
        sort: \Idea.decidedAt,
        order: .reverse
    )
    private var likedIdeas: [Idea]
    @Query(
        filter: #Predicate<Idea> { $0.statusRaw == "disliked" },
        sort: \Idea.decidedAt,
        order: .reverse
    )
    private var dislikedIdeas: [Idea]
    @Query private var allIdeas: [Idea]

    private var profile: TasteProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Inferred purely from your swipes — Spark never asks, it just watches. Everything is computed and stored on this device.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let profile, !profile.content.isEmpty {
                        Text(LocalizedStringKey(profile.content))
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))

                        Text("Based on \(profile.swipeCount) swipes\(profile.updatedAt.map { " · updated \($0.formatted(.relative(presentation: .named)))" } ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ContentUnavailableView(
                            "No profile yet",
                            systemImage: "sparkles",
                            description: Text("Swipe on a handful of ideas and Spark will start forming a read on your taste.")
                        )
                    }

                    exportSection
                }
                .padding()
            }
            .navigationTitle("What Spark thinks you like")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Take your insights elsewhere")
                .font(.headline)
            Text("Export what Spark has learned and paste it into any LLM you use — ChatGPT, Claude, Gemini, or your own. Export is the only time data leaves this device.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let profile {
                ShareLink(
                    item: InsightExporter.markdown(
                        profile: profile,
                        liked: likedIdeas,
                        disliked: dislikedIdeas
                    ),
                    preview: SharePreview("Spark taste dossier")
                ) {
                    Label("Share taste dossier (Markdown)", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                ShareLink(
                    item: InsightExporter.json(profile: profile, ideas: allIdeas),
                    preview: SharePreview("Spark data export (JSON)")
                ) {
                    Label("Share full data (JSON)", systemImage: "curlybraces")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else {
                Text("Nothing to export yet.")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 8)
    }
}
