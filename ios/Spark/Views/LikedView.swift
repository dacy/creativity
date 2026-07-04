import SwiftUI
import SwiftData

struct LikedView: View {
    @Query(
        filter: #Predicate<Idea> { $0.statusRaw == "liked" },
        sort: \Idea.decidedAt,
        order: .reverse
    )
    private var likedIdeas: [Idea]

    var body: some View {
        NavigationStack {
            Group {
                if likedIdeas.isEmpty {
                    ContentUnavailableView(
                        "Nothing saved yet",
                        systemImage: "heart",
                        description: Text("Swipe right on ideas you like and they'll collect here.")
                    )
                } else {
                    List(likedIdeas) { idea in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(idea.title).font(.headline)
                            Text(idea.details)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 8) {
                                Text(idea.category.uppercased())
                                    .font(.caption2.bold())
                                    .foregroundStyle(.purple)
                                if let minutes = idea.durationMinutes {
                                    Text("~\(minutes) min")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Ideas you kept")
        }
    }
}
